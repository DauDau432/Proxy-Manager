#!/bin/bash

# Màu sắc cho giao diện
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Hàm kiểm tra quyền root
check_root() {
    if [ "$(whoami)" != "root" ]; then
        echo -e "${RED}LỖI: Bạn cần chạy script với quyền root hoặc sử dụng sudo.${NC}"
        exit 1
    fi
}

# Hàm sinh cổng ngẫu nhiên
generate_random_port() {
    while true; do
        PORT=$(shuf -i 10000-65535 -n 1)
        if ! netstat -tuln | grep -q ":$PORT "; then
            echo $PORT
            break
        fi
    done
}

# Hàm kiểm tra hệ điều hành
check_os() {
    if [ ! -f /usr/local/bin/sok-find-os ]; then
        echo -e "${RED}Không tìm thấy /usr/local/bin/sok-find-os${NC}"
        exit 1
    fi
    SOK_OS=$(/usr/local/bin/sok-find-os)
    if [ "$SOK_OS" == "ERROR" ]; then
        echo -e "${RED}Hệ điều hành không được hỗ trợ.${NC}"
        exit 1
    fi
    echo "$SOK_OS"
}

# Hàm kiểm tra trạng thái Squid và hiển thị thông tin proxy
check_squid_status() {
    if [[ -d /etc/squid/ || -d /etc/squid3/ ]]; then
        echo -e "${GREEN}Squid Proxy đã được cài đặt.${NC}"
        # Lấy IP công cộng
        response=$(curl -s https://api.myip.com)
        ip=$(echo "$response" | jq -r '.ip')
        # Lấy cổng từ tệp cấu hình
        if [ -f /etc/squid/squid.conf ]; then
            port=$(grep -E "^http_port" /etc/squid/squid.conf | awk '{print $2}')
        elif [ -f /etc/squid3/squid.conf ]; then
            port=$(grep -E "^http_port" /etc/squid3/squid.conf | awk '{print $2}')
        else
            port="Không xác định"
        fi
        # Lấy danh sách user
        echo -e "${GREEN}Thông tin proxy hiện tại:${NC}"
        echo -e "IP: $ip"
        echo -e "Cổng: $port"
        if [ -f /etc/squid/passwd ]; then
            echo -e "Danh sách người dùng:"
            awk -F: '{print "  - " $1}' /etc/squid/passwd | nl
        else
            echo -e "Không có người dùng nào."
        fi
        # Kiểm tra trạng thái dịch vụ
        if systemctl is-active squid >/dev/null 2>&1; then
            echo -e "Trạng thái dịch vụ: ${GREEN}Đang chạy${NC}"
        else
            echo -e "Trạng thái dịch vụ: ${RED}Không chạy${NC}"
        fi
        return 0
    else
        echo -e "${RED}Squid Proxy chưa được cài đặt.${NC}"
        return 1
    fi
}

# Hàm cài đặt Squid
install_squid() {
    if check_squid_status; then
        echo -e "${RED}Squid Proxy đã được cài đặt. Vui lòng sử dụng các tùy chọn khác hoặc chạy 'squid-uninstall' để cài lại.${NC}"
        return
    fi
    SOK_OS=$(check_os)
    PORT=$(generate_random_port)
    echo -e "${GREEN}Đang cài đặt Squid Proxy trên cổng $PORT...${NC}"

    # Cài đặt công cụ cần thiết
    yum install wget -y 2>/dev/null || apt install wget -y 2>/dev/null
    wget -q --no-check-certificate -O /usr/local/bin/sok-find-os https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/sok-find-os.sh
    wget -q --no-check-certificate -O /usr/local/bin/squid-uninstall https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid-uninstall.sh
    wget -q --no-check-certificate -O /usr/local/bin/squid-add-user https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid-add-user.sh
    chmod 755 /usr/local/bin/sok-find-os /usr/local/bin/squid-uninstall /usr/local/bin/squid-add-user

    # Cài đặt Squid theo hệ điều hành
    case $SOK_OS in
        ubuntu2204|ubuntu2004|ubuntu1804|ubuntu1604)
            apt install jq apache2-utils squid -y
            touch /etc/squid/passwd /etc/squid/blacklist.acl
            mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid.conf
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf
            iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
            iptables-save
            systemctl enable squid
            systemctl restart squid
            ;;
        debian11|debian12)
            apt install jq apache2-utils squid -y
            touch /etc/squid/passwd /etc/squid/blacklist.acl
            rm -f /etc/squid/squid.conf
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid.conf
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf
            iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
            iptables-save
            systemctl enable squid
            systemctl restart squid
            ;;
        centos7|centos8|almalinux8|almalinux9|centos9)
            yum install squid httpd-tools jq -y
            touch /etc/squid/blacklist.acl
            mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/conf/squid-centos7.conf
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf
            firewall-cmd --zone=public --permanent --add-port=$PORT/tcp
            firewall-cmd --reload
            systemctl enable squid
            systemctl restart squid
            ;;
        *)
            echo -e "${RED}Hệ điều hành không được hỗ trợ: $SOK_OS${NC}"
            exit 1
            ;;
    esac

    # Thêm tài khoản proxy
    read -p "Nhập tên người dùng proxy: " usernamesquid
    read -p "Nhập mật khẩu proxy: " passwordsquid
    htpasswd -b -c /etc/squid/passwd "$usernamesquid" "$passwordsquid"

    # Lấy IP công cộng
    response=$(curl -s https://api.myip.com)
    ip=$(echo "$response" | jq -r '.ip')
    echo -e "${GREEN}Cài đặt Proxy HTTP/HTTPS thành công. Proxy: $ip:$PORT:$usernamesquid:$passwordsquid${NC}"
}

# Hàm thêm tài khoản proxy
add_user() {
    read -p "Nhập tên người dùng proxy mới: " usernamesquid
    read -p "Nhập mật khẩu proxy mới: " passwordsquid
    htpasswd -b /etc/squid/passwd "$usernamesquid" "$passwordsquid"
    echo -e "${GREEN}Thêm người dùng $usernamesquid thành công.${NC}"
}

# Hàm liệt kê danh sách user
list_users() {
    if [ -f /etc/squid/passwd ]; then
        echo -e "${GREEN}Danh sách người dùng proxy hiện có:${NC}"
        awk -F: '{print $1}' /etc/squid/passwd | nl
    else
        echo -e "${RED}Không tìm thấy tệp /etc/squid/passwd. Chưa có người dùng nào được tạo.${NC}"
    fi
}

# Hàm xóa tài khoản proxy
delete_user() {
    list_users
    read -p "Nhập tên người dùng cần xóa: " usernamesquid
    if htpasswd -D /etc/squid/passwd "$usernamesquid" 2>/dev/null; then
        echo -e "${GREEN}Xóa người dùng $usernamesquid thành công.${NC}"
    else
        echo -e "${RED}Không tìm thấy người dùng $usernamesquid.${NC}"
    fi
}

# Hàm thay đổi cổng proxy
change_port() {
    if ! check_squid_status; then
        echo -e "${RED}Squid Proxy chưa được cài đặt. Vui lòng cài đặt trước khi thay đổi cổng.${NC}"
        return
    fi
    SOK_OS=$(check_os)
    PORT=$(generate_random_port)
    echo -e "${GREEN}Đang thay đổi cổng Squid thành $PORT...${NC}"
    if [ -f /etc/squid/squid.conf ]; then
        sed -i "s/http_port [0-9]\+/http_port $PORT/" /etc/squid/squid.conf
    elif [ -f /etc/squid3/squid.conf ]; then
        sed -i "s/http_port [0-9]\+/http_port $PORT/" /etc/squid3/squid.conf
    fi
    if [[ $SOK_OS == centos* || $SOK_OS == almalinux* ]]; then
        firewall-cmd --zone=public --permanent --remove-port=3128/tcp
        firewall-cmd --zone=public --permanent --add-port=$PORT/tcp
        firewall-cmd --reload
    else
        iptables -D INPUT -p tcp --dport 3128 -j ACCEPT
        iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
        iptables-save
    fi
    systemctl restart squid
    echo -e "${GREEN}Thay đổi cổng thành $PORT thành công.${NC}"
}

# Hàm hiển thị menu
show_menu() {
    clear
    echo -e "${GREEN}=== Menu Quản Lý Squid Proxy ===${NC}"
    echo "1. Cài đặt Squid Proxy"
    echo "2. Thêm người dùng Proxy"
    echo "3. Xóa người dùng Proxy"
    echo "4. Thay đổi cổng Proxy"
    echo "5. Xem trạng thái Proxy"
    echo "6. Thoát"
    read -p "Chọn một tùy chọn [1-6]: " choice
    case $choice in
        1) install_squid ;;
        2) add_user ;;
        3) delete_user ;;
        4) change_port ;;
        5) check_squid_status ;;
        6) exit 0 ;;
        *) echo -e "${RED}Tùy chọn không hợp lệ!${NC}"; sleep 2; show_menu ;;
    esac
}

# Kiểm tra quyền root và hiển thị menu
check_root
while true; do
    show_menu
done
