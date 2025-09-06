#!/bin/bash
# Script dựng SOCKS5 proxy Dante + gửi thông tin dạng IP:PORT:USER:PASS

install_dependencies() {
  export DEBIAN_FRONTEND=noninteractive
  apt update -y
  apt install -y dante-server curl iptables
}

setup_proxy_auto() {
  local PORT=8888
  local USERNAME="dailem"
  local PASSWORD="dailem2002"

  # Telegram thông tin cố định
  local BOT_TOKEN="8345542090:AAEBz6enEVCP56YzngmFYV7oVSvM-hMyp7E"
  local CHAT_ID="8188007230"

  # Cài gói cần thiết
  install_dependencies

  # Lấy interface mạng mặc định
  local PUBLIC_IP
  PUBLIC_IP=$(curl -s ifconfig.me)

  local IFACE
  IFACE=$(ip route get 1.1.1.1 | awk '{print $5; exit}')

  # Tạo cấu hình Dante
  cat >/etc/danted.conf <<EOF
logoutput: syslog
internal: 0.0.0.0 port = $PORT
external: $IFACE
socksmethod: username
user.notprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect error
}
EOF

  # Tạo user và đặt password
  id -u "$USERNAME" &>/dev/null || useradd -M -s /bin/false "$USERNAME"
  echo "$USERNAME:$PASSWORD" | chpasswd

  # Khởi động Dante
  systemctl restart danted
  systemctl enable danted

  # Mở firewall
  iptables -C INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null || \
    iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT

  # Gửi proxy dạng IP:PORT:USER:PASS về Telegram
  local PROXY_INFO="$PUBLIC_IP:$PORT:$USERNAME:$PASSWORD"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$PROXY_INFO"

  echo "[INFO] Proxy đã được dựng và gửi về Telegram dưới dạng IP:PORT:USER:PASS"
}

# Chạy script
setup_proxy_auto
