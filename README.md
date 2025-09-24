# Proxy Manager - Quản lý Squid Proxy

`proxy-manager.sh` là một script shell dùng để cài đặt và quản lý **Squid Proxy** trên các hệ điều hành Linux như Ubuntu, Debian, CentOS, và AlmaLinux. Script hỗ trợ cài đặt proxy HTTP/HTTPS, quản lý người dùng, thay đổi cổng, và kiểm tra trạng thái proxy thông qua một menu tương tác.

## Tính năng

- **Cài đặt Squid Proxy**:
  - Tự động cài đặt Squid với cổng ngẫu nhiên (từ 1024-64511).
  - Yêu cầu nhập username và password để tạo user proxy ban đầu.
- **Quản lý Proxy**:
  - Thêm proxy mới với IP và cổng ngẫu nhiên.
  - Chỉnh sửa proxy (thay đổi IP hoặc cổng).
  - Xóa proxy hiện có.
- **Quản lý Người dùng**:
  - Thêm người dùng mới với username và password.
  - Chỉnh sửa thông tin người dùng (username hoặc password).
  - Xóa người dùng hiện có.
- **Kiểm tra Trạng thái**:
  - Hiển thị trạng thái dịch vụ Squid (đang chạy/không chạy).
  - Đếm số lượng proxy và người dùng hiện có.
- **Xem Danh sách**:
  - Xem danh sách proxy hiện có.
  - Xem danh sách IP chưa được sử dụng.
  - Xem danh sách người dùng hiện có.
- **Khởi động lại Proxy**:
  - Khởi động lại dịch vụ Squid thủ công.

## Yêu cầu

- **Quyền root**: Script phải được chạy với quyền root hoặc sử dụng `sudo`.
- **Kết nối internet**: Cần kết nối mạng để tải gói phần mềm và cấu hình.
- **Hệ điều hành**:
  - Ubuntu: 14.04, 16.04, 18.04, 20.04, 22.04
  - Debian: 8, 9, 10, 11, 12
  - CentOS: 7, 8, 9
  - AlmaLinux: 8, 9
- **Gói phụ thuộc**: `squid`, `apache2-utils` (sẽ được cài tự động).

## Cài đặt và Chạy

Sử dụng lệnh one-liner để tải và chạy script:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh)
