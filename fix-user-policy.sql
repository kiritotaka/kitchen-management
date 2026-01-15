-- =============================================
-- FIX INFINITE RECURSION IN USERS POLICY
-- =============================================

-- Xóa policy cũ gây lỗi
DROP POLICY IF EXISTS "Users can view all users" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can do all on users" ON users;

-- Tạo policy mới không gây đệ quy
CREATE POLICY "Anyone can view users" ON users 
  FOR SELECT 
  TO anon, authenticated
  USING (true);

CREATE POLICY "Users can update own profile" ON users 
  FOR UPDATE 
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users 
  FOR INSERT 
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON users 
  FOR DELETE 
  TO authenticated
  USING (auth.uid() = id);

-- Kiểm tra
SELECT 'Users policy fixed!' as status;
