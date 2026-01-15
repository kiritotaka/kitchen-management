<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { useToast } from 'primevue/usetoast'
import Card from 'primevue/card'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import DatePicker from 'primevue/datepicker'
import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown'
import { supabase } from '@/services/supabase'

interface OrderWithItems {
  id: string
  order_time: string
  total_amount: number
  status: string
  items: Array<{
    quantity: number
    menu_item: {
      id: string
      name: string
      price: number
    }
  }>
}

const toast = useToast()

const loading = ref(false)
const dateRange = ref<Date[]>([])
const viewMode = ref<'day' | 'month' | 'year'>('day')
const orders = ref<OrderWithItems[]>([])

const viewModeOptions = [
  { label: 'Theo ngày', value: 'day' },
  { label: 'Theo tháng', value: 'month' },
  { label: 'Theo năm', value: 'year' }
]

const totalRevenue = computed(() => {
  return orders.value
    .filter(o => o.status === 'paid')
    .reduce((sum, o) => sum + o.total_amount, 0)
})

const totalOrders = computed(() => {
  return orders.value.filter(o => o.status === 'paid').length
})

const averageOrderValue = computed(() => {
  if (totalOrders.value === 0) return 0
  return totalRevenue.value / totalOrders.value
})

const topDishes = computed(() => {
  const dishMap = new Map<string, { name: string; quantity: number; revenue: number }>()
  
  orders.value
    .filter(o => o.status === 'paid')
    .forEach(order => {
      order.items?.forEach(item => {
        const key = item.menu_item?.id
        if (!key) return
        
        const existing = dishMap.get(key) || { name: item.menu_item.name, quantity: 0, revenue: 0 }
        existing.quantity += item.quantity
        existing.revenue += item.menu_item.price * item.quantity
        dishMap.set(key, existing)
      })
    })
  
  return Array.from(dishMap.values())
    .sort((a, b) => b.quantity - a.quantity)
    .slice(0, 10)
})

const revenueByDate = computed(() => {
  const dateMap = new Map<string, number>()
  
  orders.value
    .filter(o => o.status === 'paid')
    .forEach(order => {
      const date = new Date(order.order_time)
      let key: string
      
      if (viewMode.value === 'day') {
        key = date.toLocaleDateString('vi-VN')
      } else if (viewMode.value === 'month') {
        key = `${date.getMonth() + 1}/${date.getFullYear()}`
      } else {
        key = `${date.getFullYear()}`
      }
      
      dateMap.set(key, (dateMap.get(key) || 0) + order.total_amount)
    })
  
  return Array.from(dateMap.entries())
    .map(([date, revenue]) => ({ date, revenue }))
    .sort((a, b) => a.date.localeCompare(b.date))
})

onMounted(async () => {
  const today = new Date()
  const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
  dateRange.value = [startOfMonth, today]
  await fetchData()
})

async function fetchData() {
  loading.value = true
  
  try {
    let query = supabase
      .from('orders')
      .select(`
        id,
        order_time,
        total_amount,
        status,
        items:order_items(
          quantity,
          menu_item:menu_items(id, name, price)
        )
      `)
      .eq('status', 'paid')
      .order('order_time', { ascending: false })

    if (dateRange.value.length === 2 && dateRange.value[0] && dateRange.value[1]) {
      const start = dateRange.value[0].toISOString()
      const end = new Date(dateRange.value[1].getTime() + 86400000).toISOString()
      query = query.gte('order_time', start).lt('order_time', end)
    }

    const { data, error } = await query

    if (error) throw error
    
    orders.value = (data || []).map((order: any) => ({
      id: order.id,
      order_time: order.order_time,
      total_amount: order.total_amount,
      status: order.status,
      items: (order.items || []).map((item: any) => ({
        quantity: item.quantity,
        menu_item: Array.isArray(item.menu_item) ? item.menu_item[0] : item.menu_item
      }))
    }))
  } catch (e: unknown) {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Không thể tải dữ liệu', life: 3000 })
  } finally {
    loading.value = false
  }
}

function formatPrice(price: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price)
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Thống kê & Báo cáo</h1>
      <p class="text-gray-600">Phân tích doanh thu và hiệu suất</p>
    </div>

    <div class="flex flex-wrap gap-4 mb-6 bg-white p-4 rounded-lg shadow">
      <div class="flex flex-col gap-2">
        <label class="font-medium text-sm">Khoảng thời gian</label>
        <DatePicker v-model="dateRange" selectionMode="range" dateFormat="dd/mm/yy" showIcon class="w-64" />
      </div>
      <div class="flex flex-col gap-2">
        <label class="font-medium text-sm">Xem theo</label>
        <Dropdown v-model="viewMode" :options="viewModeOptions" optionLabel="label" optionValue="value" class="w-40" />
      </div>
      <div class="flex items-end">
        <Button label="Áp dụng" icon="pi pi-search" :loading="loading" @click="fetchData" />
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
      <Card>
        <template #content>
          <div class="text-center">
            <i class="pi pi-dollar text-4xl text-green-500 mb-2"></i>
            <p class="text-gray-600 text-sm">Tổng doanh thu</p>
            <p class="text-2xl font-bold text-green-600">{{ formatPrice(totalRevenue) }}</p>
          </div>
        </template>
      </Card>
      <Card>
        <template #content>
          <div class="text-center">
            <i class="pi pi-shopping-cart text-4xl text-blue-500 mb-2"></i>
            <p class="text-gray-600 text-sm">Tổng đơn hàng</p>
            <p class="text-2xl font-bold text-blue-600">{{ totalOrders }}</p>
          </div>
        </template>
      </Card>
      <Card>
        <template #content>
          <div class="text-center">
            <i class="pi pi-chart-line text-4xl text-orange-500 mb-2"></i>
            <p class="text-gray-600 text-sm">Giá trị TB/đơn</p>
            <p class="text-2xl font-bold text-orange-600">{{ formatPrice(averageOrderValue) }}</p>
          </div>
        </template>
      </Card>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <Card>
        <template #title>
          <div class="flex items-center gap-2">
            <i class="pi pi-star text-yellow-500"></i>
            <span>Top 10 món bán chạy</span>
          </div>
        </template>
        <template #content>
          <DataTable :value="topDishes" :loading="loading" stripedRows>
            <Column field="name" header="Tên món" />
            <Column field="quantity" header="Số lượng" sortable style="width: 100px" />
            <Column header="Doanh thu" sortable style="width: 150px">
              <template #body="{ data }">
                {{ formatPrice(data.revenue) }}
              </template>
            </Column>
          </DataTable>
        </template>
      </Card>

      <Card>
        <template #title>
          <div class="flex items-center gap-2">
            <i class="pi pi-chart-bar text-blue-500"></i>
            <span>Doanh thu theo thời gian</span>
          </div>
        </template>
        <template #content>
          <DataTable :value="revenueByDate" :loading="loading" stripedRows>
            <Column field="date" header="Thời gian" />
            <Column header="Doanh thu" sortable>
              <template #body="{ data }">
                {{ formatPrice(data.revenue) }}
              </template>
            </Column>
          </DataTable>
        </template>
      </Card>
    </div>
  </div>
</template>
