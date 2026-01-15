# Hệ thống Quản lý Quán ăn

## Tổng quan
Đây là ứng dụng quản lý quán ăn được xây dựng bằng Vue.js 3, Supabase, và PrimeVue. Hệ thống hỗ trợ nhiều vai trò người dùng với các chức năng phù hợp.

## Công nghệ sử dụng
- **Frontend**: Vue.js 3, TypeScript, Vite
- **UI**: PrimeVue, Tailwind CSS v4, PrimeIcons
- **State Management**: Pinia với pinia-plugin-persistedstate
- **Routing**: Vue Router 4
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)

## Cấu trúc dự án
```
src/
├── assets/          # CSS và assets
├── components/      # Vue components tái sử dụng
├── composables/     # Vue composables
├── layouts/         # Layout components
├── pages/           # Các trang
│   ├── admin/       # Trang admin
│   ├── auth/        # Trang đăng nhập
│   ├── kitchen/     # Trang bếp
│   ├── manager/     # Trang quản lý
│   ├── menu/        # Trang menu công khai
│   └── staff/       # Trang nhân viên
├── router/          # Vue Router config
├── services/        # Supabase client
├── stores/          # Pinia stores
├── types/           # TypeScript types
└── utils/           # Utility functions
```

## Vai trò người dùng
1. **Guest (Khách)**: Chỉ xem menu
2. **Staff (Nhân viên)**: Quản lý bàn, đặt món
3. **Kitchen (Bếp)**: Xem và hoàn thành món
4. **Manager (Quản lý)**: Đặt bàn, thanh toán, in hóa đơn
5. **Admin**: Toàn quyền quản lý

## Thiết lập Supabase

### Bước 1: Chạy SQL Schema
Mở SQL Editor trong Supabase Dashboard và chạy nội dung file `database-schema.sql`.

### Bước 2: Tạo tài khoản người dùng
Trong Supabase Dashboard → Authentication → Users → Add User:
- Email: admin@example.com
- Password: (mật khẩu của bạn)
- User Metadata: `{"full_name": "Admin", "role": "admin"}`

### Bước 3: Biến môi trường
Đảm bảo có các secrets:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

## Các tính năng chính
- [x] Xác thực người dùng với phân quyền
- [x] Menu công khai với tìm kiếm và lọc
- [x] Quản lý bàn real-time
- [x] Đặt món và gửi order đến bếp
- [x] Bếp nhận order theo thứ tự thời gian
- [x] Thanh toán và in hóa đơn
- [x] Đặt bàn trước
- [x] Quản lý menu, danh mục
- [x] Quản lý người dùng
- [x] Thống kê doanh thu

## Chạy dự án
```bash
npm run dev
```

## Cập nhật gần đây
- 2026-01-15: Thêm chức năng upload hình ảnh món ăn với Supabase Storage
- 2026-01-15: Sửa lỗi RLS policies gây infinite recursion
- 2026-01-15: Khởi tạo dự án với đầy đủ tính năng MVP

## Supabase Storage
- Bucket: `menu-images` (public)
- Dùng để lưu hình ảnh món ăn upload từ admin
