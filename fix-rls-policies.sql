-- =============================================
-- FIX RLS POLICIES CHO PUBLIC ACCESS
-- Chạy script này nếu menu không hiển thị
-- =============================================

-- Drop existing policies và tạo lại
DROP POLICY IF EXISTS "Anyone can view categories" ON categories;
DROP POLICY IF EXISTS "Anyone can view menu items" ON menu_items;

-- Tạo policy mới cho phép đọc public (bao gồm anon)
CREATE POLICY "Public read categories" ON categories 
  FOR SELECT 
  TO anon, authenticated
  USING (true);

CREATE POLICY "Public read menu items" ON menu_items 
  FOR SELECT 
  TO anon, authenticated
  USING (true);

-- Kiểm tra dữ liệu
SELECT COUNT(*) as category_count FROM categories;
SELECT COUNT(*) as menu_item_count FROM menu_items;
