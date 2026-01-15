import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/services/supabase'
import type { User, UserRole } from '@/types'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => !!user.value)
  const userRole = computed<UserRole>(() => user.value?.role || 'guest')

  async function login(email: string, password: string) {
    loading.value = true
    error.value = null

    try {
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password
      })

      if (authError) throw authError

      if (authData.user) {
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select('*')
          .eq('id', authData.user.id)
          .single()

        if (userError) throw userError
        user.value = userData
      }

      return { success: true }
    } catch (e: unknown) {
      const errorMessage = e instanceof Error ? e.message : 'Login failed'
      error.value = errorMessage
      return { success: false, error: errorMessage }
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    loading.value = true
    try {
      await supabase.auth.signOut()
      user.value = null
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Logout failed'
    } finally {
      loading.value = false
    }
  }

  async function checkAuth() {
    loading.value = true
    try {
      const { data: { session } } = await supabase.auth.getSession()
      
      if (session?.user) {
        const { data: userData } = await supabase
          .from('users')
          .select('*')
          .eq('id', session.user.id)
          .single()

        user.value = userData
      }
    } catch (e: unknown) {
      console.error('Auth check failed:', e)
    } finally {
      loading.value = false
    }
  }

  function getHomeRoute(): string {
    switch (userRole.value) {
      case 'admin':
        return '/admin'
      case 'manager':
        return '/manager'
      case 'kitchen':
        return '/kitchen'
      case 'staff':
        return '/staff'
      default:
        return '/menu'
    }
  }

  return {
    user,
    loading,
    error,
    isAuthenticated,
    userRole,
    login,
    logout,
    checkAuth,
    getHomeRoute
  }
}, {
  persist: true
})
