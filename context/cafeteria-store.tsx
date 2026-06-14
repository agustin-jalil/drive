"use client"

import React, { createContext, useContext, useState } from "react"
import type { Pedido, ItemPedido, EstadoPedido } from "@/types/cafeteria"

// ── Pedidos hardcodeados de prueba ───────────────────────────
const pedidosIniciales: Pedido[] = [
  {
    id: "ped-001", numero: 1,
    mesaId: "mesa-3", mesaLabel: "Mesa 3",
    items: [
      { id: "i-3",  nombre: "Latte",        emoji: "🥛", precio: 1200, cantidad: 2 },
      { id: "i-12", nombre: "Medialunas x3", emoji: "🥐", precio: 900,  cantidad: 1 },
    ],
    estado: "en_preparacion", total: 3300, hora: "10:15",
  },
  {
    id: "ped-002", numero: 2,
    mesaId: "barra-2", mesaLabel: "Barra 2",
    items: [
      { id: "i-1", nombre: "Espresso", emoji: "☕", precio: 800, cantidad: 1 },
    ],
    estado: "listo", total: 800, hora: "10:28",
  },
  {
    id: "ped-003", numero: 3,
    mesaId: "mesa-1", mesaLabel: "Mesa 1",
    items: [
      { id: "i-9",  nombre: "Frappé",     emoji: "🧋", precio: 1500, cantidad: 2 },
      { id: "i-16", nombre: "Cheesecake", emoji: "🍰", precio: 1600, cantidad: 2 },
    ],
    estado: "pendiente", total: 6200, hora: "10:40",
  },
]

// ── Catálogo hardcodeado ─────────────────────────────────────
export const CATEGORIAS = [
  { id: "cat-1", nombre: "Cafés",      emoji: "☕" },
  { id: "cat-2", nombre: "Infusiones", emoji: "🍵" },
  { id: "cat-3", nombre: "Fríos",      emoji: "🧊" },
  { id: "cat-4", nombre: "Comidas",    emoji: "🥐" },
  { id: "cat-5", nombre: "Postres",    emoji: "🍰" },
]

export const ITEMS_CATALOGO = [
  { id: "i-1",  categoriaId: "cat-1", nombre: "Espresso",       emoji: "☕", precio: 800  },
  { id: "i-2",  categoriaId: "cat-1", nombre: "Americano",      emoji: "☕", precio: 900  },
  { id: "i-3",  categoriaId: "cat-1", nombre: "Latte",          emoji: "🥛", precio: 1200 },
  { id: "i-4",  categoriaId: "cat-1", nombre: "Cappuccino",     emoji: "☕", precio: 1100 },
  { id: "i-5",  categoriaId: "cat-1", nombre: "Cortado",        emoji: "☕", precio: 850  },
  { id: "i-6",  categoriaId: "cat-2", nombre: "Té Verde",       emoji: "🍵", precio: 700  },
  { id: "i-7",  categoriaId: "cat-2", nombre: "Manzanilla",     emoji: "🌼", precio: 650  },
  { id: "i-8",  categoriaId: "cat-2", nombre: "Jengibre Limón", emoji: "🍋", precio: 750  },
  { id: "i-9",  categoriaId: "cat-3", nombre: "Frappé",         emoji: "🧋", precio: 1500 },
  { id: "i-10", categoriaId: "cat-3", nombre: "Cold Brew",      emoji: "🧊", precio: 1400 },
  { id: "i-11", categoriaId: "cat-3", nombre: "Limonada",       emoji: "🍋", precio: 1000 },
  { id: "i-12", categoriaId: "cat-4", nombre: "Medialunas x3",  emoji: "🥐", precio: 900  },
  { id: "i-13", categoriaId: "cat-4", nombre: "Tostado Mixto",  emoji: "🥪", precio: 1400 },
  { id: "i-14", categoriaId: "cat-4", nombre: "Avocado Toast",  emoji: "🥑", precio: 1800 },
  { id: "i-15", categoriaId: "cat-5", nombre: "Brownie",        emoji: "🍫", precio: 1100 },
  { id: "i-16", categoriaId: "cat-5", nombre: "Cheesecake",     emoji: "🍰", precio: 1600 },
]

// ── Mesas hardcodeadas ───────────────────────────────────────
export const MESAS_CONFIG = [
  { id: "mesa-1",  label: "Mesa 1",   tipo: "mesa"  as const },
  { id: "mesa-2",  label: "Mesa 2",   tipo: "mesa"  as const },
  { id: "mesa-3",  label: "Mesa 3",   tipo: "mesa"  as const },
  { id: "mesa-4",  label: "Mesa 4",   tipo: "mesa"  as const },
  { id: "mesa-5",  label: "Mesa 5",   tipo: "mesa"  as const },
  { id: "mesa-6",  label: "Mesa 6",   tipo: "mesa"  as const },
  { id: "barra-1", label: "Barra 1",  tipo: "barra" as const },
  { id: "barra-2", label: "Barra 2",  tipo: "barra" as const },
  { id: "barra-3", label: "Barra 3",  tipo: "barra" as const },
  { id: "barra-4", label: "Barra 4",  tipo: "barra" as const },
  { id: "barra-5", label: "Barra 5",  tipo: "barra" as const },
  { id: "barra-6", label: "Barra 6",  tipo: "barra" as const },
]

// ── Context ──────────────────────────────────────────────────
type StoreCtx = {
  pedidos: Pedido[]
  crearPedido: (mesaId: string, mesaLabel: string, items: ItemPedido[]) => void
  avanzarEstado: (pedidoId: string) => void
  cerrarPedido: (pedidoId: string) => void
  getPedidosMesa: (mesaId: string) => Pedido[]
}

const Ctx = createContext<StoreCtx | null>(null)
let contador = pedidosIniciales.length + 1
const FLUJO: EstadoPedido[] = ["pendiente", "en_preparacion", "listo", "entregado"]

export function CafeteriaStore({ children }: { children: React.ReactNode }) {
  const [pedidos, setPedidos] = useState<Pedido[]>(pedidosIniciales)

  const crearPedido = (mesaId: string, mesaLabel: string, items: ItemPedido[]) => {
    const total = items.reduce((a, i) => a + i.precio * i.cantidad, 0)
    const hora  = new Date().toLocaleTimeString("es-AR", { hour: "2-digit", minute: "2-digit" })
    setPedidos(prev => [...prev, {
      id: `ped-${Date.now()}`, numero: contador++,
      mesaId, mesaLabel, items, estado: "pendiente", total, hora,
    }])
  }

  const avanzarEstado = (pedidoId: string) => {
    setPedidos(prev => prev.map(p => {
      if (p.id !== pedidoId) return p
      const idx  = FLUJO.indexOf(p.estado)
      const next = FLUJO[Math.min(idx + 1, FLUJO.length - 1)]
      return { ...p, estado: next }
    }))
  }

  const cerrarPedido = (pedidoId: string) =>
    setPedidos(prev => prev.filter(p => p.id !== pedidoId))

  const getPedidosMesa = (mesaId: string) =>
    pedidos.filter(p => p.mesaId === mesaId && p.estado !== "entregado")

  return (
    <Ctx.Provider value={{ pedidos, crearPedido, avanzarEstado, cerrarPedido, getPedidosMesa }}>
      {children}
    </Ctx.Provider>
  )
}

export function useStore() {
  const c = useContext(Ctx)
  if (!c) throw new Error("useStore fuera de CafeteriaStore")
  return c
}
