<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import type { User, UserRole } from '@/types'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Dropdown from 'primevue/dropdown'
import Tag from 'primevue/tag'
import { supabase } from '@/services/supabase'

const toast = useToast()
const confirm = useConfirm()

const users = ref<User[]>([])
const loading = ref(false)
const showDialog = ref(false)
const editingUser = ref<User | null>(null)
const processing = ref(false)

const userForm = ref({
  email: '',
  full_name: '',
  phone: '',
  role: 'staff' as UserRole
})

const roleOptions = [
  { label: 'Nhân viên', value: 'staff' },
  { label: 'Bếp', value: 'kitchen' },
  { label: 'Quản lý', value: 'manager' },
  { label: 'Admin', value: 'admin' }
]

onMounted(async () => {
  await fetchUsers()
})

async function fetchUsers() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    users.value = data || []
  } catch (e: unknown) {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Không thể tải danh sách người dùng', life: 3000 })
  } finally {
    loading.value = false
  }
}

function getRoleSeverity(role: string) {
  switch (role) {
    case 'admin': return 'danger'
    case 'manager': return 'warning'
    case 'kitchen': return 'info'
    case 'staff': return 'success'
    default: return 'secondary'
  }
}

function getRoleLabel(role: string) {
  switch (role) {
    case 'admin': return 'Admin'
    case 'manager': return 'Quản lý'
    case 'kitchen': return 'Bếp'
    case 'staff': return 'Nhân viên'
    default: return role
  }
}

function openEditUser(user: User) {
  editingUser.value = user
  userForm.value = {
    email: user.email,
    full_name: user.full_name,
    phone: user.phone || '',
    role: user.role
  }
  showDialog.value = true
}

async function saveUser() {
  if (!userForm.value.full_name || !userForm.value.email) {
    toast.add({ severity: 'warn', summary: 'Cảnh báo', detail: 'Vui lòng nhập đầy đủ thông tin', life: 3000 })
    return
  }

  processing.value = true

  try {
    if (editingUser.value) {
      const { error } = await supabase
        .from('users')
        .update({
          full_name: userForm.value.full_name,
          phone: userForm.value.phone || null,
          role: userForm.value.role
        })
        .eq('id', editingUser.value.id)

      if (error) throw error
      toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã cập nhật người dùng', life: 3000 })
    }
    
    showDialog.value = false
    await fetchUsers()
  } catch (e: unknown) {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Thao tác thất bại', life: 3000 })
  } finally {
    processing.value = false
  }
}

function confirmDeleteUser(user: User) {
  confirm.require({
    message: `Bạn có chắc muốn xóa người dùng "${user.full_name}"?`,
    header: 'Xác nhận xóa',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        const { error } = await supabase.from('users').delete().eq('id', user.id)
        if (error) throw error
        toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã xóa người dùng', life: 3000 })
        await fetchUsers()
      } catch (e: unknown) {
        toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Xóa thất bại', life: 3000 })
      }
    }
  })
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('vi-VN')
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Quản lý Người dùng</h1>
        <p class="text-gray-600">Quản lý tài khoản nhân viên</p>
      </div>
    </div>

    <div class="bg-yellow-50 border-l-4 border-yellow-500 p-4 mb-6">
      <p class="text-yellow-700">
        <i class="pi pi-info-circle mr-2"></i>
        Để thêm người dùng mới, vui lòng tạo tài khoản trong Supabase Dashboard và họ sẽ tự động xuất hiện ở đây.
      </p>
    </div>

    <DataTable :value="users" :loading="loading" paginator :rows="10" stripedRows>
      <Column field="full_name" header="Họ tên" sortable />
      <Column field="email" header="Email" sortable />
      <Column field="phone" header="Điện thoại" />
      <Column header="Vai trò" sortable>
        <template #body="{ data }">
          <Tag :value="getRoleLabel(data.role)" :severity="getRoleSeverity(data.role)" />
        </template>
      </Column>
      <Column header="Ngày tạo">
        <template #body="{ data }">
          {{ formatDate(data.created_at) }}
        </template>
      </Column>
      <Column header="Thao tác" style="width: 150px">
        <template #body="{ data }">
          <div class="flex gap-1">
            <Button icon="pi pi-pencil" severity="info" size="small" text @click="openEditUser(data)" />
            <Button icon="pi pi-trash" severity="danger" size="small" text @click="confirmDeleteUser(data)" />
          </div>
        </template>
      </Column>
    </DataTable>

    <Dialog v-model:visible="showDialog" header="Sửa người dùng" :style="{ width: '450px' }" modal>
      <div class="space-y-4">
        <div class="flex flex-col gap-2">
          <label class="font-medium">Email</label>
          <InputText v-model="userForm.email" disabled class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Họ tên *</label>
          <InputText v-model="userForm.full_name" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Điện thoại</label>
          <InputText v-model="userForm.phone" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Vai trò</label>
          <Dropdown v-model="userForm.role" :options="roleOptions" optionLabel="label" optionValue="value" class="w-full" />
        </div>
        <Button label="Lưu" icon="pi pi-check" class="w-full" :loading="processing" @click="saveUser" />
      </div>
    </Dialog>
  </div>
</template>
