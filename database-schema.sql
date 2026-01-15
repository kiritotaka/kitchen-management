-- =============================================
-- DATABASE SCHEMA CHO HỆ THỐNG QUẢN LÝ QUÁN ĂN
-- Chạy script này trong SQL Editor của Supabase
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- BẢNG USERS
-- =============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'guest' CHECK (role IN ('guest', 'staff', 'kitchen', 'manager', 'admin')),
  full_name TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- BẢNG CATEGORIES (Danh mục món ăn)
-- =============================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  icon TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- BẢNG MENU_ITEMS (Món ăn)
-- =============================================
CREATE TABLE IF NOT EXISTS menu_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(12, 0) NOT NULL DEFAULT 0,
  image_url TEXT,
  is_available BOOLEAN DEFAULT TRUE,
  badges TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- BẢNG TABLES (Bàn)
-- =============================================
CREATE TABLE IF NOT EXISTS tables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_number INTEGER NOT NULL UNIQUE,
  capacity INTEGER DEFAULT 4,
  status TEXT DEFAULT 'available' CHECK (status IN ('available', 'serving', 'reserved')),
  current_order_id UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- BẢNG ORDERS (Đơn hàng)
-- =============================================
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_id UUID REFERENCES tables(id) ON DELETE SET NULL,
  staff_id UUID REFERENCES users(id) ON DELETE SET NULL,
  order_time TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled', 'paid')),
  total_amount DECIMAL(12, 0) DEFAULT 0,
  notes TEXT
);

-- Add foreign key for current_order_id after orders table exists
ALTER TABLE tables ADD CONSTRAINT fk_current_order 
  FOREIGN KEY (current_order_id) REFERENCES orders(id) ON DELETE SET NULL;

-- =============================================
-- BẢNG ORDER_ITEMS (Chi tiết đơn hàng)
-- =============================================
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES menu_items(id) ON DELETE SET NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'cooking', 'completed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- =============================================
-- BẢNG RESERVATIONS (Đặt bàn)
-- =============================================
CREATE TABLE IF NOT EXISTS reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_id UUID REFERENCES tables(id) ON DELETE CASCADE,
  customer_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  reservation_time TIMESTAMPTZ NOT NULL,
  guest_count INTEGER DEFAULT 2,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- BẢNG WORK_SHIFTS (Ca làm việc)
-- =============================================
CREATE TABLE IF NOT EXISTS work_shifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  shift_date DATE NOT NULL,
  check_in TIMESTAMPTZ,
  check_out TIMESTAMPTZ,
  role TEXT NOT NULL
);

-- =============================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_shifts ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view all users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can do all on users" ON users FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Categories policies (public read)
CREATE POLICY "Anyone can view categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Admins can manage categories" ON categories FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Menu items policies (public read)
CREATE POLICY "Anyone can view menu items" ON menu_items FOR SELECT USING (true);
CREATE POLICY "Admins can manage menu items" ON menu_items FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Tables policies
CREATE POLICY "Authenticated users can view tables" ON tables FOR SELECT USING (true);
CREATE POLICY "Staff and above can update tables" ON tables FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('staff', 'manager', 'admin'))
);
CREATE POLICY "Admins can manage tables" ON tables FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Orders policies
CREATE POLICY "Staff can view all orders" ON orders FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('staff', 'kitchen', 'manager', 'admin'))
);
CREATE POLICY "Staff can create orders" ON orders FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('staff', 'manager', 'admin'))
);
CREATE POLICY "Staff can update orders" ON orders FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('staff', 'manager', 'admin'))
);

-- Order items policies
CREATE POLICY "Staff can view order items" ON order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('staff', 'kitchen', 'manager', 'admin'))
);
CREATE POLICY "Staff can manage order items" ON order_items FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('staff', 'kitchen', 'manager', 'admin'))
);

-- Reservations policies
CREATE POLICY "Staff can view reservations" ON reservations FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('staff', 'manager', 'admin'))
);
CREATE POLICY "Staff can manage reservations" ON reservations FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('manager', 'admin'))
);

-- Work shifts policies
CREATE POLICY "Users can view own shifts" ON work_shifts FOR SELECT USING (
  user_id = auth.uid() OR 
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('manager', 'admin'))
);
CREATE POLICY "Admins can manage shifts" ON work_shifts FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- =============================================
-- REALTIME SUBSCRIPTIONS
-- =============================================
ALTER PUBLICATION supabase_realtime ADD TABLE tables;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE order_items;

-- =============================================
-- FUNCTION: Tự động tạo user record khi đăng ký
-- =============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'staff')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- DỮ LIỆU MẪU
-- =============================================

-- Thêm danh mục mẫu
INSERT INTO categories (name, display_order, icon) VALUES
  ('Khai vị', 1, 'pi pi-star'),
  ('Món chính', 2, 'pi pi-heart'),
  ('Món nước', 3, 'pi pi-box'),
  ('Đồ uống', 4, 'pi pi-glass'),
  ('Tráng miệng', 5, 'pi pi-apple')
ON CONFLICT DO NOTHING;

-- Thêm món ăn mẫu
INSERT INTO menu_items (category_id, name, description, price, is_available, badges) VALUES
  ((SELECT id FROM categories WHERE name = 'Khai vị'), 'Gỏi cuốn tôm thịt', 'Gỏi cuốn tươi với tôm, thịt heo, bún và rau sống', 45000, true, ARRAY['Bestseller']),
  ((SELECT id FROM categories WHERE name = 'Khai vị'), 'Chả giò', 'Chả giò giòn rụm với nhân thịt heo và rau củ', 55000, true, NULL),
  ((SELECT id FROM categories WHERE name = 'Món chính'), 'Phở bò tái', 'Phở bò với thịt bò tái thơm ngon', 65000, true, ARRAY['Bestseller']),
  ((SELECT id FROM categories WHERE name = 'Món chính'), 'Cơm tấm sườn bì chả', 'Cơm tấm với sườn nướng, bì và chả trứng', 55000, true, NULL),
  ((SELECT id FROM categories WHERE name = 'Món chính'), 'Bún chả Hà Nội', 'Bún chả thơm lừng với chả viên và thịt nướng', 60000, true, ARRAY['New']),
  ((SELECT id FROM categories WHERE name = 'Món nước'), 'Hủ tiếu Nam Vang', 'Hủ tiếu với tôm, mực, và thịt heo', 55000, true, NULL),
  ((SELECT id FROM categories WHERE name = 'Đồ uống'), 'Trà đá', 'Trà đá mát lạnh', 5000, true, NULL),
  ((SELECT id FROM categories WHERE name = 'Đồ uống'), 'Nước ngọt', 'Coca, Pepsi, 7Up', 15000, true, NULL),
  ((SELECT id FROM categories WHERE name = 'Đồ uống'), 'Cà phê sữa đá', 'Cà phê sữa đá truyền thống', 25000, true, ARRAY['Bestseller']),
  ((SELECT id FROM categories WHERE name = 'Tráng miệng'), 'Chè ba màu', 'Chè ba màu mát lạnh', 25000, true, NULL)
ON CONFLICT DO NOTHING;

-- Thêm bàn mẫu
INSERT INTO tables (table_number, capacity, status) VALUES
  (1, 4, 'available'),
  (2, 4, 'available'),
  (3, 6, 'available'),
  (4, 6, 'available'),
  (5, 2, 'available'),
  (6, 2, 'available'),
  (7, 8, 'available'),
  (8, 4, 'available')
ON CONFLICT DO NOTHING;

-- =============================================
-- HOÀN THÀNH!
-- =============================================
