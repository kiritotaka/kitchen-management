-- =============================================
-- SECURE RLS POLICIES - ROLE-BASED ACCESS CONTROL
-- Chạy script này trong Supabase SQL Editor
-- =============================================

SET search_path TO public;

-- Tạo function để lấy role của user hiện tại (tránh infinite recursion)
CREATE OR REPLACE FUNCTION public.current_app_role()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE r text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN 'guest';
  END IF;
  SELECT role INTO r FROM public.users WHERE id = auth.uid();
  RETURN COALESCE(r, 'guest');
END;
$$;
GRANT EXECUTE ON FUNCTION public.current_app_role TO anon, authenticated;

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY; ALTER TABLE users FORCE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY; ALTER TABLE categories FORCE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY; ALTER TABLE menu_items FORCE ROW LEVEL SECURITY;
ALTER TABLE tables ENABLE ROW LEVEL SECURITY; ALTER TABLE tables FORCE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY; ALTER TABLE orders FORCE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY; ALTER TABLE order_items FORCE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY; ALTER TABLE reservations FORCE ROW LEVEL SECURITY;
ALTER TABLE work_shifts ENABLE ROW LEVEL SECURITY; ALTER TABLE work_shifts FORCE ROW LEVEL SECURITY;

-- =============================================
-- USERS POLICIES
-- =============================================
DROP POLICY IF EXISTS "users_select" ON users;
DROP POLICY IF EXISTS "users_insert" ON users;
DROP POLICY IF EXISTS "users_update" ON users;
DROP POLICY IF EXISTS "users_delete" ON users;
DROP POLICY IF EXISTS "Users can view all users" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can do all on users" ON users;
DROP POLICY IF EXISTS "Anyone can view users" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can delete own profile" ON users;
DROP POLICY IF EXISTS users_select_self ON users;
DROP POLICY IF EXISTS users_select_admin ON users;
DROP POLICY IF EXISTS users_update_self ON users;
DROP POLICY IF EXISTS users_admin_all ON users;
DROP POLICY IF EXISTS users_service_insert ON users;

CREATE POLICY users_select_self ON users FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY users_select_admin ON users FOR SELECT TO authenticated USING (current_app_role() = 'admin');
CREATE POLICY users_update_self ON users FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY users_admin_all ON users FOR ALL TO authenticated USING (current_app_role() = 'admin') WITH CHECK (current_app_role() = 'admin');
CREATE POLICY users_service_insert ON users FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- =============================================
-- CATEGORIES POLICIES (Public read, Admin manage)
-- =============================================
DROP POLICY IF EXISTS "categories_select" ON categories;
DROP POLICY IF EXISTS "categories_insert" ON categories;
DROP POLICY IF EXISTS "categories_update" ON categories;
DROP POLICY IF EXISTS "categories_delete" ON categories;
DROP POLICY IF EXISTS "Anyone can view categories" ON categories;
DROP POLICY IF EXISTS "Public read categories" ON categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON categories;
DROP POLICY IF EXISTS categories_public_select ON categories;
DROP POLICY IF EXISTS categories_admin_insert ON categories;
DROP POLICY IF EXISTS categories_admin_update ON categories;
DROP POLICY IF EXISTS categories_admin_delete ON categories;

CREATE POLICY categories_public_select ON categories FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY categories_admin_insert ON categories FOR INSERT TO authenticated WITH CHECK (current_app_role() = 'admin');
CREATE POLICY categories_admin_update ON categories FOR UPDATE TO authenticated USING (current_app_role() = 'admin') WITH CHECK (current_app_role() = 'admin');
CREATE POLICY categories_admin_delete ON categories FOR DELETE TO authenticated USING (current_app_role() = 'admin');

-- =============================================
-- MENU_ITEMS POLICIES (Public read, Admin manage)
-- =============================================
DROP POLICY IF EXISTS "menu_items_select" ON menu_items;
DROP POLICY IF EXISTS "menu_items_insert" ON menu_items;
DROP POLICY IF EXISTS "menu_items_update" ON menu_items;
DROP POLICY IF EXISTS "menu_items_delete" ON menu_items;
DROP POLICY IF EXISTS "Anyone can view menu items" ON menu_items;
DROP POLICY IF EXISTS "Public read menu items" ON menu_items;
DROP POLICY IF EXISTS "Admins can manage menu items" ON menu_items;
DROP POLICY IF EXISTS menu_items_public_select ON menu_items;
DROP POLICY IF EXISTS menu_items_admin_insert ON menu_items;
DROP POLICY IF EXISTS menu_items_admin_update ON menu_items;
DROP POLICY IF EXISTS menu_items_admin_delete ON menu_items;

CREATE POLICY menu_items_public_select ON menu_items FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY menu_items_admin_insert ON menu_items FOR INSERT TO authenticated WITH CHECK (current_app_role() = 'admin');
CREATE POLICY menu_items_admin_update ON menu_items FOR UPDATE TO authenticated USING (current_app_role() = 'admin') WITH CHECK (current_app_role() = 'admin');
CREATE POLICY menu_items_admin_delete ON menu_items FOR DELETE TO authenticated USING (current_app_role() = 'admin');

-- =============================================
-- TABLES POLICIES (Staff+ view, Staff+ update, Admin manage)
-- =============================================
DROP POLICY IF EXISTS "tables_select" ON tables;
DROP POLICY IF EXISTS "tables_insert" ON tables;
DROP POLICY IF EXISTS "tables_update" ON tables;
DROP POLICY IF EXISTS "tables_delete" ON tables;
DROP POLICY IF EXISTS "Authenticated users can view tables" ON tables;
DROP POLICY IF EXISTS "Staff and above can update tables" ON tables;
DROP POLICY IF EXISTS "Admins can manage tables" ON tables;
DROP POLICY IF EXISTS tables_role_select ON tables;
DROP POLICY IF EXISTS tables_admin_insert ON tables;
DROP POLICY IF EXISTS tables_manage_update ON tables;
DROP POLICY IF EXISTS tables_admin_delete ON tables;

CREATE POLICY tables_role_select ON tables FOR SELECT TO authenticated USING (current_app_role() IN ('staff','kitchen','manager','admin'));
CREATE POLICY tables_admin_insert ON tables FOR INSERT TO authenticated WITH CHECK (current_app_role() = 'admin');
CREATE POLICY tables_manage_update ON tables FOR UPDATE TO authenticated USING (current_app_role() IN ('staff','manager','admin')) WITH CHECK (current_app_role() IN ('staff','manager','admin'));
CREATE POLICY tables_admin_delete ON tables FOR DELETE TO authenticated USING (current_app_role() = 'admin');

-- =============================================
-- ORDERS POLICIES (Staff+ view, Staff+ create/update)
-- =============================================
DROP POLICY IF EXISTS "orders_select" ON orders;
DROP POLICY IF EXISTS "orders_insert" ON orders;
DROP POLICY IF EXISTS "orders_update" ON orders;
DROP POLICY IF EXISTS "orders_delete" ON orders;
DROP POLICY IF EXISTS "Staff can view all orders" ON orders;
DROP POLICY IF EXISTS "Staff can create orders" ON orders;
DROP POLICY IF EXISTS "Staff can update orders" ON orders;
DROP POLICY IF EXISTS orders_staff_select ON orders;
DROP POLICY IF EXISTS orders_staff_insert ON orders;
DROP POLICY IF EXISTS orders_staff_update ON orders;
DROP POLICY IF EXISTS orders_admin_delete ON orders;

CREATE POLICY orders_staff_select ON orders FOR SELECT TO authenticated USING (current_app_role() IN ('staff','kitchen','manager','admin'));
CREATE POLICY orders_staff_insert ON orders FOR INSERT TO authenticated WITH CHECK (current_app_role() IN ('staff','manager','admin'));
CREATE POLICY orders_staff_update ON orders FOR UPDATE TO authenticated USING (current_app_role() IN ('staff','manager','admin')) WITH CHECK (current_app_role() IN ('staff','manager','admin'));
CREATE POLICY orders_admin_delete ON orders FOR DELETE TO authenticated USING (current_app_role() = 'admin');

-- =============================================
-- ORDER_ITEMS POLICIES (Staff/Kitchen+ view/update)
-- =============================================
DROP POLICY IF EXISTS "order_items_select" ON order_items;
DROP POLICY IF EXISTS "order_items_insert" ON order_items;
DROP POLICY IF EXISTS "order_items_update" ON order_items;
DROP POLICY IF EXISTS "order_items_delete" ON order_items;
DROP POLICY IF EXISTS "Staff can view order items" ON order_items;
DROP POLICY IF EXISTS "Staff can manage order items" ON order_items;
DROP POLICY IF EXISTS order_items_select_roles ON order_items;
DROP POLICY IF EXISTS order_items_insert_staff ON order_items;
DROP POLICY IF EXISTS order_items_update_roles ON order_items;
DROP POLICY IF EXISTS order_items_delete_staff ON order_items;

CREATE POLICY order_items_select_roles ON order_items FOR SELECT TO authenticated USING (current_app_role() IN ('staff','kitchen','manager','admin'));
CREATE POLICY order_items_insert_staff ON order_items FOR INSERT TO authenticated WITH CHECK (current_app_role() IN ('staff','manager','admin'));
CREATE POLICY order_items_update_roles ON order_items FOR UPDATE TO authenticated USING (current_app_role() IN ('staff','kitchen','manager','admin')) WITH CHECK (current_app_role() IN ('staff','kitchen','manager','admin'));
CREATE POLICY order_items_delete_staff ON order_items FOR DELETE TO authenticated USING (current_app_role() IN ('staff','manager','admin'));

-- =============================================
-- RESERVATIONS POLICIES (Staff+ view, Manager+ manage)
-- =============================================
DROP POLICY IF EXISTS "reservations_select" ON reservations;
DROP POLICY IF EXISTS "reservations_insert" ON reservations;
DROP POLICY IF EXISTS "reservations_update" ON reservations;
DROP POLICY IF EXISTS "reservations_delete" ON reservations;
DROP POLICY IF EXISTS "Staff can view reservations" ON reservations;
DROP POLICY IF EXISTS "Staff can manage reservations" ON reservations;
DROP POLICY IF EXISTS reservations_select_roles ON reservations;
DROP POLICY IF EXISTS reservations_insert_manager ON reservations;
DROP POLICY IF EXISTS reservations_update_manager ON reservations;
DROP POLICY IF EXISTS reservations_delete_manager ON reservations;

CREATE POLICY reservations_select_roles ON reservations FOR SELECT TO authenticated USING (current_app_role() IN ('staff','manager','admin'));
CREATE POLICY reservations_insert_manager ON reservations FOR INSERT TO authenticated WITH CHECK (current_app_role() IN ('manager','admin'));
CREATE POLICY reservations_update_manager ON reservations FOR UPDATE TO authenticated USING (current_app_role() IN ('manager','admin')) WITH CHECK (current_app_role() IN ('manager','admin'));
CREATE POLICY reservations_delete_manager ON reservations FOR DELETE TO authenticated USING (current_app_role() IN ('manager','admin'));

-- =============================================
-- WORK_SHIFTS POLICIES (Self view, Manager+ manage)
-- =============================================
DROP POLICY IF EXISTS "work_shifts_select" ON work_shifts;
DROP POLICY IF EXISTS "work_shifts_insert" ON work_shifts;
DROP POLICY IF EXISTS "work_shifts_update" ON work_shifts;
DROP POLICY IF EXISTS "work_shifts_delete" ON work_shifts;
DROP POLICY IF EXISTS "Users can view own shifts" ON work_shifts;
DROP POLICY IF EXISTS "Admins can manage shifts" ON work_shifts;
DROP POLICY IF EXISTS work_shifts_select_self ON work_shifts;
DROP POLICY IF EXISTS work_shifts_select_managers ON work_shifts;
DROP POLICY IF EXISTS work_shifts_manage_manager ON work_shifts;
DROP POLICY IF EXISTS work_shifts_update_manager ON work_shifts;
DROP POLICY IF EXISTS work_shifts_delete_admin ON work_shifts;

CREATE POLICY work_shifts_select_self ON work_shifts FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY work_shifts_select_managers ON work_shifts FOR SELECT TO authenticated USING (current_app_role() IN ('manager','admin'));
CREATE POLICY work_shifts_manage_manager ON work_shifts FOR INSERT TO authenticated WITH CHECK (current_app_role() IN ('manager','admin'));
CREATE POLICY work_shifts_update_manager ON work_shifts FOR UPDATE TO authenticated USING (current_app_role() IN ('manager','admin')) WITH CHECK (current_app_role() IN ('manager','admin'));
CREATE POLICY work_shifts_delete_admin ON work_shifts FOR DELETE TO authenticated USING (current_app_role() = 'admin');

-- =============================================
-- HOÀN THÀNH!
-- =============================================
SELECT 'All secure RLS policies created!' as status;
