#!/bin/bash
# AWS SOCKS5 Proxy Setup Script – by DaiLem002

install_dependencies() {
  command -v danted &>/dev/null && return
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y dante-server curl iptables
}

setup_proxy_single_port() {
  local PORT="$1" PASSWORD="$2" ALLOW_IP="$3"
  local ENABLE_TELEGRAM="$4" BOT_TOKEN="$5" USER_ID="$6"
  local USERNAME="dailem"

  if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1024 || PORT > 65535 )); then
    echo "[ERR] Port $PORT không hợp lệ." >&2
    return 1
  fi

  echo "[INFO] Cài đặt phụ thuộc..."
  install_dependencies

  local IFACE
  IFACE=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
  [[ -z "$IFACE" ]] && echo "[ERR] Không tìm thấy interface mạng." && return 1

  echo "[INFO] Tạo cấu hình Dante..."
  cat > /etc/danted.conf <<EOF
internal: $IFACE port = $PORT
external: $IFACE

method: username
user.notprivileged: nobody

client pass {
  from: $ALLOW_IP to: 0.0.0.0/0
}

pass {
  from: $ALLOW_IP to: 0.0.0.0/0
  protocol: tcp udp
  method: username
}
EOF

  echo "[INFO] Tạo user proxy..."
  userdel -r "$USERNAME" 2>/dev/null || true
  useradd -M -s /bin/false "$USERNAME"
  echo "$USERNAME:$PASSWORD" | chpasswd

  echo "[INFO] Khởi động dịch vụ danted..."
  systemctl restart danted
  systemctl enable danted
  if ! systemctl is-active --quiet danted; then
    echo "[ERR] Dịch vụ danted không khởi động được." >&2
    return 1
  fi

  echo "[INFO] Mở port firewall..."
  iptables -C INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null || \
  iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT

  # Gửi Telegram nếu bật
  if [[ "$ENABLE_TELEGRAM" == "1" && -n "$BOT_TOKEN" && -n "$USER_ID" ]]; then
    local IP
    IP=$(curl -s ifconfig.me)
    local MSG="🧦 <b>Proxy SOCKS5 đã sẵn sàng</b>%0A🌐 IP: <code>$IP</code>%0A📶 Port: <code>$PORT</code>%0A👤 User: <code>$USERNAME</code>%0A🔑 Pass: <code>$PASSWORD</code>"

    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      -d chat_id="$USER_ID" \
      -d parse_mode="HTML" \
      -d text="$MSG"
    echo "[INFO] Đã gửi proxy về Telegram."
  fi
}
