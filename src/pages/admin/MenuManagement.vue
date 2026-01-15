<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useMenuStore } from '@/stores/menu'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import type { MenuItem, Category } from '@/types'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import Dropdown from 'primevue/dropdown'
import InputSwitch from 'primevue/inputswitch'
import Tag from 'primevue/tag'
import Tabs from 'primevue/tabs'
import TabList from 'primevue/tablist'
import Tab from 'primevue/tab'
import TabPanels from 'primevue/tabpanels'
import TabPanel from 'primevue/tabpanel'
import FileUpload from 'primevue/fileupload'
import { supabase } from '@/services/supabase'

const menuStore = useMenuStore()
const toast = useToast()
const confirm = useConfirm()

const showItemDialog = ref(false)
const showCategoryDialog = ref(false)
const editingItem = ref<MenuItem | null>(null)
const editingCategory = ref<Category | null>(null)
const processing = ref(false)
const uploading = ref(false)
const imagePreview = ref<string | null>(null)

const itemForm = ref({
  name: '',
  description: '',
  price: 0,
  category_id: '',
  image_url: '',
  is_available: true,
  badges: [] as string[]
})

const categoryForm = ref({
  name: '',
  display_order: 0,
  icon: ''
})

const badgeOptions = [
  { label: 'Bestseller', value: 'Bestseller' },
  { label: 'Mới', value: 'New' },
  { label: 'Khuyến mãi', value: 'Promotion' }
]

onMounted(async () => {
  await Promise.all([
    menuStore.fetchCategories(),
    menuStore.fetchMenuItems(true)
  ])
})

function formatPrice(price: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price)
}

function openAddItem() {
  editingItem.value = null
  itemForm.value = { name: '', description: '', price: 0, category_id: '', image_url: '', is_available: true, badges: [] }
  imagePreview.value = null
  showItemDialog.value = true
}

function openEditItem(item: MenuItem) {
  editingItem.value = item
  itemForm.value = {
    name: item.name,
    description: item.description || '',
    price: item.price,
    category_id: item.category_id,
    image_url: item.image_url || '',
    is_available: item.is_available,
    badges: item.badges || []
  }
  imagePreview.value = item.image_url || null
  showItemDialog.value = true
}

async function onImageSelect(event: { files: File[] }) {
  const file = event.files[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = (e) => {
    imagePreview.value = e.target?.result as string
  }
  reader.readAsDataURL(file)

  uploading.value = true
  try {
    const fileExt = file.name.split('.').pop()
    const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`
    const filePath = `menu/${fileName}`

    const { error: uploadError } = await supabase.storage
      .from('menu-images')
      .upload(filePath, file)

    if (uploadError) {
      console.error('Upload error:', uploadError)
      throw new Error(uploadError.message || 'Không thể upload hình. Vui lòng kiểm tra bucket "menu-images" đã được tạo và cấu hình public.')
    }

    const { data } = supabase.storage
      .from('menu-images')
      .getPublicUrl(filePath)

    itemForm.value.image_url = data.publicUrl
    imagePreview.value = data.publicUrl
    console.log('Image uploaded:', data.publicUrl)
    toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã tải hình ảnh lên', life: 3000 })
  } catch (e: unknown) {
    console.error('onImageSelect error:', e)
    imagePreview.value = null
    toast.add({ severity: 'error', summary: 'Lỗi upload', detail: e instanceof Error ? e.message : 'Upload thất bại', life: 5000 })
  } finally {
    uploading.value = false
  }
}

function removeImage() {
  itemForm.value.image_url = ''
  imagePreview.value = null
}

async function saveItem() {
  if (!itemForm.value.name || !itemForm.value.price) {
    toast.add({ severity: 'warn', summary: 'Cảnh báo', detail: 'Vui lòng nhập tên và giá món', life: 3000 })
    return
  }

  processing.value = true
  
  const data = {
    name: itemForm.value.name,
    description: itemForm.value.description || null,
    price: itemForm.value.price,
    category_id: itemForm.value.category_id || null,
    image_url: itemForm.value.image_url || null,
    is_available: itemForm.value.is_available,
    badges: itemForm.value.badges.length > 0 ? itemForm.value.badges : null
  }

  let result
  if (editingItem.value) {
    result = await menuStore.updateMenuItem(editingItem.value.id, data)
  } else {
    result = await menuStore.addMenuItem(data)
  }

  processing.value = false

  if (result.success) {
    toast.add({ severity: 'success', summary: 'Thành công', detail: editingItem.value ? 'Đã cập nhật món' : 'Đã thêm món mới', life: 3000 })
    showItemDialog.value = false
    await menuStore.fetchMenuItems(true)
  } else {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: result.error, life: 3000 })
  }
}

function confirmDeleteItem(item: MenuItem) {
  confirm.require({
    message: `Bạn có chắc muốn xóa món "${item.name}"?`,
    header: 'Xác nhận xóa',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: async () => {
      const result = await menuStore.deleteMenuItem(item.id)
      if (result.success) {
        toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã xóa món', life: 3000 })
      } else {
        toast.add({ severity: 'error', summary: 'Lỗi', detail: result.error, life: 3000 })
      }
    }
  })
}

function openAddCategory() {
  editingCategory.value = null
  categoryForm.value = { name: '', display_order: menuStore.categories.length + 1, icon: '' }
  showCategoryDialog.value = true
}

function openEditCategory(category: Category) {
  editingCategory.value = category
  categoryForm.value = {
    name: category.name,
    display_order: category.display_order,
    icon: category.icon || ''
  }
  showCategoryDialog.value = true
}

async function saveCategory() {
  if (!categoryForm.value.name) {
    toast.add({ severity: 'warn', summary: 'Cảnh báo', detail: 'Vui lòng nhập tên danh mục', life: 3000 })
    return
  }

  processing.value = true

  try {
    if (editingCategory.value) {
      const { error } = await supabase
        .from('categories')
        .update({
          name: categoryForm.value.name,
          display_order: categoryForm.value.display_order,
          icon: categoryForm.value.icon || null
        })
        .eq('id', editingCategory.value.id)

      if (error) throw error
    } else {
      const { error } = await supabase
        .from('categories')
        .insert({
          name: categoryForm.value.name,
          display_order: categoryForm.value.display_order,
          icon: categoryForm.value.icon || null
        })

      if (error) throw error
    }

    toast.add({ severity: 'success', summary: 'Thành công', detail: editingCategory.value ? 'Đã cập nhật danh mục' : 'Đã thêm danh mục', life: 3000 })
    showCategoryDialog.value = false
    await menuStore.fetchCategories()
  } catch (e: unknown) {
    toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Thao tác thất bại', life: 3000 })
  } finally {
    processing.value = false
  }
}

async function deleteCategory(category: Category) {
  confirm.require({
    message: `Bạn có chắc muốn xóa danh mục "${category.name}"?`,
    header: 'Xác nhận xóa',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        const { error } = await supabase.from('categories').delete().eq('id', category.id)
        if (error) throw error
        toast.add({ severity: 'success', summary: 'Thành công', detail: 'Đã xóa danh mục', life: 3000 })
        await menuStore.fetchCategories()
      } catch (e: unknown) {
        toast.add({ severity: 'error', summary: 'Lỗi', detail: e instanceof Error ? e.message : 'Xóa thất bại', life: 3000 })
      }
    }
  })
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Quản lý Menu</h1>
        <p class="text-gray-600">Thêm, sửa, xóa món ăn và danh mục</p>
      </div>
    </div>

    <Tabs value="0">
      <TabList>
        <Tab value="0">Món ăn</Tab>
        <Tab value="1">Danh mục</Tab>
      </TabList>
      <TabPanels>
        <TabPanel value="0">
          <div class="mb-4 mt-4">
            <Button label="Thêm món mới" icon="pi pi-plus" @click="openAddItem" />
          </div>

          <DataTable :value="menuStore.menuItems" :loading="menuStore.loading" paginator :rows="10" stripedRows>
            <Column header="Hình" style="width: 80px">
              <template #body="{ data }">
                <img 
                  :src="data.image_url || 'https://placehold.co/60x60/f97316/white?text=M'" 
                  class="w-12 h-12 rounded object-cover"
                />
              </template>
            </Column>
            <Column field="name" header="Tên món" sortable />
            <Column header="Danh mục" sortable>
              <template #body="{ data }">
                <Tag v-if="data.category" :value="data.category.name" />
                <span v-else class="text-gray-400">-</span>
              </template>
            </Column>
            <Column header="Giá" sortable>
              <template #body="{ data }">
                {{ formatPrice(data.price) }}
              </template>
            </Column>
            <Column header="Trạng thái">
              <template #body="{ data }">
                <Tag :value="data.is_available ? 'Còn hàng' : 'Hết hàng'" :severity="data.is_available ? 'success' : 'danger'" />
              </template>
            </Column>
            <Column header="Badges">
              <template #body="{ data }">
                <div class="flex gap-1">
                  <Tag v-for="badge in data.badges || []" :key="badge" :value="badge" severity="info" />
                </div>
              </template>
            </Column>
            <Column header="Thao tác" style="width: 150px">
              <template #body="{ data }">
                <div class="flex gap-1">
                  <Button icon="pi pi-pencil" severity="info" size="small" text @click="openEditItem(data)" />
                  <Button icon="pi pi-trash" severity="danger" size="small" text @click="confirmDeleteItem(data)" />
                </div>
              </template>
            </Column>
          </DataTable>
        </TabPanel>

        <TabPanel value="1">
          <div class="mb-4 mt-4">
            <Button label="Thêm danh mục" icon="pi pi-plus" @click="openAddCategory" />
          </div>

          <DataTable :value="menuStore.categories" stripedRows>
            <Column field="display_order" header="Thứ tự" sortable style="width: 100px" />
            <Column field="name" header="Tên danh mục" sortable />
            <Column field="icon" header="Icon" />
            <Column header="Thao tác" style="width: 150px">
              <template #body="{ data }">
                <div class="flex gap-1">
                  <Button icon="pi pi-pencil" severity="info" size="small" text @click="openEditCategory(data)" />
                  <Button icon="pi pi-trash" severity="danger" size="small" text @click="deleteCategory(data)" />
                </div>
              </template>
            </Column>
          </DataTable>
        </TabPanel>
      </TabPanels>
    </Tabs>

    <Dialog v-model:visible="showItemDialog" :header="editingItem ? 'Sửa món' : 'Thêm món mới'" :style="{ width: '500px' }" modal>
      <div class="space-y-4">
        <div class="flex flex-col gap-2">
          <label class="font-medium">Tên món *</label>
          <InputText v-model="itemForm.name" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Mô tả</label>
          <Textarea v-model="itemForm.description" rows="3" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Giá *</label>
          <InputNumber v-model="itemForm.price" :min="0" mode="currency" currency="VND" locale="vi-VN" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Danh mục</label>
          <Dropdown v-model="itemForm.category_id" :options="menuStore.categories" optionLabel="name" optionValue="id" placeholder="Chọn danh mục" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Hình ảnh</label>
          <div class="relative inline-block mb-2">
            <img 
              :src="imagePreview || 'https://placehold.co/128x128/f97316/white?text=Chưa+có+ảnh'" 
              class="w-32 h-32 object-cover rounded border"
              :class="{ 'opacity-50': uploading }"
            />
            <div v-if="uploading" class="absolute inset-0 flex items-center justify-center">
              <i class="pi pi-spin pi-spinner text-2xl text-orange-600"></i>
            </div>
            <Button 
              v-if="imagePreview"
              icon="pi pi-times" 
              severity="danger" 
              size="small" 
              rounded 
              class="absolute -top-2 -right-2"
              @click="removeImage"
            />
          </div>
          <FileUpload 
            mode="basic" 
            accept="image/*" 
            :maxFileSize="5000000"
            chooseLabel="Chọn hình ảnh"
            :auto="true"
            :disabled="uploading"
            customUpload
            @select="onImageSelect"
          />
          <small class="text-gray-500">Hoặc nhập URL:</small>
          <InputText v-model="itemForm.image_url" placeholder="https://..." class="w-full" @input="imagePreview = itemForm.image_url" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Badges</label>
          <Dropdown v-model="itemForm.badges" :options="badgeOptions" optionLabel="label" optionValue="value" multiple placeholder="Chọn badges" class="w-full" />
        </div>
        <div class="flex items-center gap-2">
          <InputSwitch v-model="itemForm.is_available" />
          <label>Còn hàng</label>
        </div>
        <Button label="Lưu" icon="pi pi-check" class="w-full" :loading="processing" @click="saveItem" />
      </div>
    </Dialog>

    <Dialog v-model:visible="showCategoryDialog" :header="editingCategory ? 'Sửa danh mục' : 'Thêm danh mục'" :style="{ width: '400px' }" modal>
      <div class="space-y-4">
        <div class="flex flex-col gap-2">
          <label class="font-medium">Tên danh mục *</label>
          <InputText v-model="categoryForm.name" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Thứ tự hiển thị</label>
          <InputNumber v-model="categoryForm.display_order" :min="1" class="w-full" />
        </div>
        <div class="flex flex-col gap-2">
          <label class="font-medium">Icon (PrimeIcons class)</label>
          <InputText v-model="categoryForm.icon" placeholder="pi pi-tag" class="w-full" />
        </div>
        <Button label="Lưu" icon="pi pi-check" class="w-full" :loading="processing" @click="saveCategory" />
      </div>
    </Dialog>
  </div>
</template>
