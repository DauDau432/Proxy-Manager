# Proxy Manager - Quản lý Squid Proxy

`proxy-manager.sh` là một script shell để cài đặt và quản lý **Squid Proxy** trên máy chủ Linux (Ubuntu/Debian). Script hỗ trợ tạo nhiều proxy trên nhiều IP, quản lý user xác thực, thay đổi/xóa proxy và kiểm tra trạng thái dịch vụ.

## 🚀 Tính năng

- **Cài đặt Squid Proxy**:
  - Tự động cài Squid và Apache2-utils (htpasswd).
  - Chọn IP từ danh sách IP của VPS để tạo proxy.
  - Tự động chọn cổng ngẫu nhiên và mở firewall.
- **Quản lý Proxy**:
  - Thêm proxy mới (theo IP chưa dùng).
  - Chỉnh sửa proxy (IP, cổng, user/pass).
  - Xóa proxy khỏi cấu hình Squid.
- **Quản lý User**:
  - Thêm user dùng chung cho toàn bộ proxy.
  - Sửa user (đổi username/password).
  - Xóa user.
- **Tiện ích**:
  - Restart dịch vụ Squid.
  - Xem danh sách proxy, user, và IP chưa add.
  - Hiển thị trạng thái proxy ngay trên menu.

## 📋 Yêu cầu

- **Quyền root** (`sudo` hoặc root).
- **Hệ điều hành**: Ubuntu/Debian (đã test).
- **Kết nối mạng** để cài gói.

## ⚙️ Cài đặt & Chạy

   ```bash
    bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh)
   ```

## 📖 Cách sử dụng

Sau khi chạy, menu chính xuất hiện:

```
[Trạng thái Proxy: Đang chạy | Proxy: 2 | User: 3]
                 Menu Quản Lý Proxy                 
[1] Quản lý Proxy
[2] Quản lý User
[3] Khởi động lại Proxy
[4] Xem danh sách
[0] Thoát
-> Chọn một tùy chọn [0-4]:
```

### Menu con

- **Quản lý Proxy**:
  - Thêm proxy (Add Proxy).
  - Sửa proxy (Edit Proxy).
  - Xóa proxy (Delete Proxy).
- **Quản lý User**:
  - Thêm user.
  - Sửa user.
  - Xóa user.
- **Xem danh sách**:
  - Proxy hiện có.
  - IP chưa add proxy.
  - User hiện có.

## 🔍 Kiểm tra Proxy

Kiểm tra kết nối:
```bash
curl --proxy http://username:password@IP:PORT https://www.google.com
```

Kiểm tra trạng thái dịch vụ:
```bash
systemctl status squid
```

Khởi động lại nếu cần:
```bash
systemctl restart squid
```

## 🗑️ Gỡ cài đặt Proxy Manager

Để gỡ hoàn toàn Squid Proxy và script:

```bash
systemctl stop squid
apt purge -y squid apache2-utils
rm -f /etc/squid/squid.conf /etc/squid/passwd
```

---

✦ Nếu gặp lỗi, hãy kiểm tra log `systemctl status squid -l` hoặc xem lại cấu hình trong `/etc/squid/squid.conf`.
