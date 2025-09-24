#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
WHITE='\033[1;37m'

# Paths
SQUID_CONF="/etc/squid/squid.conf"
PASSWD_FILE="/etc/squid/passwd"
USERS_FILE="/etc/squid/users.txt"

# Function to center text
center_text() {
    local text="$1"
    local width=85
    local text_len=${#text}
    local padding=$(( (width - text_len) / 2 ))
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
}

# Function to display header
display_header() {
    local status="Không chạy"
    local proxy_count=0
    local user_count=0
    if systemctl is-active --quiet squid; then
        status="Đang chạy"
        proxy_count=$(grep http_port $SQUID_CONF 2>/dev/null | wc -l)
        user_count=$(wc -l < $USERS_FILE 2>/dev/null)
    fi
    echo -e "${GREEN}=================== [Trạng thái Proxy: $status | Proxy: $proxy_count | User: $user_count] ===================${NC}"
}

# Function to check and install Squid
check_and_install_squid() {
    if [ -d "/etc/squid" ] || [ -d "/etc/squid3" ]; then
        return 0
    fi
    echo -e "${WHITE}[-] Đang cài đặt Squid...${NC}"
    apt update >/dev/null 2>&1
    apt install -y squid apache2-utils >/dev/null 2>&1
    touch $USERS_FILE
    chmod 600 $USERS_FILE
    echo -e "${WHITE}[-] Đang lấy danh sách IP...${NC}"
    ip_list=$(ip addr | grep inet | awk '{print $2}' | cut -d'/' -f1 | grep -v "127.0.0.1")
    if [ -z "$ip_list" ]; then
        echo -e "${RED}[!] Không tìm thấy IP nào trên VPS.${NC}"
        exit 1
    fi
    echo "Danh sách IP chưa add:"
    select ip in $ip_list; do
        if [ -n "$ip" ]; then
            break
        fi
        echo -e "${RED}[!] Vui lòng chọn IP hợp lệ.${NC}"
    done
    port=$((RANDOM % 64511 + 1024))
    read -p "-> Nhập username cho proxy: " username
    read -sp "-> Nhập password cho proxy: " password
    echo
    htpasswd -b -c $PASSWD_FILE "$username" "$password" >/dev/null 2>&1
    echo "$username:$password:$(date +%F_%H:%M):ALL" >> $USERS_FILE
    echo "auth_param basic program /usr/lib/squid/basic_ncsa_auth $PASSWD_FILE" > $SQUID_CONF
    echo "auth_param basic realm Proxy Authentication" >> $SQUID_CONF
    echo "acl authenticated proxy_auth REQUIRED" >> $SQUID_CONF
    echo "http_access allow authenticated" >> $SQUID_CONF
    echo "http_access deny all" >> $SQUID_CONF
    echo "http_port $ip:$port" >> $SQUID_CONF
    iptables -I INPUT -p tcp --dport $port -j ACCEPT >/dev/null 2>&1
    systemctl restart squid >/dev/null 2>&1
    echo -e "${GREEN}[+] Cài đặt proxy thành công: $ip:$port:$username:$password${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để tiếp tục...${NC}"
    read
}

# Function to get unadded IPs
get_unadded_ips() {
    ip_list=$(ip addr | grep inet | awk '{print $2}' | cut -d'/' -f1 | grep -v "127.0.0.1")
    added_ips=$(grep http_port $SQUID_CONF 2>/dev/null | awk '{print $2}' | cut -d':' -f1)
    unadded_ips=""
    for ip in $ip_list; do
        if ! echo "$added_ips" | grep -q "$ip"; then
            unadded_ips="$unadded_ips $ip"
        fi
    done
    echo "$unadded_ips"
}

# Function to add proxy
add_proxy() {
    unadded_ips=$(get_unadded_ips)
    if [ -z "$unadded_ips" ]; then
        echo -e "${RED}[!] Tất cả IP đã được add proxy.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    echo "Danh sách IP chưa add:"
    select ip in $unadded_ips; do
        if [ -n "$ip" ]; then
            break
        fi
        echo -e "${RED}[!] Vui lòng chọn IP hợp lệ.${NC}"
    done
    port=$((RANDOM % 64511 + 1024))
    read -p "-> Nhập username (Enter để dùng user chung): " username
    read -sp "-> Nhập password (Enter để dùng pass chung): " password
    echo
    if [ -z "$username" ] || [ -z "$password" ]; then
        username=$(head -n 1 $USERS_FILE | cut -d':' -f1)
        password=$(head -n 1 $USERS_FILE | cut -d':' -f2)
    else
        htpasswd -b $PASSWD_FILE "$username" "$password" >/dev/null 2>&1
        echo "$username:$password:$(date +%F_%H:%M):$ip:$port" >> $USERS_FILE
    fi
    echo "http_port $ip:$port" >> $SQUID_CONF
    iptables -I INPUT -p tcp --dport $port -j ACCEPT >/dev/null 2>&1
    systemctl restart squid >/dev/null 2>&1
    echo -e "${GREEN}[+] Thêm proxy thành công: $ip:$port:$username:$password${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to edit proxy
edit_proxy() {
    proxy_list=$(grep http_port $SQUID_CONF | awk '{print $2}' | nl -w2 -s'. ')
    if [ -z "$proxy_list" ]; then
        echo -e "${RED}[!] Không có proxy nào để chỉnh sửa.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    echo "Danh sách proxy đã add:"
    echo "$proxy_list" | while read -r line; do
        num=$(echo "$line" | awk '{print $1}')
        ip_port=$(echo "$line" | awk '{print $2}')
        user_pass=$(grep ":$ip_port$" $USERS_FILE | head -n 1 | cut -d':' -f1,2)
        echo "  [$num] $ip_port:$user_pass"
    done
    read -p "-> Chọn số thứ tự proxy để chỉnh sửa: " choice
    selected=$(echo "$proxy_list" | grep "^ *$choice\." | awk '{print $2}')
    if [ -z "$selected" ]; then
        echo -e "${RED}[!] Lựa chọn không hợp lệ.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    old_ip=$(echo "$selected" | cut -d':' -f1)
    old_port=$(echo "$selected" | cut -d':' -f2)
    old_user=$(grep ":$selected$" $USERS_FILE | head -n 1 | cut -d':' -f1)
    old_pass=$(grep ":$selected$" $USERS_FILE | head -n 1 | cut -d':' -f2)
    unadded_ips=$(get_unadded_ips)
    if [ -n "$unadded_ips" ]; then
        echo "Danh sách IP chưa add:"
        select ip in $unadded_ips; do
            if [ -n "$ip" ]; then
                break
            fi
            echo -e "${RED}[!] Vui lòng chọn IP hợp lệ hoặc Enter để giữ $old_ip.${NC}"
            ip="$old_ip"
            break
        done
    else
        ip="$old_ip"
        echo -e "${RED}[!] Không có IP chưa add, giữ IP cũ: $old_ip.${NC}"
    fi
    read -p "-> Nhập cổng mới (Enter để giữ $old_port): " port
    port=${port:-$old_port}
    read -p "-> Nhập username mới (Enter để giữ $old_user): " username
    read -sp "-> Nhập password mới (Enter để giữ password cũ): " password
    echo
    username=${username:-$old_user}
    password=${password:-$old_pass}
    if [ "$username" != "$old_user" ] || [ "$password" != "$old_pass" ]; then
        htpasswd -b $PASSWD_FILE "$username" "$password" >/dev/null 2>&1
        sed -i "/:$old_ip:$old_port$/d" $USERS_FILE
        echo "$username:$password:$(date +%F_%H:%M):$ip:$port" >> $USERS_FILE
    fi
    sed -i "s/http_port $old_ip:$old_port/http_port $ip:$port/" $SQUID_CONF
    iptables -D INPUT -p tcp --dport $old_port -j ACCEPT >/dev/null 2>&1
    iptables -I INPUT -p tcp --dport $port -j ACCEPT >/dev/null 2>&1
    systemctl restart squid >/dev/null 2>&1
    echo -e "${GREEN}[+] Cập nhật proxy thành công: $ip:$port:$username:$password${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to delete proxy
delete_proxy() {
    proxy_list=$(grep http_port $SQUID_CONF | awk '{print $2}' | nl -w2 -s'. ')
    if [ -z "$proxy_list" ]; then
        echo -e "${RED}[!] Không có proxy nào để xóa.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    echo "Danh sách proxy đã add:"
    echo "$proxy_list" | while read -r line; do
        num=$(echo "$line" | awk '{print $1}')
        ip_port=$(echo "$line" | awk '{print $2}')
        user_pass=$(grep ":$ip_port$" $USERS_FILE | head -n 1 | cut -d':' -f1,2)
        echo "  [$num] $ip_port:$user_pass"
    done
    read -p "-> Chọn số thứ tự proxy để xóa: " choice
    selected=$(echo "$proxy_list" | grep "^ *$choice\." | awk '{print $2}')
    if [ -z "$selected" ]; then
        echo -e "${RED}[!] Lựa chọn không hợp lệ.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    ip=$(echo "$selected" | cut -d':' -f1)
    port=$(echo "$selected" | cut -d':' -f2)
    sed -i "/http_port $ip:$port/d" $SQUID_CONF
    iptables -D INPUT -p tcp --dport $port -j ACCEPT >/dev/null 2>&1
    sed -i "/:$ip:$port$/d" $USERS_FILE
    systemctl restart squid >/dev/null 2>&1
    echo -e "${GREEN}[+] Xóa proxy $ip:$port thành công${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to add user
add_user() {
    read -p "-> Nhập username mới: " username
    read -sp "-> Nhập password mới: " password
    echo
    if grep -q "^$username:" $USERS_FILE; then
        echo -e "${RED}[!] Username đã tồn tại.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    htpasswd -b $PASSWD_FILE "$username" "$password" >/dev/null 2>&1
    echo "$username:$password:$(date +%F_%H:%M):ALL" >> $USERS_FILE
    systemctl restart squid >/dev/null 2>&1
    echo -e "${GREEN}[+] Thêm user $username thành công${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to edit user
edit_user() {
    user_list=$(cat $USERS_FILE | nl -w2 -s'. ')
    if [ -z "$user_list" ]; then
        echo -e "${RED}[!] Không có user nào để chỉnh sửa.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    echo "Danh sách user hiện có:"
    echo "$user_list" | while read -r line; do
        num=$(echo "$line" | awk '{print $1}')
        user=$(echo "$line" | cut -d':' -f1)
        pass=$(echo "$line" | cut -d':' -f2)
        scope=$(echo "$line" | cut -d':' -f4-)
        if [ "$scope" = "ALL" ]; then
            echo "  [$num] $user:$pass (Chung)"
        else
            echo "  [$num] $user:$pass (Riêng: $scope)"
        fi
    done
    read -p "-> Chọn số thứ tự user để chỉnh sửa: " choice
    selected=$(echo "$user_list" | grep "^ *$choice\." | cut -d':' -f1,2,4-)
    if [ -z "$selected" ]; then
        echo -e "${RED}[!] Lựa chọn không hợp lệ.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    old_user=$(echo "$selected" | cut -d':' -f1)
    old_pass=$(echo "$selected" | cut -d':' -f2)
    scope=$(echo "$selected" | cut -d':' -f3-)
    read -p "-> Nhập username mới (Enter để giữ $old_user): " username
    read -sp "-> Nhập password mới (Enter để giữ password cũ): " password
    echo
    username=${username:-$old_user}
    password=${password:-$old_pass}
    if [ "$username" != "$old_user" ] || [ "$password" != "$old_pass" ]; then
        htpasswd -b $PASSWD_FILE "$username" "$password" >/dev/null 2>&1
        sed -i "/^$old_user:/d" $USERS_FILE
        echo "$username:$password:$(date +%F_%H:%M):$scope" >> $USERS_FILE
        systemctl restart squid >/dev/null 2>&1
    fi
    echo -e "${GREEN}[+] Cập nhật user $username thành công${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to delete user
delete_user() {
    user_list=$(cat $USERS_FILE | nl -w2 -s'. ')
    if [ -z "$user_list" ]; then
        echo -e "${RED}[!] Không có user nào để xóa.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    echo "Danh sách user hiện có:"
    echo "$user_list" | while read -r line; do
        num=$(echo "$line" | awk '{print $1}')
        user=$(echo "$line" | cut -d':' -f1)
        pass=$(echo "$line" | cut -d':' -f2)
        scope=$(echo "$line" | cut -d':' -f4-)
        if [ "$scope" = "ALL" ]; then
            echo "  [$num] $user:$pass (Chung)"
        else
            echo "  [$num] $user:$pass (Riêng: $scope)"
        fi
    done
    read -p "-> Chọn số thứ tự user để xóa: " choice
    selected=$(echo "$user_list" | grep "^ *$choice\." | cut -d':' -f1)
    if [ -z "$selected" ]; then
        echo -e "${RED}[!] Lựa chọn không hợp lệ.${NC}"
        echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
        read
        return
    fi
    htpasswd -D $PASSWD_FILE "$selected" >/dev/null 2>&1
    sed -i "/^$selected:/d" $USERS_FILE
    systemctl restart squid >/dev/null 2>&1
    echo -e "${GREEN}[+] Xóa user $selected thành công${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to restart proxy
restart_proxy() {
    systemctl restart squid >/dev/null 2>&1
    if systemctl is-active --quiet squid; then
        echo -e "${GREEN}[+] Khởi động lại proxy thành công${NC}"
    else
        echo -e "${RED}[!] Lỗi khi khởi động lại proxy${NC}"
    fi
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to view proxy list
view_proxy_list() {
    proxy_list=$(grep http_port $SQUID_CONF | awk '{print $2}' | nl -w2 -s'. ')
    if [ -z "$proxy_list" ]; then
        echo -e "${RED}[!] Không có proxy nào.${NC}"
    else
        echo "Danh sách proxy đã add:"
        echo "$proxy_list" | while read -r line; do
            num=$(echo "$line" | awk '{print $1}')
            ip_port=$(echo "$line" | awk '{print $2}')
            user_pass=$(grep ":$ip_port$" $USERS_FILE | head -n 1 | cut -d':' -f1,2)
            echo "  [$num] $ip_port:$user_pass"
        done
    fi
    echo -e "${RED}[!] Bảo vệ mật khẩu, không chia sẻ công khai.${NC}"
    echo -e "${WHITE}[-] Sử dụng proxy: <IP>:<port>:<username>:<password>${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to view unadded IPs
view_unadded_ips() {
    unadded_ips=$(get_unadded_ips)
    count=$(echo "$unadded_ips" | wc -w)
    if [ -z "$unadded_ips" ]; then
        echo -e "${RED}[!] Không có IP chưa add (Tổng: 0).${NC}"
    else
        echo "Danh sách IP chưa add (Tổng: $count):"
        echo "$unadded_ips" | nl -w2 -s'. '
    fi
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Function to view user list
view_user_list() {
    user_list=$(cat $USERS_FILE | nl -w2 -s'. ')
    if [ -z "$user_list" ]; then
        echo -e "${RED}[!] Không có user nào.${NC}"
    else
        echo "Danh sách user hiện có:"
        echo "$user_list" | while read -r line; do
            num=$(echo "$line" | awk '{print $1}')
            user=$(echo "$line" | cut -d':' -f1)
            pass=$(echo "$line" | cut -d':' -f2)
            scope=$(echo "$line" | cut -d':' -f4-)
            if [ "$scope" = "ALL" ]; then
                echo "  [$num] $user:$pass (Chung)"
            else
                echo "  [$num] $user:$pass (Riêng: $scope)"
            fi
        done
    fi
    echo -e "${RED}[!] Bảo vệ mật khẩu, không chia sẻ công khai.${NC}"
    echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"
    read
}

# Main menu
check_and_install_squid
while true; do
    clear
    display_header
    center_text "Menu Quản Lý Proxy"
    echo -e "${WHITE}============================ Menu Quản Lý Proxy =============================${NC}"
    echo "[1] Quản lý Proxy"
    echo "[2] Quản lý User"
    echo "[3] Khởi động lại Proxy"
    echo "[4] Xem danh sách"
    echo "[0] Thoát"
    read -p "-> Chọn một tùy chọn [0-4]: " choice
    case $choice in
        1)
            while true; do
                clear
                display_header
                center_text "Quản lý Proxy"
                echo -e "${WHITE}============================ Quản lý Proxy =============================${NC}"
                echo "[1] Add Proxy"
                echo "[2] Edit Proxy"
                echo "[3] Xóa Proxy"
                echo "[0] Quay lại"
                read -p "-> Chọn một tùy chọn [0-3]: " sub_choice
                case $sub_choice in
                    1) add_proxy ;;
                    2) edit_proxy ;;
                    3) delete_proxy ;;
                    0) break ;;
                    *) echo -e "${RED}[!] Lựa chọn không hợp lệ.${NC}"; echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"; read ;;
                esac
            done
            ;;
        2)
            while true; do
                clear
                display_header
                center_text "Quản lý User"
                echo -e "${WHITE}============================ Quản lý User =============================${NC}"
                echo "[1] Add User"
                echo "[2] Edit User"
                echo "[3] Xóa User"
                echo "[0] Quay lại"
                read -p "-> Chọn một tùy chọn [0-3]: " sub_choice
                case $sub_choice in
                    1) add_user ;;
                    2) edit_user ;;
                    3) delete_user ;;
                    0) break ;;
                    *) echo -e "${RED}[!] Lựa chọn không hợp lệ.${NC}"; echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"; read ;;
                esac
            done
            ;;
        3) restart_proxy ;;
        4)
            while true; do
                clear
                display_header
                center_text "Xem danh sách"
                echo -e "${WHITE}============================ Xem danh sách =============================${NC}"
                echo "[1] Xem danh sách proxy đã add"
                echo "[2] Xem danh sách IP chưa add"
                echo "[3] Xem danh sách user hiện có"
                echo "[0] Quay lại"
                read -p "-> Chọn một tùy chọn [0-3]: " sub_choice
                case $sub_choice in
                    1) view_proxy_list ;;
                    2) view_unadded_ips ;;
                    3) view_user_list ;;
                    0) break ;;
                    *) echo -e "${RED}[!] Lựa chọn không hợp lệ.${NC}"; echo -e "${WHITE}[-] Nhấn Enter để quay lại...${NC}"; read ;;
                esac
            done
            ;;
        0) exit 0 ;;
        *) echo -e "${RED}[!] Lựa chọn không hợp lệ.${NC}"; echo -e "${WHITE}[-] Nhấn Enter để tiếp tục...${NC}"; read ;;
    esac
done
