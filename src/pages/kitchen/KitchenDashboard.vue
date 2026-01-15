<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useOrderStore } from '@/stores/orders'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Tag from 'primevue/tag'

const orderStore = useOrderStore()
const toast = useToast()
const processingItems = ref<Set<string>>(new Set())

let subscription: ReturnType<typeof orderStore.subscribeToOrderItems> | null = null
let notificationSound: HTMLAudioElement | null = null

onMounted(async () => {
  await orderStore.fetchOrderItems()
  subscription = orderStore.subscribeToOrderItems()
  
  try {
    notificationSound = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2teleS8EEDHC8t5zKQEWTNz/5HsrChdU4P/keCsKF1Tg/+R4KwoXVOD/5HgrChdU4P/keA==')
  } catch {
    console.log('Audio not supported')
  }
})

onUnmounted(() => {
  subscription?.unsubscribe()
})

function playNotification() {
  notificationSound?.play().catch(() => {})
}

function getStatusSeverity(status: string) {
  switch (status) {
    case 'pending': return 'danger'
    case 'cooking': return 'warning'
    case 'completed': return 'success'
    default: return 'secondary'
  }
}

function getStatusLabel(status: string) {
  switch (status) {
    case 'pending': return 'Chờ làm'
    case 'cooking': return 'Đang làm'
    case 'completed': return 'Hoàn thành'
    default: return status
  }
}

function formatTime(dateStr: string) {
  const date = new Date(dateStr)
  return date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
}

function getTimeAgo(dateStr: string) {
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  
  if (diffMins < 1) return 'Vừa xong'
  if (diffMins < 60) return `${diffMins} phút trước`
  const diffHours = Math.floor(diffMins / 60)
  return `${diffHours} giờ trước`
}

async function markAsCompleted(itemId: string) {
  processingItems.value.add(itemId)
  const result = await orderStore.updateOrderItemStatus(itemId, 'completed')
  processingItems.value.delete(itemId)
  
  if (result.success) {
    toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã hoàn thành món', life: 2000 })
    playNotification()
  } else {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: result.error, life: 3000 })
  }
}

async function startCooking(itemId: string) {
  processingItems.value.add(itemId)
  const result = await orderStore.updateOrderItemStatus(itemId, 'cooking')
  processingItems.value.delete(itemId)
  
  if (result.success) {
    toast.add({ severity: 'info', summary: 'Đang làm', detail: 'Bắt đầu làm món', life: 2000 })
  } else {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: result.error, life: 3000 })
  }
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Bếp</h1>
      <p class="text-gray-600">Danh sách món cần làm (sắp xếp theo thứ tự)</p>
    </div>

    <div class="flex gap-4 mb-6">
      <div class="flex items-center gap-2">
        <Tag value="Chờ làm" severity="danger" />
      </div>
      <div class="flex items-center gap-2">
        <Tag value="Đang làm" severity="warning" />
      </div>
      <div class="flex items-center gap-2">
        <Tag value="Hoàn thành" severity="success" />
      </div>
    </div>

    <div v-if="orderStore.loading" class="text-center py-12">
      <i class="pi pi-spin pi-spinner text-4xl text-orange-500"></i>
    </div>

    <div v-else-if="orderStore.pendingOrderItems.length === 0" class="text-center py-12">
      <i class="pi pi-check-circle text-6xl text-green-500 mb-4"></i>
      <p class="text-xl text-gray-600">Không có món nào cần làm</p>
      <p class="text-gray-500">Các món mới sẽ xuất hiện tự động</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <Card 
        v-for="(item, index) in orderStore.pendingOrderItems" 
        :key="item.id"
        :class="[
          'relative overflow-hidden transition-all',
          item.status === 'pending' ? 'border-l-4 border-red-500' : 'border-l-4 border-yellow-500'
        ]"
      >
        <template #header>
          <div class="bg-gray-100 px-4 py-2 flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span class="bg-orange-500 text-white rounded-full w-8 h-8 flex items-center justify-center font-bold">
                {{ index + 1 }}
              </span>
              <span class="font-semibold">
                Bàn {{ item.order?.table?.table_number || 'N/A' }}
              </span>
            </div>
            <Tag :value="getStatusLabel(item.status)" :severity="getStatusSeverity(item.status)" />
          </div>
        </template>
        
        <template #content>
          <div class="space-y-3">
            <div class="flex items-start gap-3">
              <img 
                :src="item.menu_item?.image_url || 'https://placehold.co/80x80/f97316/white?text=M'" 
                class="w-20 h-20 rounded-lg object-cover"
              />
              <div class="flex-1">
                <h3 class="font-bold text-lg">{{ item.menu_item?.name }}</h3>
                <p class="text-2xl font-bold text-orange-600">x{{ item.quantity }}</p>
              </div>
            </div>

            <div class="flex items-center gap-2 text-sm text-gray-500">
              <i class="pi pi-clock"></i>
              <span>{{ formatTime(item.created_at) }}</span>
              <span class="text-orange-600">({{ getTimeAgo(item.created_at) }})</span>
            </div>

            <div class="flex gap-2 pt-2">
              <Button 
                v-if="item.status === 'pending'"
                label="Bắt đầu làm" 
                icon="pi pi-play" 
                severity="warning"
                class="flex-1"
                :loading="processingItems.has(item.id)"
                @click="startCooking(item.id)"
              />
              <Button 
                label="Hoàn thành" 
                icon="pi pi-check" 
                severity="success"
                class="flex-1"
                :loading="processingItems.has(item.id)"
                @click="markAsCompleted(item.id)"
              />
            </div>
          </div>
        </template>
      </Card>
    </div>
  </div>
</template>
