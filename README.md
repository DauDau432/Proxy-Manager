Proxy Manager - Quản lý Squid Proxy
proxy-manager.sh là một script shell dùng để cài đặt và quản lý Squid Proxy trên các hệ điều hành Linux như Ubuntu, Debian, CentOS, và AlmaLinux. Script cung cấp giao diện menu tương tác bằng tiếng Việt, hỗ trợ cài đặt proxy HTTP/HTTPS, quản lý người dùng, thay đổi cổng, và kiểm tra trạng thái proxy.
Tính năng

Cài đặt Squid Proxy:
Tự động cài đặt Squid với cổng ngẫu nhiên (từ 10000-65535).
Hỗ trợ giao thức HTTP và HTTPS.


Quản lý người dùng:
Thêm nhiều người dùng proxy với tên người dùng và mật khẩu.
Xóa người dùng, hiển thị danh sách người dùng hiện có trước khi xóa.


Thay đổi cổng proxy:
Sinh cổng ngẫu nhiên mới và cập nhật cấu hình firewall.


Kiểm tra trạng thái proxy:
Hiển thị thông tin proxy hiện tại: IP công cộng, cổng, danh sách người dùng, và trạng thái dịch vụ.
Thông báo nếu Squid chưa được cài đặt.


Giao diện tiếng Việt:
Tất cả thông báo và menu sử dụng tiếng Việt với mã hóa UTF-8.


Mật khẩu không ẩn:
Mật khẩu hiển thị khi nhập để dễ kiểm tra.


Hỗ trợ nhiều hệ điều hành:
Ubuntu: 14.04, 16.04, 18.04, 20.04, 22.04
Debian: 8, 9, 10, 11, 12
CentOS: 7, 8, 9
AlmaLinux: 8, 9



Yêu cầu

Quyền root: Script phải được chạy với quyền root hoặc sử dụng sudo.
Kết nối internet: Cần kết nối mạng để tải gói phần mềm và tệp cấu hình.
Hệ điều hành: Một trong các hệ điều hành được liệt kê ở trên.
Gói phụ thuộc: curl, jq, net-tools (sẽ được cài tự động nếu cần).
Locale tiếng Việt: Để hiển thị đúng ký tự tiếng Việt, cần cài đặt locale vi_VN.UTF-8.

Cài đặt và chạy
Cách 1: Chạy trực tiếp từ GitHub
Sử dụng lệnh one-liner để tải và chạy script trực tiếp:
sudo bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh)

Cách 2: Tải về và chạy thủ công (khuyến nghị để kiểm tra)

Tải script:
curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh -o proxy-manager.sh


Kiểm tra nội dung:
cat proxy-manager.sh


Cấp quyền thực thi:
chmod +x proxy-manager.sh


Chạy script:
sudo ./proxy-manager.sh



Cài đặt locale tiếng Việt (nếu cần)
Nếu ký tự tiếng Việt hiển thị sai, cài đặt locale:
sudo apt install language-pack-vi
sudo locale-gen vi_VN.UTF-8
sudo dpkg-reconfigure locales

Chọn vi_VN.UTF-8 và đặt làm mặc định.
Cài đặt gói phụ thuộc
Đảm bảo các gói cần thiết được cài:
sudo apt update && sudo apt install curl jq net-tools  # Ubuntu/Debian
# Hoặc: sudo yum install curl jq net-tools  # CentOS/AlmaLinux

Cách sử dụng
Sau khi chạy script, bạn sẽ thấy menu tương tác:
=== Menu Quản Lý Squid Proxy ===
1. Cài đặt Squid Proxy
2. Thêm người dùng Proxy
3. Xóa người dùng Proxy
4. Thay đổi cổng Proxy
5. Xem trạng thái Proxy
6. Thoát
Chọn một tùy chọn [1-6]:

Tùy chọn trong menu

Cài đặt Squid Proxy:

Cài đặt Squid với cổng ngẫu nhiên.
Yêu cầu nhập tên người dùng và mật khẩu (mật khẩu hiển thị khi gõ).
Hiển thị thông tin proxy: IP:cổng:username:password.
Nếu Squid đã cài, hiển thị thông tin proxy hiện tại và không cài lại.


Thêm người dùng Proxy:

Thêm người dùng mới vào proxy hiện có.
Yêu cầu nhập tên người dùng và mật khẩu.


Xóa người dùng Proxy:

Hiển thị danh sách người dùng hiện có trước khi yêu cầu nhập tên người dùng để xóa.


Thay đổi cổng Proxy:

Sinh cổng ngẫu nhiên mới, cập nhật cấu hình Squid và firewall.


Xem trạng thái Proxy:

Hiển thị thông tin proxy hiện tại: IP, cổng, danh sách người dùng, trạng thái dịch vụ.


Thoát:

Thoát script.



Ví dụ chạy script
Giả sử bạn chạy trên VPS Ubuntu 20.04 với IP 203.0.113.10 và Squid đã cài với cổng 54321, hai user: user1, user2.

Chạy lệnh:
sudo bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh)


Menu chính:
=== Menu Quản Lý Squid Proxy ===
1. Cài đặt Squid Proxy
2. Thêm người dùng Proxy
3. Xóa người dùng Proxy
4. Thay đổi cổng Proxy
5. Xem trạng thái Proxy
6. Thoát
Chọn một tùy chọn [1-6]:


Xem trạng thái (Tùy chọn 5):Chọn 5:
Squid Proxy đã được cài đặt.
Thông tin proxy hiện tại:
IP: 203.0.113.10
Cổng: 54321
Danh sách người dùng:
     1  user1
     2  user2
Trạng thái dịch vụ: Đang chạy


Thử cài lại (Tùy chọn 1):Chọn 1:
Squid Proxy đã được cài đặt.
Thông tin proxy hiện tại:
IP: 203.0.113.10
Cổng: 54321
Danh sách người dùng:
     1  user1
     2  user2
Trạng thái dịch vụ: Đang chạy
Squid Proxy đã được cài đặt. Vui lòng sử dụng các tùy chọn khác hoặc chạy 'squid-uninstall' để cài lại.


Thêm người dùng (Tùy chọn 2):Chọn 2:
Nhập tên người dùng proxy mới: user3
Nhập mật khẩu proxy mới: pass3
Thêm người dùng user3 thành công.


Xóa người dùng (Tùy chọn 3):Chọn 3:

