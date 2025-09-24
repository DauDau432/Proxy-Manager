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

# Hàm lấy danh sách IPv4
get_ips() {
    mapfile -t IPS < <(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d'/' -f1)
    if [ ${#IPS[@]} -eq 0 ]; then
        echo -e "${RED}Không tìm thấy địa chỉ IPv4.${NC}"
        exit 1
    fi
}

# Hàm cài phụ thuộc chung
install_dependencies() {
    echo -e "${GREEN}Đang cài đặt các gói phụ thuộc cơ bản...${NC}"
    if command -v apt >/dev/null 2>&1; then
        apt update >/dev/null 2>&1
        apt install wget net-tools jq -y >/dev/null 2>&1 || {
            echo -e "${RED}Không thể cài wget, net-tools hoặc jq qua apt.${NC}"
            exit 1
        }
    elif command -v yum >/dev/null 2>&1; then
        yum install wget net-tools jq -y >/dev/null 2>&1 || {
            echo -e "${RED}Không thể cài wget, net-tools hoặc jq qua yum.${NC}"
            exit 1
        }
    elif command -v dnf >/dev/null 2>&1; then
        dnf install wget net-tools jq -y >/dev/null 2>&1 || {
            echo -e "${RED}Không thể cài wget, net-tools hoặc jq qua dnf.${NC}"
            exit 1
        }
    else
        echo -e "${RED}Không tìm thấy trình quản lý gói (apt/yum/dnf).${NC}"
        exit 1
    fi
}

# Hàm tải sok-find-os
download_sok_find_os() {
    wget -q --no-check-certificate -O /usr/local/bin/sok-find-os https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/sok-find-os.sh >/dev/null 2>&1
    chmod 755 /usr/local/bin/sok-find-os
    if [ ! -f /usr/local/bin/sok-find-os ]; then
        echo -e "${RED}Không thể tải sok-find-os.${NC}"
        exit 1
    fi
}

# Hàm kiểm tra hệ điều hành
check_os() {
    SOK_OS=$(/usr/local/bin/sok-find-os)
    if [ "$SOK_OS" == "ERROR" ]; then
        echo -e "${RED}Hệ điều hành không được hỗ trợ.${NC}"
        exit 1
    fi
    echo "$SOK_OS"
}

# Hàm sinh cổng ngẫu nhiên
generate_random_port() {
    local port
    local attempts=0
    while true; do
        port=$(shuf -i 10000-65535 -n 1)
        if ! netstat -tuln | grep -q ":$port "; then
            echo "$port"
            break
        fi
        attempts=$((attempts+1))
        if [ $attempts -gt 10 ]; then
            echo -e "${RED}Không tìm được cổng trống sau 10 lần thử.${NC}"
            exit 1
        fi
    done
}

# Hàm kiểm tra trạng thái Squid
check_squid_status() {
    echo -e "${GREEN}=== Kiểm tra trạng thái Squid Proxy ===${NC}"
    if [[ -d /etc/squid/ || -d /etc/squid3/ ]]; then
        echo -e "${GREEN}Squid Proxy đã được cài đặt.${NC}"
        # Lấy danh sách IP
        get_ips
        # Lấy cổng
        if [ -f /etc/squid/squid.conf ]; then
            port=$(grep -E "^http_port" /etc/squid/squid.conf | awk '{print $2}' || echo "Không xác định")
        elif [ -f /etc/squid3/squid.conf ]; then
            port=$(grep -E "^http_port" /etc/squid3/squid.conf | awk '{print $2}' || echo "Không xác định")
        else
            port="Không xác định"
        fi
        # Hiển thị thông tin
        echo -e "${GREEN}Thông tin proxy hiện tại:${NC}"
        for ip in "${IPS[@]}"; do
            echo -e " IP: $ip, Cổng: $port"
        done
        if [ -f /etc/squid/passwd ]; then
            echo -e " Danh sách người dùng:"
            grep -v '^$' /etc/squid/passwd | awk -F: '{print "  " $1}'
        else
            echo -e " Không có người dùng nào."
        fi
        if systemctl is-active squid >/dev/null 2>&1; then
            echo -e " Trạng thái dịch vụ: ${GREEN}Đang chạy${NC}"
        else
            echo -e " Trạng thái dịch vụ: ${RED}Không chạy${NC}"
        fi
        echo -e "${GREEN}Kiểm tra proxy: curl --proxy http://<user>:<pass>@<IP>:$port https://www.google.com${NC}"
        return 0
    else
        echo -e "${RED}Squid Proxy chưa được cài đặt.${NC}"
        return 1
    fi
}

# Hàm cài đặt Squid
install_squid() {
    if check_squid_status; then
        echo -e "${RED}Squid đã được cài đặt. Chạy 'squid-uninstall' để gỡ trước khi cài lại.${NC}"
        return
    fi
    SOK_OS=$(check_os)
    PORT=$(generate_random_port)
    echo -e "${GREEN}Đang cài đặt Squid Proxy trên cổng $PORT...${NC}"

    # Tải script bổ trợ
    wget -q --no-check-certificate -O /usr/local/bin/squid-uninstall https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid-uninstall.sh >/dev/null 2>&1
    wget -q --no-check-certificate -O /usr/local/bin/squid-add-user https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid-add-user.sh >/dev/null 2>&1
    chmod 755 /usr/local/bin/squid-uninstall /usr/local/bin/squid-add-user

    # Cài đặt Squid theo OS
    case $SOK_OS in
        ubuntu2204|ubuntu2004|ubuntu1804|ubuntu1604|ubuntu1404)
            apt install apache2-utils squid -y >/dev/null 2>&1 || { echo -e "${RED}Lỗi cài squid.${NC}"; exit 1; }
            mkdir -p /etc/squid
            touch /etc/squid/passwd /etc/squid/blacklist.acl
            mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/conf/ubuntu-2204.conf >/dev/null 2>&1 || { echo -e "${RED}Lỗi tải config.${NC}"; exit 1; }
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf
            if [ -f /sbin/iptables ]; then
                iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
                iptables-save >/dev/null 2>&1 || echo -e "${RED}Lỗi lưu iptables.${NC}"
            fi
            systemctl enable squid >/dev/null 2>&1
            systemctl restart squid || { echo -e "${RED}Lỗi khởi động squid.${NC}"; exit 1; }
            ;;
        debian12|debian11|debian10|debian9|debian8)
            apt install apache2-utils squid -y >/dev/null 2>&1 || { echo -e "${RED}Lỗi cài squid.${NC}"; exit 1; }
            rm -rf /etc/squid >/dev/null 2>&1
            mkdir -p /etc/squid
            touch /etc/squid/passwd /etc/squid/blacklist.acl
            if [ "$SOK_OS" == "debian12" ]; then
                mkdir -p /etc/squid/conf.d
                wget -q --no-check-certificate -O /etc/squid/conf.d/serverok.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/conf/debian12.conf >/dev/null 2>&1
            else
                wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid.conf >/dev/null 2>&1
            fi
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf 2>/dev/null
            if [ -f /sbin/iptables ]; then
                iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
                iptables-save >/dev/null 2>&1 || echo -e "${RED}Lỗi lưu iptables.${NC}"
            fi
            systemctl enable squid >/dev/null 2>&1
            systemctl restart squid || { echo -e "${RED}Lỗi khởi động squid.${NC}"; exit 1; }
            ;;
        centos7|centos8|centos8s|centos9|almalinux8|almalinux9)
            if [ "$SOK_OS" == "centos7" ]; then
                yum install squid httpd-tools -y >/dev/null 2>&1 || { echo -e "${RED}Lỗi cài squid.${NC}"; exit 1; }
            else
                dnf install squid httpd-tools -y >/dev/null 2>&1 || yum install squid httpd-tools -y >/dev/null 2>&1 || { echo -e "${RED}Lỗi cài squid.${NC}"; exit 1; }
            fi
            touch /etc/squid/blacklist.acl
            mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/conf/squid-centos7.conf >/dev/null 2>&1 || { echo -e "${RED}Lỗi tải config.${NC}"; exit 1; }
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf
            if [ -f /usr/bin/firewall-cmd ]; then
                firewall-cmd --zone=public --permanent --add-port=$PORT/tcp >/dev/null 2>&1
                firewall-cmd --reload >/dev/null 2>&1 || echo -e "${RED}Lỗi reload firewall.${NC}"
            fi
            systemctl enable squid >/dev/null 2>&1
            systemctl restart squid || { echo -e "${RED}Lỗi khởi động squid.${NC}"; exit 1; }
            ;;
        *)
            echo -e "${RED}Hệ điều hành không được hỗ trợ: $SOK_OS${NC}"
            exit 1
            ;;
    esac

    # Thêm tài khoản proxy
    echo -e "${GREEN}Đang tạo tài khoản proxy...${NC}"
    read -p "Nhập tên người dùng proxy: " usernamesquid
    read -p "Nhập mật khẩu proxy: " passwordsquid
    htpasswd -b -c /etc/squid/passwd "$usernamesquid" "$passwordsquid" || { echo -e "${RED}Lỗi thêm user.${NC}"; exit 1; }

    # Hiển thị thông tin proxy
    get_ips
    echo -e "${GREEN}Cài đặt Proxy thành công:${NC}"
    for ip in "${IPS[@]}"; do
        echo -e " Proxy: $ip:$PORT:$usernamesquid:$passwordsquid"
    done
}

# Hàm thêm tài khoản proxy
add_user() {
    if [ ! -f /etc/squid/passwd ]; then
        echo -e "${RED}Chưa cài Squid. Vui lòng cài trước.${NC}"
        return
    fi
    echo -e "${GREEN}Đang tạo tài khoản mới...${NC}"
    read -p "Nhập tên người dùng: " usernamesquid
    read -p "Nhập mật khẩu: " passwordsquid
    htpasswd -b /etc/squid/passwd "$usernamesquid" "$passwordsquid" && echo -e "${GREEN}Thêm user $usernamesquid thành công.${NC}" || echo -e "${RED}Lỗi thêm user.${NC}"
}

# Hàm liệt kê danh sách user
list_users() {
    if [ -f /etc/squid/passwd ]; then
        echo -e "${GREEN}Danh sách người dùng:${NC}"
        grep -v '^$' /etc/squid/passwd | awk -F: '{print "  " $1}'
    else
        echo -e "${RED}Chưa có user.${NC}"
    fi
}

# Hàm xóa tài khoản proxy
delete_user() {
    if [ ! -f /etc/squid/passwd ]; then
        echo -e "${RED}Chưa cài Squid.${NC}"
        return
    fi
    echo -e "${GREEN}Đang xóa user...${NC}"
    list_users
    read -p "Nhập tên user cần xóa: " usernamesquid
    if grep -q "^$usernamesquid:" /etc/squid/passwd; then
        htpasswd -D /etc/squid/passwd "$usernamesquid" && echo -e "${GREEN}Xóa user $usernamesquid thành công.${NC}" || echo -e "${RED}Lỗi xóa user.${NC}"
    else
        echo -e "${RED}Không tìm thấy user $usernamesquid.${NC}"
    fi
}

# Hàm thay đổi cổng proxy
change_port() {
    if ! check_squid_status; then
        echo -e "${RED}Chưa cài Squid.${NC}"
        return
    fi
    SOK_OS=$(check_os)
    OLD_PORT=$(grep -E "^http_port" /etc/squid/squid.conf | awk '{print $2}' 2>/dev/null || echo "3128")
    NEW_PORT=$(generate_random_port)
    echo -e "${GREEN}Đang thay cổng từ $OLD_PORT thành $NEW_PORT...${NC}"

    sed -i "s/http_port $OLD_PORT/http_port $NEW_PORT/" /etc/squid/squid.conf || { echo -e "${RED}Lỗi cập nhật config.${NC}"; return; }

    if [[ $SOK_OS == centos* || $SOK_OS == almalinux* ]]; then
        if [ -f /usr/bin/firewall-cmd ]; then
            firewall-cmd --zone=public --permanent --remove-port=$OLD_PORT/tcp >/dev/null 2>&1
            firewall-cmd --zone=public --permanent --add-port=$NEW_PORT/tcp >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1 || echo -e "${RED}Lỗi reload firewall.${NC}"
        fi
    else
        if [ -f /sbin/iptables ]; then
            iptables -D INPUT -p tcp --dport $OLD_PORT -j ACCEPT 2>/dev/null
            iptables -I INPUT -p tcp --dport $NEW_PORT -j ACCEPT
            iptables-save >/dev/null 2>&1 || echo -e "${RED}Lỗi lưu iptables.${NC}"
        fi
    fi

    systemctl restart squid || { echo -e "${RED}Lỗi khởi động lại squid.${NC}"; return; }
    echo -e "${GREEN}Thay cổng thành công: $NEW_PORT${NC}"
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
    echo "0. Thoát"
    read -p "Chọn một tùy chọn [0-5]: " choice
    case $choice in
        1) install_squid ;;
        2) add_user ;;
        3) delete_user ;;
        4) change_port ;;
        5) check_squid_status ;;
        0) exit 0 ;;
        *) echo -e "${RED}Tùy chọn không hợp lệ!${NC}" ;;
    esac
    read -p "Nhấn Enter để tiếp tục..."
}

# Chạy script
check_root
install_dependencies
download_sok_find_os
while true; do
    show_menu
done
