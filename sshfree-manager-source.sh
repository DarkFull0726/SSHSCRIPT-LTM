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

# Generar versión de texto plano (sin HTML) para SSH y Dropbear
generar_banner_txt() {
    local origen="/etc/ssh/banner"
    local destino="/etc/ssh/banner.txt"
    if [ ! -f "$origen" ]; then
        echo -e "${R}No existe $origen${NC}" >&2
        return 1
    fi
    sed 's/<[^>]*>//g; s/&[a-zA-Z0-9#]\{2,6\};//g; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' "$origen" > "$destino"
    echo -e "${G}Banner de texto generado en $destino${NC}"
}

# Generar versión de texto plano (sin HTML) para SSH y Dropbear
generar_banner_txt() {
    local origen="/etc/ssh/banner"
    local destino="/etc/ssh/banner.txt"
    if [ ! -f "$origen" ]; then
        echo -e "${R}No existe $origen${NC}" >&2
        return 1
    fi
    # Eliminar etiquetas HTML y entidades
    sed 's/<[^>]*>//g; s/&[a-zA-Z0-9#]\{2,6\};//g; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' "$origen" > "$destino"
    echo -e "${G}Banner de texto generado en $destino${NC}"
}

# Generar versión de texto plano (sin HTML) para SSH y Dropbear


# Generar versión de texto plano (sin HTML) para SSH y Dropbear


# Generar versión de texto plano (sin HTML) para SSH y Dropbear

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
# Generar versión de texto plano (sin HTML) para SSH y Dropbear


# Generar versión de texto plano (sin HTML) para SSH y Dropbear




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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
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
            7)
                if [ ! -f /etc/ssh/banner ]; then
                    echo -e "  ${R}No existe /etc/ssh/banner${NC}"
                else
                    /usr/local/bin/convert-banner-txt
                    systemctl restart dropbear
                    echo -e "  ${G}Dropbear reiniciado con el banner en texto plano${NC}"
                fi
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
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
            7)
                if [ ! -f /etc/ssh/banner ]; then
                    echo -e "  ${R}No existe /etc/ssh/banner${NC}"
                else
                    /usr/local/bin/convert-banner-txt
                    systemctl restart dropbear
                    echo -e "  ${G}Dropbear reiniciado con el banner en texto plano${NC}"
                fi
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) crear_user_ziv ;;
            2) listar_users_ziv ;;
            3) eliminar_user_ziv ;;
            4) limpiar_expirados_ziv; aplicar_passwords_ziv; echo -e "  ${G}Limpiado${NC}"; sleep 1 ;;
            7)
                if [ ! -f /etc/ssh/banner ]; then
                    echo -e "  ${R}No existe /etc/ssh/banner${NC}"
                else
                    /usr/local/bin/convert-banner-txt
                    systemctl restart dropbear
                    echo -e "  ${G}Dropbear reiniciado con el banner en texto plano${NC}"
                fi
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) crear_usuario ;;
            2) listar_usuarios ;;
            3) eliminar_usuario ;;
            4) renovar_usuario ;;
            7)
                if [ ! -f /etc/ssh/banner ]; then
                    echo -e "  ${R}No existe /etc/ssh/banner${NC}"
                else
                    /usr/local/bin/convert-banner-txt
                    systemctl restart dropbear
                    echo -e "  ${G}Dropbear reiniciado con el banner en texto plano${NC}"
                fi
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

            0) break ;;
        esac
    done
}



menu_banner_ssh() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ BANNER SSH & HTTP CUSTOM${NC}"; sep; echo ""

        # Estado SSH Banner
        if grep -q "^Banner" /etc/ssh/sshd_config 2>/dev/null; then
            echo -e "  ${NEON}◈${NC} ${W}Banner SSH:${NC}        ${NEON}◆ ACTIVO${NC}"
        else
            echo -e "  ${NEON}◈${NC} ${W}Banner SSH:${NC}        ${R}◇ INACTIVO${NC}"
        fi

        # Estado Banner HTTP Custom (WebSocket)
        WS_FILES=$(ls /etc/sshfreeltm/proxy_ws_*.py 2>/dev/null | head -1)
        if [ -n "$WS_FILES" ]; then
            CURRENT_MSG=$(grep "^MSG = " "$WS_FILES" 2>/dev/null | sed "s/MSG = '\(.*\)'.encode.*/\1/")
            echo -e "  ${NEON}◈${NC} ${W}Banner HTTP Custom:${NC} ${Y}${CURRENT_MSG:-No configurado}${NC}"
        else
            echo -e "  ${NEON}◈${NC} ${W}Banner HTTP Custom:${NC} ${R}Sin WebSocket activo${NC}"
        fi

        echo ""; sep
        echo -e "  ${NEON}── SSH BANNER ──────────────────${NC}"
        echo -e "  ${W}[1]${NC} Editar banner SSH (nano)"
        echo -e "  ${W}[2]${NC} Activar banner SSH"
        echo -e "  ${W}[3]${NC} Desactivar banner SSH"
        echo -e "  ${W}[4]${NC} Ver banner SSH actual"
        echo ""
        echo -e "  ${NEON}── HTTP CUSTOM BANNER ──────────${NC}"
        echo -e "  ${W}[5]${NC} Editar banner HTTP Custom"
        echo -e "  ${W}[6]${NC} Ver banner HTTP Custom actual"
        echo ""
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            2)
                if [ ! -f /etc/ssh/banner ]; then
                    echo -e "  ${R}No existe /etc/ssh/banner${NC}"
                else
                    generar_banner_txt
                    systemctl restart sshd
                    echo -e "  ${G}SSH reiniciado con el banner en texto plano${NC}"
                fi
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
            7)
                if [ ! -f /etc/ssh/banner ]; then
                    echo -e "  ${R}No existe /etc/ssh/banner${NC}"
                else
                    /usr/local/bin/convert-banner-txt
                    systemctl restart dropbear
                    echo -e "  ${G}Dropbear reiniciado con el banner en texto plano${NC}"
                fi
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
            7)
                if [ ! -f /etc/ssh/banner ]; then
                    echo -e "  ${R}No existe /etc/ssh/banner${NC}"
                else
                    /usr/local/bin/convert-banner-txt
                    systemctl restart dropbear
                    echo -e "  ${G}Dropbear reiniciado con el banner en texto plano${NC}"
                fi
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

            0) break ;;
        esac
    done
}



menu_banner_ssh() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ BANNER SSH & HTTP CUSTOM${NC}"; sep; echo ""

        # Estado SSH Banner
        if grep -q "^Banner" /etc/ssh/sshd_config 2>/dev/null; then
            echo -e "  ${NEON}◈${NC} ${W}Banner SSH:${NC}        ${NEON}◆ ACTIVO${NC}"
        else
            echo -e "  ${NEON}◈${NC} ${W}Banner SSH:${NC}        ${R}◇ INACTIVO${NC}"
        fi

        # Estado Banner HTTP Custom (WebSocket)
        WS_FILES=$(ls /etc/sshfreeltm/proxy_ws_*.py 2>/dev/null | head -1)
        if [ -n "$WS_FILES" ]; then
            CURRENT_MSG=$(grep "^MSG = " "$WS_FILES" 2>/dev/null | sed "s/MSG = '\(.*\)'.encode.*/\1/")
            echo -e "  ${NEON}◈${NC} ${W}Banner HTTP Custom:${NC} ${Y}${CURRENT_MSG:-No configurado}${NC}"
        else
            echo -e "  ${NEON}◈${NC} ${W}Banner HTTP Custom:${NC} ${R}Sin WebSocket activo${NC}"
        fi

        echo ""; sep
        echo -e "  ${NEON}── SSH BANNER ──────────────────${NC}"
        echo -e "  ${W}[1]${NC} Editar banner SSH (nano)"
        echo -e "  ${W}[2]${NC} Activar banner SSH"
        echo -e "  ${W}[3]${NC} Desactivar banner SSH"
        echo -e "  ${W}[4]${NC} Ver banner SSH actual"
        echo ""
        echo -e "  ${NEON}── HTTP CUSTOM BANNER ──────────${NC}"
        echo -e "  ${W}[5]${NC} Editar banner HTTP Custom"
        echo -e "  ${W}[6]${NC} Ver banner HTTP Custom actual"
        echo ""
        echo -e "  ${W}[7]${NC} Activar banner (usar banner SSH)"
        echo -e "  ${W}[8]${NC} Desactivar banner"
        echo -e "  ${W}[9]${NC} Editar banner"
        echo -e "  ${W}[10]${NC} Ver banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            8)
                if grep -q "\-b /etc/ssh/banner" /etc/systemd/system/dropbear.service; then
                    sed -i "s| -b /etc/ssh/banner||" /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                    systemctl restart dropbear
                    echo -e "  ${Y}Banner desactivado en Dropbear${NC}"
                else
                    echo -e "  ${R}El banner no estaba activo${NC}"
                fi
                sleep 2 ;;
            9)
                nano /etc/ssh/banner
                generar_banner_txt
                sleep 2 ;;
            10)
                echo ""; sep
                echo -e "  ${Y}Banner actual:${NC}"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  ${R}No hay archivo de banner${NC}"
                echo ""; read -p "  ENTER..." ;;

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

# Generar versión de texto plano (sin HTML) para SSH y Dropbear
# Generar versión de texto plano (sin HTML) para SSH y Dropbear

menu_dropbear() {
    while true; do
        clear
        echo -e "\033[1;34m"
        figlet -f small "DROPBEAR" 2>/dev/null || echo "  DROPBEAR SSH"
        echo -e "\033[0m"
        echo -e "\033[1;34m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        echo -e "  \033[1;37m⚡ DROPBEAR SSH MANAGER\033[0m \033[2;37mby\033[0m \033[1;34m@DarkZFull\033[0m"
        echo -e "\033[1;34m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        echo ""
        DB_ST=$(systemctl is-active dropbear 2>/dev/null)
        DB_PORT=$(cat /etc/sshfreeltm/dropbear_port 2>/dev/null || echo "444")
        if [ "$DB_ST" = "active" ]; then
            echo -e "  \033[1;34m◈\033[0m \033[1;37mEstado:\033[0m    \033[1;32m● ACTIVO\033[0m"
        else
            echo -e "  \033[1;34m◈\033[0m \033[1;37mEstado:\033[0m    \033[1;31m○ INACTIVO\033[0m"
        fi
        echo -e "  \033[1;34m◈\033[0m \033[1;37mPuerto:\033[0m    \033[1;33m$DB_PORT\033[0m"
        if [ -f /etc/ssh/banner.txt ]; then
            echo -e "  \033[1;34m◈\033[0m \033[1;37mBanner:\033[0m    \033[1;32m● ACTIVADO\033[0m"
        else
            echo -e "  \033[1;34m◈\033[0m \033[1;37mBanner:\033[0m    \033[1;31m○ DESACTIVADO\033[0m"
        fi
        echo ""
        echo -e "\033[1;34m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        printf " \033[1;34m❬1❭\033[0m \033[1;37mInstalar\033[0m         \033[1;34m❬2❭\033[0m \033[1;37mIniciar\033[0m\n"
        printf " \033[1;34m❬3❭\033[0m \033[1;37mDetener\033[0m          \033[1;34m❬4❭\033[0m \033[1;37mReiniciar\033[0m\n"
        printf " \033[1;34m❬5❭\033[0m \033[1;37mCambiar puerto\033[0m   \033[1;34m❬6❭\033[0m \033[1;37mDesinstalar\033[0m\n"
        echo ""
        printf " \033[1;34m❬7❭\033[0m \033[1;37mActivar banner\033[0m    \033[1;34m❬8❭\033[0m \033[1;37mDesactivar banner\033[0m\n"
        printf " \033[1;34m❬9❭\033[0m \033[1;37mEditar banner\033[0m     \033[1;34m❬10❭\033[0m \033[1;37mVer banner\033[0m\n"
        echo ""
        echo -e "\033[1;34m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        printf " \033[1;31m❬0❭\033[0m \033[1;37mVolver\033[0m\n"
        echo -e "\033[1;34m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
        echo ""
        read -p "  \033[1;34m➤\033[0m Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  \033[1;36mInstalando Dropbear...\033[0m"
                apt install -y dropbear
                read -p "  \033[1;37mPuerto Dropbear (default 444): \033[0m" DB_PORT
                DB_PORT=${DB_PORT:-444}
                mkdir -p /etc/sshfreeltm
                echo "$DB_PORT" > /etc/sshfreeltm/dropbear_port
                sed -i "s/NO_START=1/NO_START=0/" /etc/default/dropbear 2>/dev/null
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$DB_PORT/" /etc/default/dropbear 2>/dev/null
                grep -q "DROPBEAR_PORT" /etc/default/dropbear || echo "DROPBEAR_PORT=$DB_PORT" >> /etc/default/dropbear
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
                mkdir -p /etc/dropbear
                [ ! -f /etc/dropbear/dropbear_dss_host_key ] && dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_rsa_host_key ] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key > /dev/null 2>&1
                grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
                systemctl enable dropbear
                systemctl start dropbear
                iptables -I INPUT -p tcp --dport $DB_PORT -j ACCEPT 2>/dev/null
                echo -e "  \033[1;32m✓ Dropbear instalado en puerto $DB_PORT\033[0m"; sleep 2 ;;
            2) systemctl start dropbear && echo -e "  \033[1;32m✓ Dropbear iniciado\033[0m"; sleep 1 ;;
            3) systemctl stop dropbear && echo -e "  \033[1;33m⚠ Dropbear detenido\033[0m"; sleep 1 ;;
            4) systemctl restart dropbear && echo -e "  \033[1;32m✓ Dropbear reiniciado\033[0m"; sleep 1 ;;
            5)
                read -p "  \033[1;37mNuevo puerto: \033[0m" NEW_PORT
                echo "$NEW_PORT" > /etc/sshfreeltm/dropbear_port
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$NEW_PORT/" /etc/default/dropbear 2>/dev/null
                sed -i "s|-p [0-9]*|-p $NEW_PORT|" /etc/systemd/system/dropbear.service 2>/dev/null
                systemctl daemon-reload
                systemctl restart dropbear
                echo -e "  \033[1;32m✓ Puerto cambiado a $NEW_PORT\033[0m"; sleep 2 ;;
            6)
                systemctl stop dropbear; systemctl disable dropbear
                apt remove -y dropbear > /dev/null 2>&1
                rm -f /etc/systemd/system/dropbear.service
                systemctl daemon-reload
                echo -e "  \033[1;32m✓ Dropbear desinstalado\033[0m"; sleep 2 ;;
            7)
                echo -e "  \033[1;36mActivando banner...\033[0m"
                if [ ! -f /etc/ssh/banner ]; then
                    echo -e "  \033[1;33mCreando banner por defecto...\033[0m"
                    cat > /etc/ssh/banner << BAN
<h1 style="text-align:center"><span><big><big><span style="color: #00ff48">L</span><span style="color: #0dff5a">T</span><span style="color: #19fe6b">M</span><span style="color: #26fe7d"> </span><span style="color: #32fd8e">S</span><span style="color: #3ffda0">E</span><span style="color: #4cfcb1">R</span><span style="color: #58fcc3">V</span><span style="color: #65fbd4">I</span><span style="color: #71fbe6">D</span><span style="color: #7efaf7">OR</span><small></div><div><span style="color: #ff0000">NETFREE LTM VPS MIAMI 🇺🇲</span>
<div><div><span style="color: #00ff83">🚫</span><span style="color: #00ff87"></span><span style="color: #00ff8b">P</span><span style="color: #00ff8f">R</span><span style="color: #00ff93">O</span><span style="color: #00ff97">H</span><span style="color: #00ff9b">I</span><span style="color: #00ff9f">B</span><span style="color: #00ffa3">I</span><span style="color: #00ffa7">D</span><span style="color: #00ffab">A</span><span style="color: #00ffb0"> L</span><span style="color: #00ffb4">A</span> <span style="color: #00ffb8">V</span><span style="color: #00ffbc"></span><span style="color: #00ffc0">E</span><span style="color: #00ffc4">N</span><span style="color: #00ffc8">T</span><span style="color: #00ffcc">A</span><span style="color: #00ffd0"></span><span style="color: #00ffd4"</span><span style="color: #00ffd8">🚫</span></div>
<div><span style="color: #009aff">G</span><span style="color: #00cdc1">R</span><span style="color: #00ff83">U</span><span style="color: #80cc42">P</span><span style="color: #ff9900">O</span></div>https://t.me/+AzYZK49QGys4MDVh
<div><span style="color: #009aff">C</span><span style="color: #00cdc1">A</span><span style="color: #00ff83">N</span><span style="color: #80cc42">A</span><span style="color: #ff9900">L</span></div>https://t.me/+g8bjM5B2izkyNzYx
<big><big><big><big><big><big>🤑💥</big></big></big></big></big></big>
<h2 style="text-align:center;"><small><small><small><small><small><small><span style="color: #faff00">∘₊✧ </span><span style="color:#ffbf00;">™✶▲▽DarkFull༻༒</span></small></small></small></small></small></small></h2>
BAN
                fi
                sed 's/<[^>]*>//g; s/&[a-zA-Z0-9#]\{2,6\};//g; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' /etc/ssh/banner > /etc/ssh/banner.txt
                if ! grep -q "-b /etc/ssh/banner.txt" /etc/systemd/system/dropbear.service; then
                    sed -i 's|ExecStart=/usr/sbin/dropbear -F -p [0-9]*|& -b /etc/ssh/banner.txt|' /etc/systemd/system/dropbear.service
                    systemctl daemon-reload
                fi
                systemctl restart dropbear
                echo -e "  \033[1;32m✓ Banner activado\033[0m"; sleep 2 ;;
            8)
                sed -i 's| -b /etc/ssh/banner.txt||' /etc/systemd/system/dropbear.service
                systemctl daemon-reload
                systemctl restart dropbear
                echo -e "  \033[1;33m⚠ Banner desactivado\033[0m"; sleep 2 ;;
            9)
                nano /etc/ssh/banner
                sed 's/<[^>]*>//g; s/&[a-zA-Z0-9#]\{2,6\};//g; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' /etc/ssh/banner > /etc/ssh/banner.txt
                echo -e "  \033[1;32m✓ Banner actualizado\033[0m"; sleep 2 ;;
            10)
                echo ""; echo -e "  \033[1;34m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
                echo -e "  \033[1;37mBanner HTML original:\033[0m"; echo ""
                cat /etc/ssh/banner 2>/dev/null || echo -e "  \033[1;31mNo hay archivo de banner\033[0m"
                echo ""; echo -e "  \033[1;34m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
                echo -e "  \033[1;37mBanner texto plano (SSH/Dropbear):\033[0m"; echo ""
                cat /etc/ssh/banner.txt 2>/dev/null || echo -e "  \033[1;31mNo hay archivo de texto\033[0m"
                echo ""; echo -e "  \033[1;34m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
                read -p "  \033[1;34m➤\033[0m ENTER..." ;;
            0) break ;;
        esac
    done
}
[ "$EUID" -ne 0 ] && echo -e "${R}Ejecuta como root${NC}" && exit 1
menu_principal

# Auto-instalar comando menu
wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh"
chmod +x /usr/local/bin/menu
echo -e "\033[0;32mComando menu instalado\033[0m"





# Convertir HTML a texto plano (eliminar etiquetas)

# Generar versión de texto plano (sin HTML) para SSH y Dropbear


# Función que llama al conversor externo (usada desde el menú)
_convert_banner() {
    /usr/local/bin/convert-banner-txt
}
