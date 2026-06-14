"use client"
import React, { createContext, useContext, useState, useEffect, useCallback, useRef, useTransition } from "react"
import { api, type Pedido, type ItemCatalogo, type Categoria, type Mesa } from "@/lib/api"

type CafeteriaCtx = {
  pedidos: Pedido[]
  mesas: Mesa[]
  catalogo: ItemCatalogo[]
  categorias: Categoria[]
  loadingPedidos: boolean
  loadingMesas: boolean
  loadingCatalogo: boolean
  refreshing: boolean           // true solo en background refresh (sin skeleton)
  error: string | null
  lastUpdated: Date | null
  refetchPedidos: () => Promise<void>
  refetchMesas: () => Promise<void>
  crearPedido: (mesaId: string, items: { itemId: string; cantidad: number }[]) => Promise<void>
  avanzarEstado: (pedidoId: string) => Promise<void>
  cerrarPedido: (pedidoId: string) => Promise<void>
  getPedidosMesa: (mesaId: string) => Pedido[]
}

const Ctx = createContext<CafeteriaCtx | null>(null)

export function CafeteriaStore({ children }: { children: React.ReactNode }) {
  const [pedidos,    setPedidos]    = useState<Pedido[]>([])
  const [mesas,      setMesas]      = useState<Mesa[]>([])
  const [catalogo,   setCatalogo]   = useState<ItemCatalogo[]>([])
  const [categorias, setCategorias] = useState<Categoria[]>([])

  // loadingXxx = true solo la primera vez (muestra skeleton)
  const [loadingPedidos,  setLoadingPedidos]  = useState(true)
  const [loadingMesas,    setLoadingMesas]    = useState(true)
  const [loadingCatalogo, setLoadingCatalogo] = useState(true)
  // refreshing = true en polls silenciosos (NO muestra skeleton)
  const [refreshing, setRefreshing] = useState(false)
  const [error,        setError]       = useState<string | null>(null)
  const [lastUpdated,  setLastUpdated] = useState<Date | null>(null)

  // Usamos ref para saber si ya cargamos la primera vez
  const initializedPedidos = useRef(false)
  const initializedMesas   = useRef(false)

  // ── fetch silencioso (no muestra skeleton) ──────────────────────────────
  const fetchPedidosSilent = useCallback(async () => {
    try {
      const data = await api.getPedidos()
      // Actualizamos solo si cambió algo (evita re-render innecesario)
      setPedidos(prev => {
        const prevStr = JSON.stringify(prev.map(p => ({ id: p.id, estado: p.estado })))
        const nextStr = JSON.stringify(data.map(p => ({ id: p.id, estado: p.estado })))
        return prevStr === nextStr ? prev : data
      })
      setLastUpdated(new Date())
    } catch (e: any) {
      // Error silencioso en background, no mostramos al usuario
      console.warn("Background refresh pedidos:", e.message)
    }
  }, [])

  const fetchMesasSilent = useCallback(async () => {
    try {
      const data = await api.getMesas()
      setMesas(prev => {
        const prevStr = JSON.stringify(prev.map(m => ({ id: m.id, pedidos: m.pedidos.length })))
        const nextStr = JSON.stringify(data.map(m => ({ id: m.id, pedidos: m.pedidos.length })))
        return prevStr === nextStr ? prev : data
      })
    } catch (e: any) {
      console.warn("Background refresh mesas:", e.message)
    }
  }, [])

  // ── fetch inicial (muestra skeleton) ────────────────────────────────────
  const refetchPedidos = useCallback(async () => {
    if (!initializedPedidos.current) setLoadingPedidos(true)
    else setRefreshing(true)
    try {
      const data = await api.getPedidos()
      setPedidos(data)
      setLastUpdated(new Date())
      initializedPedidos.current = true
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoadingPedidos(false)
      setRefreshing(false)
    }
  }, [])

  const refetchMesas = useCallback(async () => {
    if (!initializedMesas.current) setLoadingMesas(true)
    else setRefreshing(true)
    try {
      const data = await api.getMesas()
      setMesas(data)
      initializedMesas.current = true
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoadingMesas(false)
      setRefreshing(false)
    }
  }, [])

  // ── montaje inicial ──────────────────────────────────────────────────────
  useEffect(() => {
    refetchPedidos()
    refetchMesas()
    api.getCategorias().then(setCategorias).catch(() => {})
    api.getCatalogo().then(setCatalogo).catch(() => {}).finally(() => setLoadingCatalogo(false))
  }, [refetchPedidos, refetchMesas])

  // ── polling silencioso cada 30s ──────────────────────────────────────────
  // SIN skeleton, SIN parpadeo — solo actualiza el estado si algo cambió
  useEffect(() => {
    const interval = setInterval(async () => {
      if (!initializedPedidos.current) return
      await fetchPedidosSilent()
      await fetchMesasSilent()
    }, 15_000)
    return () => clearInterval(interval)
  }, [fetchPedidosSilent, fetchMesasSilent])

  // ── acciones ─────────────────────────────────────────────────────────────
  const crearPedido = useCallback(async (mesaId: string, items: { itemId: string; cantidad: number }[]) => {
    await api.crearPedido(mesaId, items)
    await refetchPedidos()
    await fetchMesasSilent()
  }, [refetchPedidos, fetchMesasSilent])

  const avanzarEstado = useCallback(async (pedidoId: string) => {
    // Optimistic update — cambiamos el estado local ANTES de ir al server
    setPedidos(prev => prev.map(p => {
      if (p.id !== pedidoId) return p
      const flujo: Record<string, string> = {
        PENDIENTE: "EN_PREPARACION", EN_PREPARACION: "LISTO",
        LISTO: "ENTREGADO", ENTREGADO: "CERRADO",
      }
      return { ...p, estado: (flujo[p.estado] ?? p.estado) as any }
    }))
    try {
      await api.avanzarEstado(pedidoId)
      // Confirmamos con el server en silencio
      fetchPedidosSilent()
    } catch (e) {
      // Si falla, revertimos
      await refetchPedidos()
    }
  }, [refetchPedidos, fetchPedidosSilent])

  const cerrarPedido = useCallback(async (pedidoId: string) => {
    // Optimistic: sacar de la lista inmediatamente
    setPedidos(prev => prev.filter(p => p.id !== pedidoId))
    try {
      await api.cerrarPedido(pedidoId)
      fetchMesasSilent()
    } catch (e) {
      await refetchPedidos()
    }
  }, [refetchPedidos, fetchMesasSilent])

  const getPedidosMesa = useCallback((mesaId: string) =>
    pedidos.filter(p => p.mesa.id === mesaId && p.estado !== "CERRADO"),
  [pedidos])

  return (
    <Ctx.Provider value={{
      pedidos, mesas, catalogo, categorias,
      loadingPedidos, loadingMesas, loadingCatalogo,
      refreshing, error, lastUpdated,
      refetchPedidos, refetchMesas,
      crearPedido, avanzarEstado, cerrarPedido, getPedidosMesa,
    }}>
      {children}
    </Ctx.Provider>
  )
}

export function useStore() {
  const c = useContext(Ctx)
  if (!c) throw new Error("useStore fuera de CafeteriaStore")
  return c
}
