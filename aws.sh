#!/bin/bash
# AWS SOCKS5 Proxy setup using 3proxy (build from source)
# Tương thích Ubuntu 20.04/22.04/24.04

setup_proxy_single_port() {
    PROXY_PORT="$1"
    PROXY_PASSWORD="$2"
    ALLOW_IP="$3"
    ENABLE_TELEGRAM="$4"
    BOT_TOKEN="$5"
    USER_ID="$6"

    USERNAME="dailem"   # cố định user
    CONFIG_FILE="/etc/3proxy/3proxy.cfg"

    echo "[INFO] Installing dependencies..."
    apt update -y
    apt install -y git gcc make curl

    # Tải & build 3proxy nếu chưa có
    if [[ ! -f /usr/bin/3proxy ]]; then
        echo "[INFO] Building 3proxy from source..."
        cd /opt
        if [[ ! -d /opt/3proxy ]]; then
            git clone https://github.com/z3APA3A/3proxy.git
        fi
        cd 3proxy
        make -f Makefile.Linux
        cp src/3proxy /usr/bin/
    fi

    echo "[INFO] Creating 3proxy config at $CONFIG_FILE..."
    mkdir -p /etc/3proxy
    cat > "$CONFIG_FILE" <<EOCFG
daemon
auth strong
users $USERNAME:CL:$PROXY_PASSWORD
allow $USERNAME
socks -p$PROXY_PORT -a -i0.0.0.0 -e0.0.0.0
EOCFG

    echo "[INFO] Creating systemd service for 3proxy..."
    cat > /etc/systemd/system/3proxy.service <<EOSVC
[Unit]
Description=3proxy tiny proxy server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/3proxy $CONFIG_FILE
Restart=always

[Install]
WantedBy=multi-user.target
EOSVC

    systemctl daemon-reload
    systemctl enable 3proxy
    systemctl restart 3proxy

    sleep 2
    if systemctl is-active --quiet 3proxy; then
        echo "[INFO] 3proxy started successfully on port $PROXY_PORT"
    else
        echo "[ERR] 3proxy failed to start. Check logs with: journalctl -u 3proxy -xe"
    fi

    # Lấy IP public
    PUBLIC_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

    # Gửi thông báo Telegram nếu bật
    if [[ "$ENABLE_TELEGRAM" == "1" && -n "$BOT_TOKEN" && -n "$USER_ID" ]]; then
        MSG="SOCKS5 proxy đã sẵn sàng%0AIP: $PUBLIC_IP%0APort: $PROXY_PORT%0AUser: $USERNAME%0APass: $PROXY_PASSWORD"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$USER_ID" \
            -d text="$MSG" > /dev/null
        echo "[INFO] Telegram notification sent."
    else
        echo "[INFO] Telegram notification disabled."
    fi
}
