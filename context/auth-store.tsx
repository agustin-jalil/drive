"use client"
import React, { createContext, useContext, useState, useEffect, useCallback } from "react"
import { api, type Usuario } from "@/lib/api"
import { useRouter } from "next/navigation"

type AuthCtx = {
  usuario: Usuario | null
  token: string | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  isAuthenticated: boolean
}

const Ctx = createContext<AuthCtx | null>(null)

export function AuthStore({ children }: { children: React.ReactNode }) {
  const [usuario, setUsuario] = useState<Usuario | null>(null)
  const [token, setToken] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()

  // Restore session on mount
  useEffect(() => {
    const t = localStorage.getItem("drive_token")
    if (t) {
      setToken(t)
      api.me()
        .then(setUsuario)
        .catch(() => {
          localStorage.removeItem("drive_token")
          setToken(null)
        })
        .finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    const data = await api.login(email, password)
    localStorage.setItem("drive_token", data.access_token)
    setToken(data.access_token)
    setUsuario(data.usuario)
    router.push("/")
  }, [router])

  const logout = useCallback(() => {
    localStorage.removeItem("drive_token")
    setToken(null)
    setUsuario(null)
    router.push("/login")
  }, [router])

  return (
    <Ctx.Provider value={{ usuario, token, loading, login, logout, isAuthenticated: !!token }}>
      {children}
    </Ctx.Provider>
  )
}

export function useAuth() {
  const c = useContext(Ctx)
  if (!c) throw new Error("useAuth fuera de AuthStore")
  return c
}
