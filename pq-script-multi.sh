#!/usr/bin/env bash

# ===============================
# Paqet Tunnel - Multi-instance  |
# ===============================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

while true; do
    clear
    cat << "EOF"
██████╗  █████╗  ██████╗ ███████╗████████╗
██╔══██╗██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝
██████╔╝███████║██║   ██║█████╗     ██║   
██╔═══╝ ██╔══██║██║   ██║██╔══╝     ██║   
██║     ██║  ██║╚██████╔╝███████╗   ██║   
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   

           Paqet Tunnel Multi-Instance
EOF

    echo "1- Install Core"
    echo "2- Configure Kharej Server"
    echo "3- Configure Iran Client"
    echo "0- Exit"
    echo

    read -rp "Select an option: " OPTION

    case "$OPTION" in
        1)
            echo "Installing Paqet Core..."
            cd /root/ || exit 1
            curl -L -o paqet-core.tar.gz https://raw.githubusercontent.com/A3is/p-t/master/paqet-core.tar.gz
            tar -xzf paqet-core.tar.gz
            rm -f paqet-core.tar.gz
            chmod -R 700 /root/paqet-core
            chown -R root:root /root/paqet-core
            echo -e "${GREEN}Paqet Core installed.${NC}"
            sleep 2
            ;;

        2)
            echo "Configure Kharej Server"
            while true; do
                read -rp "Enter server name (English only): " NAME
                [[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]] && break
                echo -e "${RED}Invalid name.${NC}"
            done

            CONFIG_FILE="/root/paqet-core/config-kharej-${NAME}.yaml"
            SERVICE_FILE="/etc/systemd/system/paqet-kharej-${NAME}.service"

            if [[ -f "$CONFIG_FILE" || -f "$SERVICE_FILE" ]]; then
                read -rp "Config or service exists. Replace? [y/N]: " ANS
                [[ "$ANS" =~ ^[Yy]$ ]] || continue
            fi

            while true; do
                read -rp "Enter Tunnel Port: " TunnelPort
                [[ "$TunnelPort" =~ ^[0-9]+$ ]] && ((TunnelPort>=1 && TunnelPort<=65535)) || { echo "Invalid port"; continue; }
                ss -lntup | grep -q ":$TunnelPort " && { echo "Port in use"; continue; }
                break
            done

            SERVER_INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
            SERVER_IP=$(ip -4 addr show "$SERVER_INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
            ROUTER_MAC=$(arp -n "$(ip route | awk '/default/ {print $3}')" | awk '/ether/ {print $3}')

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
EOF

            chmod 600 "$CONFIG_FILE"
            chown root:root "$CONFIG_FILE"

            EXEC_FILE="/root/paqet-core/paqet_linux_amd64"

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

            echo "Kharej server $NAME ready on port $TunnelPort"
            ;;

        3)
            echo "Configure Iran Client"
            while true; do
                read -rp "Enter client name (English only): " NAME
                [[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]] && break
                echo "Invalid name"
            done

            CONFIG_FILE="/root/paqet-core/config-iran-${NAME}.yaml"
            SERVICE_FILE="/etc/systemd/system/paqet-iran-${NAME}.service"

            if [[ -f "$CONFIG_FILE" || -f "$SERVICE_FILE" ]]; then
                read -rp "Config or service exists. Replace? [y/N]: " ANS
                [[ "$ANS" =~ ^[Yy]$ ]] || continue
            fi

            while true; do
                read -rp "Enter Kharej server IP: " KHAREJ_IP
                [[ "$KHAREJ_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && break
                echo "Invalid IP"
            done

            while true; do
                read -rp "Enter Tunnel Port: " TunnelPort
                [[ "$TunnelPort" =~ ^[0-9]+$ ]] && ((TunnelPort>=1 && TunnelPort<=65535)) || continue
                break
            done

            while true; do
                read -rp "Enter Socks Port: " IranPortSocks
                [[ "$IranPortSocks" =~ ^[0-9]+$ ]] && ((IranPortSocks>=1 && IranPortSocks<=65535)) || continue
                ss -lntup | grep -q ":$IranPortSocks " && { echo "Port in use"; continue; }
                break
            done

            SERVER_INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
            SERVER_IP=$(ip -4 addr show "$SERVER_INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
            ROUTER_MAC=$(arp -n "$(ip route | awk '/default/ {print $3}')" | awk '/ether/ {print $3}')

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
server:
  addr: "$KHAREJ_IP:${TunnelPort}"
transport:
  protocol: "kcp"
EOF

            chmod 600 "$CONFIG_FILE"
            chown root:root "$CONFIG_FILE"

            EXEC_FILE="/root/paqet-core/paqet_linux_amd64"

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

[Install]
WantedBy=multi-user.target
EOF

            chmod 644 "$SERVICE_FILE"
            chown root:root "$SERVICE_FILE"

            systemctl daemon-reload
            systemctl enable "paqet-iran-${NAME}"
            systemctl start "paqet-iran-${NAME}"

            echo "Iran client $NAME ready. Socks:$IranPortSocks Tunnel:$TunnelPort"
            ;;

        0)
            echo "Exiting..."
            exit 0
            ;;

        *)
            echo "Invalid option"
            ;;
    esac
done
