<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useMenuStore } from '@/stores/menu'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Tag from 'primevue/tag'
import Skeleton from 'primevue/skeleton'

const menuStore = useMenuStore()
const searchInput = ref('')

onMounted(async () => {
  await Promise.all([
    menuStore.fetchCategories(),
    menuStore.fetchMenuItems()
  ])
})

function selectCategory(categoryId: string | null) {
  menuStore.selectedCategory = categoryId
}

function handleSearch() {
  menuStore.searchQuery = searchInput.value
}

function formatPrice(price: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price)
}

function getBadgeSeverity(badge: string) {
  switch (badge.toLowerCase()) {
    case 'bestseller': return 'success'
    case 'new': return 'info'
    case 'promotion': return 'warning'
    default: return 'secondary'
  }
}
</script>

<template>
  <div>
    <div class="text-center mb-8">
      <h1 class="text-3xl font-bold text-gray-800 mb-2">Thực đơn</h1>
      <p class="text-gray-600">Khám phá các món ăn ngon tại quán</p>
    </div>

    <div class="flex flex-col md:flex-row gap-4 mb-6">
      <div class="flex-1">
        <div class="flex gap-2">
          <InputText 
            v-model="searchInput" 
            placeholder="Tìm kiếm món ăn..."
            class="flex-1"
            @keyup.enter="handleSearch"
          />
          <Button icon="pi pi-search" @click="handleSearch" />
        </div>
      </div>
    </div>

    <div class="flex flex-wrap gap-2 mb-6">
      <Button 
        label="Tất cả" 
        :severity="!menuStore.selectedCategory ? 'primary' : 'secondary'"
        size="small"
        @click="selectCategory(null)"
      />
      <Button 
        v-for="category in menuStore.categories" 
        :key="category.id"
        :label="category.name"
        :severity="menuStore.selectedCategory === category.id ? 'primary' : 'secondary'"
        size="small"
        @click="selectCategory(category.id)"
      />
    </div>

    <div v-if="menuStore.loading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      <Card v-for="i in 8" :key="i">
        <template #header>
          <Skeleton height="200px" />
        </template>
        <template #content>
          <Skeleton width="70%" class="mb-2" />
          <Skeleton width="40%" />
        </template>
      </Card>
    </div>

    <div v-else-if="menuStore.filteredMenuItems.length === 0" class="text-center py-12">
      <i class="pi pi-search text-4xl text-gray-400 mb-4"></i>
      <p class="text-gray-500">Không tìm thấy món ăn nào</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      <Card v-for="item in menuStore.filteredMenuItems" :key="item.id" class="overflow-hidden hover:shadow-lg transition-shadow">
        <template #header>
          <div class="relative">
            <img 
              :src="item.image_url || 'https://placehold.co/400x300/f97316/white?text=' + encodeURIComponent(item.name)" 
              :alt="item.name"
              class="w-full h-48 object-cover"
            />
            <div v-if="item.badges?.length" class="absolute top-2 left-2 flex gap-1">
              <Tag 
                v-for="badge in item.badges" 
                :key="badge" 
                :value="badge" 
                :severity="getBadgeSeverity(badge)"
              />
            </div>
          </div>
        </template>
        <template #title>
          <h3 class="text-lg font-semibold text-gray-800 line-clamp-1">{{ item.name }}</h3>
        </template>
        <template #subtitle>
          <span class="text-orange-600 font-bold text-lg">{{ formatPrice(item.price) }}</span>
        </template>
        <template #content>
          <p class="text-gray-600 text-sm line-clamp-2">{{ item.description || 'Món ăn ngon miệng' }}</p>
          <div v-if="item.category" class="mt-2">
            <Tag :value="item.category.name" severity="secondary" />
          </div>
        </template>
      </Card>
    </div>
  </div>
</template>
