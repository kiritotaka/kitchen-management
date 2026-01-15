import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { UserRole } from '@/types'

const routes = [
  {
    path: '/',
    redirect: '/menu'
  },
  {
    path: '/menu',
    name: 'Menu',
    component: () => import('@/pages/menu/MenuPage.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/pages/auth/LoginPage.vue'),
    meta: { requiresAuth: false, guestOnly: true }
  },
  {
    path: '/staff',
    name: 'Staff',
    component: () => import('@/pages/staff/StaffDashboard.vue'),
    meta: { requiresAuth: true, roles: ['staff', 'manager', 'admin'] as UserRole[] }
  },
  {
    path: '/kitchen',
    name: 'Kitchen',
    component: () => import('@/pages/kitchen/KitchenDashboard.vue'),
    meta: { requiresAuth: true, roles: ['kitchen', 'admin'] as UserRole[] }
  },
  {
    path: '/manager',
    name: 'Manager',
    component: () => import('@/pages/manager/ManagerDashboard.vue'),
    meta: { requiresAuth: true, roles: ['manager', 'admin'] as UserRole[] }
  },
  {
    path: '/admin',
    name: 'Admin',
    component: () => import('@/pages/admin/AdminDashboard.vue'),
    meta: { requiresAuth: true, roles: ['admin'] as UserRole[] }
  },
  {
    path: '/admin/menu',
    name: 'AdminMenu',
    component: () => import('@/pages/admin/MenuManagement.vue'),
    meta: { requiresAuth: true, roles: ['admin'] as UserRole[] }
  },
  {
    path: '/admin/users',
    name: 'AdminUsers',
    component: () => import('@/pages/admin/UserManagement.vue'),
    meta: { requiresAuth: true, roles: ['admin'] as UserRole[] }
  },
  {
    path: '/admin/tables',
    name: 'AdminTables',
    component: () => import('@/pages/admin/TableManagement.vue'),
    meta: { requiresAuth: true, roles: ['admin'] as UserRole[] }
  },
  {
    path: '/admin/analytics',
    name: 'AdminAnalytics',
    component: () => import('@/pages/admin/AnalyticsDashboard.vue'),
    meta: { requiresAuth: true, roles: ['admin'] as UserRole[] }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach(async (to, _from, next) => {
  const authStore = useAuthStore()

  if (!authStore.isAuthenticated) {
    await authStore.checkAuth()
  }

  const requiresAuth = to.meta.requiresAuth as boolean
  const allowedRoles = to.meta.roles as UserRole[] | undefined
  const guestOnly = to.meta.guestOnly as boolean

  if (guestOnly && authStore.isAuthenticated) {
    next(authStore.getHomeRoute())
    return
  }

  if (requiresAuth && !authStore.isAuthenticated) {
    next('/login')
    return
  }

  if (allowedRoles && !allowedRoles.includes(authStore.userRole)) {
    next(authStore.getHomeRoute())
    return
  }

  next()
})

export default router
