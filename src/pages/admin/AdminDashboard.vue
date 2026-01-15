<script setup lang="ts">
import { useRouter } from 'vue-router'
import Card from 'primevue/card'
import Button from 'primevue/button'

const router = useRouter()

const menuItems = [
  { 
    title: 'Quản lý Menu', 
    description: 'Thêm, sửa, xóa món ăn và danh mục', 
    icon: 'pi pi-book', 
    route: '/admin/menu',
    color: 'bg-orange-500'
  },
  { 
    title: 'Quản lý Người dùng', 
    description: 'Quản lý tài khoản nhân viên', 
    icon: 'pi pi-users', 
    route: '/admin/users',
    color: 'bg-blue-500'
  },
  { 
    title: 'Quản lý Bàn', 
    description: 'Thêm, sửa, xóa bàn', 
    icon: 'pi pi-table', 
    route: '/admin/tables',
    color: 'bg-green-500'
  },
  { 
    title: 'Thống kê & Báo cáo', 
    description: 'Doanh thu, món bán chạy, phân tích', 
    icon: 'pi pi-chart-bar', 
    route: '/admin/analytics',
    color: 'bg-purple-500'
  }
]

const quickLinks = [
  { label: 'Xem bếp', icon: 'pi pi-fire', route: '/kitchen' },
  { label: 'Quản lý bàn', icon: 'pi pi-th-large', route: '/staff' },
  { label: 'Thanh toán', icon: 'pi pi-money-bill', route: '/manager' }
]
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Trang quản trị</h1>
      <p class="text-gray-600">Quản lý toàn bộ hệ thống quán ăn</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <Card 
        v-for="item in menuItems" 
        :key="item.route"
        class="cursor-pointer hover:shadow-lg transition-shadow"
        @click="router.push(item.route)"
      >
        <template #content>
          <div class="text-center">
            <div :class="['w-16 h-16 rounded-full mx-auto mb-4 flex items-center justify-center text-white', item.color]">
              <i :class="[item.icon, 'text-2xl']"></i>
            </div>
            <h3 class="font-bold text-lg mb-2">{{ item.title }}</h3>
            <p class="text-sm text-gray-600">{{ item.description }}</p>
          </div>
        </template>
      </Card>
    </div>

    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-lg font-bold mb-4">Truy cập nhanh</h2>
      <div class="flex flex-wrap gap-2">
        <Button 
          v-for="link in quickLinks" 
          :key="link.route"
          :label="link.label" 
          :icon="link.icon" 
          severity="secondary"
          @click="router.push(link.route)"
        />
      </div>
    </div>
  </div>
</template>
