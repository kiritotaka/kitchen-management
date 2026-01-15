-- =============================================
-- FIX TẤT CẢ RLS POLICIES - TRÁNH ĐỆ QUY
-- =============================================

-- 1. XÓA TẤT CẢ POLICIES CŨ
DROP POLICY IF EXISTS "Users can view all users" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can do all on users" ON users;
DROP POLICY IF EXISTS "Anyone can view users" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can delete own profile" ON users;

DROP POLICY IF EXISTS "Anyone can view categories" ON categories;
DROP POLICY IF EXISTS "Public read categories" ON categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON categories;

DROP POLICY IF EXISTS "Anyone can view menu items" ON menu_items;
DROP POLICY IF EXISTS "Public read menu items" ON menu_items;
DROP POLICY IF EXISTS "Admins can manage menu items" ON menu_items;

DROP POLICY IF EXISTS "Authenticated users can view tables" ON tables;
DROP POLICY IF EXISTS "Staff and above can update tables" ON tables;
DROP POLICY IF EXISTS "Admins can manage tables" ON tables;

DROP POLICY IF EXISTS "Staff can view all orders" ON orders;
DROP POLICY IF EXISTS "Staff can create orders" ON orders;
DROP POLICY IF EXISTS "Staff can update orders" ON orders;

DROP POLICY IF EXISTS "Staff can view order items" ON order_items;
DROP POLICY IF EXISTS "Staff can manage order items" ON order_items;

DROP POLICY IF EXISTS "Staff can view reservations" ON reservations;
DROP POLICY IF EXISTS "Staff can manage reservations" ON reservations;

DROP POLICY IF EXISTS "Users can view own shifts" ON work_shifts;
DROP POLICY IF EXISTS "Admins can manage shifts" ON work_shifts;

-- 2. TẠO POLICIES MỚI - KHÔNG ĐỆ QUY

-- Users: cho phép tất cả authenticated users đọc, tự sửa profile của mình
CREATE POLICY "users_select" ON users FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "users_insert" ON users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "users_update" ON users FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "users_delete" ON users FOR DELETE TO authenticated USING (auth.uid() = id);

-- Categories: public read, authenticated có thể quản lý
CREATE POLICY "categories_select" ON categories FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "categories_insert" ON categories FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "categories_update" ON categories FOR UPDATE TO authenticated USING (true);
CREATE POLICY "categories_delete" ON categories FOR DELETE TO authenticated USING (true);

-- Menu items: public read, authenticated có thể quản lý
CREATE POLICY "menu_items_select" ON menu_items FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "menu_items_insert" ON menu_items FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "menu_items_update" ON menu_items FOR UPDATE TO authenticated USING (true);
CREATE POLICY "menu_items_delete" ON menu_items FOR DELETE TO authenticated USING (true);

-- Tables: authenticated có thể đọc và cập nhật
CREATE POLICY "tables_select" ON tables FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "tables_insert" ON tables FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "tables_update" ON tables FOR UPDATE TO authenticated USING (true);
CREATE POLICY "tables_delete" ON tables FOR DELETE TO authenticated USING (true);

-- Orders: authenticated có thể quản lý
CREATE POLICY "orders_select" ON orders FOR SELECT TO authenticated USING (true);
CREATE POLICY "orders_insert" ON orders FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "orders_update" ON orders FOR UPDATE TO authenticated USING (true);
CREATE POLICY "orders_delete" ON orders FOR DELETE TO authenticated USING (true);

-- Order items: authenticated có thể quản lý
CREATE POLICY "order_items_select" ON order_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "order_items_insert" ON order_items FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "order_items_update" ON order_items FOR UPDATE TO authenticated USING (true);
CREATE POLICY "order_items_delete" ON order_items FOR DELETE TO authenticated USING (true);

-- Reservations: authenticated có thể quản lý
CREATE POLICY "reservations_select" ON reservations FOR SELECT TO authenticated USING (true);
CREATE POLICY "reservations_insert" ON reservations FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "reservations_update" ON reservations FOR UPDATE TO authenticated USING (true);
CREATE POLICY "reservations_delete" ON reservations FOR DELETE TO authenticated USING (true);

-- Work shifts: authenticated có thể quản lý
CREATE POLICY "work_shifts_select" ON work_shifts FOR SELECT TO authenticated USING (true);
CREATE POLICY "work_shifts_insert" ON work_shifts FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "work_shifts_update" ON work_shifts FOR UPDATE TO authenticated USING (true);
CREATE POLICY "work_shifts_delete" ON work_shifts FOR DELETE TO authenticated USING (true);

-- 3. KIỂM TRA
SELECT 'All policies fixed!' as status;
