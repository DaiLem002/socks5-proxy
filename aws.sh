#!/bin/bash

# Lựa chọn proxy type
read -p "Chọn loại proxy (SOCKS5): " proxy_type
# Lựa chọn provider
read -p "Chọn nhà cung cấp VPS (Vultr): " provider
# Lựa chọn OS
read -p "Chọn OS (Ubuntu): " os_type

# Nhập token và chat ID Telegram
read -p "Nhập Telegram Bot Token: " tg_token
read -p "Nhập Telegram Chat ID: " chat_id

# Nhập thông tin proxy
read -p "Nhập cổng proxy (8888): " port
read -p "Nhập username: " dailem
read -p "Nhập password: " dailem2002

# Cài đặt dante-server nếu chọn SOCKS5
if [[ "$proxy_type" == "1" ]]; then
    apt update -y
    apt install dante-server -y

    cat > /etc/danted.conf <<EOF
logoutput: /var/log/danted.log
internal: 0.0.0.0 port = $port
external: eth0
method: username
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

    useradd $user
    echo "$user:$pass" | chpasswd

    systemctl restart danted
    systemctl enable danted

    proxy_type_name="SOCKS5"
else
    echo "Chưa hỗ trợ loại proxy này"
    exit 1
fi

# Lấy IP public
ip=$(curl -s ifconfig.me)

# Gửi thông tin qua Telegram
msg="Proxy $proxy_type_name đã sẵn sàng ✅%0A%0A🔌 Proxy: <code>$ip:$port</code>%0A👤 User: <code>$user</code>%0A🔑 Pass: <code>$pass</code>"

curl -s -X POST "https://api.telegram.org/bot$tg_token/sendMessage" \
    -d chat_id="$chat_id" \
    -d parse_mode="HTML" \
    -d text="$msg"
