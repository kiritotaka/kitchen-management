<script setup lang="ts">
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { useTableStore } from '@/stores/tables'
import { useMenuStore } from '@/stores/menu'
import { useOrderStore } from '@/stores/orders'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'primevue/usetoast'
import { supabase } from '@/services/supabase'
import type { Table, MenuItem } from '@/types'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import Tag from 'primevue/tag'

const tableStore = useTableStore()
const menuStore = useMenuStore()
const orderStore = useOrderStore()
const authStore = useAuthStore()
const toast = useToast()

const selectedTable = ref<Table | null>(null)
const showOrderDialog = ref(false)
const orderItems = ref<{ item: MenuItem; quantity: number }[]>([])
const orderNotes = ref('')
const submitting = ref(false)

let subscription: ReturnType<typeof tableStore.subscribeToChanges> | null = null

onMounted(async () => {
  await Promise.all([
    tableStore.fetchTables(),
    menuStore.fetchMenuItems(),
    menuStore.fetchCategories()
  ])
  subscription = tableStore.subscribeToChanges()
})

onUnmounted(() => {
  subscription?.unsubscribe()
})

const availableMenuItems = computed(() => menuStore.menuItems.filter(item => item.is_available))

const orderTotal = computed(() => {
  return orderItems.value.reduce((sum, oi) => sum + oi.item.price * oi.quantity, 0)
})

function getStatusColor(status: string) {
  switch (status) {
    case 'available': return 'bg-green-500'
    case 'serving': return 'bg-orange-500'
    case 'reserved': return 'bg-blue-500'
    default: return 'bg-gray-500'
  }
}

function getStatusLabel(status: string) {
  switch (status) {
    case 'available': return 'Trống'
    case 'serving': return 'Đang phục vụ'
    case 'reserved': return 'Đã đặt'
    default: return status
  }
}

const existingOrderItems = ref<{ id: string; menu_item: MenuItem; quantity: number; status: string }[]>([])
const loadingExistingOrder = ref(false)

async function selectTable(table: Table) {
  selectedTable.value = table
  orderItems.value = []
  orderNotes.value = ''
  existingOrderItems.value = []
  showOrderDialog.value = true
  
  if (table.status === 'serving' && table.current_order_id) {
    loadingExistingOrder.value = true
    try {
      const { data, error } = await supabase
        .from('order_items')
        .select(`
          id,
          quantity,
          status,
          menu_item:menu_items(*)
        `)
        .eq('order_id', table.current_order_id)
      
      if (!error && data) {
        existingOrderItems.value = data.map(item => ({
          id: item.id,
          menu_item: item.menu_item as unknown as MenuItem,
          quantity: item.quantity,
          status: item.status
        }))
      }
    } catch (e) {
      console.error('Error loading existing order:', e)
    } finally {
      loadingExistingOrder.value = false
    }
  }
}

function addItem(item: MenuItem) {
  const existing = orderItems.value.find(oi => oi.item.id === item.id)
  if (existing) {
    existing.quantity++
  } else {
    orderItems.value.push({ item, quantity: 1 })
  }
}

function removeItem(index: number) {
  orderItems.value.splice(index, 1)
}

function formatPrice(price: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price)
}

async function submitOrder() {
  if (!selectedTable.value || orderItems.value.length === 0) {
    toast.add({ severity: 'warn', summary: 'Cảnh báo', detail: 'Vui lòng chọn ít nhất một món', life: 3000 })
    return
  }

  submitting.value = true
  
  try {
    if (selectedTable.value.status === 'serving' && selectedTable.value.current_order_id) {
      const orderItemsToInsert = orderItems.value.map(oi => ({
        order_id: selectedTable.value!.current_order_id,
        menu_item_id: oi.item.id,
        quantity: oi.quantity,
        status: 'pending',
        created_at: new Date().toISOString()
      }))

      const { error } = await supabase
        .from('order_items')
        .insert(orderItemsToInsert)

      if (error) throw error

      toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã thêm món vào order', life: 3000 })
    } else {
      const items = orderItems.value.map(oi => ({
        menu_item_id: oi.item.id,
        quantity: oi.quantity
      }))

      const result = await orderStore.createOrder(
        selectedTable.value.id,
        authStore.user!.id,
        items,
        orderNotes.value || undefined
      )

      if (!result.success) throw new Error(result.error)
      toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã gửi order đến bếp', life: 3000 })
    }
    
    showOrderDialog.value = false
    await tableStore.fetchTables()
  } catch (e: unknown) {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Thao tác thất bại', life: 3000 })
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Quản lý bàn</h1>
      <p class="text-gray-600">Chọn bàn để đặt món cho khách</p>
    </div>

    <div class="flex gap-4 mb-6">
      <div class="flex items-center gap-2">
        <span class="w-4 h-4 rounded-full bg-green-500"></span>
        <span class="text-sm">Trống</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="w-4 h-4 rounded-full bg-orange-500"></span>
        <span class="text-sm">Đang phục vụ</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="w-4 h-4 rounded-full bg-blue-500"></span>
        <span class="text-sm">Đã đặt trước</span>
      </div>
    </div>

    <div v-if="tableStore.loading" class="text-center py-12">
      <i class="pi pi-spin pi-spinner text-4xl text-orange-500"></i>
    </div>

    <div v-else class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4">
      <div 
        v-for="table in tableStore.tables" 
        :key="table.id"
        class="bg-white rounded-lg shadow-md p-4 cursor-pointer hover:shadow-lg transition-shadow border-2 border-transparent hover:border-orange-300"
        @click="selectTable(table)"
      >
        <div class="text-center">
          <div :class="['w-16 h-16 rounded-full mx-auto mb-3 flex items-center justify-center text-white font-bold text-xl', getStatusColor(table.status)]">
            {{ table.table_number }}
          </div>
          <h3 class="font-semibold text-gray-800">Bàn {{ table.table_number }}</h3>
          <p class="text-sm text-gray-500">{{ table.capacity }} chỗ</p>
          <Tag :value="getStatusLabel(table.status)" :severity="table.status === 'available' ? 'success' : table.status === 'serving' ? 'warning' : 'info'" class="mt-2" />
        </div>
      </div>
    </div>

    <Dialog 
      v-model:visible="showOrderDialog" 
      :header="`Đặt món - Bàn ${selectedTable?.table_number}`"
      :style="{ width: '90vw', maxWidth: '1000px' }"
      modal
    >
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div>
          <h3 class="font-semibold mb-3">Chọn món</h3>
          <div class="max-h-96 overflow-y-auto space-y-2">
            <div 
              v-for="item in availableMenuItems" 
              :key="item.id"
              class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 cursor-pointer"
              @click="addItem(item)"
            >
              <div class="flex items-center gap-3">
                <img 
                  :src="item.image_url || 'https://placehold.co/60x60/f97316/white?text=M'" 
                  class="w-12 h-12 rounded object-cover"
                />
                <div>
                  <p class="font-medium">{{ item.name }}</p>
                  <p class="text-sm text-orange-600">{{ formatPrice(item.price) }}</p>
                </div>
              </div>
              <Button icon="pi pi-plus" size="small" rounded />
            </div>
          </div>
        </div>

        <div>
          <div v-if="selectedTable?.status === 'serving'" class="mb-4">
            <h3 class="font-semibold mb-3 text-orange-600">Món đang phục vụ</h3>
            <div v-if="loadingExistingOrder" class="text-center py-4">
              <i class="pi pi-spin pi-spinner text-2xl text-orange-500"></i>
            </div>
            <div v-else-if="existingOrderItems.length === 0" class="text-center py-4 text-gray-500 text-sm">
              Không có món nào
            </div>
            <div v-else class="space-y-2 max-h-40 overflow-y-auto mb-4">
              <div v-for="item in existingOrderItems" :key="item.id" class="flex items-center justify-between p-2 bg-orange-50 rounded">
                <div class="flex items-center gap-2">
                  <span class="font-medium">{{ item.menu_item?.name }}</span>
                  <span class="text-orange-600 font-bold">x{{ item.quantity }}</span>
                </div>
                <Tag 
                  :value="item.status === 'pending' ? 'Chờ' : item.status === 'cooking' ? 'Đang làm' : 'Xong'" 
                  :severity="item.status === 'pending' ? 'danger' : item.status === 'cooking' ? 'warning' : 'success'" 
                  size="small"
                />
              </div>
            </div>
            <hr class="my-3" />
          </div>
          
          <h3 class="font-semibold mb-3">Thêm món mới</h3>
          <div v-if="orderItems.length === 0" class="text-center py-8 text-gray-500">
            <i class="pi pi-shopping-cart text-4xl mb-2"></i>
            <p>Chưa chọn món nào</p>
          </div>
          <DataTable v-else :value="orderItems" class="mb-4">
            <Column field="item.name" header="Món" />
            <Column header="SL" style="width: 100px">
              <template #body="{ data }">
                <InputNumber v-model="data.quantity" :min="1" :max="99" showButtons buttonLayout="horizontal" class="w-24" />
              </template>
            </Column>
            <Column header="Giá" style="width: 120px">
              <template #body="{ data }">
                {{ formatPrice(data.item.price * data.quantity) }}
              </template>
            </Column>
            <Column style="width: 60px">
              <template #body="{ index }">
                <Button icon="pi pi-trash" severity="danger" size="small" text @click="removeItem(index)" />
              </template>
            </Column>
          </DataTable>

          <Textarea v-model="orderNotes" placeholder="Ghi chú cho bếp..." rows="2" class="w-full mb-4" />

          <div class="flex items-center justify-between p-4 bg-orange-50 rounded-lg">
            <span class="font-semibold">Tổng cộng:</span>
            <span class="text-xl font-bold text-orange-600">{{ formatPrice(orderTotal) }}</span>
          </div>

          <Button 
            :label="selectedTable?.status === 'serving' ? 'Thêm món' : 'Xác nhận Order'" 
            icon="pi pi-check" 
            class="w-full mt-4"
            :loading="submitting"
            :disabled="orderItems.length === 0"
            @click="submitOrder"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>
