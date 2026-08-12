# ZaloPC Portable

Phiên bản viết lại dựa theo bản của thành viên [chín hai](https://voz.vn/u/chin-hai.1704367/) trên [VOZ](https://voz.vn/t/zalopc-portable.1064415/).

* ZaloPC Portable giúp chạy Zalo trực tiếp từ một thư mục riêng, không cần cài đặt
* Dữ liệu Zalo được lưu trong thư mục `Data\`, nên dễ dàng sao lưu hoặc chuyển sang máy khác
* **Chạy không cần quyền Administrator**

## Tải và sử dụng

1. Tải [ZaloPC.Portable.zip](https://github.com/bibicadotnet/ZaloPC-Portable/releases/download/setup/ZaloPC.Portable.zip)
2. Giải nén vào thư mục muốn sử dụng
3. Chạy `update.bat` để tải phiên bản Zalo mới nhất
4. Chạy `Zalo.exe` và đăng nhập

> Bắt buộc sử dụng ổ đĩa định dạng NTFS. FAT32 và exFAT không hỗ trợ liên kết thư mục (Junction Point).

Muốn Zalo tự khởi động cùng Windows, chạy `add_to_startup.bat`.

## Cập nhật

Khi muốn cập nhật Zalo lên phiên bản mới nhất, chỉ cần chạy lại:

```
update.bat
```

## Cấu trúc thư mục

```text
ZaloPC Portable/
├── Zalo.exe               ← Launcher, không phải Zalo gốc
├── Zalo.ini               ← Cấu hình cho launcher
├── update.bat             ← Cập nhật Zalo lên phiên bản mới nhất
├── add_to_startup.bat     ← Thêm Zalo vào danh sách tự khởi động
├── App/                   ← Toàn bộ file Zalo gốc
├── Data/                  ← Toàn bộ dữ liệu Zalo
│   ├── Roaming/ZaloData/              ← Tin nhắn, tài khoản, cài đặt
│   ├── Local/ZaloPC/                  ← Cache, dữ liệu tạm
│   └── Documents/Zalo Received Files/ ← File nhận qua Zalo
└── Registry/
    └── a.reg              ← Bản sao lưu Registry của Zalo
```

**Dữ liệu cá nhân nằm trong `Data\`**, vì vậy có thể sao lưu hoặc copy thư mục Portable sang máy khác.

## Nguồn Zalo

ZaloPC trong repo được đóng gói tự động từ package **`VNGCorp.Zalo` trên [winget-pkgs](https://github.com/microsoft/winget-pkgs)**, không chỉnh sửa file Zalo.

GitHub Actions kiểm tra phiên bản mới mỗi **6 giờ**, vì vậy bản trên repo có thể chậm hơn bản chính thức tối đa khoảng 6 giờ.

## Yêu cầu

* Windows 10/11 64-bit
* Ổ đĩa định dạng **NTFS**
