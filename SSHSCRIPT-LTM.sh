#!/bin/bash
# ═══════════════════════════════════════════════════════
#   SSHFREE LTM — Gestor de Servicios VPN/SSH
#   by DarkZFull • @DarkZFull
#   Ubuntu 22/24/25
# ═══════════════════════════════════════════════════════

# Colores
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' W='\033[1;37m' P='\033[0;35m'
B='\033[0;34m' NC='\033[0m' BOLD='\033[1m'

# Directorios
DIR_SCRIPTS="/etc/sshfreeltm"
DIR_SERVICES="/etc/systemd/system"
mkdir -p $DIR_SCRIPTS

# ── Banner ──
banner() {
    clear
    echo -e "${C}"
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║     SSHFREE LTM — Gestor VPN/SSH          ║"
    echo "  ║     by DarkZFull • t.me/ltmdkz             ║"
    echo "  ╚═══════════════════════════════════════════╝${NC}"
    echo ""
}

sep() { echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# ── Verificar si servicio está activo ──
status_service() {
    local name=$1
    if systemctl is-active --quiet "$name" 2>/dev/null; then
        echo -e "${G}[ON]${NC}"
    else
        echo -e "${R}[OFF]${NC}"
    fi
}

status_port() {
    local port=$1
    local proto=${2:-tcp}
    if ss -${proto}lnp 2>/dev/null | grep -q ":${port} "; then
        echo -e "${G}[ON]${NC}"
    else
        echo -e "${R}[OFF]${NC}"
    fi
}

# ══════════════════════════════════════════
#   WEBSOCKET PYTHON (Proxy3 WS)
# ══════════════════════════════════════════

instalar_ws() {
    banner
    sep
    echo -e "  ${Y}Configurar WebSocket Python (Proxy3 WS)${NC}"
    sep
    echo ""

    # Puerto WS
    echo -e "  ${W}Puerto WebSocket (ej: 80):${NC}"
    read -p "  Puerto: " WS_PORT
    WS_PORT=${WS_PORT:-80}

    # Puerto redireccion
    echo ""
    echo -e "  ${W}Puerto local SSH/Dropbear (ej: 22):${NC}"
    read -p "  Puerto local: " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}

    # Response
    echo ""
    sep
    echo -e "  ${W}RESPONDE DE CABECERA (101, 200, 400, etc)${NC}"
    echo -e "  ${Y}NOTA: Para OVER WEBSOCKET usa [ 101 ]${NC}"
    sep
    read -p "  RESPONSE: " STATUS_RESP
    STATUS_RESP=${STATUS_RESP:-200}

    # Mini banner
    echo ""
    sep
    echo -e "  ${W}Mini-Banner (texto que aparece en la conexión):${NC}"
    read -p "  Banner: " BANNER_MSG
    BANNER_MSG=${BANNER_MSG:-"SSHFREE LTM by DarkZFull"}

    # Encabezado
    echo ""
    sep
    echo -e "  ${W}Encabezado personalizado (ENTER para default):${NC}"
    echo -e "  ${Y}Ejemplo: \\r\\nContent-length: 0\\r\\n\\r\\nHTTP/1.1 200 Connection Established\\r\\n\\r\\n${NC}"
    sep
    read -p "  Cabecera: " CUSTOM_HEADER
    if [ -z "$CUSTOM_HEADER" ]; then
        CUSTOM_HEADER="\r\nContent-length: 0\r\n\r\nHTTP/1.1 200 Connection Established\r\n\r\n"
    fi

    echo ""
    echo -e "  ${C}Creando script WebSocket...${NC}"

    # Crear el script Python
    cat > $DIR_SCRIPTS/proxy_ws_${WS_PORT}.py << PYEOF
#!/usr/bin/env python3
# encoding: utf-8
# SSHFREE LTM WebSocket Proxy — by DarkZFull
import socket, threading, select, sys, time

LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = ${WS_PORT}
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = b'127.0.0.1:${SSH_PORT}'
MSG = '${BANNER_MSG}'.encode('utf-8')
STATUS_RESP = b'${STATUS_RESP}'
FTAG = b'${CUSTOM_HEADER}'
RESPONSE = b'HTTP/1.1 ' + STATUS_RESP + b' ' + MSG + b' ' + FTAG

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()
    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, int(self.port)))
        self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()
    def printLog(self, log):
        self.logLock.acquire()
        print(log)
        self.logLock.release()
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()
    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()
    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = b''
        self.server = server
        self.log = 'Connection: ' + str(addr)
    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except: pass
        finally: self.clientClosed = True
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except: pass
        finally: self.targetClosed = True
    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, b'X-Real-Host')
            if hostPort == b'': hostPort = DEFAULT_HOST
            split = self.findHeader(self.client_buffer, b'X-Split')
            if split != b'': self.client.recv(BUFLEN)
            if hostPort != b'':
                passwd = self.findHeader(self.client_buffer, b'X-Pass')
                if hostPort.startswith(b'127.0.0.1') or hostPort.startswith(b'localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send(b'HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                self.client.send(b'HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + str(e)
            self.server.printLog(self.log)
        finally:
            self.close()
            self.server.removeConn(self)
    def findHeader(self, head, header):
        aux = head.find(header + b': ')
        if aux == -1: return b''
        aux = head.find(b':', aux)
        head = head[aux + 2:]
        aux = head.find(b'\r\n')
        if aux == -1: return b''
        return head[:aux]
    def connect_target(self, host):
        i = host.find(b':')
        if i != -1:
            port = int(host[i + 1:])
            host = host[:i]
        else:
            port = ${SSH_PORT}
        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False
        self.target.connect(address)
    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path.decode()
        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = b''
        self.server.printLog(self.log)
        self.doCONNECT()
    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err: error = True
            if recv:
                for in_ in recv:
                    try:
                        data = in_.recv(BUFLEN)
                        if data:
                            if in_ is self.target: self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]
                            count = 0
                        else: break
                    except: error = True; break
            if count == TIMEOUT: error = True
            if error: break

if __name__ == '__main__':
    print(f"\033[0;34m{'•'*8} \033[1;32mPROXY PYTHON3 WEBSOCKET \033[0;34m{'•'*8}\n")
    print(f"\033[1;33mIP:\033[1;32m {LISTENING_ADDR}")
    print(f"\033[1;33mPUERTO:\033[1;32m {LISTENING_PORT}")
    print(f"\033[1;33mBANNER:\033[1;32m ${BANNER_MSG}\n")
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    while True:
        try: time.sleep(2)
        except KeyboardInterrupt:
            server.close()
            break
PYEOF

    chmod +x $DIR_SCRIPTS/proxy_ws_${WS_PORT}.py

    # Crear servicio systemd
    cat > $DIR_SERVICES/ws-proxy-${WS_PORT}.service << EOF
[Unit]
Description=WebSocket Proxy Python Puerto ${WS_PORT} — SSHFREE LTM
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 ${DIR_SCRIPTS}/proxy_ws_${WS_PORT}.py ${WS_PORT}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ws-proxy-${WS_PORT}.service
    systemctl start ws-proxy-${WS_PORT}.service
    sleep 2

    if systemctl is-active --quiet ws-proxy-${WS_PORT}.service; then
        echo -e "\n  ${G}✅ WebSocket activo en puerto ${WS_PORT}${NC}"
    else
        echo -e "\n  ${R}❌ Error iniciando WebSocket${NC}"
    fi
    echo ""
    read -p "  Presiona ENTER para continuar..."
}

eliminar_ws() {
    banner
    sep
    echo -e "  ${R}Eliminar WebSocket Python${NC}"
    sep
    echo ""
    echo -e "  ${W}Servicios WebSocket activos:${NC}"
    ls $DIR_SERVICES/ws-proxy-*.service 2>/dev/null | while read f; do
        name=$(basename $f .service)
        port=$(echo $name | grep -o '[0-9]*')
        echo -e "  - Puerto ${Y}${port}${NC} $(status_service $name)"
    done
    echo ""
    read -p "  Puerto a eliminar (0 para todos): " DEL_PORT
    if [ "$DEL_PORT" = "0" ]; then
        for f in $DIR_SERVICES/ws-proxy-*.service; do
            name=$(basename $f .service)
            systemctl stop $name
            systemctl disable $name
            rm -f $f
        done
        rm -f $DIR_SCRIPTS/proxy_ws_*.py
        echo -e "  ${G}✅ Todos eliminados${NC}"
    else
        systemctl stop ws-proxy-${DEL_PORT}
        systemctl disable ws-proxy-${DEL_PORT}
        rm -f $DIR_SERVICES/ws-proxy-${DEL_PORT}.service
        rm -f $DIR_SCRIPTS/proxy_ws_${DEL_PORT}.py
        echo -e "  ${G}✅ WebSocket puerto ${DEL_PORT} eliminado${NC}"
    fi
    systemctl daemon-reload
    read -p "  Presiona ENTER para continuar..."
}

menu_ws() {
    while true; do
        banner
        sep
        echo -e "  ${Y}  WEBSOCKET PYTHON${NC}"
        sep
        echo ""
        WS_SERVICES=$(ls $DIR_SERVICES/ws-proxy-*.service 2>/dev/null)
        if [ -z "$WS_SERVICES" ]; then
            echo -e "  ${R}  No hay WebSocket instalado${NC}"
        else
            for f in $WS_SERVICES; do
                name=$(basename $f .service)
                port=$(echo $name | grep -o '[0-9]*$')
                echo -e "  Puerto ${Y}${port}${NC} $(status_service $name)"
            done
        fi
        echo ""
        sep
        echo -e "  ${W}[1]${NC} Instalar / Configurar WebSocket"
        echo -e "  ${W}[2]${NC} Iniciar WebSocket"
        echo -e "  ${W}[3]${NC} Detener WebSocket"
        echo -e "  ${W}[4]${NC} Reiniciar WebSocket"
        echo -e "  ${W}[5]${NC} Eliminar WebSocket"
        echo -e "  ${W}[0]${NC} Volver"
        sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) instalar_ws ;;
            2) read -p "  Puerto: " P; systemctl start ws-proxy-${P} && echo -e "  ${G}Iniciado${NC}" || echo -e "  ${R}Error${NC}"; sleep 1 ;;
            3) read -p "  Puerto: " P; systemctl stop ws-proxy-${P} && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) read -p "  Puerto: " P; systemctl restart ws-proxy-${P} && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5) eliminar_ws ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   BADVPN UDP GATEWAY
# ══════════════════════════════════════════

menu_badvpn() {
    while true; do
        banner
        sep
        echo -e "  ${Y}  BADVPN UDP GATEWAY${NC}"
        sep
        echo ""
        echo -e "  BadVPN 7200 $(status_service badvpn-7200)"
        echo -e "  BadVPN 7300 $(status_service badvpn-7300)"
        echo ""
        sep
        echo -e "  ${W}[1]${NC} Instalar BadVPN"
        echo -e "  ${W}[2]${NC} Iniciar BadVPN 7200 y 7300"
        echo -e "  ${W}[3]${NC} Detener BadVPN"
        echo -e "  ${W}[4]${NC} Instalar puerto personalizado"
        echo -e "  ${W}[0]${NC} Volver"
        sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando BadVPN...${NC}"
                apt install -y badvpn > /dev/null 2>&1 || {
                    apt install -y cmake make gcc g++ > /dev/null 2>&1
                    cd /tmp
                    git clone https://github.com/ambrop72/badvpn.git > /dev/null 2>&1
                    cd badvpn && mkdir build && cd build
                    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
                    make install > /dev/null 2>&1
                }
                # Crear servicios
                for PORT in 7200 7300; do
                    cat > $DIR_SERVICES/badvpn-${PORT}.service << EOF
[Unit]
Description=BadVPN UDP Gateway Puerto ${PORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:${PORT} --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
                    systemctl daemon-reload
                    systemctl enable badvpn-${PORT}
                    systemctl start badvpn-${PORT}
                done
                echo -e "  ${G}✅ BadVPN instalado en 7200 y 7300${NC}"
                sleep 2
                ;;
            2)
                systemctl start badvpn-7200 badvpn-7300
                echo -e "  ${G}✅ BadVPN iniciado${NC}"; sleep 1
                ;;
            3)
                systemctl stop badvpn-7200 badvpn-7300
                echo -e "  ${Y}BadVPN detenido${NC}"; sleep 1
                ;;
            4)
                read -p "  Puerto: " BPORT
                cat > $DIR_SERVICES/badvpn-${BPORT}.service << EOF
[Unit]
Description=BadVPN UDP Gateway Puerto ${BPORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:${BPORT} --max-clients 500
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable badvpn-${BPORT}
                systemctl start badvpn-${BPORT}
                echo -e "  ${G}✅ BadVPN instalado en puerto ${BPORT}${NC}"; sleep 2
                ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   UDP CUSTOM
# ══════════════════════════════════════════

menu_udp() {
    while true; do
        banner
        sep
        echo -e "  ${Y}  UDP CUSTOM${NC}"
        sep
        echo ""
        UDP_PROC=$(ps aux | grep -i "udp-custom\|udpcustom" | grep -v grep | head -1)
        if [ -n "$UDP_PROC" ]; then
            echo -e "  UDP Custom $(status_port 36712 udp)"
        else
            echo -e "  UDP Custom ${R}[OFF]${NC}"
        fi
        echo ""
        sep
        echo -e "  ${W}[1]${NC} Instalar UDP Custom"
        echo -e "  ${W}[2]${NC} Ver estado"
        echo -e "  ${W}[0]${NC} Volver"
        sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando UDP Custom (Epro Dev Team)...${NC}"
                read -p "  Puerto a excluir (default 5300): " UDP_EXCL
                UDP_EXCL=${UDP_EXCL:-5300}
                echo -e "  ${C}Descargando instalador oficial...${NC}"
                wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1S3IE25v_fyUfCLslnujFBSBMNunDHDk2' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1S3IE25v_fyUfCLslnujFBSBMNunDHDk2" -O /tmp/install-udp && rm -rf /tmp/cookies.txt
                chmod +x /tmp/install-udp
                /tmp/install-udp $UDP_EXCL
                echo -e "  ${G}✅ UDP Custom instalado${NC}"; sleep 2
                ;;
            2)
                ss -ulnp | grep -E "36712|udp"
                echo ""
                read -p "  Presiona ENTER..."
                ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   SSL/TLS STUNNEL
# ══════════════════════════════════════════

menu_ssl() {
    while true; do
        banner
        sep
        echo -e "  ${Y}  SSL/TLS STUNNEL${NC}"
        sep
        echo ""
        echo -e "  Stunnel $(status_service stunnel4)"
        echo -e "  Puerto 443 $(status_port 443)"
        echo ""
        sep
        echo -e "  ${W}[1]${NC} Instalar SSL/TLS Stunnel"
        echo -e "  ${W}[2]${NC} Iniciar Stunnel"
        echo -e "  ${W}[3]${NC} Detener Stunnel"
        echo -e "  ${W}[4]${NC} Reiniciar Stunnel"
        echo -e "  ${W}[0]${NC} Volver"
        sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando Stunnel...${NC}"
                apt install -y stunnel4 > /dev/null 2>&1
                read -p "  Puerto SSL (ej: 443): " SSL_PORT
                SSL_PORT=${SSL_PORT:-443}
                read -p "  Puerto local SSH (ej: 22): " LOCAL_PORT
                LOCAL_PORT=${LOCAL_PORT:-22}
                # Generar certificado autofirmado
                openssl req -new -x509 -days 3650 -nodes \
                    -out /etc/stunnel/stunnel.pem \
                    -keyout /etc/stunnel/stunnel.pem \
                    -subj "/C=US/ST=Miami/L=Miami/O=SSHFREE/CN=sshfree" 2>/dev/null
                cat > /etc/stunnel/stunnel.conf << EOF
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssh]
accept = ${SSL_PORT}
connect = 127.0.0.1:${LOCAL_PORT}
EOF
                sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null
                systemctl enable stunnel4
                systemctl start stunnel4
                echo -e "  ${G}✅ SSL/TLS Stunnel instalado en puerto ${SSL_PORT}${NC}"; sleep 2
                ;;
            2) systemctl start stunnel4 && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop stunnel4 && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart stunnel4 && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   V2RAY VMESS
# ══════════════════════════════════════════

menu_v2ray() {
    while true; do
        banner
        sep
        echo -e "  ${Y}  V2RAY VMESS${NC}"
        sep
        echo ""
        echo -e "  V2Ray $(status_service v2ray)"
        echo -e "  Puerto 8080 $(status_port 8080)"
        echo -e "  Puerto 443  $(status_port 443)"
        echo ""
        sep
        echo -e "  ${W}[1]${NC} Instalar V2Ray + SSL (auto)"
        echo -e "  ${W}[2]${NC} Iniciar V2Ray"
        echo -e "  ${W}[3]${NC} Detener V2Ray"
        echo -e "  ${W}[4]${NC} Reiniciar V2Ray"
        echo -e "  ${W}[5]${NC} Crear usuario VMess"
        echo -e "  ${W}[6]${NC} Ver usuarios VMess"
        echo -e "  ${W}[0]${NC} Volver"
        sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                read -p "  Dominio (ej: mia.darkfullhn.xyz): " DOMAIN
                read -p "  Email para certificado: " EMAIL
                bash <(curl -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) > /dev/null 2>&1
                apt install -y nginx certbot python3-certbot-nginx > /dev/null 2>&1
                pkill -f "python3.*:80" 2>/dev/null; sleep 2
                certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos -m $EMAIL
                cat > /usr/local/etc/v2ray/config.json << EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "port": 8080,
    "protocol": "vmess",
    "settings": {"clients": []},
    "streamSettings": {
      "network": "ws",
      "wsSettings": {"path": "/v2ray"}
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
                cat > /etc/nginx/sites-available/v2ray << EOF
server {
    listen 443 ssl;
    server_name ${DOMAIN};
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    location /v2ray {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF
                ln -sf /etc/nginx/sites-available/v2ray /etc/nginx/sites-enabled/
                systemctl enable v2ray nginx
                systemctl start v2ray nginx
                echo -e "  ${G}✅ V2Ray instalado con SSL en ${DOMAIN}${NC}"; sleep 2
                ;;
            2) systemctl start v2ray && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop v2ray && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart v2ray && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Nombre del perfil: " VNAME
                read -p "  Dominio/IP del servidor: " VHOST
                python3 - << PYEOF
import json, uuid, base64
cfg_file = '/usr/local/etc/v2ray/config.json'
with open(cfg_file) as f: config = json.load(f)
uid = str(uuid.uuid4())
config['inbounds'][0]['settings']['clients'].append({"id": uid, "alterId": 0, "email": "${VNAME}"})
with open(cfg_file, 'w') as f: json.dump(config, f, indent=2)
vmess = {"v":"2","ps":"${VNAME}","add":"${VHOST}","port":"443","id":uid,"aid":"0","net":"ws","type":"none","host":"${VHOST}","path":"/v2ray","tls":"tls"}
link = "vmess://" + base64.b64encode(json.dumps(vmess).encode()).decode()
print(f"\n\033[1;32m✅ VMess creado:\033[0m\n{link}\n")
PYEOF
                systemctl restart v2ray
                read -p "  Presiona ENTER..."
                ;;
            6)
                python3 -c "
import json
try:
    with open('/usr/local/etc/v2ray/config.json') as f: c = json.load(f)
    clients = c['inbounds'][0]['settings']['clients']
    print(f'\n  Total usuarios: {len(clients)}')
    for u in clients: print(f'  - {u.get(\"email\",\"?\")} | {u[\"id\"]}')
except Exception as e: print(f'Error: {e}')
"
                echo ""
                read -p "  Presiona ENTER..."
                ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   ZIV VPN / HYSTERIA
# ══════════════════════════════════════════

menu_ziv() {
    while true; do
        banner
        sep
        echo -e "  ${Y}  ZIV VPN / HYSTERIA${NC}"
        sep
        echo ""
        echo -e "  Hysteria $(status_service hysteria-server)"
        echo ""
        sep
        echo -e "  ${W}[1]${NC} Instalar Hysteria2"
        echo -e "  ${W}[2]${NC} Iniciar Hysteria"
        echo -e "  ${W}[3]${NC} Detener Hysteria"
        echo -e "  ${W}[4]${NC} Ver configuración"
        echo -e "  ${W}[0]${NC} Volver"
        sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando Hysteria2...${NC}"
                bash <(curl -fsSL https://get.hy2.sh/) > /dev/null 2>&1
                read -p "  Puerto UDP (ej: 36712): " HY_PORT
                HY_PORT=${HY_PORT:-36712}
                read -p "  Contraseña: " HY_PASS
                cat > /etc/hysteria/config.yaml << EOF
listen: :${HY_PORT}
auth:
  type: password
  password: ${HY_PASS}
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
EOF
                openssl req -x509 -newkey rsa:4096 -keyout /etc/hysteria/server.key \
                    -out /etc/hysteria/server.crt -days 3650 -nodes \
                    -subj "/CN=hysteria" 2>/dev/null
                systemctl enable hysteria-server
                systemctl start hysteria-server
                echo -e "  ${G}✅ Hysteria2 instalado en puerto UDP ${HY_PORT}${NC}"; sleep 2
                ;;
            2) systemctl start hysteria-server && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop hysteria-server && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) cat /etc/hysteria/config.yaml 2>/dev/null; echo ""; read -p "  ENTER..." ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   MENÚ PRINCIPAL
# ══════════════════════════════════════════

menu_principal() {
    while true; do
        banner
        sep
        echo -e "  ${W}ESTADO DE SERVICIOS${NC}"
        sep
        echo -e "  WebSocket Python  $(status_port 80)"
        echo -e "  BadVPN 7200       $(status_service badvpn-7200)"
        echo -e "  BadVPN 7300       $(status_service badvpn-7300)"
        echo -e "  UDP Custom        $(status_port 36712 udp)"
        echo -e "  SSL/TLS Stunnel   $(status_service stunnel4)"
        echo -e "  V2Ray VMess       $(status_service v2ray)"
        echo -e "  Hysteria/ZivVPN   $(status_service hysteria-server)"
        sep
        echo ""
        echo -e "  ${W}[1]${NC} WebSocket Python (Proxy3 WS)"
        echo -e "  ${W}[2]${NC} BadVPN UDP Gateway"
        echo -e "  ${W}[3]${NC} UDP Custom"
        echo -e "  ${W}[4]${NC} SSL/TLS Stunnel"
        echo -e "  ${W}[5]${NC} V2Ray VMess"
        echo -e "  ${W}[6]${NC} ZIV VPN / Hysteria2"
        echo ""
        sep
        echo -e "  ${W}[0]${NC} Salir"
        sep
        echo ""
        read -p "  Opcion: " OPT
        case $OPT in
            1) menu_ws ;;
            2) menu_badvpn ;;
            3) menu_udp ;;
            4) menu_ssl ;;
            5) menu_v2ray ;;
            6) menu_ziv ;;
            0) echo -e "\n  ${G}Hasta luego! — DarkZFull${NC}\n"; exit 0 ;;
            *) echo -e "  ${R}Opcion invalida${NC}"; sleep 1 ;;
        esac
    done
}

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo -e "${R}Ejecuta como root: sudo bash $0${NC}"
    exit 1
fi

menu_principal
