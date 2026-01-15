import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/services/supabase'
import type { Table, TableStatus } from '@/types'

export const useTableStore = defineStore('tables', () => {
  const tables = ref<Table[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchTables() {
    loading.value = true
    try {
      const { data, error: fetchError } = await supabase
        .from('tables')
        .select('*')
        .order('table_number')

      if (fetchError) throw fetchError
      tables.value = data || []
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch tables'
    } finally {
      loading.value = false
    }
  }

  async function updateTableStatus(id: string, status: TableStatus, orderId?: string) {
    try {
      const updates: Partial<Table> = {
        status,
        updated_at: new Date().toISOString()
      }
      if (orderId !== undefined) {
        updates.current_order_id = orderId
      }

      const { data, error: updateError } = await supabase
        .from('tables')
        .update(updates)
        .eq('id', id)
        .select()
        .single()

      if (updateError) throw updateError
      const index = tables.value.findIndex(t => t.id === id)
      if (index !== -1) {
        tables.value[index] = data
      }
      return { success: true, data }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to update table' }
    }
  }

  async function addTable(table: Partial<Table>) {
    try {
      const { data, error: insertError } = await supabase
        .from('tables')
        .insert(table)
        .select()
        .single()

      if (insertError) throw insertError
      tables.value.push(data)
      return { success: true, data }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to add table' }
    }
  }

  async function deleteTable(id: string) {
    try {
      const { error: deleteError } = await supabase
        .from('tables')
        .delete()
        .eq('id', id)

      if (deleteError) throw deleteError
      tables.value = tables.value.filter(t => t.id !== id)
      return { success: true }
    } catch (e: unknown) {
      return { success: false, error: e instanceof Error ? e.message : 'Failed to delete table' }
    }
  }

  function subscribeToChanges() {
    return supabase
      .channel('tables-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tables' }, (payload) => {
        if (payload.eventType === 'INSERT') {
          tables.value.push(payload.new as Table)
        } else if (payload.eventType === 'UPDATE') {
          const index = tables.value.findIndex(t => t.id === payload.new.id)
          if (index !== -1) {
            tables.value[index] = payload.new as Table
          }
        } else if (payload.eventType === 'DELETE') {
          tables.value = tables.value.filter(t => t.id !== payload.old.id)
        }
      })
      .subscribe()
  }

  return {
    tables,
    loading,
    error,
    fetchTables,
    updateTableStatus,
    addTable,
    deleteTable,
    subscribeToChanges
  }
})
