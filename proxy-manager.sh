#!/bin/bash
CONFIG="/usr/local/3proxy/conf/3proxy.cfg"
SERVICE="/etc/systemd/system/3proxy.service"
INSTALL_DIR="/usr/local/3proxy"
RESERVED_PORTS="22 25 53 80 443 3306 3389"

# Hàm lấy IP public
get_ip() {
    curl -s ifconfig.me || hostname -I | awk '{print $1}'
}

# Hàm đọc trạng thái proxy
get_status() {
    HTTP_STATUS="TAT"
    SOCKS_STATUS="TAT"

    if grep -q "^proxy" $CONFIG 2>/dev/null; then
        PORT=$(grep "^proxy" $CONFIG | awk -F"-p" '{print $2}')
        if grep -q "^users" $CONFIG; then
            AUTH=$(grep "^users" $CONFIG | awk -F: '{print $2}')
            HTTP_STATUS="BAT (Port: $PORT, Auth: $AUTH)"
        else
            HTTP_STATUS="BAT (Port: $PORT, Auth: TAT)"
        fi
    fi

    if grep -q "^socks" $CONFIG 2>/dev/null; then
        PORT=$(grep "^socks" $CONFIG | awk -F"-p" '{print $2}')
        if grep -q "^users" $CONFIG; then
            AUTH=$(grep "^users" $CONFIG | awk -F: '{print $2}')
            SOCKS_STATUS="BAT (Port: $PORT, Auth: $AUTH)"
        else
            SOCKS_STATUS="BAT (Port: $PORT, Auth: TAT)"
        fi
    fi
}

# Hàm in header menu
print_header() {
    clear
    get_status
    echo "================== TRANG THAI HIEN TAI =================="
    echo "IP VPS: $(get_ip)"
    echo "HTTP Proxy: $HTTP_STATUS"
    echo "SOCKS5 Proxy: $SOCKS_STATUS"
    echo "=========================================================="
    echo
}

# Hàm cài đặt 3proxy
install_3proxy() {
    if [ -x "$INSTALL_DIR/bin/3proxy" ]; then
        echo "[*] 3proxy da duoc cai dat."
        read -p "Nhan Enter de quay lai menu..."
        return
    fi
    apt update -y && apt install -y build-essential wget curl
    mkdir -p /usr/local/src
    cd /usr/local/src
    wget https://github.com/z3APA3A/3proxy/archive/refs/tags/0.9.4.tar.gz -O 3proxy.tar.gz
    tar xzf 3proxy.tar.gz
    cd 3proxy-0.9.4
    make -f Makefile.Linux
    mkdir -p $INSTALL_DIR
    cp -R bin/* $INSTALL_DIR/
    mkdir -p $INSTALL_DIR/conf
    touch $CONFIG

    # Tao service
    cat > $SERVICE <<EOF
[Unit]
Description=3proxy Proxy Server
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/bin/3proxy $CONFIG
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reexec
    systemctl enable 3proxy
    systemctl start 3proxy
    echo "[+] Cai dat 3proxy hoan tat!"
    read -p "Nhan Enter de quay lai menu..."
}

# Hàm gỡ cài đặt 3proxy
uninstall_3proxy() {
    systemctl stop 3proxy 2>/dev/null
    systemctl disable 3proxy 2>/dev/null
    rm -f $SERVICE
    rm -rf $INSTALL_DIR
    echo "" > $CONFIG
    systemctl daemon-reexec
    echo "[-] Da go cai dat 3proxy."
    read -p "Nhan Enter de quay lai menu..."
}

# Hàm yêu cầu nhập port hợp lệ
ask_port() {
    while true; do
        read -p "Nhap port: " PORT
        if [[ ! "$PORT" =~ ^[0-9]+$ ]]; then
            echo "[!] Port khong hop le!"
            continue
        fi
        if echo "$RESERVED_PORTS" | grep -qw "$PORT"; then
            echo "[!] Port $PORT da duoc he thong su dung, chon port khac."
            continue
        fi
        break
    done
}

# Cấu hình HTTP Proxy
manage_http() {
    while true; do
        print_header
        echo "----- QUAN LY HTTP PROXY -----"
        echo "[1] Bat / Thay doi HTTP Proxy"
        echo "[2] Tat HTTP Proxy"
        echo "[3] Bat / Tat xac thuc"
        echo "[0] Quay lai menu chinh"
        read -p "=> Chon: " choice
        case $choice in
            1)
                ask_port
                read -p "Co bat xac thuc (y/n)? " yn
                if [[ "$yn" == "y" ]]; then
                    read -p "Nhap username: " USER
                    read -p "Nhap password: " PASS
                    AUTH="users $USER:CL:$PASS"$'\n'"allow $USER"
                else
                    AUTH="auth none"
                fi
                cat > $CONFIG <<EOF
daemon
maxconn 200
nserver 8.8.8.8
nserver 8.8.4.4
nscache 65536
auth strong
$AUTH
proxy -n -a -p$PORT
EOF
                systemctl restart 3proxy
                ;;
            2)
                sed -i '/^proxy/d' $CONFIG
                systemctl restart 3proxy
                ;;
            3)
                if grep -q "^users" $CONFIG; then
                    sed -i '/^users/d;/^allow/d' $CONFIG
                    sed -i 's/^auth strong/auth none/' $CONFIG
                else
                    read -p "Nhap username: " USER
                    read -p "Nhap password: " PASS
                    sed -i '/^auth none/d' $CONFIG
                    echo "users $USER:CL:$PASS" >> $CONFIG
                    echo "allow $USER" >> $CONFIG
                fi
                systemctl restart 3proxy
                ;;
            0) return ;;
        esac
    done
}

# Cấu hình SOCKS5 Proxy
manage_socks() {
    while true; do
        print_header
        echo "----- QUAN LY SOCKS5 PROXY -----"
        echo "[1] Bat / Thay doi SOCKS5 Proxy"
        echo "[2] Tat SOCKS5 Proxy"
        echo "[3] Bat / Tat xac thuc"
        echo "[0] Quay lai menu chinh"
        read -p "=> Chon: " choice
        case $choice in
            1)
                ask_port
                read -p "Co bat xac thuc (y/n)? " yn
                if [[ "$yn" == "y" ]]; then
                    read -p "Nhap username: " USER
                    read -p "Nhap password: " PASS
                    AUTH="users $USER:CL:$PASS"$'\n'"allow $USER"
                else
                    AUTH="auth none"
                fi
                cat > $CONFIG <<EOF
daemon
maxconn 200
nserver 8.8.8.8
nserver 8.8.4.4
nscache 65536
auth strong
$AUTH
socks -p$PORT
EOF
                systemctl restart 3proxy
                ;;
            2)
                sed -i '/^socks/d' $CONFIG
                systemctl restart 3proxy
                ;;
            3)
                if grep -q "^users" $CONFIG; then
                    sed -i '/^users/d;/^allow/d' $CONFIG
                    sed -i 's/^auth strong/auth none/' $CONFIG
                else
                    read -p "Nhap username: " USER
                    read -p "Nhap password: " PASS
                    sed -i '/^auth none/d' $CONFIG
                    echo "users $USER:CL:$PASS" >> $CONFIG
                    echo "allow $USER" >> $CONFIG
                fi
                systemctl restart 3proxy
                ;;
            0) return ;;
        esac
    done
}

# Menu chính
while true; do
    print_header
    echo "========= MENU ========="
    echo "[1] Cai dat 3proxy"
    echo "[2] Quan ly HTTP Proxy"
    echo "[3] Quan ly SOCKS5 Proxy"
    echo "[4] Restart 3proxy"
    echo "[5] Go cai dat 3proxy"
    echo "[0] Thoat"
    echo "========================="
    read -p "=> Chon: " choice
    case $choice in
        1) install_3proxy ;;
        2) manage_http ;;
        3) manage_socks ;;
        4) systemctl restart 3proxy ;;
        5) uninstall_3proxy ;;
        0) exit 0 ;;
    esac
done
