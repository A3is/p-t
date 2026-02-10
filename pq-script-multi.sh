#!/usr/bin/env bash

# ===============================
# Paqet Tunnel - Initial Checker |
# ===============================

while true; do
    clear 

    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    NC='\033[0m'



    # ---------- Check root ----------
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi


    # ---------- Banner ----------
    cat << "EOF"

██████╗  █████╗  ██████╗ ███████╗████████╗
██╔══██╗██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝
██████╔╝███████║██║   ██║█████╗     ██║   
██╔═══╝ ██╔══██║██║   ██║██╔══╝     ██║   
██║     ██║  ██║╚██████╔╝███████╗   ██║   
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   

           Paqet Tunnel

EOF

    echo "        Script written by : A3is"
    echo "        For Proper And Ethical Use."
    echo "        V 1.0.0"
    echo

    # ---------- OS Check ----------
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    else
        echo -e "${RED}Error: Cannot detect operating system.${NC}"
        exit 1
    fi

    OS_OK=true
    GLIBC_OK=true

    if [[ "$ID" != "ubuntu" ]]; then
        OS_OK=false
    elif [[ "${VERSION_ID%%.*}" -lt 22 ]]; then
        OS_OK=false
    fi

    GLIBC_VERSION=$(ldd --version 2>/dev/null | head -n1 | awk '{print $NF}')
    REQUIRED_GLIBC="2.34"

    if [[ "$(printf '%s\n' "$REQUIRED_GLIBC" "$GLIBC_VERSION" | sort -V | head -n1)" != "$REQUIRED_GLIBC" ]]; then
        GLIBC_OK=false
    fi

    if [[ "$OS_OK" == false || "$GLIBC_OK" == false ]]; then
        echo -e "${RED}Error: System requirements are not met.${NC}"
        echo -e "${RED}Prerequisites:${NC}"
        echo -e "${RED}- Ubuntu 22.04 or newer${NC}"
        echo -e "${RED}- glibc 2.34 or newer${NC}"
        exit 1
    fi


    # ---------- Install Prerequisites (First Run) ----------
    REQUIRED_PACKAGES=(iperf3 nload vnstat net-tools)
    MISSING_PACKAGES=()

    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            MISSING_PACKAGES+=("$pkg")
        fi
    done

    if [ "${#MISSING_PACKAGES[@]}" -ne 0 ]; then
        echo -e "${GREEN}Installing required packages: ${MISSING_PACKAGES[*]}${NC}"
        apt update
        apt install -y "${MISSING_PACKAGES[@]}"
        echo -e "${GREEN}Prerequisites installed successfully.${NC}"
        sleep 2
    fi


    echo
    echo "----------------------------------------"
    echo


# ---------- Path Checks ----------
check_path() {
    local label="$1"

    if [[ "$label" == "paqet-core" ]]; then
        FILE_X86="/root/paqet-core/paqet_linux_amd64"
        FILE_ARM="/root/paqet-core/paqet_linux_arm64"
        if [[ -f "$FILE_X86" || -f "$FILE_ARM" ]]; then
            echo -e "$label : ${GREEN}Exists${NC}"
        else
            echo -e "$label : ${RED}Not exists${NC}"
        fi

    elif [[ "$label" == "ConfigFile" ]]; then
        FILES=$(ls /root/paqet-core/*.yaml 2>/dev/null | xargs -n1 basename | tr '\n' '-' | sed 's/-$//')
        if [[ -n "$FILES" ]]; then
            echo -e "$label : ${GREEN}$FILES${NC}"
        else
            echo -e "$label : ${RED}Not exists${NC}"
        fi

    elif [[ "$label" == "PaqetService" ]]; then
        SERVICES=()
        for f in /etc/systemd/system/paqet-kharej-*.service /etc/systemd/system/paqet-iran-*.service; do
            [[ -e "$f" ]] || continue
            name=$(basename "$f")
            status=$(systemctl is-active "$name")
            SERVICES+=("${name} (${status})")
        done

        if [[ "${#SERVICES[@]}" -gt 0 ]]; then
            echo -e "$label : ${GREEN}$(IFS=- ; echo "${SERVICES[*]}")${NC}"
        else
            echo -e "$label : ${RED}Not exists${NC}"
        fi

    else
        # Fallback برای چک معمولی
        local path="$2"
        if [ -e "$path" ]; then
            echo -e "$label : ${GREEN}Exists${NC}"
        else
            echo -e "$label : ${RED}Not exists${NC}"
        fi
    fi
}

# فراخوانی ها
check_path "paqet-core"
check_path "ConfigFile"
check_path "PaqetService"


    echo
    echo "----------------------------------------"
    echo

    # ---------- Menu ----------
    echo "1- Install Core"
    echo "2- Config Paqet in KharejServer"
    echo "3- Config Paqet in IranServer"
    echo "4- Restart Service"
    echo "5- Service Status"
    echo "6- Paqet Test in Iran"
    echo "7- Delete Paqet"
    echo "0- Exit"
    echo

    read -rp "Select an option: " OPTION

    case "$OPTION" in
        1)
            echo
            echo "Installing Paqet Core..."
            cd /root/ || exit 1
            curl -L -o paqet-core.tar.gz https://raw.githubusercontent.com/A3is/p-t/master/paqet-core.tar.gz
            tar -xzf paqet-core.tar.gz
            rm -f paqet-core.tar.gz
            chmod -R 700 /root/paqet-core
            chown -R root:root /root/paqet-core
            echo -e "${GREEN}Paqet Core installed successfully.${NC}"
            sleep 2
            continue
            ;;

        2)
            echo
            echo "Configuring Paqet service for KharejServer..."
            echo


            # دریافت نام سرور
            while true; do
                read -rp "Enter server name (English only): " NAME
                [[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]] && break
                echo -e "${RED}Invalid name. Only English letters, numbers, '-' or '_' allowed.${NC}"
            done

            CONFIG_FILE="/root/paqet-core/config-kharej-${NAME}.yaml"
            SERVICE_FILE="/etc/systemd/system/paqet-kharej-${NAME}.service"

            # بررسی وجود فایل یا سرویس
            if [[ -f "$CONFIG_FILE" || -f "$SERVICE_FILE" ]]; then
                read -rp "Config or service exists. Replace? [y/N]: " ANS
                [[ "$ANS" =~ ^[Yy]$ ]] || continue
            fi

            # دریافت پورت Tunnel
            while true; do
                read -rp "Enter Tunnel Port: " TunnelPort
                [[ "$TunnelPort" =~ ^[0-9]+$ ]] && ((TunnelPort>=1 && TunnelPort<=65535)) || { echo "Invalid port"; continue; }
                ss -lntup | grep -q ":$TunnelPort " && { echo "Port in use"; continue; }
                break
            done

            SERVER_INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
            SERVER_IP=$(ip -4 addr show "$SERVER_INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
            DEFAULT_GATEWAY_IP=$(ip route show | grep default | awk '{print $3}' | head -n1)
            ROUTER_MAC=$(arp -n "$DEFAULT_GATEWAY_IP" | awk '/ether/ {print $3}')

            mkdir -p /root/paqet-core
            chmod 700 /root/paqet-core
            chown root:root /root/paqet-core

            cat > "$CONFIG_FILE" << EOF
role: "server"
log:
  level: "error"
listen:
  addr: "0.0.0.0:${TunnelPort}"
network:
  interface: "$SERVER_INTERFACE"
  ipv4:
    addr: "$SERVER_IP:${TunnelPort}"
    router_mac: "$ROUTER_MAC"
  tcp:
    local_flag: ["PA"]
transport:
  protocol: "kcp"
  conn: 1
  kcp:
    key: "81c994902cd2e0787d2a09cf8921da1c27f4a0656ba606e56b7327c3b9a8f492"
    block: "aes-128-gcm"
    mode: "fast2"
    mtu: 1350
    sndwnd: 1024
    rcvwnd: 1024
    nodelay: 1
    interval: 20
    resend: 2
    nc: 1
    smuxbuf: 67108864
    streambuf: 2097152
EOF
            chmod 600 "$CONFIG_FILE"
            chown root:root "$CONFIG_FILE"

            ARCH=$(uname -m)
            if [[ "$ARCH" == "x86_64" ]]; then
                EXEC_FILE="/root/paqet-core/paqet_linux_amd64"
            elif [[ "$ARCH" == "aarch64" ]]; then
                EXEC_FILE="/root/paqet-core/paqet_linux_arm64"
            else
                echo -e "${RED}Unsupported architecture: $ARCH${NC}"
                read -rp "Press enter to return to menu..."
                continue
            fi

            cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Paqet Server Service Kharej (${NAME})
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/root/paqet-core
ExecStart=$EXEC_FILE run -c $CONFIG_FILE
Restart=always
RestartSec=3
StartLimitBurst=0
LimitNOFILE=1048576
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99
Nice=-20

[Install]
WantedBy=multi-user.target
EOF
            chmod 644 "$SERVICE_FILE"
            chown root:root "$SERVICE_FILE"

            systemctl daemon-reload
            systemctl enable "paqet-kharej-${NAME}"
            systemctl start "paqet-kharej-${NAME}"

            iptables -t raw -A PREROUTING -p tcp --dport "$TunnelPort" -j NOTRACK
            iptables -t raw -A OUTPUT -p tcp --sport "$TunnelPort" -j NOTRACK
            iptables -t mangle -A OUTPUT -p tcp --sport "$TunnelPort" --tcp-flags RST RST -j DROP

            cat <<EOF > /etc/sysctl.d/99-max-performance.conf
net.core.netdev_max_backlog = 50000
net.core.rmem_max = 33554432       # 32MB
net.core.wmem_max = 33554432       # 32MB
net.core.rmem_default = 1048576    # 1MB
net.core.wmem_default = 1048576    # 1MB
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.udp_mem = 131072 262144 524288
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_timestamps = 1
EOF

            sysctl --system
            ifconfig "$SERVER_INTERFACE" txqueuelen 20000
            sync; echo 3 > /proc/sys/vm/drop_caches
            systemctl daemon-reload
            systemctl restart "paqet-kharej-${NAME}"

            echo -e "${GREEN}Paqet server configured successfully.${NC}"
            sleep 3
            continue
            ;;

        3)
            echo
            echo "Configuring Paqet client for IranServer..."
            echo

            # دریافت نام
            while true; do
                read -rp "Enter client name (English only): " NAME
                [[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]] && break
                echo "Invalid name"
            done

            CONFIG_FILE="/root/paqet-core/config-iran-${NAME}.yaml"
            SERVICE_FILE="/etc/systemd/system/paqet-iran-${NAME}.service"

            # بررسی وجود فایل یا سرویس
            if [[ -f "$CONFIG_FILE" || -f "$SERVICE_FILE" ]]; then
                read -rp "Config or service exists. Replace? [y/N]: " ANS
                [[ "$ANS" =~ ^[Yy]$ ]] || continue
            fi

            # دریافت آدرس Kharej Server
            while true; do
                read -rp "Enter Kharej server IP: " KHAREJ_IP
                [[ "$KHAREJ_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && break
                echo "Invalid IP"
            done

            # دریافت TunnelPort
            while true; do
                read -rp "Enter Tunnel Port: " TunnelPort
                [[ "$TunnelPort" =~ ^[0-9]+$ ]] && ((TunnelPort>=1 && TunnelPort<=65535)) || continue
                break
            done

            # دریافت Socks Port
            while true; do
                read -rp "Enter Socks Port: " IranPortSocks
                [[ "$IranPortSocks" =~ ^[0-9]+$ ]] && ((IranPortSocks>=1 && IranPortSocks<=65535)) || continue
                ss -lntup | grep -q ":$IranPortSocks " && { echo "Port in use"; continue; }
                break
            done

            SERVER_INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
            SERVER_IP=$(ip -4 addr show "$SERVER_INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
            DEFAULT_GATEWAY_IP=$(ip route show | grep default | awk '{print $3}' | head -n1)
            ROUTER_MAC=$(arp -n "$DEFAULT_GATEWAY_IP" | awk '/ether/ {print $3}')

            mkdir -p /root/paqet-core
            chmod 700 /root/paqet-core
            chown root:root /root/paqet-core

            cat > "$CONFIG_FILE" << EOF
role: "client"
log:
  level: "error"
socks5:
  - listen: "127.0.0.1:${IranPortSocks}"
network:
  interface: "$SERVER_INTERFACE"
  ipv4:
    addr: "$SERVER_IP:0"
    router_mac: "$ROUTER_MAC"
  tcp:
    local_flag: ["PA"]
    remote_flag: ["PA"]
server:
  addr: "$KHAREJ_IP:${TunnelPort}"
transport:
  protocol: "kcp"
  conn: 1
  kcp:
    key: "81c994902cd2e0787d2a09cf8921da1c27f4a0656ba606e56b7327c3b9a8f492"
    block: "aes-128-gcm"
    mode: "fast2"
    mtu: 1350
    sndwnd: 1024
    rcvwnd: 1024
    nodelay: 1
    interval: 20
    resend: 2
    nc: 1
    smuxbuf: 67108864
    streambuf: 2097152
EOF

            chmod 600 "$CONFIG_FILE"
            chown root:root "$CONFIG_FILE"

            ARCH=$(uname -m)
            if [[ "$ARCH" == "x86_64" ]]; then
                EXEC_FILE="/root/paqet-core/paqet_linux_amd64"
            elif [[ "$ARCH" == "aarch64" ]]; then
                EXEC_FILE="/root/paqet-core/paqet_linux_arm64"
            else
                echo -e "${RED}Unsupported architecture: $ARCH${NC}"
                read -rp "Press enter to return to menu..."
                continue
            fi

            cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Paqet Client Service Iran (${NAME})
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/root/paqet-core
ExecStart=$EXEC_FILE run -c $CONFIG_FILE
Restart=always
RestartSec=3
StartLimitBurst=0
LimitNOFILE=1048576
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99
Nice=-20

[Install]
WantedBy=multi-user.target
EOF

            chmod 644 "$SERVICE_FILE"
            chown root:root "$SERVICE_FILE"

            systemctl daemon-reload
            systemctl enable "paqet-iran-${NAME}"
            systemctl start "paqet-iran-${NAME}"

            cat <<EOF > /etc/sysctl.d/99-max-performance.conf
net.core.netdev_max_backlog = 50000
net.core.rmem_max = 33554432       # 32MB
net.core.wmem_max = 33554432       # 32MB
net.core.rmem_default = 1048576    # 1MB
net.core.wmem_default = 1048576    # 1MB
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.udp_mem = 131072 262144 524288
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_timestamps = 1
EOF

            sysctl --system
            ifconfig "$SERVER_INTERFACE" txqueuelen 20000

            echo -e "${GREEN}Paqet client configured successfully.${NC}"
            sleep 3
            continue
            ;;

        4)
            echo
            echo "Select Paqet service to restart:"
            mapfile -t SERVICES < <(ls /etc/systemd/system/paqet-*.service 2>/dev/null | xargs -n1 basename)
            if [[ "${#SERVICES[@]}" -eq 0 ]]; then
                echo -e "${RED}No Paqet services found.${NC}"
                sleep 2
                continue
            fi

            # نمایش لیست با شماره
            for i in "${!SERVICES[@]}"; do
                echo "$((i+1))- ${SERVICES[$i]}"
            done
            [[ "${#SERVICES[@]}" -gt 1 ]] && echo "$(( ${#SERVICES[@]} + 1 ))- Restart All"

            read -rp "Select option: " SEL
            if [[ "$SEL" =~ ^[0-9]+$ ]]; then
                if (( SEL >=1 && SEL <= ${#SERVICES[@]} )); then
                    systemctl restart "${SERVICES[$((SEL-1))]}"
                    echo -e "${GREEN}${SERVICES[$((SEL-1))]} restarted.${NC}"
                elif (( SEL == ${#SERVICES[@]} + 1 )); then
                    for svc in "${SERVICES[@]}"; do
                        systemctl restart "$svc"
                    done
                    echo -e "${GREEN}All Paqet services restarted.${NC}"
                else
                    echo -e "${RED}Invalid selection.${NC}"
                fi
            else
                echo -e "${RED}Invalid input.${NC}"
            fi
            sleep 2
            continue
            ;;

        5)
            echo
            echo "Select Paqet service to show status:"
            mapfile -t SERVICES < <(ls /etc/systemd/system/paqet-*.service 2>/dev/null | xargs -n1 basename)
            if [[ "${#SERVICES[@]}" -eq 0 ]]; then
                echo -e "${RED}No Paqet services found.${NC}"
                sleep 2
                continue
            fi

            for i in "${!SERVICES[@]}"; do
                echo "$((i+1))- ${SERVICES[$i]}"
            done

            read -rp "Select option: " SEL
            if [[ "$SEL" =~ ^[0-9]+$ ]] && (( SEL >=1 && SEL <= ${#SERVICES[@]} )); then
                systemctl status "${SERVICES[$((SEL-1))]}" --no-pager
            else
                echo -e "${RED}Invalid selection.${NC}"
            fi
            read -rp "Press enter to return to menu..."
            continue
            ;;

        6)
            echo
            echo "Select Paqet client service to test:"
            mapfile -t SERVICES < <(ls /etc/systemd/system/paqet-iran-*.service 2>/dev/null | xargs -n1 basename)
            if [[ "${#SERVICES[@]}" -eq 0 ]]; then
                echo -e "${RED}No Paqet client services found.${NC}"
                sleep 2
                continue
            fi

            for i in "${!SERVICES[@]}"; do
                echo "$((i+1))- ${SERVICES[$i]}"
            done

            read -rp "Select option: " SEL
            if [[ "$SEL" =~ ^[0-9]+$ ]] && (( SEL >=1 && SEL <= ${#SERVICES[@]} )); then
                CONFIG_FILE="/root/paqet-core/config-iran-${SERVICES[$((SEL-1))]#paqet-iran-}.yaml"
                if [[ ! -f "$CONFIG_FILE" ]]; then
                    echo -e "${RED}Config file not found: $CONFIG_FILE${NC}"
                    sleep 2
                    continue
                fi
                PORT=$(grep -Po '(?<=listen: ")[^:]+:\K[0-9]+' "$CONFIG_FILE")
                if [[ -z "$PORT" ]]; then
                    echo -e "${RED}Cannot extract port from config.${NC}"
                    sleep 2
                    continue
                fi
                echo -e "${GREEN}Testing service on port $PORT...${NC}"
                curl -v https://google.com --proxy "socks5h://127.0.0.1:${PORT}"
            else
                echo -e "${RED}Invalid selection.${NC}"
            fi
            read -rp "Press enter to return to menu..."
            continue
            ;;

        7)
            echo
            echo "Select Paqet service to delete:"
            mapfile -t SERVICES < <(ls /etc/systemd/system/paqet-*.service 2>/dev/null | xargs -n1 basename)
            if [[ "${#SERVICES[@]}" -eq 0 ]]; then
                echo -e "${RED}No Paqet services found.${NC}"
                sleep 2
                continue
            fi

            for i in "${!SERVICES[@]}"; do
                echo "$((i+1))- ${SERVICES[$i]}"
            done
            [[ "${#SERVICES[@]}" -gt 1 ]] && echo "$(( ${#SERVICES[@]} + 1 ))- Delete All"

            read -rp "Select option: " SEL
            if [[ "$SEL" =~ ^[0-9]+$ ]]; then
                delete_service() {
                    local svc="$1"
                    local cfg=""
                    systemctl stop "$svc"
                    rm -f "/etc/systemd/system/$svc"

                    # تعیین مسیر کانفیگ بر اساس نام سرویس
                    if [[ "$svc" =~ paqet-kharej-(.+)\.service ]]; then
                        cfg="/root/paqet-core/config-kharej-${BASH_REMATCH[1]}.yaml"
                    elif [[ "$svc" =~ paqet-iran-(.+)\.service ]]; then
                        cfg="/root/paqet-core/config-iran-${BASH_REMATCH[1]}.yaml"
                    fi

                    [[ -n "$cfg" && -f "$cfg" ]] && rm -f "$cfg"
                    echo -e "${GREEN}$svc and its config deleted.${NC}"
                }

                if (( SEL >=1 && SEL <= ${#SERVICES[@]} )); then
                    delete_service "${SERVICES[$((SEL-1))]}"
                elif (( SEL == ${#SERVICES[@]} + 1 )); then
                    for svc in "${SERVICES[@]}"; do
                        delete_service "$svc"
                    done
                    echo -e "${GREEN}All Paqet services and their configs deleted.${NC}"
                else
                    echo -e "${RED}Invalid selection.${NC}"
                fi
            else
                echo -e "${RED}Invalid input.${NC}"
            fi

            systemctl daemon-reload
            sleep 2
            continue
            ;;


        0)
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;

        *)
            echo -e "${RED}Invalid option.${NC}"
            sleep 2
            continue
            ;;
    esac
done
