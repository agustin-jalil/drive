#!/bin/bash
# ============================================================
# DRIVE Cafetería — Versión final sin React Flow
#   / → Pedidos (home + tabla)
#   /mesas → Cards hardcodeadas (6 mesas + 6 banquetas)
#   /catalogo → Crear pedido desde catálogo
# ============================================================
set -e

echo "🗑️  Limpiando archivos anteriores..."
rm -rf app/analytics app/calendar app/tasks app/team app/help app/pedidos app/dashboard
rm -f  components/analytics/analytics-content.tsx
rm -f  components/calendar/calendar-content.tsx
rm -f  components/tasks/tasks-content.tsx
rm -f  components/team/team-content.tsx
rm -f  components/help/help-content.tsx
rm -f  components/dashboard/project-analytics.tsx
rm -f  components/dashboard/project-list.tsx
rm -f  components/dashboard/project-progress.tsx
rm -f  components/dashboard/team-collaboration.tsx
rm -f  components/dashboard/time-tracker.tsx
rm -f  components/dashboard/mobile-app-card.tsx
rm -f  components/dashboard/stats-cards.tsx
rm -f  components/dashboard/reminders.tsx
rm -f  components/cafeteria/mesas-flow.tsx
rm -f  components/cafeteria/pedidos-content.tsx
rm -f  components/cafeteria/pedidos-view.tsx
rm -f  components/cafeteria/catalogo-crear-pedido.tsx
rm -f  components/cafeteria/catalogo-content.tsx
rm -f  components/cafeteria/pedido-builder.tsx
rm -f  components/cafeteria/mesas-content.tsx
rm -f  context/cafeteria-context.tsx
rm -f  context/cafeteria-store.tsx
rm -f  types/cafeteria.ts
echo "✅ Limpieza hecha"

# ── TIPOS ────────────────────────────────────────────────────
mkdir -p types
cat > types/cafeteria.ts << 'ENDOFFILE'
export type EstadoPedido = "pendiente" | "en_preparacion" | "listo" | "entregado"

export type ItemPedido = {
  id: string
  nombre: string
  emoji: string
  precio: number
  cantidad: number
}

export type Pedido = {
  id: string
  numero: number
  mesaId: string
  mesaLabel: string
  items: ItemPedido[]
  estado: EstadoPedido
  total: number
  hora: string
}
ENDOFFILE
echo "✅ types/cafeteria.ts"

# ── STORE GLOBAL ─────────────────────────────────────────────
mkdir -p context
cat > context/cafeteria-store.tsx << 'ENDOFFILE'
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
ENDOFFILE
echo "✅ context/cafeteria-store.tsx"

# ── LAYOUT ───────────────────────────────────────────────────
cat > app/layout.tsx << 'ENDOFFILE'
import type React from "react"
import type { Metadata } from "next"
import { Montserrat, Playfair_Display } from "next/font/google"
import { Analytics } from "@vercel/analytics/next"
import { ThemeProvider } from "@/components/theme-provider"
import { CafeteriaStore } from "@/context/cafeteria-store"
import "./globals.css"

const montserrat = Montserrat({
  subsets: ["latin"],
  variable: "--font-sans",
  weight: ["400","500","600","700","800","900"],
})
const playfair = Playfair_Display({
  subsets: ["latin"],
  variable: "--font-serif",
  style: ["normal","italic"],
  weight: ["400","500","600","700"],
})

export const metadata: Metadata = {
  title: "DRIVE — Café & Lubricentro",
  description: "Sistema de gestión DRIVE",
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" className="dark">
      <body className={`${montserrat.variable} ${playfair.variable} font-sans antialiased`}>
        <ThemeProvider defaultTheme="dark" storageKey="drive-theme">
          <CafeteriaStore>
            {children}
          </CafeteriaStore>
        </ThemeProvider>
        <Analytics />
      </body>
    </html>
  )
}
ENDOFFILE
echo "✅ layout.tsx"

# ── SIDEBAR ──────────────────────────────────────────────────
cat > components/dashboard/sidebar.tsx << 'ENDOFFILE'
"use client"

import { ClipboardList, MapPin, BookOpen, Settings, LogOut, Wrench } from "lucide-react"
import { cn } from "@/lib/utils"
import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"

const menuItems = [
  { icon: ClipboardList, label: "Pedidos",  href: "/" },
  { icon: MapPin,        label: "Mesas",    href: "/mesas" },
  { icon: BookOpen,      label: "Catálogo", href: "/catalogo" },
]
const generalItems = [
  { icon: Settings, label: "Configuración", href: "/settings" },
  { icon: LogOut,   label: "Salir",         href: "/logout" },
]

export function Sidebar() {
  const [hovered, setHovered] = useState<string | null>(null)
  const pathname = usePathname()

  return (
    <aside className="fixed top-0 left-0 w-64 bg-sidebar border-r border-sidebar-border p-5 h-screen flex flex-col">
      <Link href="/" className="flex items-center gap-3 group mb-8">
        <div className="w-10 h-10 rounded-lg bg-primary flex items-center justify-center shadow-lg shadow-primary/30 transition-transform group-hover:scale-105">
          <Wrench className="w-5 h-5 text-primary-foreground" />
        </div>
        <div>
          <p className="font-extrabold italic tracking-wider uppercase text-foreground text-lg leading-none">DRIVE</p>
          <p className="font-serif italic text-xs text-primary tracking-wide leading-none mt-0.5">Café & Lubricentro</p>
        </div>
      </Link>

      <div className="space-y-6 flex-1">
        <div>
          <p className="text-[10px] font-semibold text-muted-foreground mb-2 uppercase tracking-widest px-2">Cafetería</p>
          <nav className="space-y-0.5">
            {menuItems.map(item => {
              const active = pathname === item.href
              return (
                <Link key={item.href} href={item.href}
                  onMouseEnter={() => setHovered(item.label)}
                  onMouseLeave={() => setHovered(null)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200",
                    active
                      ? "bg-primary text-primary-foreground shadow-lg shadow-primary/25"
                      : "text-muted-foreground hover:bg-secondary hover:text-foreground",
                    hovered === item.label && !active && "translate-x-1"
                  )}>
                  <item.icon className="w-4 h-4 flex-shrink-0" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </div>
        <div>
          <p className="text-[10px] font-semibold text-muted-foreground mb-2 uppercase tracking-widest px-2">General</p>
          <nav className="space-y-0.5">
            {generalItems.map(item => {
              const active = pathname === item.href
              return (
                <Link key={item.href} href={item.href}
                  onMouseEnter={() => setHovered(item.label)}
                  onMouseLeave={() => setHovered(null)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200",
                    active
                      ? "bg-primary text-primary-foreground shadow-lg shadow-primary/25"
                      : "text-muted-foreground hover:bg-secondary hover:text-foreground",
                    hovered === item.label && !active && "translate-x-1"
                  )}>
                  <item.icon className="w-4 h-4 flex-shrink-0" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </div>
      </div>

      <div className="pt-4 border-t border-sidebar-border flex items-center gap-3 px-2">
        <div className="w-8 h-8 rounded-full bg-primary/20 border border-primary/30 flex items-center justify-center">
          <span className="text-xs font-bold text-primary">AD</span>
        </div>
        <div>
          <p className="text-xs font-semibold text-foreground">Admin</p>
          <p className="text-[10px] text-muted-foreground">drive@sistema.com</p>
        </div>
      </div>
    </aside>
  )
}
ENDOFFILE
echo "✅ sidebar.tsx"

# ── HEADER ───────────────────────────────────────────────────
cat > components/dashboard/header.tsx << 'ENDOFFILE'
"use client"

import type React from "react"
import { Bell } from "lucide-react"
import { Button } from "@/components/ui/button"

interface HeaderProps {
  title: string
  description?: string
  actions?: React.ReactNode
}

export function Header({ title, description, actions }: HeaderProps) {
  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-5 border-b border-border">
      <div>
        <h1 className="font-extrabold italic tracking-wide uppercase text-2xl text-foreground">{title}</h1>
        {description && <p className="font-serif italic text-sm text-primary mt-0.5">{description}</p>}
      </div>
      <div className="flex items-center gap-3">
        <Button variant="outline" size="icon"
          className="h-9 w-9 bg-secondary border-border hover:bg-primary hover:text-primary-foreground hover:border-primary transition-all duration-200 relative">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-primary rounded-full" />
        </Button>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </div>
    </div>
  )
}
ENDOFFILE
echo "✅ header.tsx"

# ════════════════════════════════════════════════════════════
# HOME → PEDIDOS
# ════════════════════════════════════════════════════════════
mkdir -p components/cafeteria

cat > components/cafeteria/pedidos-view.tsx << 'ENDOFFILE'
"use client"

import { useStore } from "@/context/cafeteria-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ClipboardList, ChefHat, CheckCircle, Clock, PackageCheck, Plus } from "lucide-react"
import Link from "next/link"
import type { EstadoPedido } from "@/types/cafeteria"

const ESTADO_CFG: Record<EstadoPedido, {
  label: string
  badge: string
  leftBorder: string
  icon: React.ElementType
  btnLabel: string
  btnClass: string
}> = {
  pendiente: {
    label: "Pendiente",
    badge: "bg-secondary text-muted-foreground",
    leftBorder: "border-l-border/50",
    icon: Clock,
    btnLabel: "Iniciar",
    btnClass: "bg-primary text-primary-foreground hover:bg-primary/90",
  },
  en_preparacion: {
    label: "En preparación",
    badge: "bg-primary/20 text-primary",
    leftBorder: "border-l-primary",
    icon: ChefHat,
    btnLabel: "Listo ✓",
    btnClass: "bg-[#6B8E23] text-white hover:bg-[#6B8E23]/90",
  },
  listo: {
    label: "Listo ✓",
    badge: "bg-[#6B8E23]/20 text-[#6B8E23]",
    leftBorder: "border-l-[#6B8E23]",
    icon: CheckCircle,
    btnLabel: "Entregar",
    btnClass: "bg-[#E6D3A3]/20 text-[#E6D3A3] border border-[#E6D3A3]/40 hover:bg-[#E6D3A3]/30",
  },
  entregado: {
    label: "Entregado",
    badge: "bg-border/40 text-muted-foreground",
    leftBorder: "border-l-border/30",
    icon: PackageCheck,
    btnLabel: "Cobrar",
    btnClass: "bg-secondary text-foreground hover:bg-secondary/70",
  },
}

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

export function PedidosView() {
  const { pedidos, avanzarEstado, cerrarPedido } = useStore()

  if (pedidos.length === 0) {
    return (
      <Card className="border-border/60 p-20 flex flex-col items-center gap-4 text-center">
        <ClipboardList className="w-14 h-14 text-muted-foreground/30" />
        <p className="font-extrabold italic uppercase tracking-wide text-muted-foreground text-lg">Sin pedidos activos</p>
        <p className="font-serif italic text-sm text-muted-foreground/60">Creá el primer pedido desde el catálogo</p>
        <Link href="/catalogo">
          <Button className="bg-primary text-primary-foreground hover:bg-primary/90 font-bold uppercase tracking-wide text-xs mt-2 h-9">
            <Plus className="w-3.5 h-3.5 mr-1" /> Nuevo pedido
          </Button>
        </Link>
      </Card>
    )
  }

  return (
    <div className="space-y-4">

      {/* Contadores por estado */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {(["pendiente","en_preparacion","listo","entregado"] as EstadoPedido[]).map(e => {
          const cfg   = ESTADO_CFG[e]
          const count = pedidos.filter(p => p.estado === e).length
          const Icon  = cfg.icon
          return (
            <Card key={e} className="p-3 border-border/60 flex items-center gap-3">
              <div className={`p-2 rounded-lg ${cfg.badge}`}>
                <Icon className="w-4 h-4" />
              </div>
              <div>
                <p className="text-xl font-extrabold text-foreground">{count}</p>
                <p className="text-[10px] text-muted-foreground font-serif italic leading-tight">{cfg.label}</p>
              </div>
            </Card>
          )
        })}
      </div>

      {/* Tabla */}
      <Card className="border-border/60 overflow-hidden">
        <div className="p-5 border-b border-border/60 flex items-center justify-between">
          <div>
            <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-base">Pedidos activos</h2>
            <p className="font-serif italic text-xs text-primary">{pedidos.length} pedido{pedidos.length !== 1 ? "s" : ""}</p>
          </div>
          <Link href="/catalogo">
            <Button className="h-8 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90">
              <Plus className="w-3 h-3 mr-1" /> Nuevo
            </Button>
          </Link>
        </div>

        {/* Cabecera */}
        <div className="grid grid-cols-[44px_100px_1fr_90px_130px_110px] gap-3 px-5 py-2.5 border-b border-border/40 bg-secondary/30">
          {["#","Mesa","Pedido","Total","Estado","Acción"].map(h => (
            <p key={h} className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">{h}</p>
          ))}
        </div>

        {/* Filas */}
        <div className="divide-y divide-border/30">
          {pedidos.map(pedido => {
            const cfg    = ESTADO_CFG[pedido.estado]
            const Icon   = cfg.icon
            const resumen = pedido.items
              .map(i => `${i.emoji} ${i.nombre}${i.cantidad > 1 ? ` x${i.cantidad}` : ""}`)
              .join(" · ")

            return (
              <div key={pedido.id}
                className={`grid grid-cols-[44px_100px_1fr_90px_130px_110px] gap-3 px-5 py-3.5 items-center border-l-2 transition-all duration-200 hover:bg-secondary/20 ${cfg.leftBorder}`}
              >
                {/* # */}
                <span className="text-xs font-extrabold text-muted-foreground tabular-nums">
                  {String(pedido.numero).padStart(3, "0")}
                </span>

                {/* Mesa */}
                <div>
                  <p className="text-sm font-bold text-foreground">{pedido.mesaLabel}</p>
                  <p className="text-[10px] text-muted-foreground">{pedido.hora}</p>
                </div>

                {/* Pedido */}
                <p className="text-xs text-muted-foreground truncate" title={resumen}>{resumen}</p>

                {/* Total */}
                <p className="text-sm font-extrabold text-primary tabular-nums">{fmtPrecio(pedido.total)}</p>

                {/* Estado */}
                <span className={`inline-flex items-center gap-1.5 text-[10px] font-bold px-2.5 py-1 rounded-full w-fit ${cfg.badge}`}>
                  <Icon className="w-3 h-3" />
                  {cfg.label}
                </span>

                {/* Acción */}
                {pedido.estado === "entregado" ? (
                  <Button onClick={() => cerrarPedido(pedido.id)} size="sm"
                    className={`h-7 text-[10px] font-bold uppercase tracking-wide ${cfg.btnClass}`}>
                    Cobrar y cerrar
                  </Button>
                ) : (
                  <Button onClick={() => avanzarEstado(pedido.id)} size="sm"
                    className={`h-7 text-[10px] font-bold uppercase tracking-wide ${cfg.btnClass}`}>
                    {cfg.btnLabel}
                  </Button>
                )}
              </div>
            )
          })}
        </div>
      </Card>
    </div>
  )
}
ENDOFFILE
echo "✅ pedidos-view.tsx"

cat > app/page.tsx << 'ENDOFFILE'
import { Sidebar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { PedidosView } from "@/components/cafeteria/pedidos-view"
import { Button } from "@/components/ui/button"
import Link from "next/link"

export default function PedidosPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <div className="hidden lg:block"><Sidebar /></div>
      <main className="flex-1 p-4 md:p-5 lg:p-6 lg:ml-64">
        <Header
          title="Pedidos"
          description="Gestión de pedidos activos"
          actions={
            <Link href="/catalogo">
              <Button className="h-9 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90 hover:shadow-lg hover:shadow-primary/30">
                + Nuevo pedido
              </Button>
            </Link>
          }
        />
        <div className="mt-5"><PedidosView /></div>
      </main>
    </div>
  )
}
ENDOFFILE
echo "✅ app/page.tsx → Pedidos"

# ════════════════════════════════════════════════════════════
# MESAS → CARDS HARDCODEADAS (sin React Flow)
# ════════════════════════════════════════════════════════════
mkdir -p app/mesas

cat > components/cafeteria/mesas-content.tsx << 'ENDOFFILE'
"use client"

import { useState } from "react"
import { useStore, MESAS_CONFIG } from "@/context/cafeteria-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Users, Coffee, ChefHat, CheckCircle, PackageCheck, Plus, X } from "lucide-react"
import Link from "next/link"
import type { Pedido } from "@/types/cafeteria"

const ESTADO_BADGE: Record<string, string> = {
  pendiente:      "bg-secondary text-muted-foreground",
  en_preparacion: "bg-primary/20 text-primary",
  listo:          "bg-[#6B8E23]/20 text-[#6B8E23]",
  entregado:      "bg-border/40 text-muted-foreground",
}
const ESTADO_LABEL: Record<string, string> = {
  pendiente:      "Pendiente",
  en_preparacion: "Preparando",
  listo:          "Listo ✓",
  entregado:      "Entregado",
}

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

export function MesasContent() {
  const { getPedidosMesa, avanzarEstado, cerrarPedido } = useStore()
  const [mesaModal, setMesaModal] = useState<string | null>(null)

  const mesas  = MESAS_CONFIG.filter(m => m.tipo === "mesa")
  const barra  = MESAS_CONFIG.filter(m => m.tipo === "barra")

  const pedidosModal: Pedido[] = mesaModal
    ? getPedidosMesa(mesaModal).filter(p => p.estado !== "entregado")
    : []
  const mesaLabel = MESAS_CONFIG.find(m => m.id === mesaModal)?.label ?? ""

  const btnAvanzar: Record<string, { label: string; icon: React.ElementType; cls: string }> = {
    pendiente:      { label: "Iniciar",        icon: ChefHat,      cls: "bg-primary text-primary-foreground hover:bg-primary/90" },
    en_preparacion: { label: "Marcar listo",   icon: CheckCircle,  cls: "bg-[#6B8E23] text-white hover:bg-[#6B8E23]/90" },
    listo:          { label: "Entregar",       icon: CheckCircle,  cls: "bg-[#E6D3A3]/20 text-[#E6D3A3] border border-[#E6D3A3]/40" },
    entregado:      { label: "Cobrar y cerrar",icon: PackageCheck, cls: "bg-secondary text-foreground" },
  }

  // ── Card de asiento ────────────────────────────────────
  function AsientoCard({ id, label, tipo }: { id: string; label: string; tipo: "mesa" | "barra" }) {
    const pedidos  = getPedidosMesa(id)
    const ocupado  = pedidos.length > 0
    const Icon     = tipo === "mesa" ? Users : Coffee
    const total    = pedidos.reduce((a, p) => a + p.total, 0)
    const estado   = pedidos[0]?.estado ?? null

    return (
      <button
        onClick={() => setMesaModal(id)}
        className={`w-full text-left p-4 rounded-xl border-2 transition-all duration-300 hover:scale-[1.03] group ${
          ocupado
            ? estado === "listo"
              ? "border-[#6B8E23]/60 bg-[#6B8E23]/8 shadow-md shadow-[#6B8E23]/20"
              : "border-primary/60 bg-primary/8 shadow-md shadow-primary/20"
            : "border-border/50 bg-card hover:border-primary/30 hover:bg-primary/5"
        }`}
      >
        {/* Icon + indicador */}
        <div className="flex items-start justify-between mb-3">
          <div className={`p-2 rounded-lg transition-colors ${
            ocupado
              ? estado === "listo" ? "bg-[#6B8E23]/20" : "bg-primary/20"
              : "bg-secondary group-hover:bg-primary/10"
          }`}>
            <Icon className={`w-4 h-4 ${
              ocupado
                ? estado === "listo" ? "text-[#6B8E23]" : "text-primary"
                : "text-muted-foreground"
            }`} />
          </div>
          <span className={`w-2.5 h-2.5 rounded-full mt-1 ${
            ocupado
              ? estado === "listo" ? "bg-[#6B8E23] animate-pulse" : "bg-primary animate-pulse"
              : "bg-border"
          }`} />
        </div>

        {/* Label */}
        <p className="font-extrabold italic uppercase tracking-wide text-sm text-foreground mb-1">{label}</p>

        {/* Estado */}
        {ocupado ? (
          <>
            <span className={`inline-block text-[10px] font-bold px-2 py-0.5 rounded-full mb-1.5 ${ESTADO_BADGE[estado!]}`}>
              {ESTADO_LABEL[estado!]}
            </span>
            <p className="font-extrabold text-primary text-base leading-none">{fmtPrecio(total)}</p>
            <p className="text-[10px] text-muted-foreground mt-0.5">
              {pedidos.reduce((a, p) => a + p.items.length, 0)} ítem{pedidos.reduce((a,p)=>a+p.items.length,0)!==1?"s":""}
            </p>
          </>
        ) : (
          <p className="text-[10px] text-muted-foreground font-serif italic">Libre</p>
        )}
      </button>
    )
  }

  const libres   = MESAS_CONFIG.filter(m => getPedidosMesa(m.id).length === 0).length
  const ocupadas = MESAS_CONFIG.filter(m => getPedidosMesa(m.id).length > 0).length

  return (
    <div className="space-y-6 animate-fade-in">

      {/* Resumen */}
      <div className="grid grid-cols-3 gap-3">
        {[
          { label: "Total",    value: MESAS_CONFIG.length, color: "text-foreground" },
          { label: "Ocupados", value: ocupadas,            color: "text-primary" },
          { label: "Libres",   value: libres,              color: "text-[#6B8E23]" },
        ].map(s => (
          <Card key={s.label} className="p-3 text-center border-border/60">
            <p className={`text-2xl font-extrabold ${s.color}`}>{s.value}</p>
            <p className="text-[10px] font-serif italic text-muted-foreground">{s.label}</p>
          </Card>
        ))}
      </div>

      {/* Mesas */}
      <Card className="p-5 border-border/60">
        <div className="flex items-center gap-2 mb-4">
          <Users className="w-4 h-4 text-primary" />
          <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-base">Mesas</h2>
          <span className="font-serif italic text-xs text-muted-foreground ml-1">6 mesas</span>
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          {mesas.map(m => <AsientoCard key={m.id} id={m.id} label={m.label} tipo={m.tipo} />)}
        </div>
      </Card>

      {/* Barra */}
      <Card className="p-5 border-border/60">
        <div className="flex items-center gap-2 mb-3">
          <Coffee className="w-4 h-4 text-primary" />
          <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-base">Barra</h2>
          <span className="font-serif italic text-xs text-muted-foreground ml-1">6 banquetas</span>
        </div>
        {/* Mostrador decorativo */}
        <div className="h-2.5 rounded-full mb-4"
          style={{ background: "linear-gradient(90deg, #6F4E37, #9a7450, #6F4E37)", opacity: 0.7 }} />
        <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
          {barra.map(m => <AsientoCard key={m.id} id={m.id} label={m.label} tipo={m.tipo} />)}
        </div>
      </Card>

      {/* Modal detalle mesa */}
      <Dialog open={!!mesaModal} onOpenChange={v => !v && setMesaModal(null)}>
        <DialogContent className="bg-card border-border max-w-md">
          <DialogHeader>
            <DialogTitle className="font-extrabold italic uppercase tracking-wide text-foreground">
              {mesaLabel}
            </DialogTitle>
          </DialogHeader>

          {pedidosModal.length === 0 ? (
            <div className="py-8 flex flex-col items-center gap-3 text-center">
              <p className="font-serif italic text-sm text-muted-foreground">Mesa libre — sin pedidos activos</p>
              <Link href={`/catalogo?mesa=${mesaModal}`} onClick={() => setMesaModal(null)}>
                <Button className="bg-primary text-primary-foreground hover:bg-primary/90 font-bold uppercase tracking-wide text-xs h-8">
                  <Plus className="w-3 h-3 mr-1" /> Tomar pedido
                </Button>
              </Link>
            </div>
          ) : (
            <div className="space-y-3 py-2">
              {pedidosModal.map(p => {
                const btn = btnAvanzar[p.estado]
                const BtnIcon = btn.icon
                return (
                  <div key={p.id} className="border border-border/50 rounded-xl p-3.5 space-y-2.5">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="text-xs font-extrabold text-foreground">
                          Pedido #{String(p.numero).padStart(3,"0")}
                        </p>
                        <p className="text-[10px] text-muted-foreground">{p.hora}</p>
                      </div>
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${ESTADO_BADGE[p.estado]}`}>
                        {ESTADO_LABEL[p.estado]}
                      </span>
                    </div>

                    <div className="space-y-1">
                      {p.items.map((it, i) => (
                        <div key={i} className="flex justify-between text-[11px]">
                          <span className="text-muted-foreground">{it.emoji} {it.nombre} x{it.cantidad}</span>
                          <span className="font-semibold text-foreground">{fmtPrecio(it.precio * it.cantidad)}</span>
                        </div>
                      ))}
                    </div>

                    <div className="flex justify-between items-center pt-1.5 border-t border-border/40">
                      <span className="font-extrabold text-primary text-base">{fmtPrecio(p.total)}</span>
                      {p.estado === "entregado" ? (
                        <Button size="sm" onClick={() => { cerrarPedido(p.id); setMesaModal(null) }}
                          className={`h-7 text-[10px] font-bold uppercase ${btn.cls}`}>
                          <BtnIcon className="w-3 h-3 mr-1" /> Cobrar
                        </Button>
                      ) : (
                        <Button size="sm" onClick={() => avanzarEstado(p.id)}
                          className={`h-7 text-[10px] font-bold uppercase ${btn.cls}`}>
                          <BtnIcon className="w-3 h-3 mr-1" /> {btn.label}
                        </Button>
                      )}
                    </div>
                  </div>
                )
              })}

              <Link href={`/catalogo?mesa=${mesaModal}`} onClick={() => setMesaModal(null)}>
                <Button variant="outline"
                  className="w-full h-8 text-xs border-primary/40 text-primary hover:bg-primary hover:text-primary-foreground mt-1">
                  <Plus className="w-3 h-3 mr-1" /> Agregar pedido a esta mesa
                </Button>
              </Link>

              <Button variant="ghost" onClick={() => setMesaModal(null)}
                className="w-full h-7 text-xs text-muted-foreground hover:text-foreground">
                <X className="w-3 h-3 mr-1" /> Cerrar
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
ENDOFFILE
echo "✅ mesas-content.tsx (sin React Flow)"

cat > app/mesas/page.tsx << 'ENDOFFILE'
import { Sidebar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { MesasContent } from "@/components/cafeteria/mesas-content"

export default function MesasPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <div className="hidden lg:block"><Sidebar /></div>
      <main className="flex-1 p-4 md:p-5 lg:p-6 lg:ml-64">
        <Header
          title="Mesas & Barra"
          description="Estado en tiempo real del salón"
        />
        <div className="mt-5"><MesasContent /></div>
      </main>
    </div>
  )
}
ENDOFFILE
echo "✅ app/mesas/page.tsx"

# ════════════════════════════════════════════════════════════
# CATÁLOGO → CREAR PEDIDO
# ════════════════════════════════════════════════════════════
mkdir -p app/catalogo

cat > components/cafeteria/catalogo-crear-pedido.tsx << 'ENDOFFILE'
"use client"

import { useState, useEffect, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { useStore, CATEGORIAS, ITEMS_CATALOGO, MESAS_CONFIG } from "@/context/cafeteria-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Minus, Plus, ShoppingCart, Tag, Trash2 } from "lucide-react"
import type { ItemPedido } from "@/types/cafeteria"

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

function CatalogoInner() {
  const router  = useRouter()
  const params  = useSearchParams()
  const { crearPedido } = useStore()

  const [mesaId,    setMesaId]    = useState(params.get("mesa") ?? "")
  const [catActiva, setCatActiva] = useState("all")
  const [carrito,   setCarrito]   = useState<ItemPedido[]>([])

  useEffect(() => {
    const m = params.get("mesa")
    if (m) setMesaId(m)
  }, [params])

  const itemsFiltrados = catActiva === "all"
    ? ITEMS_CATALOGO
    : ITEMS_CATALOGO.filter(i => i.categoriaId === catActiva)

  const total    = carrito.reduce((a, i) => a + i.precio * i.cantidad, 0)
  const getCant  = (id: string) => carrito.find(i => i.id === id)?.cantidad ?? 0

  const modificar = (item: typeof ITEMS_CATALOGO[0], delta: number) => {
    setCarrito(prev => {
      const existe = prev.find(i => i.id === item.id)
      if (!existe) {
        if (delta < 1) return prev
        return [...prev, { id: item.id, nombre: item.nombre, emoji: item.emoji, precio: item.precio, cantidad: 1 }]
      }
      const nueva = existe.cantidad + delta
      if (nueva <= 0) return prev.filter(i => i.id !== item.id)
      return prev.map(i => i.id === item.id ? { ...i, cantidad: nueva } : i)
    })
  }

  const confirmar = () => {
    if (!mesaId || carrito.length === 0) return
    const mesa = MESAS_CONFIG.find(m => m.id === mesaId)!
    crearPedido(mesaId, mesa.label, carrito)
    router.push("/")
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

      {/* ── Catálogo ── */}
      <div className="lg:col-span-2 space-y-4">

        {/* Selector mesa */}
        <Card className="p-4 border-border/60">
          <div className="flex items-center gap-3">
            <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider flex-shrink-0">Mesa / Barra</p>
            <Select value={mesaId} onValueChange={setMesaId}>
              <SelectTrigger className="bg-secondary border-border text-foreground h-9 text-sm">
                <SelectValue placeholder="Seleccioná dónde..." />
              </SelectTrigger>
              <SelectContent className="bg-card border-border">
                <p className="text-[10px] font-bold text-muted-foreground uppercase px-2 pt-1.5 pb-0.5">Mesas</p>
                {MESAS_CONFIG.filter(m => m.tipo === "mesa").map(m => (
                  <SelectItem key={m.id} value={m.id} className="text-foreground hover:bg-secondary">{m.label}</SelectItem>
                ))}
                <p className="text-[10px] font-bold text-muted-foreground uppercase px-2 pt-2 pb-0.5">Barra</p>
                {MESAS_CONFIG.filter(m => m.tipo === "barra").map(m => (
                  <SelectItem key={m.id} value={m.id} className="text-foreground hover:bg-secondary">{m.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </Card>

        {/* Filtro categorías */}
        <div className="flex flex-wrap gap-2">
          <button onClick={() => setCatActiva("all")}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
              catActiva === "all" ? "bg-primary text-primary-foreground shadow-md" : "bg-secondary text-muted-foreground hover:text-foreground"
            }`}>
            <Tag className="w-3 h-3" /> Todo
          </button>
          {CATEGORIAS.map(c => (
            <button key={c.id} onClick={() => setCatActiva(c.id)}
              className={`px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                catActiva === c.id ? "bg-primary text-primary-foreground shadow-md" : "bg-secondary text-muted-foreground hover:text-foreground"
              }`}>
              {c.emoji} {c.nombre}
            </button>
          ))}
        </div>

        {/* Grid ítems */}
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
          {itemsFiltrados.map(item => {
            const cant = getCant(item.id)
            return (
              <Card key={item.id}
                className={`p-3.5 border-2 transition-all duration-200 ${
                  cant > 0 ? "border-primary/60 bg-primary/5 shadow-md shadow-primary/10" : "border-border/50 hover:border-primary/30"
                }`}>
                <div className="flex items-start gap-2 mb-3">
                  <span className="text-2xl">{item.emoji}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-foreground truncate">{item.nombre}</p>
                    <p className="text-sm font-extrabold text-primary">{fmtPrecio(item.precio)}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <button onClick={() => modificar(item, -1)}
                    className="w-7 h-7 rounded-lg bg-secondary flex items-center justify-center hover:bg-primary/20 transition-colors">
                    <Minus className="w-3.5 h-3.5 text-foreground" />
                  </button>
                  <span className={`text-base font-extrabold w-6 text-center ${cant > 0 ? "text-primary" : "text-muted-foreground"}`}>
                    {cant}
                  </span>
                  <button onClick={() => modificar(item, 1)}
                    className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center hover:bg-primary/90 transition-colors">
                    <Plus className="w-3.5 h-3.5 text-primary-foreground" />
                  </button>
                </div>
              </Card>
            )
          })}
        </div>
      </div>

      {/* ── Carrito sticky ── */}
      <div className="lg:sticky lg:top-6 self-start">
        <Card className="p-4 border-border/60">
          <div className="flex items-center gap-2 mb-4">
            <ShoppingCart className="w-4 h-4 text-primary" />
            <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-sm">Pedido</h2>
            {carrito.length > 0 && (
              <span className="ml-auto bg-primary text-primary-foreground text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center">
                {carrito.reduce((a, i) => a + i.cantidad, 0)}
              </span>
            )}
          </div>

          {carrito.length === 0 ? (
            <div className="py-8 text-center">
              <ShoppingCart className="w-8 h-8 text-muted-foreground/30 mx-auto mb-2" />
              <p className="text-xs text-muted-foreground font-serif italic">Agregá ítems del catálogo</p>
            </div>
          ) : (
            <div className="space-y-2 mb-4 max-h-64 overflow-y-auto pr-1">
              {carrito.map(it => (
                <div key={it.id} className="flex items-center gap-2 p-2 bg-secondary/50 rounded-lg">
                  <span className="text-base flex-shrink-0">{it.emoji}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-semibold text-foreground truncate">{it.nombre}</p>
                    <p className="text-[10px] text-muted-foreground">x{it.cantidad} · {fmtPrecio(it.precio * it.cantidad)}</p>
                  </div>
                  <button onClick={() => setCarrito(prev => prev.filter(i => i.id !== it.id))}
                    className="w-5 h-5 flex items-center justify-center rounded hover:bg-destructive/20 transition-colors flex-shrink-0">
                    <Trash2 className="w-3 h-3 text-muted-foreground" />
                  </button>
                </div>
              ))}
            </div>
          )}

          {carrito.length > 0 && (
            <div className="flex justify-between items-center py-2.5 border-t border-border/50 mb-3">
              <span className="font-extrabold italic uppercase text-xs text-foreground">Total</span>
              <span className="font-extrabold text-primary text-xl">{fmtPrecio(total)}</span>
            </div>
          )}

          <Button onClick={confirmar} disabled={carrito.length === 0 || !mesaId}
            className="w-full h-10 font-bold uppercase tracking-wide text-xs bg-primary text-primary-foreground hover:bg-primary/90 hover:shadow-lg hover:shadow-primary/30 disabled:opacity-40 transition-all">
            <ShoppingCart className="w-3.5 h-3.5 mr-1.5" /> Confirmar pedido
          </Button>

          {!mesaId && carrito.length > 0 && (
            <p className="text-[10px] text-center text-muted-foreground mt-2 font-serif italic">
              Seleccioná una mesa primero
            </p>
          )}
        </Card>
      </div>
    </div>
  )
}

export function CatalogoCrearPedido() {
  return (
    <Suspense fallback={<div className="text-muted-foreground text-sm font-serif italic">Cargando catálogo...</div>}>
      <CatalogoInner />
    </Suspense>
  )
}
ENDOFFILE
echo "✅ catalogo-crear-pedido.tsx"

cat > app/catalogo/page.tsx << 'ENDOFFILE'
import { Sidebar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { CatalogoCrearPedido } from "@/components/cafeteria/catalogo-crear-pedido"

export default function CatalogoPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <div className="hidden lg:block"><Sidebar /></div>
      <main className="flex-1 p-4 md:p-5 lg:p-6 lg:ml-64">
        <Header
          title="Catálogo"
          description="Seleccioná ítems para armar el pedido"
        />
        <div className="mt-5"><CatalogoCrearPedido /></div>
      </main>
    </div>
  )
}
ENDOFFILE
echo "✅ app/catalogo/page.tsx"

# Desinstalar React Flow si quedó instalado
echo "🧹 Removiendo @xyflow/react si existe..."
pnpm remove @xyflow/react 2>/dev/null || true

echo ""
echo "============================================"
echo "✅ Versión final sin React Flow:"
echo "   /         → Pedidos (tabla + contadores)"
echo "   /mesas    → Cards hardcodeadas + barra"
echo "   /catalogo → Crear pedido con carrito"
echo "============================================"#!/bin/bash
# ============================================================
# DRIVE Cafetería — Versión Responsive
# Mobile: bottom nav + bottom sheet + floating cart
# Desktop: sidebar + tabla + cards normales
# ============================================================
set -e

echo "🗑️  Limpiando..."
rm -rf app/analytics app/calendar app/tasks app/team app/help app/pedidos app/dashboard
rm -f  components/cafeteria/mesas-flow.tsx
rm -f  components/cafeteria/pedidos-content.tsx
rm -f  components/cafeteria/pedidos-view.tsx
rm -f  components/cafeteria/catalogo-crear-pedido.tsx
rm -f  components/cafeteria/catalogo-content.tsx
rm -f  components/cafeteria/pedido-builder.tsx
rm -f  components/cafeteria/mesas-content.tsx
rm -f  context/cafeteria-context.tsx
rm -f  context/cafeteria-store.tsx
rm -f  types/cafeteria.ts
echo "✅ Limpieza"

# ── TIPOS ────────────────────────────────────────────────────
mkdir -p types
cat > types/cafeteria.ts << 'ENDOFFILE'
export type EstadoPedido = "pendiente" | "en_preparacion" | "listo" | "entregado"

export type ItemPedido = {
  id: string
  nombre: string
  emoji: string
  precio: number
  cantidad: number
}

export type Pedido = {
  id: string
  numero: number
  mesaId: string
  mesaLabel: string
  items: ItemPedido[]
  estado: EstadoPedido
  total: number
  hora: string
}
ENDOFFILE

# ── STORE ────────────────────────────────────────────────────
mkdir -p context
cat > context/cafeteria-store.tsx << 'ENDOFFILE'
"use client"

import React, { createContext, useContext, useState } from "react"
import type { Pedido, ItemPedido, EstadoPedido } from "@/types/cafeteria"

const pedidosIniciales: Pedido[] = [
  {
    id: "ped-001", numero: 1, mesaId: "mesa-3", mesaLabel: "Mesa 3",
    items: [
      { id: "i-3",  nombre: "Latte",        emoji: "🥛", precio: 1200, cantidad: 2 },
      { id: "i-12", nombre: "Medialunas x3", emoji: "🥐", precio: 900,  cantidad: 1 },
    ],
    estado: "en_preparacion", total: 3300, hora: "10:15",
  },
  {
    id: "ped-002", numero: 2, mesaId: "barra-2", mesaLabel: "Barra 2",
    items: [{ id: "i-1", nombre: "Espresso", emoji: "☕", precio: 800, cantidad: 1 }],
    estado: "listo", total: 800, hora: "10:28",
  },
  {
    id: "ped-003", numero: 3, mesaId: "mesa-1", mesaLabel: "Mesa 1",
    items: [
      { id: "i-9",  nombre: "Frappé",     emoji: "🧋", precio: 1500, cantidad: 2 },
      { id: "i-16", nombre: "Cheesecake", emoji: "🍰", precio: 1600, cantidad: 2 },
    ],
    estado: "pendiente", total: 6200, hora: "10:40",
  },
]

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

export const MESAS_CONFIG = [
  { id: "mesa-1",  label: "Mesa 1",  tipo: "mesa"  as const },
  { id: "mesa-2",  label: "Mesa 2",  tipo: "mesa"  as const },
  { id: "mesa-3",  label: "Mesa 3",  tipo: "mesa"  as const },
  { id: "mesa-4",  label: "Mesa 4",  tipo: "mesa"  as const },
  { id: "mesa-5",  label: "Mesa 5",  tipo: "mesa"  as const },
  { id: "mesa-6",  label: "Mesa 6",  tipo: "mesa"  as const },
  { id: "barra-1", label: "Barra 1", tipo: "barra" as const },
  { id: "barra-2", label: "Barra 2", tipo: "barra" as const },
  { id: "barra-3", label: "Barra 3", tipo: "barra" as const },
  { id: "barra-4", label: "Barra 4", tipo: "barra" as const },
  { id: "barra-5", label: "Barra 5", tipo: "barra" as const },
  { id: "barra-6", label: "Barra 6", tipo: "barra" as const },
]

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

  const avanzarEstado = (pedidoId: string) =>
    setPedidos(prev => prev.map(p => {
      if (p.id !== pedidoId) return p
      const next = FLUJO[Math.min(FLUJO.indexOf(p.estado) + 1, FLUJO.length - 1)]
      return { ...p, estado: next }
    }))

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
ENDOFFILE
echo "✅ store"

# ── LAYOUT ───────────────────────────────────────────────────
cat > app/layout.tsx << 'ENDOFFILE'
import type React from "react"
import type { Metadata } from "next"
import { Montserrat, Playfair_Display } from "next/font/google"
import { Analytics } from "@vercel/analytics/next"
import { ThemeProvider } from "@/components/theme-provider"
import { CafeteriaStore } from "@/context/cafeteria-store"
import "./globals.css"

const montserrat = Montserrat({ subsets: ["latin"], variable: "--font-sans", weight: ["400","500","600","700","800","900"] })
const playfair   = Playfair_Display({ subsets: ["latin"], variable: "--font-serif", style: ["normal","italic"], weight: ["400","500","600","700"] })

export const metadata: Metadata = {
  title: "DRIVE — Café & Lubricentro",
  description: "Sistema de gestión DRIVE",
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" className="dark">
      <body className={`${montserrat.variable} ${playfair.variable} font-sans antialiased`}>
        <ThemeProvider defaultTheme="dark" storageKey="drive-theme">
          <CafeteriaStore>{children}</CafeteriaStore>
        </ThemeProvider>
        <Analytics />
      </body>
    </html>
  )
}
ENDOFFILE
echo "✅ layout.tsx"

# ════════════════════════════════════════════════════════════
# SIDEBAR DESKTOP + BOTTOM NAV MOBILE
# ════════════════════════════════════════════════════════════
cat > components/dashboard/sidebar.tsx << 'ENDOFFILE'
"use client"

import { ClipboardList, MapPin, BookOpen, Settings, LogOut, Wrench } from "lucide-react"
import { cn } from "@/lib/utils"
import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"

const menuItems = [
  { icon: ClipboardList, label: "Pedidos",  href: "/" },
  { icon: MapPin,        label: "Mesas",    href: "/mesas" },
  { icon: BookOpen,      label: "Catálogo", href: "/catalogo" },
]
const generalItems = [
  { icon: Settings, label: "Config", href: "/settings" },
  { icon: LogOut,   label: "Salir",  href: "/logout" },
]

// ── Desktop sidebar ──────────────────────────────────────────
export function Sidebar() {
  const [hovered, setHovered] = useState<string | null>(null)
  const pathname = usePathname()

  return (
    <aside className="fixed top-0 left-0 w-64 bg-sidebar border-r border-sidebar-border p-5 h-screen flex-col hidden lg:flex">
      <Link href="/" className="flex items-center gap-3 group mb-8">
        <div className="w-10 h-10 rounded-lg bg-primary flex items-center justify-center shadow-lg shadow-primary/30 transition-transform group-hover:scale-105">
          <Wrench className="w-5 h-5 text-primary-foreground" />
        </div>
        <div>
          <p className="font-extrabold italic tracking-wider uppercase text-foreground text-lg leading-none">DRIVE</p>
          <p className="font-serif italic text-xs text-primary tracking-wide leading-none mt-0.5">Café & Lubricentro</p>
        </div>
      </Link>

      <div className="space-y-6 flex-1">
        <div>
          <p className="text-[10px] font-semibold text-muted-foreground mb-2 uppercase tracking-widest px-2">Cafetería</p>
          <nav className="space-y-0.5">
            {menuItems.map(item => {
              const active = pathname === item.href
              return (
                <Link key={item.href} href={item.href}
                  onMouseEnter={() => setHovered(item.label)}
                  onMouseLeave={() => setHovered(null)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200",
                    active ? "bg-primary text-primary-foreground shadow-lg shadow-primary/25"
                           : "text-muted-foreground hover:bg-secondary hover:text-foreground",
                    hovered === item.label && !active && "translate-x-1"
                  )}>
                  <item.icon className="w-4 h-4 flex-shrink-0" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </div>
        <div>
          <p className="text-[10px] font-semibold text-muted-foreground mb-2 uppercase tracking-widest px-2">General</p>
          <nav className="space-y-0.5">
            {generalItems.map(item => {
              const active = pathname === item.href
              return (
                <Link key={item.href} href={item.href}
                  onMouseEnter={() => setHovered(item.label)}
                  onMouseLeave={() => setHovered(null)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200",
                    active ? "bg-primary text-primary-foreground shadow-lg shadow-primary/25"
                           : "text-muted-foreground hover:bg-secondary hover:text-foreground",
                    hovered === item.label && !active && "translate-x-1"
                  )}>
                  <item.icon className="w-4 h-4 flex-shrink-0" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </div>
      </div>

      <div className="pt-4 border-t border-sidebar-border flex items-center gap-3 px-2">
        <div className="w-8 h-8 rounded-full bg-primary/20 border border-primary/30 flex items-center justify-center">
          <span className="text-xs font-bold text-primary">AD</span>
        </div>
        <div>
          <p className="text-xs font-semibold text-foreground">Admin</p>
          <p className="text-[10px] text-muted-foreground">drive@sistema.com</p>
        </div>
      </div>
    </aside>
  )
}

// ── Mobile bottom nav ────────────────────────────────────────
export function BottomNav() {
  const pathname = usePathname()

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-50 bg-sidebar border-t border-sidebar-border">
      <div className="flex items-center justify-around h-16 px-2">
        {menuItems.map(item => {
          const active = pathname === item.href
          return (
            <Link key={item.href} href={item.href}
              className={cn(
                "flex flex-col items-center gap-0.5 px-4 py-2 rounded-xl transition-all duration-200 min-w-0 flex-1",
                active ? "text-primary" : "text-muted-foreground"
              )}>
              <div className={cn(
                "w-8 h-8 rounded-xl flex items-center justify-center transition-all duration-200",
                active ? "bg-primary/20 shadow-md shadow-primary/20" : ""
              )}>
                <item.icon className={cn("w-5 h-5", active && "text-primary")} />
              </div>
              <span className={cn(
                "text-[10px] font-semibold leading-none",
                active ? "text-primary" : "text-muted-foreground"
              )}>
                {item.label}
              </span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}

// ── Mobile header ────────────────────────────────────────────
export function MobileTopBar({ title }: { title: string }) {
  return (
    <div className="lg:hidden flex items-center justify-between px-4 py-3 border-b border-border bg-sidebar sticky top-0 z-40">
      <div className="flex items-center gap-2.5">
        <div className="w-7 h-7 rounded-md bg-primary flex items-center justify-center">
          <Wrench className="w-3.5 h-3.5 text-primary-foreground" />
        </div>
        <div>
          <p className="font-extrabold italic tracking-wider uppercase text-foreground text-sm leading-none">DRIVE</p>
          <p className="font-serif italic text-[9px] text-primary leading-none">Cafetería</p>
        </div>
      </div>
      <p className="font-extrabold italic uppercase tracking-wide text-foreground text-sm">{title}</p>
    </div>
  )
}
ENDOFFILE
echo "✅ sidebar + bottom nav + mobile topbar"

# ── HEADER DESKTOP ───────────────────────────────────────────
cat > components/dashboard/header.tsx << 'ENDOFFILE'
"use client"

import type React from "react"
import { Bell } from "lucide-react"
import { Button } from "@/components/ui/button"

interface HeaderProps {
  title: string
  description?: string
  actions?: React.ReactNode
}

export function Header({ title, description, actions }: HeaderProps) {
  return (
    <div className="hidden lg:flex flex-row items-center justify-between gap-4 pb-5 border-b border-border">
      <div>
        <h1 className="font-extrabold italic tracking-wide uppercase text-2xl text-foreground">{title}</h1>
        {description && <p className="font-serif italic text-sm text-primary mt-0.5">{description}</p>}
      </div>
      <div className="flex items-center gap-3">
        <Button variant="outline" size="icon"
          className="h-9 w-9 bg-secondary border-border hover:bg-primary hover:text-primary-foreground hover:border-primary transition-all duration-200 relative">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-primary rounded-full" />
        </Button>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </div>
    </div>
  )
}
ENDOFFILE
echo "✅ header.tsx"

# ════════════════════════════════════════════════════════════
# PEDIDOS — tabla desktop / cards mobile
# ════════════════════════════════════════════════════════════
mkdir -p components/cafeteria

cat > components/cafeteria/pedidos-view.tsx << 'ENDOFFILE'
"use client"

import { useStore } from "@/context/cafeteria-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ClipboardList, ChefHat, CheckCircle, Clock, PackageCheck, Plus } from "lucide-react"
import Link from "next/link"
import type { EstadoPedido } from "@/types/cafeteria"

const ESTADO_CFG: Record<EstadoPedido, {
  label: string; badge: string; leftBorder: string
  icon: React.ElementType; btnLabel: string; btnClass: string
}> = {
  pendiente:      { label: "Pendiente",      badge: "bg-secondary text-muted-foreground",          leftBorder: "border-l-border",          icon: Clock,        btnLabel: "Iniciar",   btnClass: "bg-primary text-primary-foreground hover:bg-primary/90" },
  en_preparacion: { label: "En preparación", badge: "bg-primary/20 text-primary",                  leftBorder: "border-l-primary",         icon: ChefHat,      btnLabel: "Listo ✓",  btnClass: "bg-[#6B8E23] text-white hover:bg-[#6B8E23]/90" },
  listo:          { label: "Listo ✓",        badge: "bg-[#6B8E23]/20 text-[#6B8E23]",              leftBorder: "border-l-[#6B8E23]",       icon: CheckCircle,  btnLabel: "Entregar", btnClass: "bg-[#E6D3A3]/20 text-[#E6D3A3] border border-[#E6D3A3]/40 hover:bg-[#E6D3A3]/30" },
  entregado:      { label: "Entregado",      badge: "bg-border/40 text-muted-foreground",          leftBorder: "border-l-border/30",       icon: PackageCheck, btnLabel: "Cobrar",   btnClass: "bg-secondary text-foreground hover:bg-secondary/70" },
}

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

export function PedidosView() {
  const { pedidos, avanzarEstado, cerrarPedido } = useStore()

  if (pedidos.length === 0) {
    return (
      <div className="flex flex-col items-center gap-4 text-center py-20 px-6">
        <ClipboardList className="w-14 h-14 text-muted-foreground/30" />
        <p className="font-extrabold italic uppercase tracking-wide text-muted-foreground text-lg">Sin pedidos activos</p>
        <p className="font-serif italic text-sm text-muted-foreground/60">Creá el primer pedido desde el catálogo</p>
        <Link href="/catalogo">
          <Button className="bg-primary text-primary-foreground hover:bg-primary/90 font-bold uppercase tracking-wide text-xs h-10 px-6">
            <Plus className="w-3.5 h-3.5 mr-1" /> Nuevo pedido
          </Button>
        </Link>
      </div>
    )
  }

  return (
    <div className="space-y-4">

      {/* Contadores — 2 cols mobile, 4 desktop */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 lg:gap-3">
        {(["pendiente","en_preparacion","listo","entregado"] as EstadoPedido[]).map(e => {
          const cfg   = ESTADO_CFG[e]
          const count = pedidos.filter(p => p.estado === e).length
          const Icon  = cfg.icon
          return (
            <Card key={e} className="p-3 border-border/60 flex items-center gap-2.5">
              <div className={`p-1.5 lg:p-2 rounded-lg ${cfg.badge} flex-shrink-0`}>
                <Icon className="w-3.5 h-3.5 lg:w-4 lg:h-4" />
              </div>
              <div className="min-w-0">
                <p className="text-lg lg:text-xl font-extrabold text-foreground leading-none">{count}</p>
                <p className="text-[9px] lg:text-[10px] text-muted-foreground font-serif italic leading-tight truncate">{cfg.label}</p>
              </div>
            </Card>
          )
        })}
      </div>

      {/* ── MOBILE: Cards por pedido ── */}
      <div className="lg:hidden space-y-2.5">
        <div className="flex items-center justify-between px-1">
          <p className="font-extrabold italic uppercase tracking-wide text-foreground text-sm">
            {pedidos.length} pedido{pedidos.length !== 1 ? "s" : ""}
          </p>
          <Link href="/catalogo">
            <Button size="sm" className="h-8 text-xs font-bold uppercase bg-primary text-primary-foreground hover:bg-primary/90">
              <Plus className="w-3 h-3 mr-1" /> Nuevo
            </Button>
          </Link>
        </div>

        {pedidos.map(pedido => {
          const cfg  = ESTADO_CFG[pedido.estado]
          const Icon = cfg.icon
          return (
            <Card key={pedido.id}
              className={`border-l-4 border-border/60 overflow-hidden ${cfg.leftBorder}`}>
              <div className="p-4">
                {/* Header */}
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-extrabold text-muted-foreground tabular-nums">
                        #{String(pedido.numero).padStart(3,"0")}
                      </span>
                      <span className="font-bold text-foreground text-sm">{pedido.mesaLabel}</span>
                    </div>
                    <p className="text-[10px] text-muted-foreground mt-0.5">{pedido.hora}</p>
                  </div>
                  <span className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-1 rounded-full ${cfg.badge}`}>
                    <Icon className="w-3 h-3" />
                    {cfg.label}
                  </span>
                </div>

                {/* Items */}
                <p className="text-xs text-muted-foreground mb-3 line-clamp-2">
                  {pedido.items.map(i => `${i.emoji} ${i.nombre}${i.cantidad > 1 ? ` x${i.cantidad}` : ""}`).join(" · ")}
                </p>

                {/* Footer */}
                <div className="flex items-center justify-between">
                  <span className="font-extrabold text-primary text-lg">{fmtPrecio(pedido.total)}</span>
                  {pedido.estado === "entregado" ? (
                    <Button onClick={() => cerrarPedido(pedido.id)} size="sm"
                      className={`h-8 text-xs font-bold uppercase ${cfg.btnClass}`}>
                      Cobrar y cerrar
                    </Button>
                  ) : (
                    <Button onClick={() => avanzarEstado(pedido.id)} size="sm"
                      className={`h-8 text-xs font-bold uppercase ${cfg.btnClass}`}>
                      {cfg.btnLabel}
                    </Button>
                  )}
                </div>
              </div>
            </Card>
          )
        })}
      </div>

      {/* ── DESKTOP: Tabla ── */}
      <Card className="hidden lg:block border-border/60 overflow-hidden">
        <div className="p-5 border-b border-border/60 flex items-center justify-between">
          <div>
            <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-base">Pedidos activos</h2>
            <p className="font-serif italic text-xs text-primary">{pedidos.length} pedido{pedidos.length !== 1 ? "s" : ""}</p>
          </div>
          <Link href="/catalogo">
            <Button className="h-8 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90">
              <Plus className="w-3 h-3 mr-1" /> Nuevo
            </Button>
          </Link>
        </div>

        <div className="grid grid-cols-[44px_110px_1fr_100px_140px_120px] gap-3 px-5 py-2.5 border-b border-border/40 bg-secondary/30">
          {["#","Mesa","Pedido","Total","Estado","Acción"].map(h => (
            <p key={h} className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">{h}</p>
          ))}
        </div>

        <div className="divide-y divide-border/30">
          {pedidos.map(pedido => {
            const cfg    = ESTADO_CFG[pedido.estado]
            const Icon   = cfg.icon
            const resumen = pedido.items.map(i => `${i.emoji} ${i.nombre}${i.cantidad > 1 ? ` x${i.cantidad}` : ""}`).join(" · ")
            return (
              <div key={pedido.id}
                className={`grid grid-cols-[44px_110px_1fr_100px_140px_120px] gap-3 px-5 py-3.5 items-center border-l-2 hover:bg-secondary/20 transition-colors ${cfg.leftBorder}`}>
                <span className="text-xs font-extrabold text-muted-foreground tabular-nums">{String(pedido.numero).padStart(3,"0")}</span>
                <div>
                  <p className="text-sm font-bold text-foreground">{pedido.mesaLabel}</p>
                  <p className="text-[10px] text-muted-foreground">{pedido.hora}</p>
                </div>
                <p className="text-xs text-muted-foreground truncate">{resumen}</p>
                <p className="text-sm font-extrabold text-primary tabular-nums">{fmtPrecio(pedido.total)}</p>
                <span className={`inline-flex items-center gap-1.5 text-[10px] font-bold px-2.5 py-1 rounded-full w-fit ${cfg.badge}`}>
                  <Icon className="w-3 h-3" />{cfg.label}
                </span>
                {pedido.estado === "entregado" ? (
                  <Button onClick={() => cerrarPedido(pedido.id)} size="sm"
                    className={`h-7 text-[10px] font-bold uppercase ${cfg.btnClass}`}>Cobrar y cerrar</Button>
                ) : (
                  <Button onClick={() => avanzarEstado(pedido.id)} size="sm"
                    className={`h-7 text-[10px] font-bold uppercase ${cfg.btnClass}`}>{cfg.btnLabel}</Button>
                )}
              </div>
            )
          })}
        </div>
      </Card>
    </div>
  )
}
ENDOFFILE
echo "✅ pedidos-view.tsx"

cat > app/page.tsx << 'ENDOFFILE'
import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { PedidosView } from "@/components/cafeteria/pedidos-view"
import { Button } from "@/components/ui/button"
import Link from "next/link"

export default function PedidosPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <Sidebar />
      <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
        <MobileTopBar title="Pedidos" />
        {/* Mobile: botón nuevo flotante */}
        <div className="lg:hidden flex justify-end px-4 pt-4 pb-2">
          <Link href="/catalogo">
            <Button className="h-9 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/30">
              <span className="mr-1 text-base font-bold leading-none">+</span> Nuevo pedido
            </Button>
          </Link>
        </div>

        <div className="p-4 lg:p-6">
          <Header
            title="Pedidos"
            description="Gestión de pedidos activos"
            actions={
              <Link href="/catalogo">
                <Button className="h-9 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90 hover:shadow-lg hover:shadow-primary/30">
                  + Nuevo pedido
                </Button>
              </Link>
            }
          />
          <div className="mt-4 lg:mt-5"><PedidosView /></div>
        </div>
      </main>
      <BottomNav />
    </div>
  )
}
ENDOFFILE
echo "✅ app/page.tsx"

# ════════════════════════════════════════════════════════════
# MESAS — cards + bottom sheet en mobile
# ════════════════════════════════════════════════════════════
mkdir -p app/mesas

cat > components/cafeteria/mesas-content.tsx << 'ENDOFFILE'
"use client"

import { useState } from "react"
import { useStore, MESAS_CONFIG } from "@/context/cafeteria-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Drawer, DrawerContent, DrawerHeader, DrawerTitle } from "@/components/ui/drawer"
import { Users, Coffee, ChefHat, CheckCircle, PackageCheck, Plus, X } from "lucide-react"
import Link from "next/link"
import type { Pedido } from "@/types/cafeteria"

const ESTADO_BADGE: Record<string, string> = {
  pendiente:      "bg-secondary text-muted-foreground",
  en_preparacion: "bg-primary/20 text-primary",
  listo:          "bg-[#6B8E23]/20 text-[#6B8E23]",
  entregado:      "bg-border/40 text-muted-foreground",
}
const ESTADO_LABEL: Record<string, string> = {
  pendiente: "Pendiente", en_preparacion: "Preparando", listo: "Listo ✓", entregado: "Entregado",
}

const BTN_AVANZAR: Record<string, { label: string; icon: React.ElementType; cls: string }> = {
  pendiente:      { label: "Iniciar",         icon: ChefHat,     cls: "bg-primary text-primary-foreground hover:bg-primary/90" },
  en_preparacion: { label: "Marcar listo",    icon: CheckCircle, cls: "bg-[#6B8E23] text-white hover:bg-[#6B8E23]/90" },
  listo:          { label: "Entregar",        icon: CheckCircle, cls: "bg-[#E6D3A3]/20 text-[#E6D3A3] border border-[#E6D3A3]/40" },
  entregado:      { label: "Cobrar y cerrar", icon: PackageCheck,cls: "bg-secondary text-foreground" },
}

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

export function MesasContent() {
  const { getPedidosMesa, avanzarEstado, cerrarPedido } = useStore()
  const [mesaModal, setMesaModal] = useState<string | null>(null)

  const mesas = MESAS_CONFIG.filter(m => m.tipo === "mesa")
  const barra = MESAS_CONFIG.filter(m => m.tipo === "barra")

  const pedidosModal = mesaModal
    ? getPedidosMesa(mesaModal).filter(p => p.estado !== "entregado")
    : []
  const mesaLabel = MESAS_CONFIG.find(m => m.id === mesaModal)?.label ?? ""

  // ── Card asiento ─────────────────────────────────────────
  function AsientoCard({ id, label, tipo }: { id: string; label: string; tipo: "mesa" | "barra" }) {
    const pedidos = getPedidosMesa(id)
    const ocupado = pedidos.length > 0
    const estado  = pedidos[0]?.estado ?? null
    const total   = pedidos.reduce((a, p) => a + p.total, 0)
    const Icon    = tipo === "mesa" ? Users : Coffee
    const esListo = estado === "listo"

    return (
      <button onClick={() => setMesaModal(id)}
        className={[
          "w-full text-left p-3.5 lg:p-4 rounded-xl border-2 transition-all duration-200 active:scale-95 lg:hover:scale-[1.03] group",
          ocupado
            ? esListo
              ? "border-[#6B8E23]/60 bg-[#6B8E23]/8 shadow-md shadow-[#6B8E23]/20"
              : "border-primary/60 bg-primary/8 shadow-md shadow-primary/20"
            : "border-border/50 bg-card hover:border-primary/30",
        ].join(" ")}
      >
        <div className="flex items-start justify-between mb-2.5">
          <div className={`p-1.5 lg:p-2 rounded-lg ${ocupado ? (esListo ? "bg-[#6B8E23]/20" : "bg-primary/20") : "bg-secondary"}`}>
            <Icon className={`w-3.5 h-3.5 lg:w-4 lg:h-4 ${ocupado ? (esListo ? "text-[#6B8E23]" : "text-primary") : "text-muted-foreground"}`} />
          </div>
          <span className={`w-2 h-2 rounded-full mt-1 ${ocupado ? (esListo ? "bg-[#6B8E23] animate-pulse" : "bg-primary animate-pulse") : "bg-border"}`} />
        </div>
        <p className="font-extrabold italic uppercase tracking-wide text-xs lg:text-sm text-foreground mb-1">{label}</p>
        {ocupado ? (
          <>
            <span className={`inline-block text-[9px] lg:text-[10px] font-bold px-1.5 py-0.5 rounded-full mb-1 ${ESTADO_BADGE[estado!]}`}>
              {ESTADO_LABEL[estado!]}
            </span>
            <p className="font-extrabold text-primary text-sm lg:text-base leading-none">{fmtPrecio(total)}</p>
          </>
        ) : (
          <p className="text-[9px] lg:text-[10px] text-muted-foreground font-serif italic">Libre</p>
        )}
      </button>
    )
  }

  // ── Contenido del modal/drawer compartido ─────────────────
  function ModalContent({ onClose }: { onClose: () => void }) {
    return (
      <div className="space-y-3 py-2">
        {pedidosModal.length === 0 ? (
          <div className="py-8 flex flex-col items-center gap-3 text-center">
            <p className="font-serif italic text-sm text-muted-foreground">Mesa libre — sin pedidos activos</p>
            <Link href={`/catalogo?mesa=${mesaModal}`} onClick={onClose}>
              <Button className="bg-primary text-primary-foreground hover:bg-primary/90 font-bold uppercase tracking-wide text-xs h-9">
                <Plus className="w-3 h-3 mr-1" /> Tomar pedido
              </Button>
            </Link>
          </div>
        ) : (
          <>
            {pedidosModal.map((p: Pedido) => {
              const btn = BTN_AVANZAR[p.estado]
              const BtnIcon = btn.icon
              return (
                <div key={p.id} className="border border-border/50 rounded-xl p-3.5 space-y-2.5">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="text-xs font-extrabold text-foreground">Pedido #{String(p.numero).padStart(3,"0")}</p>
                      <p className="text-[10px] text-muted-foreground">{p.hora}</p>
                    </div>
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${ESTADO_BADGE[p.estado]}`}>
                      {ESTADO_LABEL[p.estado]}
                    </span>
                  </div>
                  <div className="space-y-1">
                    {p.items.map((it, i) => (
                      <div key={i} className="flex justify-between text-[11px]">
                        <span className="text-muted-foreground">{it.emoji} {it.nombre} x{it.cantidad}</span>
                        <span className="font-semibold text-foreground">{fmtPrecio(it.precio * it.cantidad)}</span>
                      </div>
                    ))}
                  </div>
                  <div className="flex justify-between items-center pt-1.5 border-t border-border/40">
                    <span className="font-extrabold text-primary text-base">{fmtPrecio(p.total)}</span>
                    {p.estado === "entregado" ? (
                      <Button size="sm" onClick={() => { cerrarPedido(p.id); onClose() }}
                        className={`h-8 text-xs font-bold uppercase ${btn.cls}`}>
                        <BtnIcon className="w-3 h-3 mr-1" /> Cobrar
                      </Button>
                    ) : (
                      <Button size="sm" onClick={() => avanzarEstado(p.id)}
                        className={`h-8 text-xs font-bold uppercase ${btn.cls}`}>
                        <BtnIcon className="w-3 h-3 mr-1" /> {btn.label}
                      </Button>
                    )}
                  </div>
                </div>
              )
            })}

            <Link href={`/catalogo?mesa=${mesaModal}`} onClick={onClose}>
              <Button variant="outline"
                className="w-full h-9 text-xs border-primary/40 text-primary hover:bg-primary hover:text-primary-foreground mt-1">
                <Plus className="w-3 h-3 mr-1" /> Agregar pedido
              </Button>
            </Link>
          </>
        )}
      </div>
    )
  }

  const libres   = MESAS_CONFIG.filter(m => getPedidosMesa(m.id).length === 0).length
  const ocupadas = MESAS_CONFIG.filter(m => getPedidosMesa(m.id).length > 0).length

  return (
    <div className="space-y-5">
      {/* Resumen */}
      <div className="grid grid-cols-3 gap-2 lg:gap-3">
        {[
          { label: "Total",    value: MESAS_CONFIG.length, color: "text-foreground" },
          { label: "Ocupados", value: ocupadas,            color: "text-primary" },
          { label: "Libres",   value: libres,              color: "text-[#6B8E23]" },
        ].map(s => (
          <Card key={s.label} className="p-3 text-center border-border/60">
            <p className={`text-xl lg:text-2xl font-extrabold ${s.color}`}>{s.value}</p>
            <p className="text-[9px] lg:text-[10px] font-serif italic text-muted-foreground">{s.label}</p>
          </Card>
        ))}
      </div>

      {/* Mesas — 3 cols mobile, 6 cols desktop */}
      <Card className="p-4 lg:p-5 border-border/60">
        <div className="flex items-center gap-2 mb-3 lg:mb-4">
          <Users className="w-4 h-4 text-primary" />
          <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-sm lg:text-base">Mesas</h2>
          <span className="font-serif italic text-xs text-muted-foreground ml-1">6 mesas</span>
        </div>
        <div className="grid grid-cols-3 lg:grid-cols-6 gap-2 lg:gap-3">
          {mesas.map(m => <AsientoCard key={m.id} id={m.id} label={m.label} tipo={m.tipo} />)}
        </div>
      </Card>

      {/* Barra */}
      <Card className="p-4 lg:p-5 border-border/60">
        <div className="flex items-center gap-2 mb-3">
          <Coffee className="w-4 h-4 text-primary" />
          <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-sm lg:text-base">Barra</h2>
          <span className="font-serif italic text-xs text-muted-foreground ml-1">6 banquetas</span>
        </div>
        <div className="h-2 rounded-full mb-3"
          style={{ background: "linear-gradient(90deg,#6F4E37,#9a7450,#6F4E37)", opacity: 0.7 }} />
        <div className="grid grid-cols-3 lg:grid-cols-6 gap-2 lg:gap-3">
          {barra.map(m => <AsientoCard key={m.id} id={m.id} label={m.label} tipo={m.tipo} />)}
        </div>
      </Card>

      {/* ── MOBILE: Drawer (bottom sheet) ── */}
      <Drawer open={!!mesaModal && true} onOpenChange={v => !v && setMesaModal(null)}>
        <DrawerContent className="bg-card border-border lg:hidden max-h-[85vh]">
          <DrawerHeader className="pb-2">
            <DrawerTitle className="font-extrabold italic uppercase tracking-wide text-foreground text-left">
              {mesaLabel}
            </DrawerTitle>
          </DrawerHeader>
          <div className="px-4 pb-6 overflow-y-auto">
            <ModalContent onClose={() => setMesaModal(null)} />
          </div>
        </DrawerContent>
      </Drawer>

      {/* ── DESKTOP: Dialog ── */}
      <Dialog open={!!mesaModal} onOpenChange={v => !v && setMesaModal(null)}>
        <DialogContent className="bg-card border-border max-w-md hidden lg:block">
          <DialogHeader>
            <DialogTitle className="font-extrabold italic uppercase tracking-wide text-foreground">
              {mesaLabel}
            </DialogTitle>
          </DialogHeader>
          <ModalContent onClose={() => setMesaModal(null)} />
        </DialogContent>
      </Dialog>
    </div>
  )
}
ENDOFFILE
echo "✅ mesas-content.tsx (drawer mobile + dialog desktop)"

cat > app/mesas/page.tsx << 'ENDOFFILE'
import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { MesasContent } from "@/components/cafeteria/mesas-content"

export default function MesasPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <Sidebar />
      <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
        <MobileTopBar title="Mesas" />
        <div className="p-4 lg:p-6">
          <Header title="Mesas & Barra" description="Estado en tiempo real del salón" />
          <div className="mt-4 lg:mt-5"><MesasContent /></div>
        </div>
      </main>
      <BottomNav />
    </div>
  )
}
ENDOFFILE
echo "✅ app/mesas/page.tsx"

# ════════════════════════════════════════════════════════════
# CATÁLOGO — grid items + carrito como sheet en mobile
# ════════════════════════════════════════════════════════════
mkdir -p app/catalogo

cat > components/cafeteria/catalogo-crear-pedido.tsx << 'ENDOFFILE'
"use client"

import { useState, useEffect, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { useStore, CATEGORIAS, ITEMS_CATALOGO, MESAS_CONFIG } from "@/context/cafeteria-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet"
import { Minus, Plus, ShoppingCart, Tag, Trash2 } from "lucide-react"
import type { ItemPedido } from "@/types/cafeteria"

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

function CatalogoInner() {
  const router = useRouter()
  const params = useSearchParams()
  const { crearPedido } = useStore()

  const [mesaId,    setMesaId]    = useState(params.get("mesa") ?? "")
  const [catActiva, setCatActiva] = useState("all")
  const [carrito,   setCarrito]   = useState<ItemPedido[]>([])
  const [sheetOpen, setSheetOpen] = useState(false)

  useEffect(() => { const m = params.get("mesa"); if (m) setMesaId(m) }, [params])

  const itemsFiltrados = catActiva === "all"
    ? ITEMS_CATALOGO
    : ITEMS_CATALOGO.filter(i => i.categoriaId === catActiva)

  const total      = carrito.reduce((a, i) => a + i.precio * i.cantidad, 0)
  const totalItems = carrito.reduce((a, i) => a + i.cantidad, 0)
  const getCant    = (id: string) => carrito.find(i => i.id === id)?.cantidad ?? 0

  const modificar = (item: typeof ITEMS_CATALOGO[0], delta: number) => {
    setCarrito(prev => {
      const existe = prev.find(i => i.id === item.id)
      if (!existe) {
        if (delta < 1) return prev
        return [...prev, { id: item.id, nombre: item.nombre, emoji: item.emoji, precio: item.precio, cantidad: 1 }]
      }
      const nueva = existe.cantidad + delta
      if (nueva <= 0) return prev.filter(i => i.id !== item.id)
      return prev.map(i => i.id === item.id ? { ...i, cantidad: nueva } : i)
    })
  }

  const confirmar = () => {
    if (!mesaId || carrito.length === 0) return
    const mesa = MESAS_CONFIG.find(m => m.id === mesaId)!
    crearPedido(mesaId, mesa.label, carrito)
    router.push("/")
  }

  // Carrito compartido (usado en sidebar desktop y sheet mobile)
  const CarritoContent = () => (
    <div className="flex flex-col h-full">
      {carrito.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center gap-2 py-10 text-center">
          <ShoppingCart className="w-10 h-10 text-muted-foreground/30" />
          <p className="text-xs text-muted-foreground font-serif italic">Agregá ítems del catálogo</p>
        </div>
      ) : (
        <div className="flex-1 overflow-y-auto space-y-2 mb-4 pr-1">
          {carrito.map(it => (
            <div key={it.id} className="flex items-center gap-2.5 p-2.5 bg-secondary/50 rounded-xl">
              <span className="text-lg flex-shrink-0">{it.emoji}</span>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-foreground truncate">{it.nombre}</p>
                <p className="text-[10px] text-muted-foreground">x{it.cantidad} · {fmtPrecio(it.precio * it.cantidad)}</p>
              </div>
              <button onClick={() => setCarrito(prev => prev.filter(i => i.id !== it.id))}
                className="w-6 h-6 flex items-center justify-center rounded-lg hover:bg-destructive/20 transition-colors flex-shrink-0">
                <Trash2 className="w-3 h-3 text-muted-foreground" />
              </button>
            </div>
          ))}
        </div>
      )}

      {carrito.length > 0 && (
        <div className="flex justify-between items-center py-3 border-t border-border/50 mb-3">
          <span className="font-extrabold italic uppercase text-xs text-foreground">Total</span>
          <span className="font-extrabold text-primary text-xl">{fmtPrecio(total)}</span>
        </div>
      )}

      <Button onClick={() => { confirmar(); setSheetOpen(false) }}
        disabled={carrito.length === 0 || !mesaId}
        className="w-full h-11 font-bold uppercase tracking-wide text-xs bg-primary text-primary-foreground hover:bg-primary/90 hover:shadow-lg hover:shadow-primary/30 disabled:opacity-40 transition-all rounded-xl">
        <ShoppingCart className="w-3.5 h-3.5 mr-1.5" /> Confirmar pedido
      </Button>
      {!mesaId && carrito.length > 0 && (
        <p className="text-[10px] text-center text-muted-foreground mt-2 font-serif italic">
          Seleccioná una mesa primero
        </p>
      )}
    </div>
  )

  return (
    <div className="flex flex-col lg:grid lg:grid-cols-3 gap-4 lg:gap-5 relative">

      {/* ── Catálogo ── */}
      <div className="lg:col-span-2 space-y-4">
        {/* Selector mesa */}
        <Card className="p-3.5 lg:p-4 border-border/60">
          <div className="flex items-center gap-3">
            <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider flex-shrink-0 hidden sm:block">
              Mesa / Barra
            </p>
            <Select value={mesaId} onValueChange={setMesaId}>
              <SelectTrigger className="bg-secondary border-border text-foreground h-9 text-sm flex-1">
                <SelectValue placeholder="¿Para qué mesa?" />
              </SelectTrigger>
              <SelectContent className="bg-card border-border">
                <p className="text-[10px] font-bold text-muted-foreground uppercase px-2 pt-1.5 pb-0.5">Mesas</p>
                {MESAS_CONFIG.filter(m => m.tipo === "mesa").map(m => (
                  <SelectItem key={m.id} value={m.id} className="text-foreground hover:bg-secondary">{m.label}</SelectItem>
                ))}
                <p className="text-[10px] font-bold text-muted-foreground uppercase px-2 pt-2 pb-0.5">Barra</p>
                {MESAS_CONFIG.filter(m => m.tipo === "barra").map(m => (
                  <SelectItem key={m.id} value={m.id} className="text-foreground hover:bg-secondary">{m.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </Card>

        {/* Filtro categorías — scroll horizontal en mobile */}
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide -mx-4 px-4 lg:mx-0 lg:px-0 lg:flex-wrap">
          <button onClick={() => setCatActiva("all")}
            className={`flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
              catActiva === "all" ? "bg-primary text-primary-foreground shadow-md" : "bg-secondary text-muted-foreground"
            }`}>
            <Tag className="w-3 h-3" /> Todo
          </button>
          {CATEGORIAS.map(c => (
            <button key={c.id} onClick={() => setCatActiva(c.id)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                catActiva === c.id ? "bg-primary text-primary-foreground shadow-md" : "bg-secondary text-muted-foreground"
              }`}>
              {c.emoji} {c.nombre}
            </button>
          ))}
        </div>

        {/* Grid ítems — 2 cols mobile, 3 cols desktop */}
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-2.5 lg:gap-3">
          {itemsFiltrados.map(item => {
            const cant = getCant(item.id)
            return (
              <Card key={item.id}
                className={`p-3 lg:p-3.5 border-2 transition-all duration-150 ${
                  cant > 0 ? "border-primary/60 bg-primary/5 shadow-md shadow-primary/10" : "border-border/50 active:scale-95"
                }`}>
                <div className="flex items-start gap-2 mb-3">
                  <span className="text-xl lg:text-2xl">{item.emoji}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs lg:text-sm font-semibold text-foreground leading-tight">{item.nombre}</p>
                    <p className="text-sm lg:text-sm font-extrabold text-primary mt-0.5">{fmtPrecio(item.precio)}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <button onClick={() => modificar(item, -1)}
                    className="w-7 h-7 rounded-lg bg-secondary flex items-center justify-center active:bg-primary/20 transition-colors">
                    <Minus className="w-3.5 h-3.5 text-foreground" />
                  </button>
                  <span className={`text-base font-extrabold w-6 text-center ${cant > 0 ? "text-primary" : "text-muted-foreground"}`}>
                    {cant}
                  </span>
                  <button onClick={() => modificar(item, 1)}
                    className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center active:bg-primary/80 transition-colors">
                    <Plus className="w-3.5 h-3.5 text-primary-foreground" />
                  </button>
                </div>
              </Card>
            )
          })}
        </div>

        {/* Espacio para el FAB en mobile */}
        <div className="h-20 lg:hidden" />
      </div>

      {/* ── DESKTOP: Carrito sidebar sticky ── */}
      <div className="hidden lg:block lg:sticky lg:top-6 self-start">
        <Card className="p-4 border-border/60 flex flex-col" style={{ maxHeight: "calc(100vh - 120px)" }}>
          <div className="flex items-center gap-2 mb-4 flex-shrink-0">
            <ShoppingCart className="w-4 h-4 text-primary" />
            <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-sm">Pedido</h2>
            {totalItems > 0 && (
              <span className="ml-auto bg-primary text-primary-foreground text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center">
                {totalItems}
              </span>
            )}
          </div>
          <CarritoContent />
        </Card>
      </div>

      {/* ── MOBILE: FAB flotante + Sheet ── */}
      {carrito.length > 0 && (
        <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
          <SheetTrigger asChild>
            <button
              className="lg:hidden fixed bottom-20 right-4 z-50 flex items-center gap-2.5 bg-primary text-primary-foreground px-4 py-3 rounded-2xl shadow-2xl shadow-primary/40 active:scale-95 transition-transform"
            >
              <ShoppingCart className="w-4 h-4" />
              <span className="font-bold text-sm">{fmtPrecio(total)}</span>
              <span className="bg-primary-foreground/20 text-primary-foreground text-[10px] font-extrabold w-5 h-5 rounded-full flex items-center justify-center">
                {totalItems}
              </span>
            </button>
          </SheetTrigger>
          <SheetContent side="bottom" className="bg-card border-border rounded-t-2xl h-[75vh] flex flex-col">
            <SheetHeader className="flex-shrink-0 pb-3 border-b border-border/50">
              <SheetTitle className="font-extrabold italic uppercase tracking-wide text-foreground text-left flex items-center gap-2">
                <ShoppingCart className="w-4 h-4 text-primary" />
                Tu pedido
                <span className="text-primary font-extrabold">{fmtPrecio(total)}</span>
              </SheetTitle>
            </SheetHeader>
            <div className="flex-1 overflow-hidden flex flex-col pt-3">
              <CarritoContent />
            </div>
          </SheetContent>
        </Sheet>
      )}
    </div>
  )
}

export function CatalogoCrearPedido() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center h-40">
        <p className="text-muted-foreground text-sm font-serif italic">Cargando catálogo...</p>
      </div>
    }>
      <CatalogoInner />
    </Suspense>
  )
}
ENDOFFILE
echo "✅ catalogo-crear-pedido.tsx (FAB + sheet mobile)"

cat > app/catalogo/page.tsx << 'ENDOFFILE'
import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { CatalogoCrearPedido } from "@/components/cafeteria/catalogo-crear-pedido"

export default function CatalogoPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <Sidebar />
      <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
        <MobileTopBar title="Catálogo" />
        <div className="p-4 lg:p-6">
          <Header title="Catálogo" description="Seleccioná ítems para armar el pedido" />
          <div className="mt-4 lg:mt-5"><CatalogoCrearPedido /></div>
        </div>
      </main>
      <BottomNav />
    </div>
  )
}
ENDOFFILE
echo "✅ app/catalogo/page.tsx"

# ── CSS: ocultar scrollbar en filtro de categorías mobile ───
cat >> app/globals.css << 'ENDOFFILE'

/* Ocultar scrollbar en filtro de categorías móvil */
.scrollbar-hide::-webkit-scrollbar { display: none; }
.scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
ENDOFFILE
echo "✅ scrollbar-hide utility"

echo ""
echo "============================================"
echo "✅ Versión responsive lista:"
echo ""
echo "   MOBILE:"
echo "   • Top bar con logo + título de página"
echo "   • Bottom nav (Pedidos / Mesas / Catálogo)"
echo "   • Pedidos: cards apiladas con estado + acción"
echo "   • Mesas: grid 3 cols + bottom sheet al tocar"
echo "   • Catálogo: grid 2 cols + FAB flotante → sheet"
echo ""
echo "   DESKTOP:"
echo "   • Sidebar fijo 256px"
echo "   • Pedidos: tabla con columnas"
echo "   • Mesas: grid 6 cols + dialog modal"
echo "   • Catálogo: grid 3 cols + carrito sticky sidebar"
echo "============================================"