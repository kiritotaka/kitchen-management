<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import Button from 'primevue/button'
import Menubar from 'primevue/menubar'

const router = useRouter()
const authStore = useAuthStore()

const menuItems = computed(() => {
  const items = [
    { label: 'Menu', icon: 'pi pi-book', command: () => router.push('/menu') }
  ]

  if (authStore.isAuthenticated) {
    if (['staff', 'manager', 'admin'].includes(authStore.userRole)) {
      items.push({ label: 'Bàn', icon: 'pi pi-table', command: () => router.push('/staff') })
    }
    if (['kitchen', 'admin'].includes(authStore.userRole)) {
      items.push({ label: 'Bếp', icon: 'pi pi-fire', command: () => router.push('/kitchen') })
    }
    if (['manager', 'admin'].includes(authStore.userRole)) {
      items.push({ label: 'Quản lý', icon: 'pi pi-briefcase', command: () => router.push('/manager') })
    }
    if (authStore.userRole === 'admin') {
      items.push({ label: 'Admin', icon: 'pi pi-cog', command: () => router.push('/admin') })
    }
  }

  return items
})

function handleLogout() {
  authStore.logout()
  router.push('/menu')
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <header class="bg-white shadow-sm">
      <div class="max-w-7xl mx-auto px-4">
        <div class="flex items-center justify-between h-16">
          <div class="flex items-center gap-4">
            <h1 class="text-xl font-bold text-orange-600 cursor-pointer" @click="router.push('/')">
              <i class="pi pi-star-fill mr-2"></i>
              Quán Ăn
            </h1>
            <Menubar :model="menuItems" class="border-0 bg-transparent" />
          </div>
          
          <div class="flex items-center gap-3">
            <template v-if="authStore.isAuthenticated">
              <span class="text-sm text-gray-600">
                <i class="pi pi-user mr-1"></i>
                {{ authStore.user?.full_name }}
                <span class="text-xs bg-orange-100 text-orange-700 px-2 py-1 rounded ml-2">
                  {{ authStore.userRole }}
                </span>
              </span>
              <Button 
                label="Đăng xuất" 
                icon="pi pi-sign-out" 
                severity="secondary" 
                size="small"
                @click="handleLogout" 
              />
            </template>
            <template v-else>
              <Button 
                label="Đăng nhập" 
                icon="pi pi-sign-in" 
                size="small"
                @click="router.push('/login')" 
              />
            </template>
          </div>
        </div>
      </div>
    </header>

    <main class="max-w-7xl mx-auto px-4 py-6">
      <slot />
    </main>
  </div>
</template>
