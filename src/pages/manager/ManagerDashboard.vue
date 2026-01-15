<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useTableStore } from '@/stores/tables'
import { useOrderStore } from '@/stores/orders'
import { useToast } from 'primevue/usetoast'
import type { Table, Order } from '@/types'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import InputText from 'primevue/inputtext'
import DatePicker from 'primevue/datepicker'
import InputNumber from 'primevue/inputnumber'
import { supabase } from '@/services/supabase'

const tableStore = useTableStore()
const orderStore = useOrderStore()
const toast = useToast()

const selectedTable = ref<Table | null>(null)
const showPaymentDialog = ref(false)
const showReservationDialog = ref(false)
const currentOrder = ref<Order | null>(null)
const processing = ref(false)

const reservationForm = ref({
  customer_name: '',
  phone: '',
  reservation_time: null as Date | null,
  guest_count: 2,
  notes: ''
})

onMounted(async () => {
  await Promise.all([
    tableStore.fetchTables(),
    orderStore.fetchOrders()
  ])
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

function formatPrice(price: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price)
}

function formatDateTime(dateStr: string) {
  return new Date(dateStr).toLocaleString('vi-VN')
}

async function selectTable(table: Table) {
  selectedTable.value = table
  
  if (table.status === 'serving' && table.current_order_id) {
    await orderStore.fetchOrders()
    currentOrder.value = orderStore.orders.find(o => o.id === table.current_order_id) || null
    
    if (!currentOrder.value) {
      const { data } = await supabase
        .from('orders')
        .select(`
          *,
          table:tables!orders_table_id_fkey(*),
          items:order_items(*, menu_item:menu_items(*))
        `)
        .eq('id', table.current_order_id)
        .single()
      
      currentOrder.value = data
    }
    
    showPaymentDialog.value = true
  } else if (table.status === 'available') {
    showReservationDialog.value = true
  } else if (table.status === 'reserved') {
    const result = await tableStore.updateTableStatus(table.id, 'available')
    if (result.success) {
      toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã hủy đặt bàn', life: 3000 })
    }
  }
}

function calculateTotal() {
  if (!currentOrder.value?.items) return 0
  return currentOrder.value.items.reduce((sum, item) => {
    const price = item.menu_item?.price || 0
    return sum + (price * item.quantity)
  }, 0)
}

async function processPayment() {
  if (!currentOrder.value) return
  
  processing.value = true
  const total = calculateTotal()
  const result = await orderStore.completeOrder(currentOrder.value.id, total)
  processing.value = false
  
  if (result.success) {
    toast.add({ severity: 'success', summary: 'Thành công', detail: 'Thanh toán thành công', life: 3000 })
    printInvoice(result.data)
    showPaymentDialog.value = false
    await tableStore.fetchTables()
  } else {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: result.error, life: 3000 })
  }
}

function printInvoice(order: Order) {
  const total = order.items?.reduce((sum, item) => {
    const price = item.menu_item?.price || 0
    return sum + (price * item.quantity)
  }, 0) || 0
  
  const vat = total * 0.1
  const grandTotal = total + vat
  
  const invoiceHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Hóa đơn</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 300px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 20px; }
        .header h1 { margin: 0; font-size: 20px; }
        .info { font-size: 12px; margin-bottom: 15px; }
        table { width: 100%; border-collapse: collapse; font-size: 12px; }
        th, td { padding: 5px; text-align: left; border-bottom: 1px dashed #ccc; }
        .total { font-weight: bold; margin-top: 10px; }
        .footer { text-align: center; margin-top: 20px; font-size: 11px; }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>QUÁN ĂN</h1>
        <p>123 Đường ABC, Quận XYZ</p>
        <p>ĐT: 0123.456.789</p>
      </div>
      <div class="info">
        <p><strong>Bàn:</strong> ${order.table?.table_number || 'N/A'}</p>
        <p><strong>Thời gian:</strong> ${formatDateTime(order.order_time)}</p>
        <p><strong>Mã HĐ:</strong> ${order.id.slice(0, 8).toUpperCase()}</p>
      </div>
      <table>
        <thead>
          <tr><th>Món</th><th>SL</th><th>Giá</th></tr>
        </thead>
        <tbody>
          ${order.items?.map(item => `
            <tr>
              <td>${item.menu_item?.name}</td>
              <td>${item.quantity}</td>
              <td>${formatPrice((item.menu_item?.price || 0) * item.quantity)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
      <div class="total">
        <p>Tạm tính: ${formatPrice(total)}</p>
        <p>VAT (10%): ${formatPrice(vat)}</p>
        <p style="font-size: 16px;">TỔNG: ${formatPrice(grandTotal)}</p>
      </div>
      <div class="footer">
        <p>Cảm ơn quý khách!</p>
        <p>Hẹn gặp lại!</p>
      </div>
    </body>
    </html>
  `
  
  const printWindow = window.open('', '_blank')
  if (printWindow) {
    printWindow.document.write(invoiceHtml)
    printWindow.document.close()
    printWindow.print()
  }
}

async function createReservation() {
  if (!selectedTable.value || !reservationForm.value.customer_name || !reservationForm.value.phone) {
    toast.add({ severity: 'warn', summary: 'Cảnh báo', detail: 'Vui lòng nhập đầy đủ thông tin', life: 3000 })
    return
  }

  processing.value = true
  
  try {
    const { error } = await supabase
      .from('reservations')
      .insert({
        table_id: selectedTable.value.id,
        customer_name: reservationForm.value.customer_name,
        phone: reservationForm.value.phone,
        reservation_time: reservationForm.value.reservation_time?.toISOString() || new Date().toISOString(),
        guest_count: reservationForm.value.guest_count,
        notes: reservationForm.value.notes,
        status: 'confirmed'
      })

    if (error) throw error

    await tableStore.updateTableStatus(selectedTable.value.id, 'reserved')
    
    toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã đặt bàn thành công', life: 3000 })
    showReservationDialog.value = false
    reservationForm.value = { customer_name: '', phone: '', reservation_time: null, guest_count: 2, notes: '' }
  } catch (e: unknown) {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Đặt bàn thất bại', life: 3000 })
  } finally {
    processing.value = false
  }
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Quản lý</h1>
      <p class="text-gray-600">Đặt bàn và thanh toán</p>
    </div>

    <div class="flex gap-4 mb-6">
      <div class="flex items-center gap-2">
        <span class="w-4 h-4 rounded-full bg-green-500"></span>
        <span class="text-sm">Trống (Nhấn để đặt bàn)</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="w-4 h-4 rounded-full bg-orange-500"></span>
        <span class="text-sm">Đang phục vụ (Nhấn để thanh toán)</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="w-4 h-4 rounded-full bg-blue-500"></span>
        <span class="text-sm">Đã đặt (Nhấn để hủy)</span>
      </div>
    </div>

    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4">
      <div 
        v-for="table in tableStore.tables" 
        :key="table.id"
        class="bg-white rounded-lg shadow-md p-4 cursor-pointer hover:shadow-lg transition-shadow"
        @click="selectTable(table)"
      >
        <div class="text-center">
          <div :class="['w-16 h-16 rounded-full mx-auto mb-3 flex items-center justify-center text-white font-bold text-xl', getStatusColor(table.status)]">
            {{ table.table_number }}
          </div>
          <h3 class="font-semibold">Bàn {{ table.table_number }}</h3>
          <Tag :value="getStatusLabel(table.status)" :severity="table.status === 'available' ? 'success' : table.status === 'serving' ? 'warning' : 'info'" class="mt-2" />
        </div>
      </div>
    </div>

    <Dialog 
      v-model:visible="showPaymentDialog" 
      :header="`Thanh toán - Bàn ${selectedTable?.table_number}`"
      :style="{ width: '600px' }"
      modal
    >
      <div v-if="currentOrder">
        <DataTable :value="currentOrder.items" class="mb-4">
          <Column field="menu_item.name" header="Món" />
          <Column field="quantity" header="SL" style="width: 80px" />
          <Column header="Đơn giá" style="width: 120px">
            <template #body="{ data }">
              {{ formatPrice(data.menu_item?.price || 0) }}
            </template>
          </Column>
          <Column header="Thành tiền" style="width: 120px">
            <template #body="{ data }">
              {{ formatPrice((data.menu_item?.price || 0) * data.quantity) }}
            </template>
          </Column>
        </DataTable>

        <div class="bg-gray-50 rounded-lg p-4 space-y-2">
          <div class="flex justify-between">
            <span>Tạm tính:</span>
            <span>{{ formatPrice(calculateTotal()) }}</span>
          </div>
          <div class="flex justify-between">
            <span>VAT (10%):</span>
            <span>{{ formatPrice(calculateTotal() * 0.1) }}</span>
          </div>
          <div class="flex justify-between text-xl font-bold text-orange-600">
            <span>Tổng cộng:</span>
            <span>{{ formatPrice(calculateTotal() * 1.1) }}</span>
          </div>
        </div>

        <div class="flex gap-2 mt-4">
          <Button 
            label="In hóa đơn" 
            icon="pi pi-print" 
            severity="secondary" 
            class="flex-1"
            @click="printInvoice(currentOrder)"
          />
          <Button 
            label="Thanh toán" 
            icon="pi pi-check" 
            class="flex-1"
            :loading="processing"
            @click="processPayment"
          />
        </div>
      </div>
    </Dialog>

    <Dialog 
      v-model:visible="showReservationDialog" 
      :header="`Đặt bàn ${selectedTable?.table_number}`"
      :style="{ width: '500px' }"
      modal
    >
      <div class="space-y-4">
        <div class="flex flex-col gap-2">
          <label class="font-medium">Tên khách hàng *</label>
          <InputText v-model="reservationForm.customer_name" placeholder="Nhập tên khách" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Số điện thoại *</label>
          <InputText v-model="reservationForm.phone" placeholder="Nhập số điện thoại" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Thời gian đặt</label>
          <DatePicker v-model="reservationForm.reservation_time" showTime hourFormat="24" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Số khách</label>
          <InputNumber v-model="reservationForm.guest_count" :min="1" :max="20" showButtons class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Ghi chú</label>
          <InputText v-model="reservationForm.notes" placeholder="Ghi chú thêm" class="w-full" />
        </div>
        <Button 
          label="Xác nhận đặt bàn" 
          icon="pi pi-check" 
          class="w-full"
          :loading="processing"
          @click="createReservation"
        />
      </div>
    </Dialog>
  </div>
</template>
