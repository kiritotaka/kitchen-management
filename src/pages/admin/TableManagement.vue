<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useTableStore } from '@/stores/tables'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import type { Table } from '@/types'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import InputNumber from 'primevue/inputnumber'
import Tag from 'primevue/tag'

const tableStore = useTableStore()
const toast = useToast()
const confirm = useConfirm()

const showDialog = ref(false)
const editingTable = ref<Table | null>(null)
const processing = ref(false)

const tableForm = ref({
  table_number: 1,
  capacity: 4
})

onMounted(async () => {
  await tableStore.fetchTables()
})

function getStatusLabel(status: string) {
  switch (status) {
    case 'available': return 'Trống'
    case 'serving': return 'Đang phục vụ'
    case 'reserved': return 'Đã đặt'
    default: return status
  }
}

function getStatusSeverity(status: string) {
  switch (status) {
    case 'available': return 'success'
    case 'serving': return 'warning'
    case 'reserved': return 'info'
    default: return 'secondary'
  }
}

function openAddTable() {
  editingTable.value = null
  const maxNumber = tableStore.tables.reduce((max, t) => Math.max(max, t.table_number), 0)
  tableForm.value = { table_number: maxNumber + 1, capacity: 4 }
  showDialog.value = true
}

function openEditTable(table: Table) {
  editingTable.value = table
  tableForm.value = {
    table_number: table.table_number,
    capacity: table.capacity
  }
  showDialog.value = true
}

async function saveTable() {
  if (!tableForm.value.table_number || !tableForm.value.capacity) {
    toast.add({ severity: 'warn', summary: 'Cảnh báo', detail: 'Vui lòng nhập đầy đủ thông tin', life: 3000 })
    return
  }

  processing.value = true

  try {
    if (editingTable.value) {
      const { supabase } = await import('@/services/supabase')
      const { error } = await supabase
        .from('tables')
        .update({
          table_number: tableForm.value.table_number,
          capacity: tableForm.value.capacity
        })
        .eq('id', editingTable.value.id)

      if (error) throw error
      toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã cập nhật bàn', life: 3000 })
    } else {
      const result = await tableStore.addTable({
        table_number: tableForm.value.table_number,
        capacity: tableForm.value.capacity,
        status: 'available'
      })

      if (!result.success) throw new Error(result.error)
      toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã thêm bàn mới', life: 3000 })
    }
    
    showDialog.value = false
    await tableStore.fetchTables()
  } catch (e: unknown) {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Thao tác thất bại', life: 3000 })
  } finally {
    processing.value = false
  }
}

function confirmDeleteTable(table: Table) {
  if (table.status !== 'available') {
    toast.add({ severity: 'warn', summary: 'Cảnh báo', detail: 'Không thể xóa bàn đang được sử dụng', life: 3000 })
    return
  }

  confirm.require({
    message: `Bạn có chắc muốn xóa Bàn ${table.table_number}?`,
    header: 'Xác nhận xóa',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: async () => {
      const result = await tableStore.deleteTable(table.id)
      if (result.success) {
        toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã xóa bàn', life: 3000 })
      } else {
        toast.add({ severity: 'error', summary: 'Lỗi', detail: result.error, life: 3000 })
      }
    }
  })
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Quản lý Bàn</h1>
        <p class="text-gray-600">Thêm, sửa, xóa bàn</p>
      </div>
      <Button label="Thêm bàn mới" icon="pi pi-plus" @click="openAddTable" />
    </div>

    <DataTable :value="tableStore.tables" :loading="tableStore.loading" stripedRows>
      <Column field="table_number" header="Số bàn" sortable />
      <Column field="capacity" header="Sức chứa" sortable>
        <template #body="{ data }">
          {{ data.capacity }} người
        </template>
      </Column>
      <Column header="Trạng thái" sortable>
        <template #body="{ data }">
          <Tag :value="getStatusLabel(data.status)" :severity="getStatusSeverity(data.status)" />
        </template>
      </Column>
      <Column header="Thao tác" style="width: 150px">
        <template #body="{ data }">
          <div class="flex gap-1">
            <Button icon="pi pi-pencil" severity="info" size="small" text @click="openEditTable(data)" />
            <Button icon="pi pi-trash" severity="danger" size="small" text @click="confirmDeleteTable(data)" :disabled="data.status !== 'available'" />
          </div>
        </template>
      </Column>
    </DataTable>

    <Dialog v-model:visible="showDialog" :header="editingTable ? 'Sửa bàn' : 'Thêm bàn mới'" :style="{ width: '400px' }" modal>
      <div class="space-y-4">
        <div class="flex flex-col gap-2">
          <label class="font-medium">Số bàn *</label>
          <InputNumber v-model="tableForm.table_number" :min="1" showButtons class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Sức chứa (người) *</label>
          <InputNumber v-model="tableForm.capacity" :min="1" :max="20" showButtons class="w-full" />
        </div>
        <Button label="Lưu" icon="pi pi-check" class="w-full" :loading="processing" @click="saveTable" />
      </div>
    </Dialog>
  </div>
</template>
