export type UserRole = 'guest' | 'staff' | 'kitchen' | 'manager' | 'admin'

export interface User {
  id: string
  email: string
  role: UserRole
  full_name: string
  phone?: string
  avatar_url?: string
  created_at: string
}

export interface Category {
  id: string
  name: string
  display_order: number
  icon?: string
  created_at: string
}

export interface MenuItem {
  id: string
  category_id: string
  name: string
  description?: string
  price: number
  image_url?: string
  is_available: boolean
  badges?: string[]
  created_at: string
  category?: Category
}

export type TableStatus = 'available' | 'serving' | 'reserved'

export interface Table {
  id: string
  table_number: number
  capacity: number
  status: TableStatus
  current_order_id?: string
  updated_at: string
}

export type OrderStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled' | 'paid'

export interface Order {
  id: string
  table_id: string
  staff_id: string
  order_time: string
  status: OrderStatus
  total_amount: number
  notes?: string
  table?: Table
  staff?: User
  items?: OrderItem[]
}

export type OrderItemStatus = 'pending' | 'cooking' | 'completed'

export interface OrderItem {
  id: string
  order_id: string
  menu_item_id: string
  quantity: number
  status: OrderItemStatus
  created_at: string
  completed_at?: string
  menu_item?: MenuItem
  order?: Order
}

export type ReservationStatus = 'pending' | 'confirmed' | 'cancelled' | 'completed'

export interface Reservation {
  id: string
  table_id: string
  customer_name: string
  phone: string
  reservation_time: string
  guest_count: number
  status: ReservationStatus
  notes?: string
  table?: Table
}

export interface WorkShift {
  id: string
  user_id: string
  shift_date: string
  check_in?: string
  check_out?: string
  role: UserRole
  user?: User
}

export interface RevenueStats {
  id: string
  date: string
  total_orders: number
  total_revenue: number
  peak_hour?: number
}

export interface DishAnalytics {
  id: string
  menu_item_id: string
  date: string
  quantity_sold: number
  revenue: number
  menu_item?: MenuItem
}

export interface RestaurantInfo {
  name: string
  address: string
  phone: string
  tax_id?: string
  logo_url?: string
}
