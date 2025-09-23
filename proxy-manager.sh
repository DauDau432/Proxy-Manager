#!/bin/bash

# Màu sắc cho giao diện
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Hàm kiểm tra quyền root
check_root() {
    if [ "$(whoami)" != "root" ]; then
        echo -e "${RED}LỖI: Bạn cần chạy script với quyền root hoặc sử dụng sudo.${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        exit 1
    fi
}

# Hàm sinh cổng ngẫu nhiên
generate_random_port() {
    if ! command -v netstat >/dev/null 2>&1; then
        echo -e "${GREEN}Đang cài đặt net-tools, vui lòng chờ...${NC}"
        apt install net-tools -y >/dev/null 2>&1 || yum install net-tools -y >/dev/null 2>&1 || {
            echo -e "${RED}Không thể cài net-tools. Vui lòng cài thủ công: 'apt install net-tools' hoặc 'yum install net-tools'.${NC}"
            echo -e ""
            read -p "Nhấn Enter để tiếp tục..."
            exit 1
        }
    fi
    local port
    while true; do
        port=$(shuf -i 10000-65535 -n 1)
        if ! netstat -tuln | grep -q ":$port "; then
            echo "$port"
            break
        fi
    done
}

# Hàm kiểm tra hệ điều hành
check_os() {
    echo -e "${GREEN}Đang kiểm tra hệ điều hành...${NC}"
    if [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release)
        if [[ $OS == *"CentOS release 7"* ]]; then
            echo "centos7"
        elif [[ $OS == *"CentOS release 8"* ]]; then
            echo "centos8"
        elif [[ $OS == *"CentOS Stream release 8"* ]]; then
            echo "centos8s"
        elif [[ $OS == *"CentOS Stream release 9"* ]]; then
            echo "centos9"
        elif [[ $OS == *"AlmaLinux release 8"* ]]; then
            echo "almalinux8"
        elif [[ $OS == *"AlmaLinux release 9"* ]]; then
            echo "almalinux9"
        else
            echo -e "${RED}Hệ điều hành CentOS/AlmaLinux không được hỗ trợ: $OS${NC}"
            echo -e ""
            read -p "Nhấn Enter để tiếp tục..."
            exit 1
        fi
    elif [ -f /etc/os-release ]; then
        OS=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d \")
        if [[ $OS == *"Ubuntu 22.04"* ]]; then
            echo "ubuntu2204"
        elif [[ $OS == *"Ubuntu 20.04"* ]]; then
            echo "ubuntu2004"
        elif [[ $OS == *"Ubuntu 18.04"* ]]; then
            echo "ubuntu1804"
        elif [[ $OS == *"Ubuntu 16.04"* ]]; then
            echo "ubuntu1604"
        elif [[ $OS == *"Ubuntu 14.04"* ]]; then
            echo "ubuntu1404"
        elif [[ $OS == *"Debian GNU/Linux 8"* ]]; then
            echo "debian8"
        elif [[ $OS == *"Debian GNU/Linux 9"* ]]; then
            echo "debian9"
        elif [[ $OS == *"Debian GNU/Linux 10"* ]]; then
            echo "debian10"
        elif [[ $OS == *"Debian GNU/Linux 11"* ]]; then
            echo "debian11"
        elif [[ $OS == *"Debian GNU/Linux 12"* ]]; then
            echo "debian12"
        else
            echo -e "${RED}Hệ điều hành không được hỗ trợ: $OS${NC}"
            echo -e ""
            read -p "Nhấn Enter để tiếp tục..."
            exit 1
        fi
    elif command -v lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -d | cut -f2)
        echo -e "${RED}Hệ điều hành không được hỗ trợ (lsb_release): $OS${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        exit 1
    else
        echo -e "${RED}Không thể xác định hệ điều hành.${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        exit 1
    fi
}

# Hàm kiểm tra trạng thái Squid và hiển thị thông tin proxy
check_squid_status() {
    echo -e "${GREEN}=== Kiểm tra trạng thái Squid Proxy ===${NC}"
    if [[ -d /etc/squid/ || -d /etc/squid3/ ]]; then
        echo -e "${GREEN}Squid Proxy đã được cài đặt.${NC}"
        echo -e ""
        # Lấy IP công cộng
        ip="Không lấy được IP"
        if command -v jq >/dev/null 2>&1; then
            echo -e "${GREEN}Đang lấy IP công cộng...${NC}"
            response=$(curl -s https://api.myip.com)
            ip=$(echo "$response" | jq -r '.ip' 2>/dev/null || echo "Không lấy được IP")
        fi
        # Lấy cổng từ tệp cấu hình
        if [ -f /etc/squid/squid.conf ]; then
            port=$(grep -E "^http_port" /etc/squid/squid.conf | awk '{print $2}' || echo "Không xác định")
        elif [ -f /etc/squid3/squid.conf ]; then
            port=$(grep -E "^http_port" /etc/squid3/squid.conf | awk '{print $2}' || echo "Không xác định")
        else
            port="Không xác định"
        fi
        # Lấy danh sách user
        echo -e "${GREEN}Thông tin proxy hiện tại:${NC}"
        echo -e "  IP: $ip"
        echo -e "  Cổng: $port"
        if [ -f /etc/squid/passwd ]; then
            echo -e "  Danh sách người dùng (mật khẩu được nhập khi tạo):"
            grep -v '^$' /etc/squid/passwd | awk -F: '{print "    " $1}'
        else
            echo -e "  Không có người dùng nào."
        fi
        # Kiểm tra trạng thái dịch vụ
        if systemctl is-active squid >/dev/null 2>&1; then
            echo -e "  Trạng thái dịch vụ: ${GREEN}Đang chạy${NC}"
        else
            echo -e "  Trạng thái dịch vụ: ${RED}Không chạy${NC}"
        fi
        echo -e ""
        echo -e "${GREEN}Để kiểm tra proxy, sử dụng lệnh:${NC}"
        echo -e "  curl --proxy http://<username>:<password>@$ip:$port https://www.google.com"
        echo -e "  Thay <username> và <password> bằng thông tin đã nhập khi tạo user."
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        return 0
    else
        echo -e "${RED}Squid Proxy chưa được cài đặt.${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        return 1
    fi
}

# Hàm cài đặt Squid
install_squid() {
    if check_squid_status; then
        return
    fi
    SOK_OS=$(check_os)
    PORT=$(generate_random_port)
    echo -e "${GREEN}Đang cài đặt Squid Proxy trên cổng $PORT...${NC}"
    echo -e ""

    # Cài đặt công cụ cần thiết
    echo -e "${GREEN}Đang cài đặt các gói phụ thuộc, vui lòng chờ...${NC}"
    yum install wget -y >/dev/null 2>&1 || apt install wget -y >/dev/null 2>&1 || {
        echo -e "${RED}Không thể cài wget. Vui lòng cài thủ công: 'apt install wget' hoặc 'yum install wget'.${NC}"
        read -p "Nhấn Enter để tiếp tục..."
        exit 1
    }
    apt install net-tools -y >/dev/null 2>&1 || yum install net-tools -y >/dev/null 2>&1 || {
        echo -e "${RED}Không thể cài net-tools. Vui lòng cài thủ công: 'apt install net-tools' hoặc 'yum install net-tools'.${NC}"
        read -p "Nhấn Enter để tiếp tục..."
        exit 1
    }
    # Cố gắng cài jq, nếu thất bại thì bỏ qua
    if ! apt install jq -y >/dev/null 2>&1; then
        echo -e "${GREEN}Cố gắng thêm kho universe và cài jq...${NC}"
        add-apt-repository universe -y >/dev/null 2>&1
        apt update >/dev/null 2>&1
        apt install jq -y >/dev/null 2>&1 || {
            echo -e "${GREEN}Cài jq qua snap...${NC}"
            snap install jq >/dev/null 2>&1 || {
                echo -e "${RED}Không thể cài jq, tiếp tục mà không sử dụng jq.${NC}"
            }
        }
    fi

    # Tạo thư mục /etc/squid nếu chưa có
    echo -e "${GREEN}Đang cấu hình thư mục Squid...${NC}"
    mkdir -p /etc/squid

    # Tải các script bổ trợ
    echo -e "${GREEN}Đang tải các script bổ trợ...${NC}"
    wget -q --no-check-certificate -O /usr/local/bin/squid-uninstall https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid-uninstall.sh >/dev/null 2>&1
    wget -q --no-check-certificate -O /usr/local/bin/squid-add-user https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid-add-user.sh >/dev/null 2>&1
    chmod 755 /usr/local/bin/squid-uninstall /usr/local/bin/squid-add-user

    # Cài đặt Squid theo hệ điều hành
    echo -e "${GREEN}Đang cài đặt Squid, vui lòng chờ...${NC}"
    case $SOK_OS in
        ubuntu2204|ubuntu2004|ubuntu1804|ubuntu1604)
            apt install apache2-utils squid -y >/dev/null 2>&1 || {
                echo -e "${RED}Lỗi cài đặt squid. Vui lòng kiểm tra kho lưu trữ hoặc cài thủ công: 'apt install squid'.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                exit 1
            }
            touch /etc/squid/passwd /etc/squid/blacklist.acl
            mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid.conf >/dev/null 2>&1
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf
            iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
            iptables-save >/dev/null 2>&1
            systemctl enable squid >/dev/null 2>&1
            systemctl restart squid || {
                echo -e "${RED}Lỗi khởi động squid. Vui lòng kiểm tra dịch vụ: 'systemctl status squid'.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                exit 1
            }
            ;;
        debian11|debian12)
            apt install apache2-utils squid -y >/dev/null 2>&1 || {
                echo -e "${RED}Lỗi cài đặt squid. Vui lòng kiểm tra kho lưu trữ hoặc cài thủ công: 'apt install squid'.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                exit 1
            }
            touch /etc/squid/passwd /etc/squid/blacklist.acl
            rm -f /etc/squid/squid.conf
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid.conf >/dev/null 2>&1
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf
            iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
            iptables-save >/dev/null 2>&1
            systemctl enable squid >/dev/null 2>&1
            systemctl restart squid || {
                echo -e "${RED}Lỗi khởi động squid. Vui lòng kiểm tra dịch vụ: 'systemctl status squid'.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                exit 1
            }
            ;;
        centos7|centos8|almalinux8|almalinux9|centos9)
            yum install squid httpd-tools -y >/dev/null 2>&1 || {
                echo -e "${RED}Lỗi cài đặt squid. Vui lòng kiểm tra kho lưu trữ hoặc cài thủ công: 'yum install squid'.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                exit 1
            }
            touch /etc/squid/blacklist.acl
            mv /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/conf/squid-centos7.conf >/dev/null 2>&1
            sed -i "s/http_port 3128/http_port $PORT/" /etc/squid/squid.conf
            firewall-cmd --zone=public --permanent --add-port=$PORT/tcp >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1
            systemctl enable squid >/dev/null 2>&1
            systemctl restart squid || {
                echo -e "${RED}Lỗi khởi động squid. Vui lòng kiểm tra dịch vụ: 'systemctl status squid'.${NC}"
                read -p "Nhấn Enter để tiếp tục..."
                exit 1
            }
            ;;
        *)
            echo -e "${RED}Hệ điều hành không được hỗ trợ: $SOK_OS${NC}"
            read -p "Nhấn Enter để tiếp tục..."
            exit 1
            ;;
    esac

    # Thêm tài khoản proxy
    echo -e "${GREEN}Đang tạo tài khoản proxy...${NC}"
    read -p "Nhập tên người dùng proxy: " usernamesquid
    read -p "Nhập mật khẩu proxy: " passwordsquid
    htpasswd -b -c /etc/squid/passwd "$usernamesquid" "$passwordsquid" && {
        echo -e "${GREEN}Thêm người dùng $usernamesquid thành công.${NC}"
    } || {
        echo -e "${RED}Lỗi khi thêm người dùng $usernamesquid. Vui lòng kiểm tra quyền truy cập tệp /etc/squid/passwd.${NC}"
        read -p "Nhấn Enter để tiếp tục..."
        exit 1
    }

    # Lấy IP công cộng
    ip="Không lấy được IP"
    if command -v jq >/dev/null 2>&1; then
        echo -e "${GREEN}Đang lấy IP công cộng...${NC}"
        response=$(curl -s https://api.myip.com)
        ip=$(echo "$response" | jq -r '.ip' 2>/dev/null || echo "Không lấy được IP")
    fi
    echo -e ""
    echo -e "${GREEN}Cài đặt Proxy HTTP/HTTPS thành công:${NC}"
    echo -e "  Proxy: $ip:$PORT:$usernamesquid:$passwordsquid"
    echo -e ""
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm thêm tài khoản proxy
add_user() {
    if [ ! -f /etc/squid/passwd ]; then
        echo -e "${RED}Tệp /etc/squid/passwd không tồn tại. Vui lòng cài đặt Squid trước.${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        return
    fi
    echo -e "${GREEN}Đang tạo tài khoản proxy mới...${NC}"
    read -p "Nhập tên người dùng proxy mới: " usernamesquid
    read -p "Nhập mật khẩu proxy mới: " passwordsquid
    htpasswd -b /etc/squid/passwd "$usernamesquid" "$passwordsquid" && {
        echo -e "${GREEN}Thêm người dùng $usernamesquid thành công.${NC}"
    } || {
        echo -e "${RED}Lỗi khi thêm người dùng $usernamesquid. Vui lòng kiểm tra quyền truy cập tệp /etc/squid/passwd.${NC}"
    }
    echo -e ""
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm liệt kê danh sách user
list_users() {
    if [ -f /etc/squid/passwd ]; then
        echo -e "${GREEN}Danh sách người dùng proxy hiện có:${NC}"
        grep -v '^$' /etc/squid/passwd | awk -F: '{print "    " $1}'
    else
        echo -e "${RED}Không tìm thấy tệp /etc/squid/passwd. Chưa có người dùng nào được tạo.${NC}"
    fi
}

# Hàm xóa tài khoản proxy
delete_user() {
    if [ ! -f /etc/squid/passwd ]; then
        echo -e "${RED}Tệp /etc/squid/passwd không tồn tại. Vui lòng cài đặt Squid trước.${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        return
    fi
    echo -e "${GREEN}Đang xóa người dùng proxy...${NC}"
    list_users
    read -p "Nhập tên người dùng cần xóa: " usernamesquid
    if grep -q "^$usernamesquid:" /etc/squid/passwd; then
        htpasswd -D /etc/squid/passwd "$usernamesquid" && {
            echo -e "${GREEN}Xóa người dùng $usernamesquid thành công.${NC}"
        } || {
            echo -e "${RED}Lỗi khi xóa người dùng $usernamesquid. Vui lòng kiểm tra quyền truy cập tệp /etc/squid/passwd.${NC}"
        }
    else
        echo -e "${RED}Không tìm thấy người dùng $usernamesquid.${NC}"
    fi
    echo -e ""
    read -p "Nhấn Enter để tiếp tục..."
}

# Hàm thay đổi cổng proxy
change_port() {
    if ! check_squid_status; then
        echo -e "${RED}Squid Proxy chưa được cài đặt. Vui lòng cài đặt trước khi thay đổi cổng.${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        return
    fi
    SOK_OS=$(check_os)
    PORT=$(generate_random_port)
    if [ -z "$PORT" ] || ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Lỗi: Cổng không hợp lệ ($PORT).${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        return
    fi
    echo -e "${GREEN}Đang thay đổi cổng Squid thành $PORT...${NC}"
    echo -e ""
    if [ -f /etc/squid/squid.conf ]; then
        sed -i "s/http_port [0-9]\+/http_port $PORT/" /etc/squid/squid.conf || {
            echo -e "${RED}Lỗi khi cập nhật tệp cấu hình Squid.${NC}"
            echo -e ""
            read -p "Nhấn Enter để tiếp tục..."
            return
        }
    elif [ -f /etc/squid3/squid.conf ]; then
        sed -i "s/http_port [0-9]\+/http_port $PORT/" /etc/squid3/squid.conf || {
            echo -e "${RED}Lỗi khi cập nhật tệp cấu hình Squid.${NC}"
            echo -e ""
            read -p "Nhấn Enter để tiếp tục..."
            return
        }
    else
        echo -e "${RED}Không tìm thấy tệp cấu hình Squid.${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        return
    fi
    if [[ $SOK_OS == centos* || $SOK_OS == almalinux* ]]; then
        echo -e "${GREEN}Đang cập nhật firewall...${NC}"
        firewall-cmd --zone=public --permanent --remove-port=3128/tcp >/dev/null 2>&1
        firewall-cmd --zone=public --permanent --add-port=$PORT/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1 || {
            echo -e "${RED}Lỗi khi cập nhật firewall.${NC}"
            echo -e ""
            read -p "Nhấn Enter để tiếp tục..."
            return
        }
    else
        echo -e "${GREEN}Đang cập nhật iptables...${NC}"
        iptables -D INPUT -p tcp --dport 3128 -j ACCEPT 2>/dev/null
        iptables -I INPUT -p tcp --dport $PORT -j ACCEPT || {
            echo -e "${RED}Lỗi khi cập nhật iptables cho cổng $PORT.${NC}"
            echo -e ""
            read -p "Nhấn Enter để tiếp tục..."
            return
        }
        iptables-save >/dev/null 2>&1
    fi
    echo -e "${GREEN}Đang khởi động lại dịch vụ Squid...${NC}"
    systemctl restart squid || {
        echo -e "${RED}Lỗi khởi động squid. Vui lòng kiểm tra dịch vụ: 'systemctl status squid'.${NC}"
        echo -e ""
        read -p "Nhấn Enter để tiếp tục..."
        return
    }
    echo -e "${GREEN}Thay đổi cổng thành $PORT thành công.${NC}"
    echo -e ""
    read -p "Nhấn Enter để tiếp tục..."
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
        *) echo -e "${RED}Tùy chọn không hợp lệ!${NC}"; read -p "Nhấn Enter để tiếp tục..."; show_menu ;;
    esac
}

# Kiểm tra quyền root và hiển thị menu
check_root
while true; do
    show_menu
done
