"use client"
import React, { createContext, useContext, useState, useEffect, useCallback } from "react"
import { useRouter } from "next/navigation"
import { api } from "@/lib/api"

const TOKEN_KEY  = "drive_token"
const USER_KEY   = "drive_usuario"

type Usuario = {
  id: string
  email: string
  nombre: string
  rol: string
}

type AuthCtx = {
  usuario: Usuario | null
  isAuthenticated: boolean
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

const Ctx = createContext<AuthCtx | null>(null)

export function AuthStore({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const [usuario,  setUsuario]  = useState<Usuario | null>(null)
  const [loading,  setLoading]  = useState(true)

  // ── Al montar: leer token y usuario de localStorage ──
  useEffect(() => {
    try {
      const token    = localStorage.getItem(TOKEN_KEY)
      const userJson = localStorage.getItem(USER_KEY)
      if (token && userJson) {
        setUsuario(JSON.parse(userJson))
      }
    } catch {
      // localStorage no disponible (SSR) — no hacer nada
    } finally {
      setLoading(false)
    }
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    const data = await api.login(email, password)
    // Guardar en localStorage para que persista entre recargas
    localStorage.setItem(TOKEN_KEY,  data.access_token)
    localStorage.setItem(USER_KEY,   JSON.stringify(data.usuario))
    setUsuario(data.usuario)
    router.replace("/")
  }, [router])

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
    setUsuario(null)
    router.replace("/login")
  }, [router])

  return (
    <Ctx.Provider value={{
      usuario,
      isAuthenticated: !!usuario,
      loading,
      login,
      logout,
    }}>
      {children}
    </Ctx.Provider>
  )
}

export function useAuth() {
  const c = useContext(Ctx)
  if (!c) throw new Error("useAuth fuera de AuthStore")
  return c
}
