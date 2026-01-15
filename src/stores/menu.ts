import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/services/supabase'
import type { MenuItem, Category } from '@/types'

export const useMenuStore = defineStore('menu', () => {
  const menuItems = ref<MenuItem[]>([])
  const categories = ref<Category[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const selectedCategory = ref<string | null>(null)
  const searchQuery = ref('')

  const filteredMenuItems = computed(() => {
    let items = menuItems.value.filter(item => item.is_available)

    if (selectedCategory.value) {
      items = items.filter(item => item.category_id === selectedCategory.value)
    }

    if (searchQuery.value) {
      const query = searchQuery.value.toLowerCase()
      items = items.filter(item =>
        item.name.toLowerCase().includes(query) ||
        item.description?.toLowerCase().includes(query)
      )
    }

    return items
  })

  async function fetchCategories() {
    try {
      const { data, error: fetchError } = await supabase
        .from('categories')
        .select('*')
        .order('display_order')

      if (fetchError) throw fetchError
      categories.value = data || []
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch categories'
    }
  }

  async function fetchMenuItems() {
    loading.value = true
    try {
      const { data, error: fetchError } = await supabase
        .from('menu_items')
        .select('*')
        .eq('is_available', true)
        .order('name')

      if (fetchError) throw fetchError
      
      // Map category names from categories store
      const items = (data || []).map(item => {
        const cat = categories.value.find(c => c.id === item.category_id)
        return { ...item, category: cat || null }
      })
      
      menuItems.value = items
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch menu items'
      console.error('Menu fetch error:', e)
    } finally {
      loading.value = false
    }
  }

  async function addMenuItem(item: Partial<MenuItem>) {
    try {
      const { data, error: insertError } = await supabase
        .from('menu_items')
        .insert(item)
        .select()
        .single()

      if (insertError) throw insertError
      menuItems.value.push(data)
      return { success: true, data }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to add item' }
    }
  }

  async function updateMenuItem(id: string, updates: Partial<MenuItem>) {
    try {
      const { data, error: updateError } = await supabase
        .from('menu_items')
        .update(updates)
        .eq('id', id)
        .select()
        .single()

      if (updateError) throw updateError
      const index = menuItems.value.findIndex(item => item.id === id)
      if (index !== -1) {
        menuItems.value[index] = data
      }
      return { success: true, data }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to update item' }
    }
  }

  async function deleteMenuItem(id: string) {
    try {
      const { error: deleteError } = await supabase
        .from('menu_items')
        .delete()
        .eq('id', id)

      if (deleteError) throw deleteError
      menuItems.value = menuItems.value.filter(item => item.id !== id)
      return { success: true }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to delete item' }
    }
  }

  return {
    menuItems,
    categories,
    loading,
    error,
    selectedCategory,
    searchQuery,
    filteredMenuItems,
    fetchCategories,
    fetchMenuItems,
    addMenuItem,
    updateMenuItem,
    deleteMenuItem
  }
})
