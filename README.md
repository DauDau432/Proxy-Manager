# Proxy Manager cho Ubuntu (3proxy)

Script Bash giúp cài đặt và quản lý **3proxy** trên Ubuntu một cách dễ dàng thông qua menu.  
Hỗ trợ tạo **HTTP Proxy** và **SOCKS5 Proxy**, có thể bật/tắt xác thực bằng user/password.  

---

## 🚀 Cách cài đặt nhanh

Chạy lệnh sau trên VPS Ubuntu của bạn:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/DauDau432/Proxy-Manager/refs/heads/main/proxy-manager.sh)
```

---

## 📋 Tính năng

- [x] Tự động cài đặt **3proxy** nếu chưa có.  
- [x] Quản lý **HTTP Proxy** (bật/tắt, thay đổi port, user/pass, xác thực).  
- [x] Quản lý **SOCKS5 Proxy** (bật/tắt, thay đổi port, user/pass, xác thực).  
- [x] Hiển thị trạng thái proxy (port, user/pass, bật/tắt).  
- [x] Tự động lấy và hiển thị **IP public** VPS.  
- [x] Menu rõ ràng, có tùy chọn quay lại `[0]`.  
- [x] Gỡ cài đặt 3proxy hoàn toàn nếu không cần dùng nữa.  

---

## 📖 Cách sử dụng

1. Chạy script bằng lệnh cài đặt ở trên.  
2. Menu sẽ hiện ra với các lựa chọn:  

```
================== TRẠNG THÁI HIỆN TẠI ==================
IP VPS: 203.113.25.178
HTTP Proxy: BẬT (Port: 3128, Auth: demo/123456)
SOCKS5 Proxy: TẮT
==========================================================

========= MENU =========
[1] Cài đặt 3proxy
[2] Quản lý HTTP Proxy
[3] Quản lý SOCKS5 Proxy
[4] Restart 3proxy
[5] Gỡ cài đặt 3proxy
[0] Thoát
=========================
=> Chọn:
```

3. Khi vào menu con (ví dụ quản lý HTTP Proxy), bạn có thể:  
   - Bật proxy mới.  
   - Thay đổi port.  
   - Bật/tắt xác thực user/pass.  
   - Tắt proxy nếu không dùng nữa.  

---

## 🔑 Ví dụ cấu hình Proxy

- **HTTP Proxy không có xác thực**  
  ```
  http://203.113.25.178:3128
  ```

- **HTTP Proxy có user/pass**  
  ```
  http://demo:123456@203.113.25.178:3128
  ```

- **SOCKS5 Proxy có user/pass**  
  ```
  socks5://demo:123456@203.113.25.178:1080
  ```

---

## ⚠️ Lưu ý

- Tránh chọn port trùng với dịch vụ hệ thống như `22` (SSH), `25` (SMTP), `3389` (RDP), ...  
- Đảm bảo VPS của bạn đã mở port trong firewall (nếu có).  
- Script được thiết kế cho Ubuntu 20.04/22.04/24.04, các bản khác có thể cần chỉnh sửa nhỏ.  

---

## 📜 Giấy phép

Script này được phát hành miễn phí và có thể tùy chỉnh thoải mái.
