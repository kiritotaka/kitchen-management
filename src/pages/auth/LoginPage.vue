<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'primevue/usetoast'
import Card from 'primevue/card'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import Button from 'primevue/button'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const email = ref('')
const password = ref('')

async function handleLogin() {
  if (!email.value || !password.value) {
    toast.add({ severity: 'warn', summary: 'Cảnh báo', detail: 'Vui lòng nhập email và mật khẩu', life: 3000 })
    return
  }

  const result = await authStore.login(email.value, password.value)
  
  if (result.success) {
    toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đăng nhập thành công', life: 3000 })
    router.push(authStore.getHomeRoute())
  } else {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: result.error || 'Đăng nhập thất bại', life: 3000 })
  }
}
</script>

<template>
  <div class="flex items-center justify-center min-h-[80vh]">
    <Card class="w-full max-w-md">
      <template #title>
        <div class="text-center">
          <i class="pi pi-star-fill text-orange-500 text-4xl mb-4"></i>
          <h2 class="text-2xl font-bold text-gray-800">Đăng nhập</h2>
          <p class="text-sm text-gray-500 mt-2">Hệ thống quản lý quán ăn</p>
        </div>
      </template>
      <template #content>
        <form @submit.prevent="handleLogin" class="space-y-4">
          <div class="flex flex-col gap-2">
            <label for="email" class="font-medium text-gray-700">Email</label>
            <InputText 
              id="email" 
              v-model="email" 
              type="email" 
              placeholder="Nhập email" 
              class="w-full"
            />
          </div>
          
          <div class="flex flex-col gap-2">
            <label for="password" class="font-medium text-gray-700">Mật khẩu</label>
            <Password 
              id="password" 
              v-model="password" 
              placeholder="Nhập mật khẩu"
              :feedback="false"
              toggleMask
              class="w-full"
              inputClass="w-full"
            />
          </div>

          <Button 
            type="submit" 
            label="Đăng nhập" 
            icon="pi pi-sign-in" 
            class="w-full mt-4"
            :loading="authStore.loading"
          />
        </form>
      </template>
    </Card>
  </div>
</template>
