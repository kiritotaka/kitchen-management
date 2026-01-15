-- =============================================
-- CHÈN DỮ LIỆU MẪU
-- =============================================

-- Xóa dữ liệu cũ (nếu có)
DELETE FROM menu_items;
DELETE FROM categories;
DELETE FROM tables;

-- Thêm danh mục
INSERT INTO categories (name, display_order, icon) VALUES
  ('Khai vị', 1, 'pi-star'),
  ('Món chính', 2, 'pi-heart'),
  ('Đồ uống', 3, 'pi-box'),
  ('Tráng miệng', 4, 'pi-gift'),
  ('Món đặc biệt', 5, 'pi-crown');

-- Thêm món ăn
INSERT INTO menu_items (category_id, name, description, price, image_url, is_available, badges)
SELECT 
  c.id,
  m.name,
  m.description,
  m.price,
  m.image_url,
  m.is_available,
  m.badges
FROM (VALUES
  ('Khai vị', 'Gỏi cuốn tôm thịt', 'Gỏi cuốn tươi với tôm, thịt, rau sống, bún', 45000, 'https://images.unsplash.com/photo-1562967916-eb82221dfb44?w=400', true, ARRAY['bestseller']),
  ('Khai vị', 'Chả giò chiên', 'Chả giò giòn rụm, nhân thịt rau', 55000, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400', true, ARRAY['new']),
  ('Món chính', 'Phở bò tái', 'Phở bò với nước dùng đậm đà, thịt bò tái mềm', 65000, 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=400', true, ARRAY['bestseller']),
  ('Món chính', 'Cơm tấm sườn', 'Cơm tấm với sườn nướng, bì, chả, trứng ốp la', 70000, 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400', true, NULL),
  ('Món chính', 'Bún chả Hà Nội', 'Bún với chả nướng, nước mắm pha, rau sống', 60000, 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400', true, ARRAY['promotion']),
  ('Đồ uống', 'Trà đá', 'Trà đá mát lạnh', 10000, 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400', true, NULL),
  ('Đồ uống', 'Cà phê sữa đá', 'Cà phê phin pha sữa đặc', 35000, 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400', true, ARRAY['bestseller']),
  ('Đồ uống', 'Nước ép cam', 'Nước cam tươi ép tại chỗ', 40000, 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400', true, NULL),
  ('Tráng miệng', 'Chè ba màu', 'Chè đậu xanh, đậu đỏ, thạch, nước cốt dừa', 30000, 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400', true, NULL),
  ('Món đặc biệt', 'Lẩu thái hải sản', 'Lẩu chua cay với tôm, mực, cá, nghêu', 350000, 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400', true, ARRAY['new', 'bestseller'])
) AS m(category_name, name, description, price, image_url, is_available, badges)
JOIN categories c ON c.name = m.category_name;

-- Thêm bàn
INSERT INTO tables (table_number, capacity, status) VALUES
  (1, 4, 'available'),
  (2, 4, 'available'),
  (3, 2, 'available'),
  (4, 6, 'available'),
  (5, 8, 'available'),
  (6, 4, 'available'),
  (7, 2, 'available'),
  (8, 4, 'available');

-- Kiểm tra kết quả
SELECT 'Categories: ' || COUNT(*)::text FROM categories
UNION ALL
SELECT 'Menu items: ' || COUNT(*)::text FROM menu_items
UNION ALL
SELECT 'Tables: ' || COUNT(*)::text FROM tables;
