import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/services/supabase'
import type { Order, OrderItem, OrderItemStatus } from '@/types'

export const useOrderStore = defineStore('orders', () => {
  const orders = ref<Order[]>([])
  const orderItems = ref<OrderItem[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const pendingOrderItems = computed(() => {
    return orderItems.value
      .filter(item => item.status !== 'completed')
      .sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime())
  })

  async function fetchOrders() {
    loading.value = true
    try {
      const { data, error: fetchError } = await supabase
        .from('orders')
        .select(`
          *,
          table:tables!orders_table_id_fkey(*),
          staff:app_users(*),
          items:order_items(
            *,
            menu_item:menu_items(*)
          )
        `)
        .order('order_time', { ascending: false })

      if (fetchError) throw fetchError
      orders.value = data || []
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch orders'
    } finally {
      loading.value = false
    }
  }

  async function fetchOrderItems() {
    loading.value = true
    try {
      const { data, error: fetchError } = await supabase
        .from('order_items')
        .select(`
          *,
          menu_item:menu_items(*),
          order:orders(
            *,
            table:tables!orders_table_id_fkey(*)
          )
        `)
        .order('created_at', { ascending: true })

      if (fetchError) throw fetchError
      orderItems.value = data || []
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch order items'
    } finally {
      loading.value = false
    }
  }

  async function createOrder(tableId: string, staffId: string, items: { menu_item_id: string; quantity: number }[], notes?: string) {
    try {
      const totalAmount = 0

      const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert({
          table_id: tableId,
          staff_id: staffId,
          order_time: new Date().toISOString(),
          status: 'pending',
          total_amount: totalAmount,
          notes
        })
        .select()
        .single()

      if (orderError) throw orderError

      const orderItemsToInsert = items.map(item => ({
        order_id: order.id,
        menu_item_id: item.menu_item_id,
        quantity: item.quantity,
        status: 'pending' as OrderItemStatus,
        created_at: new Date().toISOString()
      }))

      const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItemsToInsert)

      if (itemsError) throw itemsError

      await supabase
        .from('tables')
        .update({ status: 'serving', current_order_id: order.id })
        .eq('id', tableId)

      return { success: true, data: order }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to create order' }
    }
  }

  async function updateOrderItemStatus(id: string, status: OrderItemStatus) {
    try {
      const updates: Partial<OrderItem> = { status }
      if (status === 'completed') {
        updates.completed_at = new Date().toISOString()
      }

      const { data, error: updateError } = await supabase
        .from('order_items')
        .update(updates)
        .eq('id', id)
        .select()
        .single()

      if (updateError) throw updateError
      
      const index = orderItems.value.findIndex(item => item.id === id)
      if (index !== -1) {
        orderItems.value[index] = { ...orderItems.value[index], ...data }
      }
      
      return { success: true, data }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to update order item' }
    }
  }

  async function completeOrder(orderId: string, totalAmount: number) {
    try {
      const { data, error: updateError } = await supabase
        .from('orders')
        .update({ status: 'paid', total_amount: totalAmount })
        .eq('id', orderId)
        .select(`
          *,
          table:tables!orders_table_id_fkey(*),
          items:order_items(
            *,
            menu_item:menu_items(*)
          )
        `)
        .single()

      if (updateError) throw updateError

      if (data.table_id) {
        await supabase
          .from('tables')
          .update({ status: 'available', current_order_id: null })
          .eq('id', data.table_id)
      }

      return { success: true, data }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to complete order' }
    }
  }

  function subscribeToOrderItems() {
    return supabase
      .channel('order-items-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'order_items' }, async () => {
        await fetchOrderItems()
      })
      .subscribe()
  }

  return {
    orders,
    orderItems,
    loading,
    error,
    pendingOrderItems,
    fetchOrders,
    fetchOrderItems,
    createOrder,
    updateOrderItemStatus,
    completeOrder,
    subscribeToOrderItems
  }
})
