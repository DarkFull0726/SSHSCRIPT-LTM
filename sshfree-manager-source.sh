#!/bin/bash
# ═══════════════════════════════════════════════════════
#   SSHFREE LTM — Gestor de Servicios VPN/SSH
#   by DarkZFull • @DarkZFull
#   Ubuntu 22/24/25
# ═══════════════════════════════════════════════════════

SCRIPT_VERSION="3.1"
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;96m'
W='\033[1;97m'
B='\033[0;34m'
P='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
NEON='\033[1;96m'
DIM='\033[2;37m'
LINE='◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆'
LINE2='◇─────────────────────────────────────────────◇'
DIR_SCRIPTS="/etc/sshfreeltm"
DIR_SERVICES="/etc/systemd/system"
mkdir -p $DIR_SCRIPTS

# Desactivar restricciones PAM de contraseña
sed -i 's/pam_unix.so obscure/pam_unix.so/' /etc/pam.d/common-password 2>/dev/null
sed -i 's/use_authtok //' /etc/pam.d/common-password 2>/dev/null
sed -i '/pam_pwquality/d' /etc/pam.d/common-password 2>/dev/null
sed -i '/pam_cracklib/d' /etc/pam.d/common-password 2>/dev/null

# Configurar UFW si esta activo
if command -v ufw > /dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    ufw allow 8080/tcp > /dev/null 2>&1
    ufw allow 8388/tcp > /dev/null 2>&1
    ufw allow 8388/udp > /dev/null 2>&1
    ufw allow 7200/tcp > /dev/null 2>&1
    ufw allow 7300/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 36712/udp > /dev/null 2>&1
    ufw allow 90/tcp > /dev/null 2>&1
    ufw reload > /dev/null 2>&1
fi

# ══════════════════════════════════════════
# VERIFICACION DE LICENCIA
# ══════════════════════════════════════════
# Verificar licencia real
LICENSED_KEY=""
[ -f /etc/sshfreeltm/.licensed ] && LICENSED_KEY=$(cat /etc/sshfreeltm/.licensed 2>/dev/null)
VALID_LICENSE=false
if [ -n "$LICENSED_KEY" ] && [[ "$LICENSED_KEY" == LTM-SCRIPT-KEY-* ]]; then
    VALID_LICENSE=true
fi
if [ "$VALID_LICENSE" = "false" ]; then
    clear
    echo -e "\033[1;96m"
    figlet -f small "LTM VPN TOOLS" 2>/dev/null || echo "LTM VPN TOOLS"
    echo -e "\033[0m"
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    echo -e "  \033[1;97m⚡ LTM VPN TOOLS v3.1 by @DarkZFull\033[0m"
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    echo ""
    echo -e "  \033[1;33m🔐 Se requiere una KEY de licencia para instalar\033[0m"
    echo -e "  \033[2;37m   Obtén tu KEY con @DarkZFull\033[0m"
    echo ""
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    read -p "  🗝️  Ingresa tu KEY: " INPUT_KEY
    echo ""
    command -v curl > /dev/null 2>&1 || apt install -y curl > /dev/null 2>&1
    echo -e "  \033[0;36m⏳  Verificando key...\033[0m"

    VPS_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    VPS_OS=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Ubuntu")
    VERIFY_RESULT=$(curl -s -X POST http://172.233.176.159:6000/api/key/verify -H "Content-Type: application/json" -d "{\"key\": \"$INPUT_KEY\", \"ip\": \"$VPS_IP\", \"os\": \"$VPS_OS\"}" 2>/dev/null)

    IS_OK=$(echo $VERIFY_RESULT | python3 -c "import sys,json; print(json.load(sys.stdin).get('ok','false'))" 2>/dev/null)
    ERROR_MSG=$(echo $VERIFY_RESULT | python3 -c "import sys,json; print(json.load(sys.stdin).get('error','Error desconocido'))" 2>/dev/null)

    if [ "$IS_OK" = "True" ]; then
        mkdir -p /etc/sshfreeltm
        echo "$INPUT_KEY" > /etc/sshfreeltm/.licensed
        echo -e "  \033[0;32m✅ Key valida — Bienvenido a LTM VPN TOOLS\033[0m"
        sleep 1
        echo ""
        echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        echo -e "  \033[1;97m⚡ Instalando dependencias del sistema...\033[0m"
        echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        echo -e "  \033[0;36m⏳ Actualizando repos...\033[0m"
        DEBIAN_FRONTEND=noninteractive apt update -y -o Acquire::ForceIPv4=true > /dev/null 2>&1
        echo -e "  \033[1;32m✓ Repos actualizados\033[0m"
        install_dep() {
            PKG=$1
            LABEL=${2:-$1}
            echo -ne "  \033[1;96m◈\033[0m \033[1;97m$LABEL\033[0m \033[0;36m...\033[0m"
            DEBIAN_FRONTEND=noninteractive apt install -y -qq $PKG > /dev/null 2>&1
            if dpkg -l $PKG 2>/dev/null | grep -q "^ii"; then
                echo -e "\r  \033[1;96m◈\033[0m \033[1;97m$LABEL\033[0m \033[1;32m✓ OK\033[0m          "
            else
                echo -e "\r  \033[1;96m◈\033[0m \033[1;97m$LABEL\033[0m \033[1;31m✗ Error\033[0m       "
            fi
        }
        install_dep curl "curl"
        install_dep wget "wget"
        install_dep figlet "figlet (ASCII art)"
        install_dep python3 "python3"
        install_dep sqlite3 "sqlite3"
        install_dep net-tools "net-tools"
        install_dep iptables "iptables"
        install_dep openssl "openssl"
        install_dep unzip "unzip"
        install_dep screen "screen"
        install_dep cmake "cmake"
        install_dep make "make"
        install_dep gcc "gcc"
        install_dep g++ "g++"
        install_dep git "git"
        echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        echo -e "  \033[1;32m✅ Sistema listo\033[0m"
        echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        sleep 2
    else
        echo -e "  \033[0;31m❌ $ERROR_MSG\033[0m"
        echo -e "  \033[2;37m   Obtén tu KEY con @DarkZFull\033[0m"
        sleep 3
        exit 1
    fi
fi



# Deshabilitar mensajes de bienvenida de Ubuntu
touch ~/.hushlogin 2>/dev/null
chmod -x /etc/update-motd.d/* 2>/dev/null
> /etc/motd 2>/dev/null

# Dar permisos a certificados letsencrypt
if [ -d /etc/letsencrypt ]; then
    chmod 755 /etc/letsencrypt/live/ /etc/letsencrypt/archive/ 2>/dev/null
    find /etc/letsencrypt -name "*.pem" -exec chmod 644 {} \; 2>/dev/null
fi

# Preguntar nombre ASCII al instalar por primera vez
if [ ! -f /etc/sshfreeltm/server_name ]; then
    mkdir -p /etc/sshfreeltm
    apt install -y figlet > /dev/null 2>&1
    echo ""
    echo -e "\033[1;33mEscribe el nombre que aparecera en el menu:\033[0m"
    read -p "Nombre: " INSTALL_NAME
    INSTALL_NAME=${INSTALL_NAME:-"SSHFREE LTM"}
    echo "$INSTALL_NAME" > /etc/sshfreeltm/server_name
    echo "$(date +%d-%m-%Y)" > /etc/sshfreeltm/install_date
fi

# Preguntar nombre ASCII al instalar por primera vez
if [ ! -f /etc/sshfreeltm/server_name ]; then
    mkdir -p /etc/sshfreeltm
    apt install -y figlet > /dev/null 2>&1
    echo ""
    echo -e "\033[1;33mEscribe el nombre que aparecera en el menu:\033[0m"
    read -p "Nombre: " INSTALL_NAME
    INSTALL_NAME=${INSTALL_NAME:-"SSHFREE LTM"}
    echo "$INSTALL_NAME" > /etc/sshfreeltm/server_name
    echo "$(date +%d-%m-%Y)" > /etc/sshfreeltm/install_date
fi

# Instalar MOTD automáticamente
cat > /etc/profile.d/sshfree-motd.sh << 'MOTDSCRIPT'
#!/bin/bash
PURPLE='\033[0;35m' CYAN='\033[0;36m' GREEN='\033[0;32m'
YELLOW='\033[1;33m' WHITE='\033[1;37m' NC='\033[0m'
INSTALL_DATE=$(cat /etc/sshfreeltm/install_date 2>/dev/null || echo "N/A")
SRV_NAME=$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
CURRENT_DATE=$(date +%d-%m-%Y)
CURRENT_TIME=$(date +%H:%M:%S)
UPTIME=$(uptime -p | sed 's/up //')
RAM_FREE=$(free -h | awk '/^Mem:/{print $4}')
echo -e "${PURPLE}"
figlet -f small "$SRV_NAME" 2>/dev/null || echo "  $SRV_NAME"
echo -e "${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}SERVIDOR INSTALADO EL${NC}   : ${WHITE}$INSTALL_DATE${NC}"
echo -e "  ${YELLOW}FECHA/HORA ACTUAL${NC}        : ${WHITE}$CURRENT_DATE - $CURRENT_TIME${NC}"
echo -e "  ${YELLOW}NOMBRE DEL SERVIDOR${NC}      : ${WHITE}$(hostname)${NC}"
echo -e "  ${YELLOW}TIEMPO EN LINEA${NC}          : ${WHITE}$UPTIME${NC}"
echo -e "  ${YELLOW}VERSION INSTALADA${NC}        : ${WHITE}V1.0.0${NC}"
echo -e "  ${YELLOW}MEMORIA RAM LIBRE${NC}        : ${WHITE}$RAM_FREE${NC}"
echo -e "  ${YELLOW}CREADOR DEL SCRIPT${NC}       : ${PURPLE}@DarkZFull ❴LTM❵${NC}"
echo -e "  ${GREEN}BIENVENIDO DE NUEVO!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Teclee ${YELLOW}menu${NC} para ver el MENU LTM"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
MOTDSCRIPT
chmod +x /etc/profile.d/sshfree-motd.sh
[ -f /etc/motd ] && > /etc/motd

banner() {
    clear
    SRV_NAME=$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
    echo -e "${NEON}"
    figlet -f small "$SRV_NAME" 2>/dev/null || echo "  $SRV_NAME"
    echo -e "${NC}"
    echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
    echo -e "  ${W}⚡ Gestor VPN/SSH${NC} ${DIM}by${NC} ${NEON}@DarkZFull${NC}  ${Y}❖ v${SCRIPT_VERSION}${NC}"
    echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
    echo ""
}

sep() { echo -e "${NEON}${LINE}${NC}"; }
sep2() { echo -e "${DIM}${LINE2}${NC}"; }

status_service() {
    systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${NEON}◆ ON ${NC}" || echo -e "${R}◇ OFF${NC}"
}

status_port() {
    ss -${2:-t}lnp 2>/dev/null | grep -q ":${1} " && echo -e "${NEON}◆ ON ${NC}" || echo -e "${R}◇ OFF${NC}"
}

# ══════════════════════════════════════════
#   WEBSOCKET PYTHON
# ══════════════════════════════════════════

instalar_ws() {
    banner; sep
    echo -e "  ${Y}Configurar WebSocket Python${NC}"; sep; echo ""
    read -p "  Puerto WebSocket (ej: 80): " WS_PORT; WS_PORT=${WS_PORT:-80}
    read -p "  Puerto local SSH (ej: 22): " SSH_PORT; SSH_PORT=${SSH_PORT:-22}
    echo ""; sep
    echo -e "  ${W}RESPONSE (101 para WebSocket, 200 default):${NC}"
    read -p "  RESPONSE: " STATUS_RESP; STATUS_RESP=${STATUS_RESP:-200}
    echo ""; read -p "  Mini-Banner: " BANNER_MSG
    BANNER_MSG=${BANNER_MSG:-"SSHFREE LTM by DarkZFull"}
    echo ""; sep
    echo -e "  ${W}Encabezado personalizado (ENTER para default):${NC}"
    read -p "  Cabecera: " CUSTOM_HEADER
    [ -z "$CUSTOM_HEADER" ] && CUSTOM_HEADER="\r\nContent-length: 0\r\n\r\nHTTP/1.1 200 Connection Established\r\n\r\n"

    cat > $DIR_SCRIPTS/proxy_ws_${WS_PORT}.py << PYEOF
#!/usr/bin/env python3
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
        self.running = False; self.host = host; self.port = port
        self.threads = []; self.threadsLock = threading.Lock(); self.logLock = threading.Lock()
    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2); self.soc.bind((self.host, int(self.port))); self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try: c, addr = self.soc.accept(); c.setblocking(1)
                except socket.timeout: continue
                conn = ConnectionHandler(c, self, addr); conn.start(); self.addConn(conn)
        finally: self.running = False; self.soc.close()
    def printLog(self, log):
        self.logLock.acquire(); print(log); self.logLock.release()
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running: self.threads.append(conn)
        finally: self.threadsLock.release()
    def removeConn(self, conn):
        try: self.threadsLock.acquire(); self.threads.remove(conn)
        finally: self.threadsLock.release()
    def close(self):
        try:
            self.running = False; self.threadsLock.acquire()
            for c in list(self.threads): c.close()
        finally: self.threadsLock.release()

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False; self.targetClosed = True
        self.client = socClient; self.client_buffer = b''
        self.server = server; self.log = 'Connection: ' + str(addr)
    def close(self):
        try:
            if not self.clientClosed: self.client.shutdown(socket.SHUT_RDWR); self.client.close()
        except: pass
        finally: self.clientClosed = True
        try:
            if not self.targetClosed: self.target.shutdown(socket.SHUT_RDWR); self.target.close()
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
                if hostPort.startswith(b'127.0.0.1') or hostPort.startswith(b'localhost'):
                    self.method_CONNECT(hostPort)
                else: self.client.send(b'HTTP/1.1 403 Forbidden!\r\n\r\n')
            else: self.client.send(b'HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + str(e); self.server.printLog(self.log)
        finally: self.close(); self.server.removeConn(self)
    def findHeader(self, head, header):
        aux = head.find(header + b': ')
        if aux == -1: return b''
        aux = head.find(b':', aux); head = head[aux + 2:]
        aux = head.find(b'\r\n')
        if aux == -1: return b''
        return head[:aux]
    def connect_target(self, host):
        i = host.find(b':')
        if i != -1: port = int(host[i + 1:]); host = host[:i]
        else: port = ${SSH_PORT}
        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False; self.target.connect(address)
    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path.decode()
        self.connect_target(path); self.client.sendall(RESPONSE)
        self.client_buffer = b''; self.server.printLog(self.log); self.doCONNECT()
    def doCONNECT(self):
        socs = [self.client, self.target]; count = 0; error = False
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
                                while data: byte = self.target.send(data); data = data[byte:]
                            count = 0
                        else: break
                    except: error = True; break
            if count == TIMEOUT: error = True
            if error: break

if __name__ == '__main__':
    print(f"\033[0;34m{'*'*8} \033[1;32mPROXY PYTHON3 WEBSOCKET \033[0;34m{'*'*8}\n")
    print(f"\033[1;33mPUERTO:\033[1;32m {LISTENING_PORT}\n")
    server = Server(LISTENING_ADDR, LISTENING_PORT); server.start()
    while True:
        try: time.sleep(2)
        except KeyboardInterrupt: server.close(); break
PYEOF

    chmod +x $DIR_SCRIPTS/proxy_ws_${WS_PORT}.py
    cat > $DIR_SERVICES/ws-proxy-${WS_PORT}.service << EOF
[Unit]
Description=WebSocket Proxy Python Puerto ${WS_PORT}
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
    systemctl daemon-reload; systemctl enable ws-proxy-${WS_PORT}; systemctl start ws-proxy-${WS_PORT}
    sleep 2
    systemctl is-active --quiet ws-proxy-${WS_PORT} && echo -e "\n  ${G}OK WebSocket activo en puerto ${WS_PORT}${NC}" || echo -e "\n  ${R}Error${NC}"
    read -p "  ENTER..."
}

menu_ws() {
    while true; do
        banner; sep; echo -e "  ${Y}  WEBSOCKET PYTHON${NC}"; sep; echo ""
        for f in $(ls $DIR_SERVICES/ws-proxy-*.service 2>/dev/null); do
            name=$(basename $f .service); port=$(echo $name | grep -o '[0-9]*$')
            echo -e "  Puerto ${Y}${port}${NC} $(status_service $name)"
        done
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar/Configurar"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Eliminar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) instalar_ws ;;
            2) read -p "  Puerto: " P; systemctl start ws-proxy-${P} && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) read -p "  Puerto: " P; systemctl stop ws-proxy-${P} && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) read -p "  Puerto: " P; systemctl restart ws-proxy-${P} && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Puerto (0=todos): " DEL_PORT
                if [ "$DEL_PORT" = "0" ]; then
                    for f in $DIR_SERVICES/ws-proxy-*.service; do
                        name=$(basename $f .service); systemctl stop $name; systemctl disable $name; rm -f $f
                    done; rm -f $DIR_SCRIPTS/proxy_ws_*.py
                else
                    systemctl stop ws-proxy-${DEL_PORT}; systemctl disable ws-proxy-${DEL_PORT}
                    rm -f $DIR_SERVICES/ws-proxy-${DEL_PORT}.service $DIR_SCRIPTS/proxy_ws_${DEL_PORT}.py
                fi
                systemctl daemon-reload; echo -e "  ${G}Eliminado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   BADVPN
# ══════════════════════════════════════════

menu_badvpn() {
    while true; do
        banner; sep; echo -e "  ${Y}  BADVPN UDP GATEWAY${NC}"; sep; echo ""
        echo -e "  BadVPN 7200 $(status_service badvpn-7200)"
        echo -e "  BadVPN 7300 $(status_service badvpn-7300)"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar BadVPN"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Puerto personalizado"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                if [ ! -f /usr/local/bin/badvpn-udpgw ] || [ ! -s /usr/local/bin/badvpn-udpgw ]; then
                    rm -f /usr/local/bin/badvpn-udpgw
                    echo -e "\n  ${C}Actualizando repositorios...${NC}"
                    apt update -y > /dev/null 2>&1
                    echo -e "  ${C}Instalando dependencias...${NC}"
                    apt install -y cmake make gcc g++ git > /dev/null 2>&1
                    echo -e "  ${C}Compilando BadVPN...${NC}"
                    cd /tmp || cd /root
                    rm -rf badvpn
                    git clone https://github.com/ambrop72/badvpn.git > /dev/null 2>&1
                    cd /tmp/badvpn && mkdir -p build && cd build
                    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
                    make > /dev/null 2>&1
                    cd /tmp
                    if [ -f /tmp/badvpn/build/udpgw/badvpn-udpgw ] && [ -s /tmp/badvpn/build/udpgw/badvpn-udpgw ]; then
                        cp /tmp/badvpn/build/udpgw/badvpn-udpgw /usr/local/bin/
                        chmod +x /usr/local/bin/badvpn-udpgw
                        echo -e "  ${G}OK Binario compilado${NC}"
                    else
                        echo -e "  ${R}Error: compilacion fallida${NC}"
                        read -p "  ENTER..."; return
                    fi
                fi
                for PORT in 7200 7300; do
                    cat > $DIR_SERVICES/badvpn-${PORT}.service << EOF
[Unit]
Description=BadVPN UDP Gateway ${PORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${PORT} --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
                    systemctl daemon-reload; systemctl enable badvpn-${PORT}; systemctl start badvpn-${PORT}
                done
                echo -e "  ${G}OK BadVPN 7200 y 7300${NC}"; sleep 2 ;;
            2) systemctl start badvpn-7200 badvpn-7300 && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop badvpn-7200 badvpn-7300 && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart badvpn-7200 badvpn-7300 && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Puerto: " BPORT
                cat > $DIR_SERVICES/badvpn-${BPORT}.service << EOF
[Unit]
Description=BadVPN UDP Gateway ${BPORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${BPORT} --max-clients 500
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload; systemctl enable badvpn-${BPORT}; systemctl start badvpn-${BPORT}
                echo -e "  ${G}OK BadVPN puerto ${BPORT}${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   UDP CUSTOM
# ══════════════════════════════════════════

menu_udp() {
    while true; do
        banner; sep; echo -e "  ${Y}  UDP CUSTOM${NC}"; sep; echo ""
        ps aux | grep -i "udp-custom\|UDP-Custom" | grep -v grep | grep -q . && echo -e "  UDP Custom ${G}[ON]${NC}" || echo -e "  UDP Custom ${R}[OFF]${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar UDP Custom"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Ver estado"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando UDP Custom (Epro Dev Team)...${NC}"
                read -p "  Puerto a excluir (default 5300): " UDP_EXCL; UDP_EXCL=${UDP_EXCL:-5300}
                wget -O /tmp/install-udp "https://drive.usercontent.google.com/download?id=1S3IE25v_fyUfCLslnujFBSBMNunDHDk2&export=download&confirm=t"
                chmod +x /tmp/install-udp; bash /tmp/install-udp $UDP_EXCL
                echo -e "  ${G}OK UDP Custom instalado${NC}"; sleep 2 ;;
            2) systemctl start udp-custom 2>/dev/null || (/root/udp/udp-custom server -exclude 5300 &); echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop udp-custom 2>/dev/null; pkill -f udp-custom 2>/dev/null; echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) pkill -f udp-custom 2>/dev/null; sleep 1; systemctl start udp-custom 2>/dev/null || (/root/udp/udp-custom server -exclude 5300 &); echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5) ss -ulnp | grep udp; echo ""; read -p "  ENTER..." ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   SSL/TLS STUNNEL
# ══════════════════════════════════════════

menu_ssl() {
    while true; do
        banner; sep; echo -e "  ${Y}  SSL/TLS STUNNEL${NC}"; sep; echo ""
        echo -e "  Stunnel $(status_service stunnel4)"
        echo -e "  Puerto 443 $(status_port 443)"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar SSL/TLS Stunnel"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                apt install -y stunnel4 > /dev/null 2>&1
                read -p "  Puerto SSL (ej: 443): " SSL_PORT; SSL_PORT=${SSL_PORT:-443}
                read -p "  Puerto local SSH (ej: 22): " LOCAL_PORT; LOCAL_PORT=${LOCAL_PORT:-22}
                openssl req -new -x509 -days 3650 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem -subj "/C=US/ST=Miami/L=Miami/O=SSHFREE/CN=sshfree" 2>/dev/null
                cat > /etc/stunnel/stunnel.conf << EOF
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
socket = a:SO_REUSEADDR=1
[ssh]
accept = ${SSL_PORT}
connect = 127.0.0.1:${LOCAL_PORT}
EOF
                sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null
                systemctl enable stunnel4; systemctl start stunnel4
                echo -e "  ${G}OK SSL/TLS en puerto ${SSL_PORT}${NC}"; sleep 2 ;;
            2) systemctl start stunnel4 && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop stunnel4 && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart stunnel4 && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   V2RAY
# ══════════════════════════════════════════

menu_v2ray() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ V2RAY VMESS${NC}"; sep; echo ""
        echo -e "  V2Ray $(status_service v2ray)"
        if [ -f /usr/local/etc/v2ray/config.json ]; then
            python3 -c "
import json
try:
    with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
    inbounds = c.get('inbounds',[])
    if not inbounds:
        print('  \033[2;37m  Sin inbounds configurados\033[0m')
    for ib in inbounds:
        net=ib.get('streamSettings',{}).get('network','tcp')
        tls=ib.get('streamSettings',{}).get('security','none')
        tls_icon='\033[1;96m TLS\033[0m' if tls=='tls' else ''
        print(f'  \033[1;96m◈\033[0m \033[1;97mPuerto \033[1;33m{ib[\"port\"]}\033[0m \033[2;37m|\033[0m \033[1;96m{ib[\"protocol\"]}\033[0m \033[2;37m|\033[0m {net}{tls_icon}')
except: pass
" 2>/dev/null
        fi
        echo ""; sep
        printf " ${Y}❬1❭ ⚡ Instalar V2Ray      ❬2❭ ➕ Agregar inbound${NC}\n"
        printf " ${Y}❬3❭ 🗑  Eliminar inbound    ❬4❭ ▶  Iniciar${NC}\n"
        printf " ${Y}❬5❭ ⏹  Detener             ❬6❭ 🔄 Reiniciar${NC}\n"
        printf " ${Y}❬7❭ 👤 Crear usuario        ❬8❭ 📋 Ver usuarios${NC}\n"
        printf " ${R}❬9❭ 🗑  Desinstalar V2Ray${NC}\n"
        sep
        printf " ${R}❬0❭ Volver${NC}\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1)
                read -p "  Dominio (para SSL): " DOMAIN
                EMAIL="admin@${DOMAIN#*.}"
                echo -e "  ${C}Instalando V2Ray...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) > /dev/null 2>&1
                echo -e "  ${C}Obteniendo certificado SSL...${NC}"
                apt install -y certbot > /dev/null 2>&1
                pkill -f "python3.*:80" 2>/dev/null; sleep 1
                certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos -m $EMAIL
                chmod 755 /etc/letsencrypt/live/ /etc/letsencrypt/archive/ 2>/dev/null
                chmod 644 /etc/letsencrypt/live/$DOMAIN/*.pem 2>/dev/null
                chmod 644 /etc/letsencrypt/archive/$DOMAIN/*.pem 2>/dev/null
                cat > /usr/local/etc/v2ray/config.json << EOF
{"log":{"loglevel":"warning"},"inbounds":[],"outbounds":[{"protocol":"freedom"}]}
EOF
                mkdir -p /etc/sshfreeltm
                echo "$DOMAIN" > /etc/sshfreeltm/v2ray_domain
                systemctl enable v2ray; systemctl start v2ray
                echo -e "  ${G}OK V2Ray instalado — Usa ❬2❭ para agregar puertos${NC}"; sleep 2 ;;
            2)
                banner; sep
                echo -e "  ${Y}  AGREGAR INBOUND${NC}"; sep; echo ""
                read -p "  Puerto: " V2_PORT
                echo -e "  Protocolo: ${Y}❬1❭${NC} vmess ${Y}❬2❭${NC} vless ${Y}❬3❭${NC} trojan"
                read -p "  Opcion: " V2_PROTO_OPT
                case $V2_PROTO_OPT in
                    1) V2_PROTO="vmess" ;; 2) V2_PROTO="vless" ;; 3) V2_PROTO="trojan" ;; *) V2_PROTO="vmess" ;;
                esac
                echo -e "  Red: ${Y}❬1❭${NC} ws ${Y}❬2❭${NC} tcp ${Y}❬3❭${NC} xhttp ${Y}❬4❭${NC} grpc"
                read -p "  Opcion: " V2_NET_OPT
                case $V2_NET_OPT in
                    1) V2_NET="ws" ;; 2) V2_NET="tcp" ;; 3) V2_NET="xhttp" ;; 4) V2_NET="grpc" ;; *) V2_NET="ws" ;;
                esac
                read -p "  Path (ej: /v2ray): " V2_PATH; V2_PATH=${V2_PATH:-/v2ray}
                echo -e "  TLS: ${Y}❬1❭${NC} Si ${Y}❬2❭${NC} No"
                read -p "  Opcion: " V2_TLS_OPT
                [ "$V2_TLS_OPT" = "1" ] && V2_TLS="tls" || V2_TLS="none"
                python3 - << PYEOF
import json, os
port, proto, net, path, tls = int("$V2_PORT"), "$V2_PROTO", "$V2_NET", "$V2_PATH", "$V2_TLS"
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
ib = {"port": port, "protocol": proto, "settings": {"clients": []}, "streamSettings": {"network": net, "security": tls}}
if net == "ws": ib["streamSettings"]["wsSettings"] = {"path": path}
elif net == "xhttp": ib["streamSettings"]["xhttpSettings"] = {"path": path}
elif net == "grpc": ib["streamSettings"]["grpcSettings"] = {"serviceName": path.strip("/")}
if tls == "tls":
    domain = open('/etc/sshfreeltm/v2ray_domain').read().strip() if os.path.exists('/etc/sshfreeltm/v2ray_domain') else ''
    ib["streamSettings"]["tlsSettings"] = {"certificates": [{"certificateFile": f"/etc/letsencrypt/live/{domain}/fullchain.pem","keyFile": f"/etc/letsencrypt/live/{domain}/privkey.pem"}]}
config["inbounds"].append(ib)
with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
print(f"OK {proto} {net} puerto {port}")
PYEOF
                systemctl restart v2ray; echo -e "  ${G}OK Inbound agregado${NC}"; read -p "  ENTER..." ;;
            3)
                banner; sep; echo -e "  ${R}  ELIMINAR INBOUND${NC}"; sep; echo ""
                python3 -c "
import json
with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
for i,ib in enumerate(c.get('inbounds',[])):
    print(f'  [{i+1}] Puerto {ib[\"port\"]} | {ib[\"protocol\"]}')
" 2>/dev/null
                echo ""; read -p "  Numero a eliminar: " DEL_NUM
                python3 - << PYEOF
import json
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
idx = int("$DEL_NUM") - 1
if 0 <= idx < len(config['inbounds']):
    removed = config['inbounds'].pop(idx)
    with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
    print(f"OK Puerto {removed['port']} eliminado")
else: print("Numero invalido")
PYEOF
                systemctl restart v2ray; sleep 1 ;;
            4) systemctl start v2ray && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            5) systemctl stop v2ray && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            6) systemctl restart v2ray && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            7)
                banner; sep; echo -e "  ${Y}  CREAR USUARIO VMESS${NC}"; sep; echo ""
                python3 -c "
import json
with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
for i,ib in enumerate(c.get('inbounds',[])):
    net=ib.get('streamSettings',{}).get('network','tcp')
    tls=ib.get('streamSettings',{}).get('security','none')
    print(f'  [{i+1}] Puerto {ib[\"port\"]} | {ib[\"protocol\"]} | {net} | tls:{tls}')
" 2>/dev/null
                echo ""; read -p "  Numero de inbound: " IB_NUM
                IB_IDX=$((IB_NUM - 1))
                read -p "  Nombre del perfil: " VNAME
                read -p "  Dias de validez (default 30): " V2_DAYS; V2_DAYS=${V2_DAYS:-30}
                EXP_SHOW=$(date -d "+${V2_DAYS} days" +%d/%m/%Y)
                VDOMAIN=$(cat /etc/sshfreeltm/v2ray_domain 2>/dev/null || hostname -I | awk '{print $1}')
                python3 - << PYEOF
import json, uuid, base64, datetime
idx, name, days, domain = int("$IB_IDX"), "$VNAME", int("$V2_DAYS"), "$VDOMAIN"
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
inbounds = config.get('inbounds', [])
if idx >= len(inbounds): print("Inbound no encontrado"); exit(1)
ib = inbounds[idx]
uid = str(uuid.uuid4())
exp = (datetime.datetime.now() + datetime.timedelta(days=days)).strftime("%Y-%m-%d")
if 'clients' not in ib['settings']: ib['settings']['clients'] = []
ib['settings']['clients'].append({"id": uid, "alterId": 0, "email": name, "expires": exp})
with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
net = ib.get('streamSettings', {}).get('network', 'tcp')
tls = ib.get('streamSettings', {}).get('security', 'none')
path = ib.get('streamSettings', {}).get('wsSettings', {}).get('path', '/v2ray') if net == 'ws' else ''
out_port = "443" if ib['port'] == 8080 else str(ib['port'])
out_tls = "tls" if ib['port'] == 8080 else (tls if tls != "none" else "")
vmess = {"v":"2","ps":name,"add":domain,"port":out_port,"id":uid,"aid":"0","net":net,"type":"none","host":domain,"path":path,"tls":out_tls}
link = "vmess://" + base64.b64encode(json.dumps(vmess).encode()).decode()
print("")
print("\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m")
print("  \033[1;32m✅ CUENTA VMESS CREADA\033[0m")
print("\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mPerfil :\033[0m  \033[1;97m{name}\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mHost   :\033[0m  \033[1;97m{domain}\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mPuerto :\033[0m  \033[1;33m{out_port}\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mRed    :\033[0m  \033[1;96m{net}\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mExpira :\033[0m  \033[1;33m$EXP_SHOW\033[0m")
print("\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m")
print("  \033[1;96m🔑 VMESS LINK:\033[0m")
print("")
print("\033[1;97m" + link + "\033[0m")
print("")
print("\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m")
PYEOF
                systemctl restart v2ray; read -p "  ENTER..." ;;
            8)
                python3 -c "
import json
try:
    with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
    for ib in c['inbounds']:
        print(f'  Puerto {ib[\"port\"]}:')
        for u in ib['settings'].get('clients',[]):
            print(f'    - {u.get(\"email\",\"?\")} | expira: {u.get(\"expires\",\"sin exp\")}')
except Exception as e: print(f'Error: {e}')
"; read -p "  ENTER..." ;;
            9)
                read -p "  Confirmar desinstalar V2Ray (si/no): " CONFIRM
                if [ "$CONFIRM" = "si" ]; then
                    systemctl stop v2ray; systemctl disable v2ray
                    bash <(curl -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --remove > /dev/null 2>&1
                    rm -f /etc/sshfreeltm/v2ray_domain
                    echo -e "  ${G}OK V2Ray desinstalado${NC}"; sleep 2
                fi ;;
            0) break ;;
            *) echo -e "  ${R}Opcion invalida${NC}"; sleep 1 ;;
        esac
    done
}



# ══════════════════════════════════════════
#   ZIV VPN
# ══════════════════════════════════════════

menu_ziv() {
    while true; do
        banner; sep; echo -e "  ${Y}  ZIV VPN UDP${NC}"; sep; echo ""
        echo -e "  ZIV VPN $(status_service zivpn)"
        [ -f /etc/zivpn/config.json ] && PORT=$(cat /etc/zivpn/config.json | python3 -c "import json,sys; print(json.load(sys.stdin).get('listen',':5667').replace(':',''))" 2>/dev/null) && echo -e "  Puerto: ${Y}${PORT}${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar ZIV VPN V2 (Recomendado)"
        echo -e "  ${W}[2]${NC} Instalar ZIV VPN V1"
        echo -e "  ${W}[3]${NC} Iniciar"
        echo -e "  ${W}[4]${NC} Detener"
        echo -e "  ${W}[5]${NC} Reiniciar"
        echo -e "  ${W}[6]${NC} Ver configuracion"
        echo -e "  ${W}[7]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) bash <(curl -fsSL https://raw.githubusercontent.com/powermx/zivpn/main/ziv2.sh) ;;
            2) bash <(curl -fsSL https://raw.githubusercontent.com/powermx/zivpn/main/ziv1.sh) ;;
            3) systemctl start zivpn && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            4) systemctl stop zivpn && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            5) systemctl restart zivpn && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            6) cat /etc/zivpn/config.json 2>/dev/null; echo ""; read -p "  ENTER..." ;;
            7) bash <(curl -fsSL https://raw.githubusercontent.com/powermx/zivpn/main/uninstall.sh) 2>/dev/null; echo -e "  ${G}Desinstalado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   USUARIOS ZIV VPN
# ══════════════════════════════════════════

aplicar_passwords_ziv() {
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 - << PYEOF
import json, datetime
with open("/etc/zivpn/users.json") as f: users = json.load(f)
now = datetime.datetime.now()
active = [u["password"] for u in users if datetime.datetime.fromisoformat(u["expires"].split("+")[0].split(".")[0]) > now]
if not active: active = ["zi"]
with open("/etc/zivpn/config.json") as f: config = json.load(f)
# Mantener passwords existentes y agregar nuevas sin duplicar
existing = config["auth"]["config"]
merged = list(set(existing + active))
config["auth"]["config"] = merged
with open("/etc/zivpn/config.json", "w") as f: json.dump(config, f, indent=2)
PYEOF
    systemctl restart zivpn 2>/dev/null
}

crear_user_ziv() {
    banner; sep; echo -e "  ${Y}  CREAR USUARIO ZIV VPN${NC}"; sep; echo ""
    read -p "  Contraseña: " ZIV_PASS
    [ -z "$ZIV_PASS" ] && echo -e "  ${R}Contraseña requerida${NC}" && sleep 1 && return
    read -p "  Dias de validez (default 30): " ZIV_DAYS; ZIV_DAYS=${ZIV_DAYS:-30}
    EXP_DATE=$(date -d "+${ZIV_DAYS} days" -Iseconds)
    EXP_SHOW=$(date -d "+${ZIV_DAYS} days" +"%d/%m/%Y")
    SERVER_IP=$(curl -s -4 ifconfig.me 2>/dev/null || ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 - << PYEOF
import json, datetime
with open("/etc/zivpn/users.json") as f: users = json.load(f)
users.append({"password": "$ZIV_PASS", "expires": "$EXP_DATE", "created": datetime.datetime.now().isoformat()})
with open("/etc/zivpn/users.json", "w") as f: json.dump(users, f, indent=2)
PYEOF
    aplicar_passwords_ziv
    echo ""; sep
    echo -e "  ${Y}  CREDENCIALES ZIV VPN${NC}"; sep
    echo -e "  ${W}IP:${NC}       $SERVER_IP"
    echo -e "  ${W}Puerto:${NC}   5667"
    echo -e "  ${W}Pass:${NC}     $ZIV_PASS"
    echo -e "  ${W}Expira:${NC}   $EXP_SHOW ($ZIV_DAYS dias)"
    echo ""; sep; read -p "  ENTER..."
}

listar_users_ziv() {
    banner; sep; echo -e "  ${Y}  USUARIOS ZIV VPN${NC}"; sep; echo ""
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 - << PYEOF
import json, datetime
with open("/etc/zivpn/users.json") as f: users = json.load(f)
if not users: print("  Sin usuarios")
else:
    now = datetime.datetime.now()
    for u in users:
        exp = datetime.datetime.fromisoformat(u["expires"])
        estado = "\033[0;32m[ACTIVO]\033[0m" if exp > now else "\033[0;31m[EXPIRADO]\033[0m"
        print(f"  Pass: {u['password']:<20} Expira: {exp.strftime('%d/%m/%Y')}  {estado}")
PYEOF
    echo ""; read -p "  ENTER..."
}

eliminar_user_ziv() {
    banner; sep; echo -e "  ${R}  ELIMINAR USUARIO ZIV VPN${NC}"; sep; echo ""
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 -c "
import json
with open('/etc/zivpn/users.json') as f: u=json.load(f)
[print(f'  - {x[\"password\"]}') for x in u] if u else print('  Sin usuarios')
"
    echo ""; read -p "  Contraseña a eliminar: " DEL_PASS
    python3 - << PYEOF
import json
with open("/etc/zivpn/users.json") as f: users = json.load(f)
users = [u for u in users if u["password"] != "$DEL_PASS"]
with open("/etc/zivpn/users.json", "w") as f: json.dump(users, f, indent=2)
PYEOF
    aplicar_passwords_ziv; echo -e "  ${G}Eliminado${NC}"; sleep 1
}

limpiar_expirados_ziv() {
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 - << PYEOF
import json, datetime
with open("/etc/zivpn/users.json") as f: users = json.load(f)
now = datetime.datetime.now()
activos = [u for u in users if datetime.datetime.fromisoformat(u["expires"]) > now]
exp = len(users) - len(activos)
with open("/etc/zivpn/users.json", "w") as f: json.dump(activos, f, indent=2)
print(f"  {exp} expirados eliminados" if exp > 0 else "  Sin expirados")
PYEOF
}

menu_users_ziv() {
    while true; do
        banner; sep; echo -e "  ${Y}  USUARIOS ZIV VPN${NC}"; sep; echo ""
        [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
        TOTAL=$(python3 -c "import json; print(len(json.load(open('/etc/zivpn/users.json'))))" 2>/dev/null || echo 0)
        echo -e "  Total usuarios: ${G}${TOTAL}${NC}"
        echo -e "  ZIV VPN: $(status_service zivpn)"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Crear usuario"
        echo -e "  ${W}[2]${NC} Listar usuarios"
        echo -e "  ${W}[3]${NC} Eliminar usuario"
        echo -e "  ${W}[4]${NC} Limpiar expirados"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) crear_user_ziv ;;
            2) listar_users_ziv ;;
            3) eliminar_user_ziv ;;
            4) limpiar_expirados_ziv; aplicar_passwords_ziv; echo -e "  ${G}Limpiado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   USUARIOS SSH
# ══════════════════════════════════════════

listar_usuarios() {
    banner; sep; echo -e "  ${Y}  USUARIOS SSH ACTIVOS${NC}"; sep; echo ""
    printf "  %-20s %-15s %s\n" "Usuario" "Expira" "Estado"
    sep
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do
        EXP=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        if [ "$EXP" = "never" ] || [ -z "$EXP" ]; then
            printf "  ${Y}%-20s${NC} %-15s\n" "$user" "Sin expirar"
        else
            EXP_TS=$(date -d "$EXP" +%s 2>/dev/null || echo 0)
            NOW_TS=$(date +%s)
            if [ $EXP_TS -lt $NOW_TS ]; then
                printf "  ${R}%-20s${NC} %-15s ${R}[EXPIRADO]${NC}\n" "$user" "$EXP"
            else
                printf "  ${G}%-20s${NC} %-15s\n" "$user" "$EXP"
            fi
        fi
    done
    echo ""; sep; read -p "  ENTER..."
}

crear_usuario() {
    banner; sep; echo -e "  ${Y}  CREAR USUARIO SSH${NC}"; sep; echo ""
    read -p "  Nombre de usuario: " USR_NAME
    [ -z "$USR_NAME" ] && echo -e "  ${R}Nombre requerido${NC}" && sleep 1 && return
    read -p "  Contraseña (ENTER para generar): " USR_PASS
    [ -z "$USR_PASS" ] && USR_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1) && echo -e "  ${G}Generada: ${W}${USR_PASS}${NC}"
    read -p "  Dias de validez (default 30): " USR_DAYS; USR_DAYS=${USR_DAYS:-30}
    EXP_DATE=$(date -d "+${USR_DAYS} days" +%Y-%m-%d)
    EXP_SHOW=$(date -d "+${USR_DAYS} days" +%d/%m/%Y)
    SERVER_IP=$(curl -s -4 ifconfig.me 2>/dev/null || ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
    echo ""; echo -e "  ${C}Creando usuario...${NC}"
    if id "$USR_NAME" &>/dev/null; then
        usermod -e $EXP_DATE $USR_NAME; echo "$USR_NAME:$USR_PASS" | chpasswd
    else
        useradd -M -s /bin/false -e $EXP_DATE $USR_NAME
        echo "$USR_NAME:$USR_PASS" | chpasswd
        chage -E $EXP_DATE -M 99999 $USR_NAME; usermod -f 0 $USR_NAME
    fi
    echo ""; sep; echo -e "  ${Y}  CREDENCIALES${NC}"; sep
    echo -e "  ${W}Usuario:${NC}  $USR_NAME"
    echo -e "  ${W}Password:${NC} $USR_PASS"
    echo -e "  ${W}IP:${NC}       $SERVER_IP"
    echo -e "  ${W}Expira:${NC}   $EXP_SHOW ($USR_DAYS dias)"
    echo ""; sep; echo -e "  ${Y}  CONEXIONES DISPONIBLES${NC}"; sep; echo ""
    echo -e "  ${C}SSH Directo:${NC}"; echo -e "  ${W}$SERVER_IP:22@$USR_NAME:$USR_PASS${NC}"; echo ""
    ss -tlnp | grep -q ":80 " && echo -e "  ${C}WS Puerto 80:${NC}" && echo -e "  ${W}$SERVER_IP:80@$USR_NAME:$USR_PASS${NC}" && echo ""
    systemctl is-active --quiet stunnel4 2>/dev/null && echo -e "  ${C}SSL/TLS 443:${NC}" && echo -e "  ${W}$SERVER_IP:443@$USR_NAME:$USR_PASS${NC}" && echo ""
    ps aux | grep -i "udp-custom\|UDP-Custom" | grep -v grep | grep -q . && echo -e "  ${C}UDP Custom:${NC}" && echo -e "  ${W}$SERVER_IP:1-65535@$USR_NAME:$USR_PASS${NC}" && echo ""
    (systemctl is-active --quiet badvpn-7200 2>/dev/null || systemctl is-active --quiet badvpn-7300 2>/dev/null) && echo -e "  ${C}BadVPN:${NC}" && systemctl is-active --quiet badvpn-7200 && echo -e "  ${W}Puerto 7200 activo${NC}" && systemctl is-active --quiet badvpn-7300 && echo -e "  ${W}Puerto 7300 activo${NC}" && echo ""
    sep; read -p "  ENTER..."
}

eliminar_usuario() {
    banner; sep; echo -e "  ${R}  ELIMINAR USUARIO SSH${NC}"; sep; echo ""
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do printf "  ${Y}%-20s${NC}\n" "$user"; done
    echo ""; read -p "  Usuario a eliminar: " DEL_USR
    if id "$DEL_USR" &>/dev/null; then
        pkill -u "$DEL_USR" 2>/dev/null; userdel -f "$DEL_USR" 2>/dev/null
        echo -e "  ${G}OK Usuario $DEL_USR eliminado${NC}"
    else echo -e "  ${R}Usuario no encontrado${NC}"; fi
    sleep 2
}

renovar_usuario() {
    banner; sep; echo -e "  ${Y}  RENOVAR USUARIO SSH${NC}"; sep; echo ""
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do
        EXP=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        printf "  ${Y}%-20s${NC} %s\n" "$user" "$EXP"
    done
    echo ""; read -p "  Usuario a renovar: " REN_USR
    id "$REN_USR" &>/dev/null || { echo -e "  ${R}No encontrado${NC}"; sleep 1; return; }
    read -p "  Dias a agregar (default 30): " REN_DAYS; REN_DAYS=${REN_DAYS:-30}
    EXP_DATE=$(date -d "+${REN_DAYS} days" +%Y-%m-%d)
    EXP_SHOW=$(date -d "+${REN_DAYS} days" +%d/%m/%Y)
    usermod -e $EXP_DATE $REN_USR; chage -E $EXP_DATE $REN_USR
    echo -e "  ${G}OK $REN_USR renovado hasta $EXP_SHOW${NC}"; sleep 2
}

menu_usuarios() {
    while true; do
        banner; sep; echo -e "  ${Y}  GESTIÓN DE USUARIOS SSH${NC}"; sep; echo ""
        TOTAL=$(awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | wc -l)
        echo -e "  Total usuarios: ${G}${TOTAL}${NC}"; echo ""; sep
        echo -e "  ${W}[1]${NC} Crear usuario"
        echo -e "  ${W}[2]${NC} Listar usuarios"
        echo -e "  ${W}[3]${NC} Eliminar usuario"
        echo -e "  ${W}[4]${NC} Renovar usuario"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) crear_usuario ;;
            2) listar_usuarios ;;
            3) eliminar_usuario ;;
            4) renovar_usuario ;;
            0) break ;;
        esac
    done
}


instalar_motd() {
    banner; sep
    echo -e "  ${Y}  CONFIGURAR MOTD DEL SERVIDOR${NC}"; sep; echo ""
    read -p "  Nombre del servidor: " SRV_NAME
    [ -z "$SRV_NAME" ] && SRV_NAME="SSHFREE LTM"

    # Instalar figlet para ASCII art
    apt install -y figlet > /dev/null 2>&1

    INSTALL_DATE=$(date +%d-%m-%Y)

    # Guardar fecha de instalación
    echo "$INSTALL_DATE" > /etc/sshfreeltm/install_date
    echo "$SRV_NAME" > /etc/sshfreeltm/server_name

    # Probar figlet
    echo -e "  ${C}Preview del nombre:${NC}"
    figlet -f slant "$SRV_NAME" 2>/dev/null || figlet "$SRV_NAME" 2>/dev/null || echo "$SRV_NAME"
    
    # Crear script MOTD dinámico
    cat > /etc/profile.d/sshfree-motd.sh << MOTDEOF
#!/bin/bash
PURPLE='[0;35m'
CYAN='[0;36m'
GREEN='[0;32m'
YELLOW='[1;33m'
WHITE='[1;37m'
NC='[0m'

INSTALL_DATE=\$(cat /etc/sshfreeltm/install_date 2>/dev/null || echo "N/A")
SRV_NAME=\$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
CURRENT_DATE=\$(date +%d-%m-%Y)
CURRENT_TIME=\$(date +%H:%M:%S)
UPTIME=\$(uptime -p | sed 's/up //')
RAM_FREE=\$(free -h | awk '/^Mem:/{print \$4}')
HOSTNAME=\$(hostname)

echo -e "\${PURPLE}"
figlet -f slant "\$SRV_NAME" 2>/dev/null || echo "\$SRV_NAME"
echo -e "\${NC}"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo -e "  \${YELLOW}SERVIDOR INSTALADO EL\${NC}   : \${WHITE}\$INSTALL_DATE\${NC}"
echo -e "  \${YELLOW}FECHA/HORA ACTUAL\${NC}        : \${WHITE}\$CURRENT_DATE - \$CURRENT_TIME\${NC}"
echo -e "  \${YELLOW}NOMBRE DEL SERVIDOR\${NC}      : \${WHITE}\$HOSTNAME\${NC}"
echo -e "  \${YELLOW}TIEMPO EN LINEA\${NC}          : \${WHITE}\$UPTIME\${NC}"
echo -e "  \${YELLOW}VERSION INSTALADA\${NC}        : \${WHITE}V1.0.0\${NC}"
echo -e "  \${YELLOW}MEMORIA RAM LIBRE\${NC}        : \${WHITE}\$RAM_FREE\${NC}"
echo -e "  \${YELLOW}CREADOR DEL SCRIPT\${NC}       : \${PURPLE}@DarkZFull ❴LTM❵\${NC}"
echo -e "  \${GREEN}BIENVENIDO DE NUEVO!\${NC}"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo -e "  Teclee \${YELLOW}menu\${NC} para ver el MENU LTM"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo ""
MOTDEOF

    chmod +x /etc/profile.d/sshfree-motd.sh
    
    # Deshabilitar MOTD por defecto de Ubuntu
    [ -f /etc/motd ] && > /etc/motd
    
    echo -e "
  ${G}OK MOTD configurado para ${SRV_NAME}${NC}"
    echo -e "  ${Y}Se mostrara al conectarte por SSH${NC}"
    sleep 2
}

# ══════════════════════════════════════════
#   MENÚ PRINCIPAL
# ══════════════════════════════════════════

desinstalar_script() {
    banner; sep
    echo -e "  ${R}  DESINSTALAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${Y}Esto eliminará:${NC}"
    echo -e "  - Comando menu"
    echo -e "  - MOTD del servidor"
    echo -e "  - Archivos de configuracion"
    echo -e "  - Servicios instalados (WS, BadVPN, etc)"
    echo ""
    read -p "  Confirmar (si/no): " CONFIRM
    [ "$CONFIRM" != "si" ] && echo -e "  ${Y}Cancelado${NC}" && sleep 1 && return

    echo -e "\n  ${C}Desinstalando...${NC}"
    # Detener y eliminar servicios
    for svc in ws-proxy-* badvpn-* udp-custom stunnel4 v2ray zivpn hysteria-server; do
        systemctl stop $svc 2>/dev/null
        systemctl disable $svc 2>/dev/null
        rm -f /etc/systemd/system/$svc.service
    done
    systemctl daemon-reload

    # Eliminar archivos
    rm -f /usr/local/bin/menu
    rm -f /etc/profile.d/sshfree-motd.sh
    rm -rf /etc/sshfreeltm
    rm -rf $DIR_SCRIPTS

    echo -e "  ${G}Script desinstalado correctamente${NC}"
    sleep 2
    exit 0
}
actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh?$(date +%s)"
    chmod +x /usr/local/bin/menu
    mkdir -p /etc/sshfreeltm
    touch /etc/sshfreeltm/.licensed
    echo -e "  ${G}OK Script actualizado a v$(grep SCRIPT_VERSION /usr/local/bin/menu | head -1 | grep -o '[0-9.]*')${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh?$(date +%s)"
    chmod +x /usr/local/bin/menu
    mkdir -p /etc/sshfreeltm
    touch /etc/sshfreeltm/.licensed
    echo -e "  ${G}OK Script actualizado a v$(grep SCRIPT_VERSION /usr/local/bin/menu | head -1 | grep -o '[0-9.]*')${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_atacantes() {
    banner; sep
    echo -e "  ${NEON}◆ IPs ATACANTES${NC}"; sep; echo ""
    
    # Ver IPs bloqueadas por fail2ban
    if command -v fail2ban-client > /dev/null 2>&1; then
        BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | cut -d: -f2 | tr ' ' '\n' | grep -v '^$')
        if [ -n "$BANNED" ]; then
            echo -e "  ${R}🚨 IPs bloqueadas por Fail2ban:${NC}"
            echo "$BANNED" | while read ip; do
                [ -n "$ip" ] && echo -e "  ${NEON}◈${NC} ${R}$ip${NC}"
            done
        else
            echo -e "  ${G}✅ Sin IPs bloqueadas en Fail2ban${NC}"
        fi
    fi
    
    echo ""
    
    # Ver conexiones sospechosas activas
    echo -e "  ${Y}🔍 Conexiones activas por IP:${NC}"
    CONNS=$(ss -tn state established | awk 'NR>1{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10)
    if [ -n "$CONNS" ]; then
        echo "$CONNS" | while read count ip; do
            [ -z "$ip" ] && continue
            if [ "$count" -gt 10 ]; then
                echo -e "  ${R}◈ $ip — $count conexiones ⚠️${NC}"
            else
                echo -e "  ${NEON}◈${NC} $ip — ${Y}$count${NC} conexiones"
            fi
        done
    else
        echo -e "  ${G}✅ Sin conexiones sospechosas${NC}"
    fi
    
    echo ""
    
    # Ver logs de iptables DROP recientes
    echo -e "  ${Y}🛡️ Paquetes bloqueados recientes:${NC}"
    DROPS=$(dmesg 2>/dev/null | grep "IN=.*OUT=" | tail -5 | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn)
    if [ -n "$DROPS" ]; then
        echo "$DROPS" | while read count ip; do
            echo -e "  ${NEON}◈${NC} ${R}$ip${NC} — $count paquetes bloqueados"
        done
    else
        echo -e "  ${G}✅ Sin ataques detectados${NC}"
    fi
    
    echo ""; sep
    read -p "  ENTER..."
}

menu_antiddos() {
    while true; do
        banner; sep
        echo -e "  ${Y}  ANTI-DDOS${NC}"; sep; echo ""
        DDOS_ACTIVE=$(iptables -L INPUT -n 2>/dev/null | grep -q "limit" && echo 1 || echo 0)
        if [ "$DDOS_ACTIVE" = "1" ]; then
            echo -e "  Estado: ${G}[ACTIVO]${NC}"
        else
            echo -e "  Estado: ${R}[INACTIVO]${NC}"
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Activar Anti-DDoS Agresivo"
        echo -e "  ${W}[2]${NC} Desactivar Anti-DDoS"
        echo -e "  ${W}[3]${NC} Ver reglas activas"
        echo -e "  ${W}[4]${NC} Ver IPs atacantes"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}[1/5] Instalando dependencias...${NC}"
                DEBIAN_FRONTEND=noninteractive apt install -y -qq iptables-persistent fail2ban 2>&1 | \
                    grep -E "^(Get|Setting|Processing|Unpacking)" | while read line; do echo "    $line"; done
                echo -e "  ${G}  ✓ Dependencias listas${NC}"

                echo -e "  ${C}[2/5] Limpiando reglas previas...${NC}"
                iptables -F; iptables -X; iptables -Z
                echo -e "  ${G}  ✓ Reglas limpiadas${NC}"

                echo -e "  ${C}[3/5] Aplicando politicas base...${NC}"
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                echo -e "  ${G}  ✓ Politicas base aplicadas${NC}"

                echo -e "  ${C}[4/5] Abriendo puertos activos...${NC}"
                for PORT in $(ss -tlnp | awk '/LISTEN/{print $4}' | grep -oE '[0-9]+$' | sort -u); do
                    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
                    echo -e "  ${DIM}    TCP $PORT abierto${NC}"
                done
                for PORT in $(ss -ulnp | awk '/UNCONN/{print $4}' | grep -oE '[0-9]+$' | sort -u); do
                    iptables -A INPUT -p udp --dport $PORT -j ACCEPT
                    echo -e "  ${DIM}    UDP $PORT abierto${NC}"
                done
                echo -e "  ${G}  ✓ Puertos configurados${NC}"

                echo -e "  ${C}[5/5] Aplicando reglas anti-ataque...${NC}"
                iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP
                echo -e "  ${G}  ✓ SYN Flood bloqueado${NC}"
                iptables -A INPUT -p udp -m limit --limit 50/s --limit-burst 100 -j ACCEPT
                iptables -A INPUT -p udp -j DROP
                echo -e "  ${G}  ✓ UDP Flood bloqueado${NC}"
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 2/s --limit-burst 4 -j ACCEPT
                iptables -A INPUT -p icmp -j DROP
                echo -e "  ${G}  ✓ ICMP Flood bloqueado${NC}"
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
                echo -e "  ${G}  ✓ Port scanning bloqueado${NC}"
                iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 5 -j REJECT
                iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 -j REJECT
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP
                iptables -A INPUT -s 10.0.0.0/8 ! -i lo -j DROP
                iptables -A INPUT -s 172.16.0.0/12 ! -i lo -j DROP
                iptables -A INPUT -s 192.168.0.0/16 ! -i lo -j DROP
                echo -e "  ${G}  ✓ Brute Force y spoofing bloqueados${NC}"

                echo -e "  ${C}  Guardando reglas...${NC}"
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules
                echo -e "  ${G}  ✓ Reglas guardadas${NC}"

                echo -e "  ${C}  Configurando Fail2ban...${NC}"
                mkdir -p /etc/fail2ban
                cat > /etc/fail2ban/jail.local << EOF_JAIL
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 86400

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF_JAIL
                echo -e "  ${G}  ✓ Fail2ban configurado${NC}"

                systemctl enable fail2ban -q 2>/dev/null
                systemctl restart fail2ban 2>/dev/null
                echo -ne "  ${C}  Iniciando Fail2ban${NC}"
                for i in 1 2 3 4 5; do sleep 0.5; echo -ne "."; done; echo ""
                systemctl is-active --quiet fail2ban && \
                    echo -e "  ${G}  ✓ Fail2ban activo${NC}" || \
                    echo -e "  ${Y}  ⚠ Verifica: systemctl status fail2ban${NC}"

                BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | cut -d: -f2 | xargs)
                if [ -n "$BANNED_IPS" ]; then
                    curl -s -X POST "https://api.telegram.org/bot7998209606:AAGNwiDAH5cOhWftedzZosjq7GLElvJRtws/sendMessage" \
                        -d "chat_id=6290827127&text=Anti-DDoS+Activado+-+IPs:+${BANNED_IPS}&parse_mode=Markdown" > /dev/null 2>&1
                fi

                echo ""; sep
                echo -e "  ${G}OK Anti-DDoS agresivo activado${NC}"; sep
                read -p "  ENTER..." ;;
            2)
                iptables -F; iptables -X
                iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT
                systemctl stop fail2ban 2>/dev/null
                echo -e "  ${Y}Anti-DDoS desactivado${NC}"; sleep 2 ;;
            3)
                echo ""; iptables -L INPUT -n --line-numbers | head -30; echo ""
                read -p "  ENTER..." ;;
            4) menu_atacantes ;;
            0) break ;;
        esac
    done
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh?$(date +%s)"
    chmod +x /usr/local/bin/menu
    mkdir -p /etc/sshfreeltm
    touch /etc/sshfreeltm/.licensed
    echo -e "  ${G}OK Script actualizado a v$(grep SCRIPT_VERSION /usr/local/bin/menu | head -1 | grep -o '[0-9.]*')${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_atacantes() {
    banner; sep
    echo -e "  ${NEON}◆ IPs ATACANTES${NC}"; sep; echo ""
    
    # Ver IPs bloqueadas por fail2ban
    if command -v fail2ban-client > /dev/null 2>&1; then
        BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | cut -d: -f2 | tr ' ' '\n' | grep -v '^$')
        if [ -n "$BANNED" ]; then
            echo -e "  ${R}🚨 IPs bloqueadas por Fail2ban:${NC}"
            echo "$BANNED" | while read ip; do
                [ -n "$ip" ] && echo -e "  ${NEON}◈${NC} ${R}$ip${NC}"
            done
        else
            echo -e "  ${G}✅ Sin IPs bloqueadas en Fail2ban${NC}"
        fi
    fi
    
    echo ""
    
    # Ver conexiones sospechosas activas
    echo -e "  ${Y}🔍 Conexiones activas por IP:${NC}"
    CONNS=$(ss -tn state established | awk 'NR>1{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10)
    if [ -n "$CONNS" ]; then
        echo "$CONNS" | while read count ip; do
            [ -z "$ip" ] && continue
            if [ "$count" -gt 10 ]; then
                echo -e "  ${R}◈ $ip — $count conexiones ⚠️${NC}"
            else
                echo -e "  ${NEON}◈${NC} $ip — ${Y}$count${NC} conexiones"
            fi
        done
    else
        echo -e "  ${G}✅ Sin conexiones sospechosas${NC}"
    fi
    
    echo ""
    
    # Ver logs de iptables DROP recientes
    echo -e "  ${Y}🛡️ Paquetes bloqueados recientes:${NC}"
    DROPS=$(dmesg 2>/dev/null | grep "IN=.*OUT=" | tail -5 | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn)
    if [ -n "$DROPS" ]; then
        echo "$DROPS" | while read count ip; do
            echo -e "  ${NEON}◈${NC} ${R}$ip${NC} — $count paquetes bloqueados"
        done
    else
        echo -e "  ${G}✅ Sin ataques detectados${NC}"
    fi
    
    echo ""; sep
    read -p "  ENTER..."
}

menu_antiddos() {
    while true; do
        banner; sep
        echo -e "  ${Y}  ANTI-DDOS${NC}"; sep; echo ""
        DDOS_ACTIVE=$(iptables -L INPUT -n 2>/dev/null | grep -q "limit" && echo 1 || echo 0)
        if [ "$DDOS_ACTIVE" = "1" ]; then
            echo -e "  Estado: ${G}[ACTIVO]${NC}"
        else
            echo -e "  Estado: ${R}[INACTIVO]${NC}"
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Activar Anti-DDoS Agresivo"
        echo -e "  ${W}[2]${NC} Desactivar Anti-DDoS"
        echo -e "  ${W}[3]${NC} Ver reglas activas"
        echo -e "  ${W}[4]${NC} Ver IPs atacantes"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}[1/5] Instalando dependencias...${NC}"
                DEBIAN_FRONTEND=noninteractive apt install -y -qq iptables-persistent fail2ban 2>&1 | \
                    grep -E "^(Get|Setting|Processing|Unpacking)" | while read line; do echo "    $line"; done
                echo -e "  ${G}  ✓ Dependencias listas${NC}"

                echo -e "  ${C}[2/5] Limpiando reglas previas...${NC}"
                iptables -F; iptables -X; iptables -Z
                echo -e "  ${G}  ✓ Reglas limpiadas${NC}"

                echo -e "  ${C}[3/5] Aplicando politicas base...${NC}"
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                echo -e "  ${G}  ✓ Politicas base aplicadas${NC}"

                echo -e "  ${C}[4/5] Abriendo puertos activos...${NC}"
                for PORT in $(ss -tlnp | awk '/LISTEN/{print $4}' | grep -oE '[0-9]+$' | sort -u); do
                    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
                    echo -e "  ${DIM}    TCP $PORT abierto${NC}"
                done
                for PORT in $(ss -ulnp | awk '/UNCONN/{print $4}' | grep -oE '[0-9]+$' | sort -u); do
                    iptables -A INPUT -p udp --dport $PORT -j ACCEPT
                    echo -e "  ${DIM}    UDP $PORT abierto${NC}"
                done
                echo -e "  ${G}  ✓ Puertos configurados${NC}"

                echo -e "  ${C}[5/5] Aplicando reglas anti-ataque...${NC}"
                iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP
                echo -e "  ${G}  ✓ SYN Flood bloqueado${NC}"
                iptables -A INPUT -p udp -m limit --limit 50/s --limit-burst 100 -j ACCEPT
                iptables -A INPUT -p udp -j DROP
                echo -e "  ${G}  ✓ UDP Flood bloqueado${NC}"
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 2/s --limit-burst 4 -j ACCEPT
                iptables -A INPUT -p icmp -j DROP
                echo -e "  ${G}  ✓ ICMP Flood bloqueado${NC}"
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
                echo -e "  ${G}  ✓ Port scanning bloqueado${NC}"
                iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 5 -j REJECT
                iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 -j REJECT
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP
                iptables -A INPUT -s 10.0.0.0/8 ! -i lo -j DROP
                iptables -A INPUT -s 172.16.0.0/12 ! -i lo -j DROP
                iptables -A INPUT -s 192.168.0.0/16 ! -i lo -j DROP
                echo -e "  ${G}  ✓ Brute Force y spoofing bloqueados${NC}"

                echo -e "  ${C}  Guardando reglas...${NC}"
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules
                echo -e "  ${G}  ✓ Reglas guardadas${NC}"

                echo -e "  ${C}  Configurando Fail2ban...${NC}"
                mkdir -p /etc/fail2ban
                cat > /etc/fail2ban/jail.local << EOF_JAIL
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 86400

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF_JAIL
                echo -e "  ${G}  ✓ Fail2ban configurado${NC}"

                systemctl enable fail2ban -q 2>/dev/null
                systemctl restart fail2ban 2>/dev/null
                echo -ne "  ${C}  Iniciando Fail2ban${NC}"
                for i in 1 2 3 4 5; do sleep 0.5; echo -ne "."; done; echo ""
                systemctl is-active --quiet fail2ban && \
                    echo -e "  ${G}  ✓ Fail2ban activo${NC}" || \
                    echo -e "  ${Y}  ⚠ Verifica: systemctl status fail2ban${NC}"

                BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | cut -d: -f2 | xargs)
                if [ -n "$BANNED_IPS" ]; then
                    curl -s -X POST "https://api.telegram.org/bot7998209606:AAGNwiDAH5cOhWftedzZosjq7GLElvJRtws/sendMessage" \
                        -d "chat_id=6290827127&text=Anti-DDoS+Activado+-+IPs:+${BANNED_IPS}&parse_mode=Markdown" > /dev/null 2>&1
                fi

                echo ""; sep
                echo -e "  ${G}OK Anti-DDoS agresivo activado${NC}"; sep
                read -p "  ENTER..." ;;
            2)
                iptables -F; iptables -X
                iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT
                systemctl stop fail2ban 2>/dev/null
                echo -e "  ${Y}Anti-DDoS desactivado${NC}"; sleep 2 ;;
            3)
                echo ""; iptables -L INPUT -n --line-numbers | head -30; echo ""
                read -p "  ENTER..." ;;
            4) menu_atacantes ;;
            0) break ;;
        esac
    done
}

menu_speed_udp() {
    banner; sep
    echo -e "  ${Y}  MEJORAR VELOCIDAD UDP${NC}"; sep; echo ""
    echo -e "  ${C}Aplicando optimizaciones...${NC}"
    echo ""

    # BBR
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf 2>/dev/null
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

    # Buffers UDP
    echo "net.core.rmem_max=134217728" >> /etc/sysctl.conf
    echo "net.core.wmem_max=134217728" >> /etc/sysctl.conf
    echo "net.core.rmem_default=25165824" >> /etc/sysctl.conf
    echo "net.core.wmem_default=25165824" >> /etc/sysctl.conf
    echo "net.core.netdev_max_backlog=65536" >> /etc/sysctl.conf
    echo "net.ipv4.udp_rmem_min=8192" >> /etc/sysctl.conf
    echo "net.ipv4.udp_wmem_min=8192" >> /etc/sysctl.conf

    # Aplicar cambios
    sysctl -p > /dev/null 2>&1

    # Verificar BBR
    BBR=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -o bbr)
    if [ "$BBR" = "bbr" ]; then
        echo -e "  ${G}✓ BBR activado${NC}"
    else
        echo -e "  ${Y}✓ Buffers optimizados (BBR no disponible en este kernel)${NC}"
    fi
    echo -e "  ${G}✓ Buffers UDP maximizados${NC}"
    echo -e "  ${G}✓ Network backlog optimizado${NC}"
    echo ""
    sep
    echo -e "  ${G}OK Optimizacion aplicada${NC}"
    read -p "  ENTER..."
}

menu_slowdns() {
    SLOWDNS_DIR="/etc/slowdns"
    SERVER_SERVICE="server-sldns"
    CLIENT_SERVICE="client-sldns"
    PUBKEY_FILE="$SLOWDNS_DIR/server.pub"
    while true; do
        banner; sep
        echo -e "  ${Y}  SLOWDNS${NC}"; sep; echo ""
        SDNS_ST=$(systemctl is-active $SERVER_SERVICE 2>/dev/null)
        [ "$SDNS_ST" = "active" ] && echo -e "  Estado: ${G}[ACTIVO]${NC}" || echo -e "  Estado: ${R}[INACTIVO]${NC}"
        [ -f "$PUBKEY_FILE" ] && echo -e "  PubKey: ${W}$(cat $PUBKEY_FILE)${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar SlowDNS"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Ver Public Key"
        echo -e "  ${W}[5]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Instalando dependencias...${NC}"
                apt install -y git screen iptables net-tools curl wget dos2unix gnutls-bin netfilter-persistent
                mkdir -p $SLOWDNS_DIR
                chmod 700 $SLOWDNS_DIR
                read -p "  Dominio NS: " SDNS_DOMAIN
                read -p "  Puerto SSH local (default 22): " SDNS_PORT
                SDNS_PORT=${SDNS_PORT:-22}
                echo -e "  ${C}Descargando binarios...${NC}"
                wget -q -O $SLOWDNS_DIR/sldns-server "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-server"
                wget -q -O $SLOWDNS_DIR/sldns-client "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-client"
                wget -q -O $SLOWDNS_DIR/server.key "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.key"
                wget -q -O $SLOWDNS_DIR/server.pub "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.pub"
                chmod +x $SLOWDNS_DIR/*
                iptables -I INPUT -p udp --dport 5300 -j ACCEPT
                iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
                netfilter-persistent save 2>/dev/null
                cat > /etc/systemd/system/$CLIENT_SERVICE.service << EOF
[Unit]
Description=Client SlowDNS
After=network.target
[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/sldns-client -udp 8.8.8.8:53 --pubkey-file $PUBKEY_FILE $SDNS_DOMAIN 127.0.0.1:$SDNS_PORT
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
                cat > /etc/systemd/system/$SERVER_SERVICE.service << EOF
[Unit]
Description=Server SlowDNS
After=network.target
[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/sldns-server -udp :5300 -privkey-file $SLOWDNS_DIR/server.key $SDNS_DOMAIN 127.0.0.1:$SDNS_PORT
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable $CLIENT_SERVICE $SERVER_SERVICE
                systemctl start $CLIENT_SERVICE $SERVER_SERVICE
                echo -e "  ${G}OK SlowDNS instalado${NC}"
                echo -e "  PubKey: $(cat $PUBKEY_FILE 2>/dev/null)"
                read -p "  ENTER..." ;;
            2) systemctl start $CLIENT_SERVICE $SERVER_SERVICE && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop $CLIENT_SERVICE $SERVER_SERVICE && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) cat $PUBKEY_FILE 2>/dev/null || echo -e "  ${R}No encontrada${NC}"; echo ""; read -p "  ENTER..." ;;
            5)
                systemctl stop $CLIENT_SERVICE $SERVER_SERVICE 2>/dev/null
                systemctl disable $CLIENT_SERVICE $SERVER_SERVICE 2>/dev/null
                rm -rf $SLOWDNS_DIR
                rm -f /etc/systemd/system/$CLIENT_SERVICE.service /etc/systemd/system/$SERVER_SERVICE.service
                systemctl daemon-reload
                echo -e "  ${G}SlowDNS desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_dropbear() {
    while true; do
        banner; sep
        echo -e "  ${Y}  DROPBEAR SSH${NC}"; sep; echo ""
        DB_ST=$(systemctl is-active dropbear 2>/dev/null)
        [ "$DB_ST" = "active" ] && echo -e "  Estado: ${G}[ACTIVO]${NC}" || echo -e "  Estado: ${R}[INACTIVO]${NC}"
        DB_PORT=$(cat /etc/sshfreeltm/dropbear_port 2>/dev/null || echo "444")
        echo -e "  Puerto: ${W}${DB_PORT}${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar Dropbear"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Cambiar puerto"
        echo -e "  ${W}[6]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Instalando Dropbear...${NC}"
                apt install -y dropbear
                read -p "  Puerto Dropbear (default 444): " DB_PORT
                DB_PORT=${DB_PORT:-444}
                mkdir -p /etc/sshfreeltm
                echo "$DB_PORT" > /etc/sshfreeltm/dropbear_port
                # Configurar
                sed -i "s/NO_START=1/NO_START=0/" /etc/default/dropbear 2>/dev/null
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$DB_PORT/" /etc/default/dropbear 2>/dev/null
                grep -q "DROPBEAR_PORT" /etc/default/dropbear || echo "DROPBEAR_PORT=$DB_PORT" >> /etc/default/dropbear
                # Crear servicio
                cat > /etc/systemd/system/dropbear.service << EOF
[Unit]
Description=Dropbear SSH Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/sbin/dropbear -F -p $DB_PORT
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                # Generar llaves Dropbear
                mkdir -p /etc/dropbear
                [ ! -f /etc/dropbear/dropbear_dss_host_key ] && dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_rsa_host_key ] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key > /dev/null 2>&1
                # Agregar /bin/false a shells permitidos
                grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
                systemctl enable dropbear
                systemctl start dropbear
                iptables -I INPUT -p tcp --dport $DB_PORT -j ACCEPT 2>/dev/null
                echo -e "  ${G}OK Dropbear instalado en puerto ${DB_PORT}${NC}"; sleep 2 ;;
            2) systemctl start dropbear && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop dropbear && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart dropbear && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Nuevo puerto: " NEW_PORT
                echo "$NEW_PORT" > /etc/sshfreeltm/dropbear_port
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$NEW_PORT/" /etc/default/dropbear 2>/dev/null
                sed -i "s/-p [0-9]*/-p $NEW_PORT/" /etc/systemd/system/dropbear.service 2>/dev/null
                systemctl daemon-reload
                systemctl restart dropbear
                echo -e "  ${G}Puerto cambiado a ${NEW_PORT}${NC}"; sleep 2 ;;
            6)
                systemctl stop dropbear; systemctl disable dropbear
                apt remove -y dropbear > /dev/null 2>&1
                rm -f /etc/systemd/system/dropbear.service
                systemctl daemon-reload
                echo -e "  ${G}Dropbear desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_banner_ssh() {
    while true; do
        banner; sep
        echo -e "  ${Y}  BANNER SSH${NC}"; sep; echo ""
        echo -e "  Banner actual:"
        echo ""
        cat /etc/ssh/sshd_config | grep -i "^Banner" || echo "  Sin banner configurado"
        [ -f /etc/ssh/banner ] && cat /etc/ssh/banner || echo ""
        echo ""; sep
        echo -e "  ${W}[1]${NC} Crear/Editar banner"
        echo -e "  ${W}[2]${NC} Quitar banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                banner; sep
                echo -e "  ${Y}Escribe el banner SSH${NC}"
                echo -e "  ${C}(Texto que aparece al conectar por SSH)${NC}"; sep; echo ""
                echo -e "  Ejemplo:"
                echo -e "  ╔══════════════════════════════════╗"
                echo -e "  ║   SERVIDOR PRIVADO - SSHFREE LTM ║"
                echo -e "  ╚══════════════════════════════════╝"
                echo ""; sep
                read -p "  Texto del banner: " BANNER_TXT
                echo "$BANNER_TXT" > /etc/ssh/banner
                # Configurar sshd para mostrar banner
                grep -q "^Banner" /etc/ssh/sshd_config && sed -i "s|^Banner.*|Banner /etc/ssh/banner|" /etc/ssh/sshd_config || echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
                systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
                echo -e "  ${G}OK Banner SSH configurado${NC}"; sleep 2 ;;
            2)
                sed -i '/^Banner/d' /etc/ssh/sshd_config
                rm -f /etc/ssh/banner
                systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
                echo -e "  ${G}OK Banner eliminado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

menu_limpieza() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ LIMPIEZA Y AUTO-REINICIO${NC}"; sep; echo ""
        # Ver estado del cron de reinicio
        CRON_ST=$(crontab -l 2>/dev/null | grep -c "reboot\|ltm_reboot" || echo 0)
        [ "$CRON_ST" -gt 0 ] && echo -e "  ${NEON}◈${NC} ${W}Auto-reinicio:${NC} ${NEON}◆ ACTIVO${NC}" || echo -e "  ${NEON}◈${NC} ${W}Auto-reinicio:${NC} ${R}◇ INACTIVO${NC}"
        RAM_FREE=$(free -h | awk '/^Mem:/{print $4}')
        RAM_USED=$(free -h | awk '/^Mem:/{print $3}')
        echo -e "  ${NEON}◈${NC} ${W}RAM Libre:${NC} ${Y}${RAM_FREE}${NC} | ${W}Usada:${NC} ${Y}${RAM_USED}${NC}"
        echo ""; sep
        printf " ${Y}❬1❭ Limpiar cache RAM ahora${NC}\n"
        printf " ${Y}❬2❭ Limpiar archivos temporales${NC}\n"
        printf " ${Y}❬3❭ Configurar auto-reinicio${NC}\n"
        printf " ${Y}❬4❭ Ver cron de reinicio${NC}\n"
        printf " ${R}❬5❭ Desactivar auto-reinicio${NC}\n"
        printf " ${Y}❬6❭ Reiniciar ahora${NC}\n"
        sep; printf " ${R}❬0❭ Volver${NC}\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Limpiando cache RAM...${NC}"
                sync
                echo 3 > /proc/sys/vm/drop_caches
                RAM_FREE_NEW=$(free -h | awk '/^Mem:/{print $4}')
                echo -e "  ${G}✓ Cache limpiada${NC}"
                echo -e "  ${NEON}◈${NC} ${W}RAM Libre ahora:${NC} ${Y}${RAM_FREE_NEW}${NC}"
                sleep 2 ;;
            2)
                echo -e "\n  ${C}Limpiando archivos temporales...${NC}"
                apt autoremove -y > /dev/null 2>&1
                apt clean > /dev/null 2>&1
                rm -rf /tmp/*.sh /tmp/*.py /tmp/*.txt 2>/dev/null
                journalctl --vacuum-time=3d > /dev/null 2>&1
                echo -e "  ${G}✓ Temporales eliminados${NC}"
                echo -e "  ${G}✓ Cache apt limpiada${NC}"
                echo -e "  ${G}✓ Logs antiguos eliminados${NC}"
                sleep 2 ;;
            3)
                banner; sep
                echo -e "  ${Y}  CONFIGURAR AUTO-REINICIO${NC}"; sep; echo ""
                read -p "  Intervalo en horas (ej: 1, 6, 12, 24): " REBOOT_HOURS
                [ -z "$REBOOT_HOURS" ] && echo -e "  ${R}Cancelado${NC}" && sleep 1 && continue
                # Crear script de limpieza y reinicio
                cat > /usr/local/bin/ltm-reboot.sh << REBOOTEOF
#!/bin/bash
sync
echo 3 > /proc/sys/vm/drop_caches
/sbin/reboot
REBOOTEOF
                chmod +x /usr/local/bin/ltm-reboot.sh
                # Agregar cron
                (crontab -l 2>/dev/null | grep -v "ltm_reboot\|ltm-reboot"; echo "0 */$REBOOT_HOURS * * * /usr/local/bin/ltm-reboot.sh # ltm_reboot") | crontab -
                echo -e "  ${G}OK Auto-reinicio cada ${Y}${REBOOT_HOURS}h${G} configurado${NC}"
                sleep 2 ;;
            4)
                echo ""; echo -e "  ${W}Cron actual:${NC}"; echo ""
                crontab -l 2>/dev/null | grep "ltm_reboot\|ltm-reboot" || echo "  Sin auto-reinicio configurado"
                echo ""; read -p "  ENTER..." ;;
            5)
                (crontab -l 2>/dev/null | grep -v "ltm_reboot\|ltm-reboot") | crontab -
                echo -e "  ${G}Auto-reinicio desactivado${NC}"; sleep 2 ;;
            6)
                read -p "  Confirmar reinicio (si/no): " CONFIRM
                [ "$CONFIRM" = "si" ] && {
                    echo -e "  ${Y}Reiniciando en 3 segundos...${NC}"
                    sleep 3
                    /sbin/reboot; } ;;
            0) break ;;
        esac
    done
}

menu_shadowsocks() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ SHADOWSOCKS${NC}"; sep; echo ""
        SS_ST=$(systemctl is-active shadowsocks-server 2>/dev/null)
        [ "$SS_ST" = "active" ] && echo -e "  ${NEON}◈${NC} ${W}Shadowsocks${NC} ${NEON}◆ ON${NC}" || echo -e "  ${NEON}◈${NC} ${W}Shadowsocks${NC} ${R}◇ OFF${NC}"
        if [ -f /etc/shadowsocks/config.json ]; then
            SS_PORT=$(python3 -c "import json; c=json.load(open('/etc/shadowsocks/config.json')); print(c.get('server_port','8388'))" 2>/dev/null)
            SS_METHOD=$(python3 -c "import json; c=json.load(open('/etc/shadowsocks/config.json')); print(c.get('method','aes-256-gcm'))" 2>/dev/null)
            echo -e "  ${NEON}◈${NC} ${W}Puerto:${NC} ${Y}${SS_PORT}${NC}"
            echo -e "  ${NEON}◈${NC} ${W}Metodo:${NC} ${Y}${SS_METHOD}${NC}"
        fi
        echo ""; sep
        printf " ${Y}❬1❭ Instalar Shadowsocks${NC}\n"
        printf " ${Y}❬2❭ Iniciar    ❬3❭ Detener    ❬4❭ Reiniciar${NC}\n"
        printf " ${Y}❬5❭ Agregar usuario${NC}\n"
        printf " ${Y}❬6❭ Ver usuarios${NC}\n"
        printf " ${Y}❬7❭ Ver config${NC}\n"
        printf " ${R}❬8❭ Desinstalar${NC}\n"
        sep; printf " ${R}❬0❭ Volver${NC}\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando Shadowsocks...${NC}"
                apt install -y shadowsocks-libev > /dev/null 2>&1
                mkdir -p /etc/shadowsocks
                read -p "  Puerto (default 8388): " SS_PORT; SS_PORT=${SS_PORT:-8388}
                read -p "  Password: " SS_PASS; SS_PASS=${SS_PASS:-"ltmssh2026"}
                echo -e "  Metodo: ${Y}❬1❭${NC} aes-256-gcm ${Y}❬2❭${NC} chacha20-ietf-poly1305 ${Y}❬3❭${NC} aes-128-gcm"
                read -p "  Opcion: " SS_METHOD_OPT
                case $SS_METHOD_OPT in
                    1) SS_METHOD="aes-256-gcm" ;;
                    2) SS_METHOD="chacha20-ietf-poly1305" ;;
                    3) SS_METHOD="aes-128-gcm" ;;
                    *) SS_METHOD="aes-256-gcm" ;;
                esac
                cat > /etc/shadowsocks/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": $SS_PORT,
    "password": "$SS_PASS",
    "method": "$SS_METHOD",
    "timeout": 300,
    "mode": "tcp_and_udp",
    "fast_open": true
}
EOF
                cat > /etc/systemd/system/shadowsocks-server.service << EOF2
[Unit]
Description=Shadowsocks Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/ss-server -c /etc/shadowsocks/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF2
                systemctl daemon-reload
                systemctl enable shadowsocks-server
                # Matar proceso anterior si el puerto esta ocupado
                pkill -f ss-server 2>/dev/null; sleep 1
                systemctl start shadowsocks-server
                iptables -I INPUT -p tcp --dport $SS_PORT -j ACCEPT 2>/dev/null
                iptables -I INPUT -p udp --dport $SS_PORT -j ACCEPT 2>/dev/null
                SS_IP=$(hostname -I | awk '{print $1}')
                echo ""
                echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
                echo -e "  ${G}✅ SHADOWSOCKS INSTALADO${NC}"
                echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
                echo -e "  ${NEON}◈${NC} ${W}IP:${NC}       ${Y}$SS_IP${NC}"
                echo -e "  ${NEON}◈${NC} ${W}Puerto:${NC}   ${Y}$SS_PORT${NC}"
                echo -e "  ${NEON}◈${NC} ${W}Password:${NC} ${Y}$SS_PASS${NC}"
                echo -e "  ${NEON}◈${NC} ${W}Metodo:${NC}   ${Y}$SS_METHOD${NC}"
                echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
                read -p "  ENTER..." ;;
            2) systemctl start shadowsocks-server && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop shadowsocks-server && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart shadowsocks-server && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                banner; sep; echo -e "  ${Y}AGREGAR USUARIO${NC}"; sep; echo ""
                echo -e "  ${Y}Shadowsocks basico usa una sola password${NC}"
                echo -e "  ${Y}Para multi-usuario necesitas shadowsocks-manager${NC}"; echo ""
                read -p "  Nueva password: " SS_NEW_PASS
                python3 -c "
import json
with open('/etc/shadowsocks/config.json') as f: c=json.load(f)
c['password'] = '$SS_NEW_PASS'
with open('/etc/shadowsocks/config.json','w') as f: json.dump(c,f,indent=2)
print('OK')
"
                systemctl restart shadowsocks-server
                echo -e "  ${G}Password actualizada: ${Y}$SS_NEW_PASS${NC}"
                read -p "  ENTER..." ;;
            6)
                echo ""; echo -e "  ${W}Configuracion actual:${NC}"; echo ""
                python3 -c "
import json
with open('/etc/shadowsocks/config.json') as f: c=json.load(f)
print(f'  Puerto:   {c.get(\"server_port\")}')
print(f'  Password: {c.get(\"password\")}')
print(f'  Metodo:   {c.get(\"method\")}')
" 2>/dev/null || echo "  No instalado"
                echo ""; read -p "  ENTER..." ;;
            7) cat /etc/shadowsocks/config.json 2>/dev/null || echo "No instalado"; echo ""; read -p "  ENTER..." ;;
            8)
                read -p "  Confirmar (si/no): " CONFIRM
                [ "$CONFIRM" = "si" ] && {
                    systemctl stop shadowsocks-server 2>/dev/null
                    systemctl disable shadowsocks-server 2>/dev/null
                    apt remove -y shadowsocks-libev > /dev/null 2>&1
                    rm -f /etc/systemd/system/shadowsocks-server.service
                    rm -rf /etc/shadowsocks
                    systemctl daemon-reload
                    echo -e "  ${G}Desinstalado${NC}"; sleep 2; } ;;
            0) break ;;
        esac
    done
}

menu_udp_hysteria_mod() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ UDP HYSTERIA MOD${NC}"; sep; echo ""
        HM_ST=$(systemctl is-active hysteria-server 2>/dev/null)
        [ "$HM_ST" = "active" ] && echo -e "  ${NEON}◈${NC} ${W}UDP Hysteria Mod${NC} ${NEON}◆ ON${NC}" || echo -e "  ${NEON}◈${NC} ${W}UDP Hysteria Mod${NC} ${R}◇ OFF${NC}"
        HM_IP=$(hostname -I | awk '{print $1}')
        echo -e "  ${NEON}◈${NC} ${W}IP:${NC}   ${Y}${HM_IP}${NC}"
        HM_OBFS_NOW=$(python3 -c "import json; c=json.load(open('/etc/hysteria/config.json')); print(c.get('obfs','ltmudp'))" 2>/dev/null || echo "ltmudp")
        echo -e "  ${NEON}◈${NC} ${W}Obfs:${NC} ${Y}${HM_OBFS_NOW}${NC}"
        echo ""; sep
        printf " ${Y}❬1❭ Instalar    ❬2❭ Iniciar    ❬3❭ Detener${NC}\n"
        printf " ${Y}❬4❭ Reiniciar   ❬5❭ Agregar usuario${NC}\n"
        printf " ${Y}❬6❭ Ver usuarios    ❬7❭ Cambiar obfs${NC}\n"
        printf " ${R}❬8❭ Desinstalar${NC}\n"
        sep; printf " ${R}❬0❭ Volver${NC}\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando UDP Hysteria Mod...${NC}"
                curl -sL https://raw.githubusercontent.com/JotchuaDevz/JT-UDP-DEV/refs/heads/main/install_udp.sh -o /tmp/ltmudp_install.sh
                sed -i 's/DOMAIN="requestlab-x.space"/DOMAIN="ltm.darkfullhn.xyz"/' /tmp/ltmudp_install.sh
                sed -i 's/OBFS="jt"/OBFS="ltmudp"/' /tmp/ltmudp_install.sh
                sed -i 's/PASSWORD="jt"/PASSWORD="ltmudp"/' /tmp/ltmudp_install.sh
                bash /tmp/ltmudp_install.sh > /tmp/ltmudp_out.txt 2>&1
                grep -v "JT-UDP\|Felicitaciones\|gestor\|udp'\|Ahora puedes\|Script del gestor\|Creando enlace\|Descargando script" /tmp/ltmudp_out.txt | sed 's/JT-UDP/LTMUDPv1/g'
                echo -e "  ${G}OK Instalado${NC}"
                read -p "  ENTER..." ;;
            2) systemctl start hysteria-server && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop hysteria-server && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart hysteria-server && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                banner; sep; echo -e "  ${Y}AGREGAR USUARIO${NC}"; sep; echo ""
                read -p "  Usuario: " HM_USER
                read -p "  Password: " HM_PASS
                read -p "  Dias (default 30): " HM_DAYS; HM_DAYS=${HM_DAYS:-30}
                HM_EXP=$(date -d "+${HM_DAYS} days" +%d/%m/%Y)
                python3 -c "
import json
with open('/etc/hysteria/config.json') as f: c=json.load(f)
users = c.get('auth',{}).get('config',[])
entry = '$HM_USER:$HM_PASS'
if entry not in users: users.append(entry)
c['auth']['config'] = users
with open('/etc/hysteria/config.json','w') as f: json.dump(c,f,indent=2)
print('OK')
"
                systemctl restart hysteria-server
                HM_IP=$(hostname -I | awk '{print $1}')
                echo ""
                echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
                echo -e "  ${G}✅ USUARIO CREADO${NC}"
                echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
                echo -e "  ${NEON}◈${NC} ${W}Usuario:${NC}  ${Y}$HM_USER${NC}"
                echo -e "  ${NEON}◈${NC} ${W}Password:${NC} ${Y}$HM_PASS${NC}"
                echo -e "  ${NEON}◈${NC} ${W}IP:${NC}       ${Y}$HM_IP${NC}"
                echo -e "  ${NEON}◈${NC} ${W}Puerto:${NC}   ${Y}36712${NC}"
                HM_OBFS_NOW=$(python3 -c "import json; c=json.load(open('/etc/hysteria/config.json')); print(c.get('obfs','ltmudp'))" 2>/dev/null || echo "ltmudp")
                echo -e "  ${NEON}◈${NC} ${W}Obfs:${NC}     ${Y}${HM_OBFS_NOW}${NC}"
                echo -e "  ${NEON}◈${NC} ${W}Expira:${NC}   ${Y}$HM_EXP${NC}"
                echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
                read -p "  ENTER..." ;;
            6)
                echo ""; echo -e "  ${W}Usuarios:${NC}"; echo ""
                echo -e "  ${NEON}◈${NC} ${DIM}Usuario : Password${NC}"; echo ""
                python3 -c "
import json
with open('/etc/hysteria/config.json') as f: c=json.load(f)
users = c.get('auth',{}).get('config',[])
for u in users: print('  ' + u)
" 2>/dev/null || echo "  No instalado"
                echo ""; read -p "  ENTER..." ;;
            7)
                banner; sep; echo -e "  ${Y}CAMBIAR OBFS${NC}"; sep; echo ""
                CURRENT_OBFS=$(grep -o '"obfs":"[^"]*"' /etc/hysteria/config.json 2>/dev/null | cut -d'"' -f4 || echo "ltmudp")
                echo -e "  ${NEON}◈${NC} ${W}Obfs actual:${NC} ${Y}$CURRENT_OBFS${NC}"; echo ""
                read -p "  Nuevo obfs: " NEW_OBFS
                [ -z "$NEW_OBFS" ] && echo -e "  ${R}Cancelado${NC}" && sleep 1 && continue
                python3 -c "
import json
with open('/etc/hysteria/config.json') as f: c=json.load(f)
c['obfs'] = '$NEW_OBFS'
with open('/etc/hysteria/config.json','w') as f: json.dump(c,f,indent=2)
print('OK')
" 2>/dev/null
                systemctl restart hysteria-server
                echo -e "  ${G}Obfs cambiado a: ${Y}$NEW_OBFS${NC}"; sleep 2 ;;
            8)
                read -p "  Confirmar (si/no): " CONFIRM
                [ "$CONFIRM" = "si" ] && {
                    systemctl stop hysteria-server 2>/dev/null
                    systemctl disable hysteria-server 2>/dev/null
                    rm -f /etc/systemd/system/hysteria-server.service
                    rm -f /usr/local/bin/hysteria
                    rm -rf /etc/hysteria
                    systemctl daemon-reload
                    echo -e "  ${G}Desinstalado${NC}"; sleep 2; } ;;
            0) break ;;
        esac
    done
}



menu_hysteria() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ HYSTERIA UDP${NC}"; sep; echo ""
        H1_ST=$(systemctl is-active hysteria-server 2>/dev/null)
        H2_ST=$(systemctl is-active hysteria2-server 2>/dev/null)
        [ "$H1_ST" = "active" ] && echo -e "  ${NEON}◈${NC} ${W}Hysteria V1${NC} ${NEON}◆ ON${NC}" || echo -e "  ${NEON}◈${NC} ${W}Hysteria V1${NC} ${R}◇ OFF${NC}"
        [ "$H2_ST" = "active" ] && echo -e "  ${NEON}◈${NC} ${W}Hysteria V2${NC} ${NEON}◆ ON${NC}" || echo -e "  ${NEON}◈${NC} ${W}Hysteria V2${NC} ${R}◇ OFF${NC}"
        echo ""; sep
        printf " ${Y}❬1❭ Instalar Hysteria V1    ❬2❭ Instalar Hysteria V2${NC}\n"
        printf " ${Y}❬3❭ Iniciar V1              ❬4❭ Iniciar V2${NC}\n"
        printf " ${Y}❬5❭ Detener V1              ❬6❭ Detener V2${NC}\n"
        printf " ${Y}❬7❭ Ver config V1           ❬8❭ Ver config V2${NC}\n"
        printf " ${R}❬9❭ Desinstalar V1          ❬10❭ Desinstalar V2${NC}\n"
        sep
        printf " ${R}❬0❭ Volver${NC}\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando Hysteria V1...${NC}"
                apt install -y wget > /dev/null 2>&1
                wget -q -O /usr/local/bin/hysteria-v1 https://github.com/HyNetwork/hysteria/releases/download/v1.3.5/hysteria-linux-amd64
                chmod +x /usr/local/bin/hysteria-v1
                read -p "  Puerto UDP (default 36712): " H1_PORT; H1_PORT=${H1_PORT:-36712}
                read -p "  Password: " H1_PASS; H1_PASS=${H1_PASS:-"ltmssh2026"}
                read -p "  Dominio (para TLS, deja vacio para self-signed): " H1_DOMAIN
                mkdir -p /etc/hysteria
                if [ -n "$H1_DOMAIN" ]; then
                    apt install -y certbot > /dev/null 2>&1
                    certbot certonly --standalone -d $H1_DOMAIN --non-interactive --agree-tos -m admin@${H1_DOMAIN#*.} 2>/dev/null
                    CERT_FILE="/etc/letsencrypt/live/$H1_DOMAIN/fullchain.pem"
                    KEY_FILE="/etc/letsencrypt/live/$H1_DOMAIN/privkey.pem"
                else
                    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
                        -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt \
                        -subj "/CN=hysteria" -days 36500 2>/dev/null
                    CERT_FILE="/etc/hysteria/server.crt"
                    KEY_FILE="/etc/hysteria/server.key"
                fi
                cat > /etc/hysteria/config.json << EOF
{
  "listen": ":$H1_PORT",
  "cert": "$CERT_FILE",
  "key": "$KEY_FILE",
  "auth": {
    "mode": "password",
    "config": {"password": "$H1_PASS"}
  },
  "obfs": "ltmssh",
  "up_mbps": 100,
  "down_mbps": 100
}
EOF
                cat > /etc/systemd/system/hysteria-server.service << EOF
[Unit]
Description=Hysteria V1 Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria-v1 server --config /etc/hysteria/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable hysteria-server
                systemctl start hysteria-server
                iptables -I INPUT -p udp --dport $H1_PORT -j ACCEPT 2>/dev/null
                echo -e "  ${G}OK Hysteria V1 instalado${NC}"
                echo -e "  ${NEON}◈${NC} Puerto: ${Y}$H1_PORT${NC}"
                echo -e "  ${NEON}◈${NC} Password: ${Y}$H1_PASS${NC}"
                echo -e "  ${NEON}◈${NC} Obfs: ${Y}ltmssh${NC}"
                read -p "  ENTER..." ;;
            2)
                echo -e "\n  ${C}Instalando Hysteria V2...${NC}"
                apt install -y wget > /dev/null 2>&1
                wget -q -O /usr/local/bin/hysteria2 https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64
                # hysteria2 es el mismo binario de apernet pero con nombre diferente
                chmod +x /usr/local/bin/hysteria2
                read -p "  Puerto UDP (default 8443): " H2_PORT; H2_PORT=${H2_PORT:-8443}
                read -p "  Password: " H2_PASS; H2_PASS=${H2_PASS:-"ltmssh2026"}
                read -p "  Dominio (deja vacio para self-signed): " H2_DOMAIN
                mkdir -p /etc/hysteria2
                if [ -n "$H2_DOMAIN" ]; then
                    apt install -y certbot > /dev/null 2>&1
                    certbot certonly --standalone -d $H2_DOMAIN --non-interactive --agree-tos -m admin@${H2_DOMAIN#*.} 2>/dev/null
                    CERT2_FILE="/etc/letsencrypt/live/$H2_DOMAIN/fullchain.pem"
                    KEY2_FILE="/etc/letsencrypt/live/$H2_DOMAIN/privkey.pem"
                else
                    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
                        -keyout /etc/hysteria2/server.key -out /etc/hysteria2/server.crt \
                        -subj "/CN=hysteria2" -days 36500 2>/dev/null
                    CERT2_FILE="/etc/hysteria2/server.crt"
                    KEY2_FILE="/etc/hysteria2/server.key"
                fi
                cat > /etc/hysteria2/config.yaml << EOF
listen: :$H2_PORT
tls:
  cert: $CERT2_FILE
  key: $KEY2_FILE
auth:
  type: password
  password: $H2_PASS
masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com/
    rewriteHost: true
EOF
                cat > /etc/systemd/system/hysteria2-server.service << EOF
[Unit]
Description=Hysteria V2 Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria2 server --config /etc/hysteria2/config.yaml
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable hysteria2-server
                systemctl start hysteria2-server
                iptables -I INPUT -p udp --dport $H2_PORT -j ACCEPT 2>/dev/null
                echo -e "  ${G}OK Hysteria V2 instalado${NC}"
                echo -e "  ${NEON}◈${NC} Puerto: ${Y}$H2_PORT${NC}"
                echo -e "  ${NEON}◈${NC} Password: ${Y}$H2_PASS${NC}"
                read -p "  ENTER..." ;;
            3) systemctl start hysteria-server && echo -e "  ${G}Hysteria V1 iniciado${NC}"; sleep 1 ;;
            4) systemctl start hysteria2-server && echo -e "  ${G}Hysteria V2 iniciado${NC}"; sleep 1 ;;
            5) systemctl stop hysteria-server && echo -e "  ${Y}Hysteria V1 detenido${NC}"; sleep 1 ;;
            6) systemctl stop hysteria2-server && echo -e "  ${Y}Hysteria V2 detenido${NC}"; sleep 1 ;;
            7) cat /etc/hysteria/config.json 2>/dev/null || echo "No instalado"; echo ""; read -p "  ENTER..." ;;
            8) cat /etc/hysteria2/config.yaml 2>/dev/null || echo "No instalado"; echo ""; read -p "  ENTER..." ;;
            9)
                systemctl stop hysteria-server; systemctl disable hysteria-server
                rm -f /usr/local/bin/hysteria /etc/systemd/system/hysteria-server.service
                rm -rf /etc/hysteria; systemctl daemon-reload
                echo -e "  ${G}Hysteria V1 desinstalado${NC}"; sleep 2 ;;
            10)
                systemctl stop hysteria2-server; systemctl disable hysteria2-server
                rm -f /usr/local/bin/hysteria2 /etc/systemd/system/hysteria2-server.service
                rm -rf /etc/hysteria2; systemctl daemon-reload
                echo -e "  ${G}Hysteria V2 desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_herramientas() {
    while true; do
        banner; sep
        echo -e "  ${Y}  HERRAMIENTAS Y PROTOCOLOS${NC}"; sep; echo ""
        printf " ${NEON}◈${NC} ${W}WebSocket${NC}  %-12b ${NEON}◈${NC} ${W}BadVPN 7200${NC} %b\n" "$(status_port 80)" "$(status_service badvpn-7200)"
        printf " ${NEON}◈${NC} ${W}UDP Custom${NC} %-11b ${NEON}◈${NC} ${W}BadVPN 7300${NC} %b\n" "$(ps aux | grep -i UDP-Custom | grep -v grep | grep -q . && echo -e "${NEON}◆ ON${NC}" || echo -e "${R}◇ OFF${NC}")" "$(status_service badvpn-7300)"
        printf " ${NEON}◈${NC} ${W}SSL/TLS${NC}    %-12b ${NEON}◈${NC} ${W}V2Ray${NC}       %b\n" "$(status_service stunnel4)" "$(status_service v2ray)"
        printf " ${NEON}◈${NC} ${W}ZIV VPN${NC}   %-12b ${NEON}◈${NC} ${W}SlowDNS${NC}     %b\n" "$(status_service zivpn)" "$(status_service server-sldns)"
        printf " ${NEON}◈${NC} ${W}Dropbear${NC}  %-12b ${NEON}◈${NC} ${W}LTMUDPv1${NC}    %b\n" "$(status_service dropbear)" "$(status_service hysteria-server)"
        echo ""; sep
        printf " \033[1;97m[1] %-22s [2] %s\033[0m\n" "WebSocket Python" "BadVPN UDP"
        printf " \033[1;97m[3] %-22s [4] %s\033[0m\n" "UDP Custom" "SSL/TLS Stunnel"
        printf " \033[1;97m[5] %-22s [6] %s\033[0m\n" "V2Ray VMess" "ZIV VPN"
        printf " \033[1;97m[7] %-22s [8] %s\033[0m\n" "Banner SSH" "Mejorar Velocidad UDP"
        printf " \033[1;97m[9] %-22s [10] %s\033[0m\n" "Anti-DDoS" "SlowDNS"
        printf " \033[1;97m[11] %-21s [12] %s\033[0m\n" "Dropbear SSH" "UDP Hysteria Mod"
        printf " \033[1;97m[13] %-21s [14] %s\033[0m\n" "Shadowsocks" "Limpieza/Auto-reinicio"
        sep
        printf " ${W}[0]${NC} Volver\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1) menu_ws ;;
            2) menu_badvpn ;;
            3) menu_udp ;;
            4) menu_ssl ;;
            5) menu_v2ray ;;
            6) menu_ziv ;;
            7) menu_banner_ssh ;;
            8) menu_speed_udp ;;
            9) menu_antiddos ;;
            10) menu_slowdns ;;
            11) menu_dropbear ;;

            12) menu_udp_hysteria_mod ;;
            13) menu_shadowsocks ;;
            14) menu_limpieza ;;
            9) menu_antiddos ;;
            10) menu_slowdns ;;
            11) menu_dropbear ;;

            12) menu_udp_hysteria_mod ;;
            13) menu_shadowsocks ;;
            14) menu_limpieza ;;
            0) break ;;
            *) echo -e "  ${R}Opcion invalida${NC}"; sleep 1 ;;
        esac
    done
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh?$(date +%s)"
    chmod +x /usr/local/bin/menu
    mkdir -p /etc/sshfreeltm
    touch /etc/sshfreeltm/.licensed
    echo -e "  ${G}OK Script actualizado a v$(grep SCRIPT_VERSION /usr/local/bin/menu | head -1 | grep -o '[0-9.]*')${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh?$(date +%s)"
    chmod +x /usr/local/bin/menu
    mkdir -p /etc/sshfreeltm
    touch /etc/sshfreeltm/.licensed
    echo -e "  ${G}OK Script actualizado a v$(grep SCRIPT_VERSION /usr/local/bin/menu | head -1 | grep -o '[0-9.]*')${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_atacantes() {
    banner; sep
    echo -e "  ${NEON}◆ IPs ATACANTES${NC}"; sep; echo ""
    
    # Ver IPs bloqueadas por fail2ban
    if command -v fail2ban-client > /dev/null 2>&1; then
        BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | cut -d: -f2 | tr ' ' '\n' | grep -v '^$')
        if [ -n "$BANNED" ]; then
            echo -e "  ${R}🚨 IPs bloqueadas por Fail2ban:${NC}"
            echo "$BANNED" | while read ip; do
                [ -n "$ip" ] && echo -e "  ${NEON}◈${NC} ${R}$ip${NC}"
            done
        else
            echo -e "  ${G}✅ Sin IPs bloqueadas en Fail2ban${NC}"
        fi
    fi
    
    echo ""
    
    # Ver conexiones sospechosas activas
    echo -e "  ${Y}🔍 Conexiones activas por IP:${NC}"
    CONNS=$(ss -tn state established | awk 'NR>1{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10)
    if [ -n "$CONNS" ]; then
        echo "$CONNS" | while read count ip; do
            [ -z "$ip" ] && continue
            if [ "$count" -gt 10 ]; then
                echo -e "  ${R}◈ $ip — $count conexiones ⚠️${NC}"
            else
                echo -e "  ${NEON}◈${NC} $ip — ${Y}$count${NC} conexiones"
            fi
        done
    else
        echo -e "  ${G}✅ Sin conexiones sospechosas${NC}"
    fi
    
    echo ""
    
    # Ver logs de iptables DROP recientes
    echo -e "  ${Y}🛡️ Paquetes bloqueados recientes:${NC}"
    DROPS=$(dmesg 2>/dev/null | grep "IN=.*OUT=" | tail -5 | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn)
    if [ -n "$DROPS" ]; then
        echo "$DROPS" | while read count ip; do
            echo -e "  ${NEON}◈${NC} ${R}$ip${NC} — $count paquetes bloqueados"
        done
    else
        echo -e "  ${G}✅ Sin ataques detectados${NC}"
    fi
    
    echo ""; sep
    read -p "  ENTER..."
}

menu_antiddos() {
    while true; do
        banner; sep
        echo -e "  ${Y}  ANTI-DDOS${NC}"; sep; echo ""
        DDOS_ACTIVE=$(iptables -L INPUT -n 2>/dev/null | grep -q "limit" && echo 1 || echo 0)
        if [ "$DDOS_ACTIVE" = "1" ]; then
            echo -e "  Estado: ${G}[ACTIVO]${NC}"
        else
            echo -e "  Estado: ${R}[INACTIVO]${NC}"
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Activar Anti-DDoS Agresivo"
        echo -e "  ${W}[2]${NC} Desactivar Anti-DDoS"
        echo -e "  ${W}[3]${NC} Ver reglas activas"
        echo -e "  ${W}[4]${NC} Ver IPs atacantes"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}[1/5] Instalando dependencias...${NC}"
                DEBIAN_FRONTEND=noninteractive apt install -y -qq iptables-persistent fail2ban 2>&1 | \
                    grep -E "^(Get|Setting|Processing|Unpacking)" | while read line; do echo "    $line"; done
                echo -e "  ${G}  ✓ Dependencias listas${NC}"

                echo -e "  ${C}[2/5] Limpiando reglas previas...${NC}"
                iptables -F; iptables -X; iptables -Z
                echo -e "  ${G}  ✓ Reglas limpiadas${NC}"

                echo -e "  ${C}[3/5] Aplicando politicas base...${NC}"
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                echo -e "  ${G}  ✓ Politicas base aplicadas${NC}"

                echo -e "  ${C}[4/5] Abriendo puertos activos...${NC}"
                for PORT in $(ss -tlnp | awk '/LISTEN/{print $4}' | grep -oE '[0-9]+$' | sort -u); do
                    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
                    echo -e "  ${DIM}    TCP $PORT abierto${NC}"
                done
                for PORT in $(ss -ulnp | awk '/UNCONN/{print $4}' | grep -oE '[0-9]+$' | sort -u); do
                    iptables -A INPUT -p udp --dport $PORT -j ACCEPT
                    echo -e "  ${DIM}    UDP $PORT abierto${NC}"
                done
                echo -e "  ${G}  ✓ Puertos configurados${NC}"

                echo -e "  ${C}[5/5] Aplicando reglas anti-ataque...${NC}"
                iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP
                echo -e "  ${G}  ✓ SYN Flood bloqueado${NC}"
                iptables -A INPUT -p udp -m limit --limit 50/s --limit-burst 100 -j ACCEPT
                iptables -A INPUT -p udp -j DROP
                echo -e "  ${G}  ✓ UDP Flood bloqueado${NC}"
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 2/s --limit-burst 4 -j ACCEPT
                iptables -A INPUT -p icmp -j DROP
                echo -e "  ${G}  ✓ ICMP Flood bloqueado${NC}"
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
                echo -e "  ${G}  ✓ Port scanning bloqueado${NC}"
                iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 5 -j REJECT
                iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 -j REJECT
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP
                iptables -A INPUT -s 10.0.0.0/8 ! -i lo -j DROP
                iptables -A INPUT -s 172.16.0.0/12 ! -i lo -j DROP
                iptables -A INPUT -s 192.168.0.0/16 ! -i lo -j DROP
                echo -e "  ${G}  ✓ Brute Force y spoofing bloqueados${NC}"

                echo -e "  ${C}  Guardando reglas...${NC}"
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules
                echo -e "  ${G}  ✓ Reglas guardadas${NC}"

                echo -e "  ${C}  Configurando Fail2ban...${NC}"
                mkdir -p /etc/fail2ban
                cat > /etc/fail2ban/jail.local << EOF_JAIL
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 86400

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF_JAIL
                echo -e "  ${G}  ✓ Fail2ban configurado${NC}"

                systemctl enable fail2ban -q 2>/dev/null
                systemctl restart fail2ban 2>/dev/null
                echo -ne "  ${C}  Iniciando Fail2ban${NC}"
                for i in 1 2 3 4 5; do sleep 0.5; echo -ne "."; done; echo ""
                systemctl is-active --quiet fail2ban && \
                    echo -e "  ${G}  ✓ Fail2ban activo${NC}" || \
                    echo -e "  ${Y}  ⚠ Verifica: systemctl status fail2ban${NC}"

                BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | cut -d: -f2 | xargs)
                if [ -n "$BANNED_IPS" ]; then
                    curl -s -X POST "https://api.telegram.org/bot7998209606:AAGNwiDAH5cOhWftedzZosjq7GLElvJRtws/sendMessage" \
                        -d "chat_id=6290827127&text=Anti-DDoS+Activado+-+IPs:+${BANNED_IPS}&parse_mode=Markdown" > /dev/null 2>&1
                fi

                echo ""; sep
                echo -e "  ${G}OK Anti-DDoS agresivo activado${NC}"; sep
                read -p "  ENTER..." ;;
            2)
                iptables -F; iptables -X
                iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT
                systemctl stop fail2ban 2>/dev/null
                echo -e "  ${Y}Anti-DDoS desactivado${NC}"; sleep 2 ;;
            3)
                echo ""; iptables -L INPUT -n --line-numbers | head -30; echo ""
                read -p "  ENTER..." ;;
            4) menu_atacantes ;;
            0) break ;;
        esac
    done
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh?$(date +%s)"
    chmod +x /usr/local/bin/menu
    mkdir -p /etc/sshfreeltm
    touch /etc/sshfreeltm/.licensed
    echo -e "  ${G}OK Script actualizado a v$(grep SCRIPT_VERSION /usr/local/bin/menu | head -1 | grep -o '[0-9.]*')${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_atacantes() {
    banner; sep
    echo -e "  ${NEON}◆ IPs ATACANTES${NC}"; sep; echo ""
    
    # Ver IPs bloqueadas por fail2ban
    if command -v fail2ban-client > /dev/null 2>&1; then
        BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | cut -d: -f2 | tr ' ' '\n' | grep -v '^$')
        if [ -n "$BANNED" ]; then
            echo -e "  ${R}🚨 IPs bloqueadas por Fail2ban:${NC}"
            echo "$BANNED" | while read ip; do
                [ -n "$ip" ] && echo -e "  ${NEON}◈${NC} ${R}$ip${NC}"
            done
        else
            echo -e "  ${G}✅ Sin IPs bloqueadas en Fail2ban${NC}"
        fi
    fi
    
    echo ""
    
    # Ver conexiones sospechosas activas
    echo -e "  ${Y}🔍 Conexiones activas por IP:${NC}"
    CONNS=$(ss -tn state established | awk 'NR>1{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10)
    if [ -n "$CONNS" ]; then
        echo "$CONNS" | while read count ip; do
            [ -z "$ip" ] && continue
            if [ "$count" -gt 10 ]; then
                echo -e "  ${R}◈ $ip — $count conexiones ⚠️${NC}"
            else
                echo -e "  ${NEON}◈${NC} $ip — ${Y}$count${NC} conexiones"
            fi
        done
    else
        echo -e "  ${G}✅ Sin conexiones sospechosas${NC}"
    fi
    
    echo ""
    
    # Ver logs de iptables DROP recientes
    echo -e "  ${Y}🛡️ Paquetes bloqueados recientes:${NC}"
    DROPS=$(dmesg 2>/dev/null | grep "IN=.*OUT=" | tail -5 | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn)
    if [ -n "$DROPS" ]; then
        echo "$DROPS" | while read count ip; do
            echo -e "  ${NEON}◈${NC} ${R}$ip${NC} — $count paquetes bloqueados"
        done
    else
        echo -e "  ${G}✅ Sin ataques detectados${NC}"
    fi
    
    echo ""; sep
    read -p "  ENTER..."
}

menu_antiddos() {
    while true; do
        banner; sep
        echo -e "  ${Y}  ANTI-DDOS${NC}"; sep; echo ""
        DDOS_ACTIVE=$(iptables -L INPUT -n 2>/dev/null | grep -q "limit" && echo 1 || echo 0)
        if [ "$DDOS_ACTIVE" = "1" ]; then
            echo -e "  Estado: ${G}[ACTIVO]${NC}"
        else
            echo -e "  Estado: ${R}[INACTIVO]${NC}"
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Activar Anti-DDoS Agresivo"
        echo -e "  ${W}[2]${NC} Desactivar Anti-DDoS"
        echo -e "  ${W}[3]${NC} Ver reglas activas"
        echo -e "  ${W}[4]${NC} Ver IPs atacantes"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}[1/5] Instalando dependencias...${NC}"
                DEBIAN_FRONTEND=noninteractive apt install -y -qq iptables-persistent fail2ban 2>&1 | \
                    grep -E "^(Get|Setting|Processing|Unpacking)" | while read line; do echo "    $line"; done
                echo -e "  ${G}  ✓ Dependencias listas${NC}"

                echo -e "  ${C}[2/5] Limpiando reglas previas...${NC}"
                iptables -F; iptables -X; iptables -Z
                echo -e "  ${G}  ✓ Reglas limpiadas${NC}"

                echo -e "  ${C}[3/5] Aplicando politicas base...${NC}"
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                echo -e "  ${G}  ✓ Politicas base aplicadas${NC}"

                echo -e "  ${C}[4/5] Abriendo puertos activos...${NC}"
                for PORT in $(ss -tlnp | awk '/LISTEN/{print $4}' | grep -oE '[0-9]+$' | sort -u); do
                    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
                    echo -e "  ${DIM}    TCP $PORT abierto${NC}"
                done
                for PORT in $(ss -ulnp | awk '/UNCONN/{print $4}' | grep -oE '[0-9]+$' | sort -u); do
                    iptables -A INPUT -p udp --dport $PORT -j ACCEPT
                    echo -e "  ${DIM}    UDP $PORT abierto${NC}"
                done
                echo -e "  ${G}  ✓ Puertos configurados${NC}"

                echo -e "  ${C}[5/5] Aplicando reglas anti-ataque...${NC}"
                iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP
                echo -e "  ${G}  ✓ SYN Flood bloqueado${NC}"
                iptables -A INPUT -p udp -m limit --limit 50/s --limit-burst 100 -j ACCEPT
                iptables -A INPUT -p udp -j DROP
                echo -e "  ${G}  ✓ UDP Flood bloqueado${NC}"
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 2/s --limit-burst 4 -j ACCEPT
                iptables -A INPUT -p icmp -j DROP
                echo -e "  ${G}  ✓ ICMP Flood bloqueado${NC}"
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
                echo -e "  ${G}  ✓ Port scanning bloqueado${NC}"
                iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 5 -j REJECT
                iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 -j REJECT
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP
                iptables -A INPUT -s 10.0.0.0/8 ! -i lo -j DROP
                iptables -A INPUT -s 172.16.0.0/12 ! -i lo -j DROP
                iptables -A INPUT -s 192.168.0.0/16 ! -i lo -j DROP
                echo -e "  ${G}  ✓ Brute Force y spoofing bloqueados${NC}"

                echo -e "  ${C}  Guardando reglas...${NC}"
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules
                echo -e "  ${G}  ✓ Reglas guardadas${NC}"

                echo -e "  ${C}  Configurando Fail2ban...${NC}"
                mkdir -p /etc/fail2ban
                cat > /etc/fail2ban/jail.local << EOF_JAIL
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 86400

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF_JAIL
                echo -e "  ${G}  ✓ Fail2ban configurado${NC}"

                systemctl enable fail2ban -q 2>/dev/null
                systemctl restart fail2ban 2>/dev/null
                echo -ne "  ${C}  Iniciando Fail2ban${NC}"
                for i in 1 2 3 4 5; do sleep 0.5; echo -ne "."; done; echo ""
                systemctl is-active --quiet fail2ban && \
                    echo -e "  ${G}  ✓ Fail2ban activo${NC}" || \
                    echo -e "  ${Y}  ⚠ Verifica: systemctl status fail2ban${NC}"

                BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | cut -d: -f2 | xargs)
                if [ -n "$BANNED_IPS" ]; then
                    curl -s -X POST "https://api.telegram.org/bot7998209606:AAGNwiDAH5cOhWftedzZosjq7GLElvJRtws/sendMessage" \
                        -d "chat_id=6290827127&text=Anti-DDoS+Activado+-+IPs:+${BANNED_IPS}&parse_mode=Markdown" > /dev/null 2>&1
                fi

                echo ""; sep
                echo -e "  ${G}OK Anti-DDoS agresivo activado${NC}"; sep
                read -p "  ENTER..." ;;
            2)
                iptables -F; iptables -X
                iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT
                systemctl stop fail2ban 2>/dev/null
                echo -e "  ${Y}Anti-DDoS desactivado${NC}"; sleep 2 ;;
            3)
                echo ""; iptables -L INPUT -n --line-numbers | head -30; echo ""
                read -p "  ENTER..." ;;
            4) menu_atacantes ;;
            0) break ;;
        esac
    done
}

menu_speed_udp() {
    banner; sep
    echo -e "  ${Y}  MEJORAR VELOCIDAD UDP${NC}"; sep; echo ""
    echo -e "  ${C}Aplicando optimizaciones...${NC}"
    echo ""

    # BBR
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf 2>/dev/null
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

    # Buffers UDP
    echo "net.core.rmem_max=134217728" >> /etc/sysctl.conf
    echo "net.core.wmem_max=134217728" >> /etc/sysctl.conf
    echo "net.core.rmem_default=25165824" >> /etc/sysctl.conf
    echo "net.core.wmem_default=25165824" >> /etc/sysctl.conf
    echo "net.core.netdev_max_backlog=65536" >> /etc/sysctl.conf
    echo "net.ipv4.udp_rmem_min=8192" >> /etc/sysctl.conf
    echo "net.ipv4.udp_wmem_min=8192" >> /etc/sysctl.conf

    # Aplicar cambios
    sysctl -p > /dev/null 2>&1

    # Verificar BBR
    BBR=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -o bbr)
    if [ "$BBR" = "bbr" ]; then
        echo -e "  ${G}✓ BBR activado${NC}"
    else
        echo -e "  ${Y}✓ Buffers optimizados (BBR no disponible en este kernel)${NC}"
    fi
    echo -e "  ${G}✓ Buffers UDP maximizados${NC}"
    echo -e "  ${G}✓ Network backlog optimizado${NC}"
    echo ""
    sep
    echo -e "  ${G}OK Optimizacion aplicada${NC}"
    read -p "  ENTER..."
}

menu_slowdns() {
    SLOWDNS_DIR="/etc/slowdns"
    SERVER_SERVICE="server-sldns"
    CLIENT_SERVICE="client-sldns"
    PUBKEY_FILE="$SLOWDNS_DIR/server.pub"
    while true; do
        banner; sep
        echo -e "  ${Y}  SLOWDNS${NC}"; sep; echo ""
        SDNS_ST=$(systemctl is-active $SERVER_SERVICE 2>/dev/null)
        [ "$SDNS_ST" = "active" ] && echo -e "  Estado: ${G}[ACTIVO]${NC}" || echo -e "  Estado: ${R}[INACTIVO]${NC}"
        [ -f "$PUBKEY_FILE" ] && echo -e "  PubKey: ${W}$(cat $PUBKEY_FILE)${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar SlowDNS"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Ver Public Key"
        echo -e "  ${W}[5]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Instalando dependencias...${NC}"
                apt install -y git screen iptables net-tools curl wget dos2unix gnutls-bin netfilter-persistent
                mkdir -p $SLOWDNS_DIR
                chmod 700 $SLOWDNS_DIR
                read -p "  Dominio NS: " SDNS_DOMAIN
                read -p "  Puerto SSH local (default 22): " SDNS_PORT
                SDNS_PORT=${SDNS_PORT:-22}
                echo -e "  ${C}Descargando binarios...${NC}"
                wget -q -O $SLOWDNS_DIR/sldns-server "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-server"
                wget -q -O $SLOWDNS_DIR/sldns-client "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-client"
                wget -q -O $SLOWDNS_DIR/server.key "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.key"
                wget -q -O $SLOWDNS_DIR/server.pub "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.pub"
                chmod +x $SLOWDNS_DIR/*
                iptables -I INPUT -p udp --dport 5300 -j ACCEPT
                iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
                netfilter-persistent save 2>/dev/null
                cat > /etc/systemd/system/$CLIENT_SERVICE.service << EOF
[Unit]
Description=Client SlowDNS
After=network.target
[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/sldns-client -udp 8.8.8.8:53 --pubkey-file $PUBKEY_FILE $SDNS_DOMAIN 127.0.0.1:$SDNS_PORT
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
                cat > /etc/systemd/system/$SERVER_SERVICE.service << EOF
[Unit]
Description=Server SlowDNS
After=network.target
[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/sldns-server -udp :5300 -privkey-file $SLOWDNS_DIR/server.key $SDNS_DOMAIN 127.0.0.1:$SDNS_PORT
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable $CLIENT_SERVICE $SERVER_SERVICE
                systemctl start $CLIENT_SERVICE $SERVER_SERVICE
                echo -e "  ${G}OK SlowDNS instalado${NC}"
                echo -e "  PubKey: $(cat $PUBKEY_FILE 2>/dev/null)"
                read -p "  ENTER..." ;;
            2) systemctl start $CLIENT_SERVICE $SERVER_SERVICE && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop $CLIENT_SERVICE $SERVER_SERVICE && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) cat $PUBKEY_FILE 2>/dev/null || echo -e "  ${R}No encontrada${NC}"; echo ""; read -p "  ENTER..." ;;
            5)
                systemctl stop $CLIENT_SERVICE $SERVER_SERVICE 2>/dev/null
                systemctl disable $CLIENT_SERVICE $SERVER_SERVICE 2>/dev/null
                rm -rf $SLOWDNS_DIR
                rm -f /etc/systemd/system/$CLIENT_SERVICE.service /etc/systemd/system/$SERVER_SERVICE.service
                systemctl daemon-reload
                echo -e "  ${G}SlowDNS desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_dropbear() {
    while true; do
        banner; sep
        echo -e "  ${Y}  DROPBEAR SSH${NC}"; sep; echo ""
        DB_ST=$(systemctl is-active dropbear 2>/dev/null)
        [ "$DB_ST" = "active" ] && echo -e "  Estado: ${G}[ACTIVO]${NC}" || echo -e "  Estado: ${R}[INACTIVO]${NC}"
        DB_PORT=$(cat /etc/sshfreeltm/dropbear_port 2>/dev/null || echo "444")
        echo -e "  Puerto: ${W}${DB_PORT}${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar Dropbear"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Cambiar puerto"
        echo -e "  ${W}[6]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Instalando Dropbear...${NC}"
                apt install -y dropbear
                read -p "  Puerto Dropbear (default 444): " DB_PORT
                DB_PORT=${DB_PORT:-444}
                mkdir -p /etc/sshfreeltm
                echo "$DB_PORT" > /etc/sshfreeltm/dropbear_port
                # Configurar
                sed -i "s/NO_START=1/NO_START=0/" /etc/default/dropbear 2>/dev/null
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$DB_PORT/" /etc/default/dropbear 2>/dev/null
                grep -q "DROPBEAR_PORT" /etc/default/dropbear || echo "DROPBEAR_PORT=$DB_PORT" >> /etc/default/dropbear
                # Crear servicio
                cat > /etc/systemd/system/dropbear.service << EOF
[Unit]
Description=Dropbear SSH Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/sbin/dropbear -F -p $DB_PORT
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                # Generar llaves Dropbear
                mkdir -p /etc/dropbear
                [ ! -f /etc/dropbear/dropbear_dss_host_key ] && dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_rsa_host_key ] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key > /dev/null 2>&1
                # Agregar /bin/false a shells permitidos
                grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
                systemctl enable dropbear
                systemctl start dropbear
                iptables -I INPUT -p tcp --dport $DB_PORT -j ACCEPT 2>/dev/null
                echo -e "  ${G}OK Dropbear instalado en puerto ${DB_PORT}${NC}"; sleep 2 ;;
            2) systemctl start dropbear && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop dropbear && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart dropbear && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Nuevo puerto: " NEW_PORT
                echo "$NEW_PORT" > /etc/sshfreeltm/dropbear_port
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$NEW_PORT/" /etc/default/dropbear 2>/dev/null
                sed -i "s/-p [0-9]*/-p $NEW_PORT/" /etc/systemd/system/dropbear.service 2>/dev/null
                systemctl daemon-reload
                systemctl restart dropbear
                echo -e "  ${G}Puerto cambiado a ${NEW_PORT}${NC}"; sleep 2 ;;
            6)
                systemctl stop dropbear; systemctl disable dropbear
                apt remove -y dropbear > /dev/null 2>&1
                rm -f /etc/systemd/system/dropbear.service
                systemctl daemon-reload
                echo -e "  ${G}Dropbear desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_banner_ssh() {
    while true; do
        banner; sep
        echo -e "  ${Y}  BANNER SSH${NC}"; sep; echo ""
        echo -e "  Banner actual:"
        echo ""
        cat /etc/ssh/sshd_config | grep -i "^Banner" || echo "  Sin banner configurado"
        [ -f /etc/ssh/banner ] && cat /etc/ssh/banner || echo ""
        echo ""; sep
        echo -e "  ${W}[1]${NC} Crear/Editar banner"
        echo -e "  ${W}[2]${NC} Quitar banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                banner; sep
                echo -e "  ${Y}Escribe el banner SSH${NC}"
                echo -e "  ${C}(Texto que aparece al conectar por SSH)${NC}"; sep; echo ""
                echo -e "  Ejemplo:"
                echo -e "  ╔══════════════════════════════════╗"
                echo -e "  ║   SERVIDOR PRIVADO - SSHFREE LTM ║"
                echo -e "  ╚══════════════════════════════════╝"
                echo ""; sep
                read -p "  Texto del banner: " BANNER_TXT
                echo "$BANNER_TXT" > /etc/ssh/banner
                # Configurar sshd para mostrar banner
                grep -q "^Banner" /etc/ssh/sshd_config && sed -i "s|^Banner.*|Banner /etc/ssh/banner|" /etc/ssh/sshd_config || echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
                systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
                echo -e "  ${G}OK Banner SSH configurado${NC}"; sleep 2 ;;
            2)
                sed -i '/^Banner/d' /etc/ssh/sshd_config
                rm -f /etc/ssh/banner
                systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
                echo -e "  ${G}OK Banner eliminado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}



menu_hysteria() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ HYSTERIA UDP${NC}"; sep; echo ""
        H1_ST=$(systemctl is-active hysteria-server 2>/dev/null)
        H2_ST=$(systemctl is-active hysteria2-server 2>/dev/null)
        [ "$H1_ST" = "active" ] && echo -e "  ${NEON}◈${NC} ${W}Hysteria V1${NC} ${NEON}◆ ON${NC}" || echo -e "  ${NEON}◈${NC} ${W}Hysteria V1${NC} ${R}◇ OFF${NC}"
        [ "$H2_ST" = "active" ] && echo -e "  ${NEON}◈${NC} ${W}Hysteria V2${NC} ${NEON}◆ ON${NC}" || echo -e "  ${NEON}◈${NC} ${W}Hysteria V2${NC} ${R}◇ OFF${NC}"
        echo ""; sep
        printf " ${Y}❬1❭ Instalar Hysteria V1    ❬2❭ Instalar Hysteria V2${NC}\n"
        printf " ${Y}❬3❭ Iniciar V1              ❬4❭ Iniciar V2${NC}\n"
        printf " ${Y}❬5❭ Detener V1              ❬6❭ Detener V2${NC}\n"
        printf " ${Y}❬7❭ Ver config V1           ❬8❭ Ver config V2${NC}\n"
        printf " ${R}❬9❭ Desinstalar V1          ❬10❭ Desinstalar V2${NC}\n"
        sep
        printf " ${R}❬0❭ Volver${NC}\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando Hysteria V1...${NC}"
                apt install -y wget > /dev/null 2>&1
                wget -q -O /usr/local/bin/hysteria-v1 https://github.com/HyNetwork/hysteria/releases/download/v1.3.5/hysteria-linux-amd64
                chmod +x /usr/local/bin/hysteria-v1
                read -p "  Puerto UDP (default 36712): " H1_PORT; H1_PORT=${H1_PORT:-36712}
                read -p "  Password: " H1_PASS; H1_PASS=${H1_PASS:-"ltmssh2026"}
                read -p "  Dominio (para TLS, deja vacio para self-signed): " H1_DOMAIN
                mkdir -p /etc/hysteria
                if [ -n "$H1_DOMAIN" ]; then
                    apt install -y certbot > /dev/null 2>&1
                    certbot certonly --standalone -d $H1_DOMAIN --non-interactive --agree-tos -m admin@${H1_DOMAIN#*.} 2>/dev/null
                    CERT_FILE="/etc/letsencrypt/live/$H1_DOMAIN/fullchain.pem"
                    KEY_FILE="/etc/letsencrypt/live/$H1_DOMAIN/privkey.pem"
                else
                    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
                        -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt \
                        -subj "/CN=hysteria" -days 36500 2>/dev/null
                    CERT_FILE="/etc/hysteria/server.crt"
                    KEY_FILE="/etc/hysteria/server.key"
                fi
                cat > /etc/hysteria/config.json << EOF
{
  "listen": ":$H1_PORT",
  "cert": "$CERT_FILE",
  "key": "$KEY_FILE",
  "auth": {
    "mode": "password",
    "config": {"password": "$H1_PASS"}
  },
  "obfs": "ltmssh",
  "up_mbps": 100,
  "down_mbps": 100
}
EOF
                cat > /etc/systemd/system/hysteria-server.service << EOF
[Unit]
Description=Hysteria V1 Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria-v1 server --config /etc/hysteria/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable hysteria-server
                systemctl start hysteria-server
                iptables -I INPUT -p udp --dport $H1_PORT -j ACCEPT 2>/dev/null
                echo -e "  ${G}OK Hysteria V1 instalado${NC}"
                echo -e "  ${NEON}◈${NC} Puerto: ${Y}$H1_PORT${NC}"
                echo -e "  ${NEON}◈${NC} Password: ${Y}$H1_PASS${NC}"
                echo -e "  ${NEON}◈${NC} Obfs: ${Y}ltmssh${NC}"
                read -p "  ENTER..." ;;
            2)
                echo -e "\n  ${C}Instalando Hysteria V2...${NC}"
                apt install -y wget > /dev/null 2>&1
                wget -q -O /usr/local/bin/hysteria2 https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64
                # hysteria2 es el mismo binario de apernet pero con nombre diferente
                chmod +x /usr/local/bin/hysteria2
                read -p "  Puerto UDP (default 8443): " H2_PORT; H2_PORT=${H2_PORT:-8443}
                read -p "  Password: " H2_PASS; H2_PASS=${H2_PASS:-"ltmssh2026"}
                read -p "  Dominio (deja vacio para self-signed): " H2_DOMAIN
                mkdir -p /etc/hysteria2
                if [ -n "$H2_DOMAIN" ]; then
                    apt install -y certbot > /dev/null 2>&1
                    certbot certonly --standalone -d $H2_DOMAIN --non-interactive --agree-tos -m admin@${H2_DOMAIN#*.} 2>/dev/null
                    CERT2_FILE="/etc/letsencrypt/live/$H2_DOMAIN/fullchain.pem"
                    KEY2_FILE="/etc/letsencrypt/live/$H2_DOMAIN/privkey.pem"
                else
                    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
                        -keyout /etc/hysteria2/server.key -out /etc/hysteria2/server.crt \
                        -subj "/CN=hysteria2" -days 36500 2>/dev/null
                    CERT2_FILE="/etc/hysteria2/server.crt"
                    KEY2_FILE="/etc/hysteria2/server.key"
                fi
                cat > /etc/hysteria2/config.yaml << EOF
listen: :$H2_PORT
tls:
  cert: $CERT2_FILE
  key: $KEY2_FILE
auth:
  type: password
  password: $H2_PASS
masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com/
    rewriteHost: true
EOF
                cat > /etc/systemd/system/hysteria2-server.service << EOF
[Unit]
Description=Hysteria V2 Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria2 server --config /etc/hysteria2/config.yaml
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable hysteria2-server
                systemctl start hysteria2-server
                iptables -I INPUT -p udp --dport $H2_PORT -j ACCEPT 2>/dev/null
                echo -e "  ${G}OK Hysteria V2 instalado${NC}"
                echo -e "  ${NEON}◈${NC} Puerto: ${Y}$H2_PORT${NC}"
                echo -e "  ${NEON}◈${NC} Password: ${Y}$H2_PASS${NC}"
                read -p "  ENTER..." ;;
            3) systemctl start hysteria-server && echo -e "  ${G}Hysteria V1 iniciado${NC}"; sleep 1 ;;
            4) systemctl start hysteria2-server && echo -e "  ${G}Hysteria V2 iniciado${NC}"; sleep 1 ;;
            5) systemctl stop hysteria-server && echo -e "  ${Y}Hysteria V1 detenido${NC}"; sleep 1 ;;
            6) systemctl stop hysteria2-server && echo -e "  ${Y}Hysteria V2 detenido${NC}"; sleep 1 ;;
            7) cat /etc/hysteria/config.json 2>/dev/null || echo "No instalado"; echo ""; read -p "  ENTER..." ;;
            8) cat /etc/hysteria2/config.yaml 2>/dev/null || echo "No instalado"; echo ""; read -p "  ENTER..." ;;
            9)
                systemctl stop hysteria-server; systemctl disable hysteria-server
                rm -f /usr/local/bin/hysteria /etc/systemd/system/hysteria-server.service
                rm -rf /etc/hysteria; systemctl daemon-reload
                echo -e "  ${G}Hysteria V1 desinstalado${NC}"; sleep 2 ;;
            10)
                systemctl stop hysteria2-server; systemctl disable hysteria2-server
                rm -f /usr/local/bin/hysteria2 /etc/systemd/system/hysteria2-server.service
                rm -rf /etc/hysteria2; systemctl daemon-reload
                echo -e "  ${G}Hysteria V2 desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}


menu_principal() {
    while true; do
        banner
        SRV_IP=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
        SRV_OS=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Ubuntu")
        SRV_CPU=$(nproc)
        SRV_DATE=$(date +%d/%m/%Y-%H:%M)
        SRV_RAM=$(free -h | awk '/^Mem:/{print $4}')
        SRV_UPTIME=$(uptime -p | sed 's/up //')
        sep
        printf " ${NEON}◈${NC} ${DIM}SO:${NC}  ${W}%-20s${NC} ${NEON}◈${NC} ${DIM}IP:${NC}  ${NEON}%s${NC}\n" "$SRV_OS" "$SRV_IP"
        printf " ${NEON}◈${NC} ${DIM}CPU:${NC} ${W}%-19s${NC} ${NEON}◈${NC} ${DIM}Fecha:${NC} ${Y}%s${NC}\n" "$SRV_CPU cores" "$SRV_DATE"
        printf " ${NEON}◈${NC} ${DIM}RAM:${NC} ${W}%-19s${NC} ${NEON}◈${NC} ${DIM}Uptime:${NC} ${W}%s${NC}\n" "$SRV_RAM" "$SRV_UPTIME"
        sep
        WS_PORT=$(cat /etc/sshfreeltm/ws_port 2>/dev/null || echo "80")
        DB_PORT=$(cat /etc/sshfreeltm/dropbear_port 2>/dev/null || echo "444")
        C1="" C2=""
        systemctl is-active --quiet ws-proxy-${WS_PORT} 2>/dev/null && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}WebSocket:${WS_PORT}${NC} ${NEON}◆ ON${NC}" || C2="${NEON}◈${NC} ${W}WebSocket:${WS_PORT}${NC} ${NEON}◆ ON${NC}"; }
        systemctl is-active --quiet badvpn-7200 2>/dev/null && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}BadVPN:7200${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}BadVPN:7200${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}BadVPN:7200${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        systemctl is-active --quiet badvpn-7300 2>/dev/null && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}BadVPN:7300${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}BadVPN:7300${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}BadVPN:7300${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        ps aux | grep -i "UDP-Custom" | grep -v grep | grep -q . && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}UDP:36712${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}UDP:36712${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}UDP:36712${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        systemctl is-active --quiet stunnel4 2>/dev/null && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}SSL/TLS:443${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}SSL/TLS:443${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}SSL/TLS:443${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        if systemctl is-active --quiet v2ray 2>/dev/null; then
            V2P=$(python3 -c "import json; c=json.load(open('/usr/local/etc/v2ray/config.json')); print(','.join([str(ib['port']) for ib in c.get('inbounds',[])]))" 2>/dev/null)
            [ -n "$V2P" ] && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}V2Ray:${V2P}${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}V2Ray:${V2P}${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}V2Ray:${V2P}${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        fi
        systemctl is-active --quiet zivpn 2>/dev/null && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}ZIV VPN:5667${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}ZIV VPN:5667${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}ZIV VPN:5667${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        systemctl is-active --quiet server-sldns 2>/dev/null && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}SlowDNS:5300${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}SlowDNS:5300${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}SlowDNS:5300${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        systemctl is-active --quiet dropbear 2>/dev/null && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}Dropbear:${DB_PORT}${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}Dropbear:${DB_PORT}${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}Dropbear:${DB_PORT}${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        systemctl is-active --quiet hysteria-server 2>/dev/null && { [ -z "$C1" ] && C1="${NEON}◈${NC} ${W}LTMUDPv1:36712${NC} ${NEON}◆ ON${NC}" || { [ -z "$C2" ] && C2="${NEON}◈${NC} ${W}LTMUDPv1:36712${NC} ${NEON}◆ ON${NC}" || { echo -e " $C1    $C2"; C1="${NEON}◈${NC} ${W}LTMUDPv1:36712${NC} ${NEON}◆ ON${NC}"; C2=""; }; }; }
        [ -n "$C1" ] && [ -n "$C2" ] && echo -e " $C1    $C2" || { [ -n "$C1" ] && echo -e " $C1"; }
        [ -z "$C1" ] && echo -e " ${DIM}  Sin servicios activos${NC}"
        sep
        printf " \033[1;97m❬1❭ ⚡  Usuarios SSH         ❬2❭ 📡 Usuarios VMess\033[0m\n"
        printf " \033[1;97m❬3❭ 🔐 Usuarios ZIV VPN     ❬4❭ 🛠  Herramientas\033[0m\n"
        printf " \033[1;97m❬5❭ 👤 SSH Online           ❬6❭ 📡 V2Ray Online\033[0m\n"
        printf " \033[1;97m❬7❭ 🔒 ZIV Online\033[0m\n"
        printf " ${NEON}❖ Version: ${Y}v%s ${NEON}❖${NC}\n" "$SCRIPT_VERSION"
        sep
        printf " ${Y}❬9❭ 🖥️  %-18s${NC} ${R}❬10❭ 🗑️  %s${NC}\n" "Configurar MOTD" "Desinstalar"
        printf " ${Y}❬11❭ 🔄 Actualizar Script${NC}\n"
        sep
        printf " ${R}❬0❭ ✖  Salir${NC}\n"
        sep
        echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1) menu_usuarios ;;
            2) menu_v2ray ;;
            3) menu_users_ziv ;;
            5) usuarios_ssh_online_count ;;
            6) usuarios_v2ray_online_count ;;
            7) usuarios_ziv_online_count ;;
            4) menu_herramientas ;;
            9) instalar_motd ;;
            10) desinstalar_script ;;
            11) actualizar_script ;;
            11) actualizar_script ;;
            0) echo -e "\n  ${G}Hasta luego! — DarkZFull${NC}\n"; exit 0 ;;
            *) echo -e "  ${R}Opcion invalida${NC}"; sleep 1 ;;
        esac
    done
}

[ "$EUID" -ne 0 ] && echo -e "${R}Ejecuta como root${NC}" && exit 1
menu_principal

# Auto-instalar comando menu
wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh"
chmod +x /usr/local/bin/menu
echo -e "\033[0;32mComando menu instalado\033[0m"





