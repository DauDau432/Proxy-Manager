# Proxy Manager - Quản lý Squid Proxy

`proxy-manager.sh` là một script shell dùng để cài đặt và quản lý **Squid Proxy** trên các hệ điều hành Linux như Ubuntu, Debian, CentOS, và AlmaLinux. hỗ trợ cài đặt proxy HTTP/HTTPS, quản lý người dùng, thay đổi cổng, và kiểm tra trạng thái proxy.

## Tính năng

- **Cài đặt Squid Proxy**:
  - Tự động cài đặt Squid với cổng ngẫu nhiên (từ 10000-65535).
  - Hỗ trợ giao thức HTTP và HTTPS.
- **Quản lý người dùng**:
  - Thêm nhiều người dùng proxy với tên người dùng và mật khẩu.
  - Xóa người dùng, hiển thị danh sách người dùng hiện có trước khi xóa.
- **Thay đổi cổng proxy**:
  - Tạo cổng ngẫu nhiên mới và cập nhật cấu hình firewall.
- **Kiểm tra trạng thái proxy**:
  - Hiển thị thông tin proxy hiện tại: IP công cộng, cổng, danh sách người dùng, và trạng thái dịch vụ.
  - Thông báo nếu Squid chưa được cài đặt.
- **Hỗ trợ nhiều hệ điều hành**:
  - Ubuntu: 14.04, 16.04, 18.04, 20.04, 22.04
  - Debian: 8, 9, 10, 11, 12
  - CentOS: 7, 8, 9
  - AlmaLinux: 8, 9

## Yêu cầu

- **Quyền root**: Script phải được chạy với quyền root hoặc sử dụng `sudo`.
- **Kết nối internet**: Cần kết nối mạng để tải gói phần mềm và tệp cấu hình.
- **Hệ điều hành**: Một trong các hệ điều hành được liệt kê ở trên.
- **Gói phụ thuộc**: `curl`, `jq`, `net-tools` (sẽ được cài tự động nếu cần).

## Cài đặt và chạy

### Cách 1: Chạy trực tiếp từ GitHub
Sử dụng lệnh one-liner để tải và chạy script trực tiếp:

```bash
sudo bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh)
```

### Cách 2: Tải về và chạy thủ công (khuyến nghị để kiểm tra)
1. **Tải script**:
   ```bash
   curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh -o proxy-manager.sh
   ```

2. **Kiểm tra nội dung**:
   ```bash
   cat proxy-manager.sh
   ```

3. **Cấp quyền thực thi**:
   ```bash
   chmod +x proxy-manager.sh
   ```

4. **Chạy script**:
   ```bash
   sudo ./proxy-manager.sh
   ```

### Cài đặt locale tiếng Việt (nếu cần)
Nếu ký tự tiếng Việt hiển thị sai, cài đặt locale:
```bash
sudo apt install language-pack-vi
sudo locale-gen vi_VN.UTF-8
sudo dpkg-reconfigure locales
```
Chọn `vi_VN.UTF-8` và đặt làm mặc định.

### Cài đặt gói phụ thuộc
Đảm bảo các gói cần thiết được cài:
```bash
sudo apt update && sudo apt install curl jq net-tools  # Ubuntu/Debian
```
***Hoặc:***
```
sudo yum install curl jq net-tools  # CentOS/AlmaLinux
```

## Cách sử dụng

Sau khi chạy script, bạn sẽ thấy menu tương tác:
```
=== Menu Quản Lý Squid Proxy ===
1. Cài đặt Squid Proxy
2. Thêm người dùng Proxy
3. Xóa người dùng Proxy
4. Thay đổi cổng Proxy
5. Xem trạng thái Proxy
6. Thoát
Chọn một tùy chọn [1-6]:
```

### Tùy chọn trong menu
1. **Cài đặt Squid Proxy**:
   - Cài đặt Squid với cổng ngẫu nhiên.
   - Yêu cầu nhập tên người dùng và mật khẩu).
   - Hiển thị thông tin proxy: `IP:cổng:username:password`.
   - Nếu Squid đã cài, hiển thị thông tin proxy hiện tại và không cài lại.

2. **Thêm người dùng Proxy**:
   - Thêm người dùng mới vào proxy hiện có.
   - Yêu cầu nhập tên người dùng và mật khẩu.

3. **Xóa người dùng Proxy**:
   - Hiển thị danh sách người dùng hiện có trước khi yêu cầu nhập tên người dùng để xóa.

4. **Thay đổi cổng Proxy**:
   - Tạo cổng ngẫu nhiên mới, cập nhật cấu hình Squid và firewall.

5. **Xem trạng thái Proxy**:
   - Hiển thị thông tin proxy hiện tại: IP, cổng, danh sách người dùng, trạng thái dịch vụ.

6. **Thoát**:
   - Thoát script.

## Ví dụ chạy script

Giả sử bạn chạy trên VPS Ubuntu 20.04 với IP `203.0.113.10` và Squid đã cài với cổng `54321`, hai user: `user1`, `user2`.

1. **Chạy lệnh**:
   ```bash
   sudo bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh)
   ```

2. **Menu chính**:
   ```
   === Menu Quản Lý Squid Proxy ===
   1. Cài đặt Squid Proxy
   2. Thêm người dùng Proxy
   3. Xóa người dùng Proxy
   4. Thay đổi cổng Proxy
   5. Xem trạng thái Proxy
   6. Thoát
   Chọn một tùy chọn [1-6]:
   ```

3. **Xem trạng thái (Tùy chọn 5)**:
   Chọn `5`:
   ```
   Squid Proxy đã được cài đặt.
   Thông tin proxy hiện tại:
   IP: 203.0.113.10
   Cổng: 54321
   Danh sách người dùng:
        1  user1
        2  user2
   Trạng thái dịch vụ: Đang chạy
   ```

4. **Thử cài lại (Tùy chọn 1)**:
   Chọn `1`:
   ```
   Squid Proxy đã được cài đặt.
   Thông tin proxy hiện tại:
   IP: 203.0.113.10
   Cổng: 54321
   Danh sách người dùng:
        1  user1
        2  user2
   Trạng thái dịch vụ: Đang chạy
   Squid Proxy đã được cài đặt. Vui lòng sử dụng các tùy chọn khác hoặc chạy 'squid-uninstall' để cài lại.
   ```

5. **Thêm người dùng (Tùy chọn 2)**:
   Chọn `2`:
   ```
   Nhập tên người dùng proxy mới: user3
   Nhập mật khẩu proxy mới: pass3
   Thêm người dùng user3 thành công.
   ```

6. **Xóa người dùng (Tùy chọn 3)**:
   Chọn `3`:
   ```
   Danh sách người dùng proxy hiện có:
        1  user1
        2  user2
        3  user3
   Nhập tên người dùng cần xóa: user2
   Xóa người dùng user2 thành công.
   ```

7. **Thay đổi cổng (Tùy chọn 4)**:
   Chọn `4`:
   ```
   Đang thay đổi cổng Squid thành 45678...
   Thay đổi cổng thành 45678 thành công.
   ```

8. **Thoát (Tùy chọn 6)**:
   Chọn `6` để thoát.

## Kiểm tra Proxy

Kiểm tra proxy bằng `curl`:
```bash
curl --proxy http://user1:pass1@203.0.113.10:54321 https://www.google.com
```

Kiểm tra trạng thái dịch vụ Squid:
```bash
systemctl status squid
```
Nếu Squid không chạy, khởi động lại:
```bash
systemctl restart squid
```

- **Lỗi tiềm ẩn**:
  - Nếu gặp lỗi "curl: command not found", cài curl:
    ```bash
    sudo apt install curl  # Ubuntu/Debian
    sudo yum install curl  # CentOS/AlmaLinux
    ```


## Cải tiến trong tương lai

- **Giao diện đồ họa**: Thêm hỗ trợ `dialog` cho menu đẹp hơn:
  ```bash
  sudo apt install dialog
  ```
- **Ghi log**: Lưu các hành động vào `/var/log/squid_manager.log`.
- **Tùy chọn khởi động lại**: Thêm tùy chọn khởi động lại dịch vụ Squid trong menu.

## Hỗ trợ

Nếu gặp lỗi hoặc cần thêm tính năng, hãy mở issue trên repository GitHub: [DauDau432/Proxy-Manager](https://github.com/DauDau432/Proxy-Manager). Kiểm tra tệp cấu hình `/etc/squid/squid.conf` hoặc trạng thái dịch vụ để khắc phục sự cố.
