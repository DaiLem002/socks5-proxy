#!/bin/bash
# Script dựng SOCKS5 proxy với Dante + gửi thông tin về Telegram
# Port: 8888
# User: dailem
# Pass: dailem2002

install_dependencies() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y dante-server curl iptables
}

setup_proxy_fixed() {
  local PORT=8888
  local PASSWORD="dailem2002"
  local USERNAME="dailem"

  local BOT_TOKEN="$1"
  local USER_ID="$2"

  # Cài gói
  install_dependencies

  # Lấy interface mạng mặc định
  local IFACE
  IFACE=$(ip route get 1.1.1.1 | awk '{print $5; exit}')

  # Cấu hình Dante
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

  # Gửi thông tin về Telegram
  if [[ -n "$BOT_TOKEN" && -n "$USER_ID" ]]; then
    PUBLIC_IP=$(curl -s ifconfig.me)
    MSG="Proxy SOCKS5 đã sẵn sàng!
IP: $PUBLIC_IP
Port: $PORT
User: $USERNAME
Pass: $PASSWORD"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      -d chat_id="$USER_ID" \
      -d text="$MSG" >/dev/null
  fi
}

setup_proxy_fixed "$@"
