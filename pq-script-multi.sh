        2)
            echo
            echo "Configuring Paqet service for KharejServer..."
            echo

            # ---------- Get name ----------
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

            # ---------- Tunnel Port ----------
            while true; do
                read -rp "Enter Tunnel Port: " TUNNEL_PORT
                [[ "$TUNNEL_PORT" =~ ^[0-9]+$ ]] && ((TUNNEL_PORT>=1 && TUNNEL_PORT<=65535)) || {
                    echo -e "${RED}Invalid port.${NC}"; continue; }
                ss -lntup | grep -q ":$TUNNEL_PORT " && {
                    echo -e "${RED}Port already in use.${NC}"; continue; }
                break
            done

            SERVER_INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
            SERVER_IP=$(ip -4 addr show "$SERVER_INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
            ROUTER_MAC=$(arp -n "$(ip route | awk '/default/ {print $3}')" | awk '/ether/ {print $3}')

            cat > "$CONFIG_FILE" << EOF
role: "server"
log:
  level: "error"
listen:
  addr: "0.0.0.0:${TUNNEL_PORT}"
network:
  interface: "$SERVER_INTERFACE"
  ipv4:
    addr: "$SERVER_IP:${TUNNEL_PORT}"
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
EOF

            chmod 600 "$CONFIG_FILE"

            EXEC_FILE="/root/paqet-core/paqet_linux_amd64"

            cat > "$SERVICE_FILE" << EOF
[Service]
ExecStart=$EXEC_FILE run -c $CONFIG_FILE
Restart=always
EOF

            systemctl daemon-reload
            systemctl enable "paqet-kharej-${NAME}"
            systemctl start "paqet-kharej-${NAME}"

            iptables -t raw -A PREROUTING -p tcp --dport "$TUNNEL_PORT" -j NOTRACK
            iptables -t raw -A OUTPUT -p tcp --sport "$TUNNEL_PORT" -j NOTRACK

            echo -e "${GREEN}Kharej server ${NAME} ready.${NC}"
            continue
            ;;
