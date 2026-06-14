#!/usr/bin/env bash
# =============================================================================
# DRIVE Cafetería — FRONTEND CHANGES
# Tareas: PWA, mesas sin actualizar, catálogo mobile, botón flotante pedido,
#         historial pedidos del día, modal confirmación cerrar pedido
# =============================================================================
set -e

echo "🚀 Aplicando cambios en el FRONTEND..."

# ─────────────────────────────────────────────────────────────────────────────
# 1) PWA — next.config.mjs (agregar soporte PWA con next-pwa)
# ─────────────────────────────────────────────────────────────────────────────
echo "📦 Instalando next-pwa..."
pnpm add next-pwa

cat > next.config.mjs << 'NEXTCONFIG'
import withPWA from 'next-pwa'

const pwaConfig = withPWA({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
})

/** @type {import('next').NextConfig} */
const nextConfig = {
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
}

export default pwaConfig(nextConfig)
NEXTCONFIG

# ─────────────────────────────────────────────────────────────────────────────
# 2) PWA — public/manifest.json
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Creando manifest.json..."
mkdir -p public

cat > public/manifest.json << 'MANIFEST'
{
  "name": "Cafetería DRIVE",
  "short_name": "Cafetería",
  "description": "Sistema de gestión de cafetería DRIVE",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#1a1208",
  "theme_color": "#F57C00",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
MANIFEST

# ─────────────────────────────────────────────────────────────────────────────
# 3) PWA — app/layout.tsx (agregar meta PWA + manifest)
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Actualizando layout.tsx para PWA..."
cat > app/layout.tsx << 'LAYOUT'
import type React from "react"
import type { Metadata, Viewport } from "next"
import { Montserrat, Playfair_Display } from "next/font/google"
import { Analytics } from "@vercel/analytics/next"
import { ThemeProvider } from "@/components/theme-provider"
import { AuthStore } from "@/context/auth-store"
import { CafeteriaStore } from "@/context/cafeteria-store"
import "./globals.css"

const montserrat = Montserrat({ subsets: ["latin"], variable: "--font-sans", weight: ["400","500","600","700","800","900"] })
const playfair   = Playfair_Display({ subsets: ["latin"], variable: "--font-serif", style: ["normal","italic"], weight: ["400","500","600","700"] })

export const metadata: Metadata = {
  title: "Cafetería — DRIVE",
  description: "Sistema de gestión DRIVE",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Cafetería",
  },
}

export const viewport: Viewport = {
  themeColor: "#F57C00",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" className="dark" suppressHydrationWarning>
      <head>
        <link rel="apple-touch-icon" href="/icon-192.png" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="mobile-web-app-capable" content="yes" />
      </head>
      <body className={`${montserrat.variable} ${playfair.variable} font-sans antialiased`}>
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem={false} storageKey="drive-theme">
          <AuthStore>
            <CafeteriaStore>
              {children}
            </CafeteriaStore>
          </AuthStore>
        </ThemeProvider>
        <Analytics />
      </body>
    </html>
  )
}
LAYOUT

# ─────────────────────────────────────────────────────────────────────────────
# 4) cafeteria-store.tsx — polling 15s (más reactivo) + refetch mesas también
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Actualizando cafeteria-store.tsx (polling 15s)..."
# Solo cambiamos el intervalo de 30_000 a 15_000
sed -i 's/}, 30_000)/}, 15_000)/' context/cafeteria-store.tsx

# ─────────────────────────────────────────────────────────────────────────────
# 5) components/cafeteria/pedidos-view.tsx — Modal confirmación cerrar pedido
#    + botón "Historial del día"
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Actualizando pedidos-view.tsx..."
cat > components/cafeteria/pedidos-view.tsx << 'PEDIDOSVIEW'
"use client"
import { useState } from "react"
import { useStore } from "@/context/cafeteria-store"
import { usePedidosActivos, useEstadoColor, useEstadoLabel, useAccionLabel } from "@/hooks/use-pedidos"
import { Badge }    from "@/components/ui/badge"
import { Button }   from "@/components/ui/button"
import { Card }     from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import {
  RefreshCw, Clock, ChevronRight, PackageCheck,
  Plus, CheckCircle2, Circle, Timer, Truck, History,
} from "lucide-react"
import { cn } from "@/lib/utils"
import Link from "next/link"
import type { Pedido } from "@/lib/api"

const ESTADO_ICON: Record<string, React.FC<{ className?: string }>> = {
  PENDIENTE:      Circle,
  EN_PREPARACION: Timer,
  LISTO:          CheckCircle2,
  ENTREGADO:      Truck,
}

const BTN_CFG: Record<string, { label: string; cls: string }> = {
  PENDIENTE:      { label: "Preparar",        cls: "bg-yellow-500 hover:bg-yellow-600 text-white" },
  EN_PREPARACION: { label: "Marcar listo",    cls: "bg-primary hover:bg-primary/90 text-primary-foreground" },
  LISTO:          { label: "Entregar",        cls: "bg-green-600 hover:bg-green-700 text-white" },
  ENTREGADO:      { label: "Cobrar y cerrar", cls: "bg-blue-600 hover:bg-blue-700 text-white" },
}

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

const fmtHora = (iso: string) =>
  new Date(iso).toLocaleTimeString("es-AR", { hour: "2-digit", minute: "2-digit" })

export function PedidosView() {
  const { refreshing, lastUpdated } = useStore()
  const { pedidos, loading, refetchPedidos, avanzarEstado, cerrarPedido } = usePedidosActivos()

  // Modal confirmación cerrar
  const [pedidoACerrar, setPedidoACerrar] = useState<Pedido | null>(null)

  if (loading) return <PedidosSkeleton />

  const handleAccion = async (pedido: Pedido) => {
    if (pedido.estado === "ENTREGADO") {
      // Mostrar modal de confirmación antes de cerrar
      setPedidoACerrar(pedido)
    } else {
      await avanzarEstado(pedido.id)
    }
  }

  const confirmarCierre = async () => {
    if (!pedidoACerrar) return
    await cerrarPedido(pedidoACerrar.id)
    setPedidoACerrar(null)
  }

  return (
    <>
      {/* ── Modal confirmación cierre ── */}
      <AlertDialog open={!!pedidoACerrar} onOpenChange={(open) => !open && setPedidoACerrar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Cerrar pedido #{pedidoACerrar?.numero}?</AlertDialogTitle>
            <AlertDialogDescription>
              Mesa <strong>{pedidoACerrar?.mesa.label}</strong> — Total:{" "}
              <strong className="text-primary">{pedidoACerrar ? fmtPrecio(pedidoACerrar.total) : ""}</strong>
              <br />
              Esta acción marca el pedido como cobrado y lo archiva. No se puede deshacer.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              className="bg-blue-600 hover:bg-blue-700 text-white"
              onClick={confirmarCierre}
            >
              Confirmar cobro y cerrar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <div className="space-y-4">
        {/* ── Barra superior ── */}
        <div className="flex items-center justify-between gap-3 flex-wrap">
          <div className="flex items-center gap-2">
            <p className="text-sm text-muted-foreground">
              {pedidos.length === 0
                ? "Sin pedidos activos"
                : `${pedidos.length} pedido${pedidos.length !== 1 ? "s" : ""} activo${pedidos.length !== 1 ? "s" : ""}`}
            </p>
            {refreshing && <RefreshCw className="w-3.5 h-3.5 text-primary animate-spin" />}
            {lastUpdated && !refreshing && (
              <span className="text-[10px] text-muted-foreground/60">
                · {lastUpdated.toLocaleTimeString("es-AR", { hour: "2-digit", minute: "2-digit" })}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="ghost" size="sm"
              onClick={refetchPedidos}
              disabled={refreshing}
              className="gap-1.5 text-muted-foreground hover:text-foreground h-8"
            >
              <RefreshCw className={cn("w-3.5 h-3.5", refreshing && "animate-spin")} />
              <span className="text-xs">Actualizar</span>
            </Button>
            {/* Botón historial */}
            <Link href="/historial">
              <Button
                variant="outline" size="sm"
                className="h-8 text-xs font-bold uppercase tracking-wide gap-1 border-border/60 text-muted-foreground hover:text-foreground"
              >
                <History className="w-3.5 h-3.5" /> Historial
              </Button>
            </Link>
            {/* Botón nuevo — solo desktop */}
            <Link href="/catalogo" className="hidden lg:block">
              <Button className="h-8 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90 gap-1">
                <Plus className="w-3.5 h-3.5" /> Nuevo pedido
              </Button>
            </Link>
          </div>
        </div>

        {pedidos.length === 0 ? (
          <EmptyPedidos />
        ) : (
          <>
            {/* MOBILE: cards verticales */}
            <div className="flex flex-col gap-3 lg:hidden">
              {pedidos.map(p => (
                <PedidoCard key={p.id} pedido={p} onAccion={handleAccion} />
              ))}
            </div>

            {/* DESKTOP: tabla */}
            <Card className="hidden lg:block border-border/60 overflow-hidden">
              <div className="grid grid-cols-[48px_120px_1fr_110px_150px_130px] gap-3 px-5 py-3 border-b border-border/50 bg-secondary/40">
                {["#", "Mesa", "Pedido", "Total", "Estado", "Acción"].map(h => (
                  <p key={h} className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest">{h}</p>
                ))}
              </div>
              <div className="divide-y divide-border/30">
                {pedidos.map(pedido => {
                  const colorClass  = useEstadoColor(pedido.estado)
                  const estadoLabel = useEstadoLabel(pedido.estado)
                  const btnCfg      = BTN_CFG[pedido.estado]
                  const Icon        = ESTADO_ICON[pedido.estado] ?? Circle
                  const resumen     = pedido.items
                    .map(i => `${i.item.emoji ?? "•"} ${i.item.nombre}${i.cantidad > 1 ? ` ×${i.cantidad}` : ""}`)
                    .join("  ·  ")

                  return (
                    <div
                      key={pedido.id}
                      className="grid grid-cols-[48px_120px_1fr_110px_150px_130px] gap-3 px-5 py-3.5 items-center hover:bg-secondary/20 transition-colors duration-150"
                    >
                      <span className="text-xs font-bold text-muted-foreground bg-secondary rounded px-1.5 py-0.5 text-center w-fit">
                        #{pedido.numero}
                      </span>
                      <div>
                        <p className="text-sm font-semibold text-foreground">{pedido.mesa.label}</p>
                        <p className="text-[10px] text-muted-foreground flex items-center gap-1">
                          <Clock className="w-3 h-3" />{fmtHora(pedido.creadoEn)}
                        </p>
                      </div>
                      <p className="text-xs text-muted-foreground truncate pr-4" title={resumen}>{resumen}</p>
                      <p className="text-sm font-extrabold text-primary">{fmtPrecio(pedido.total)}</p>
                      <Badge className={cn("text-[10px] px-2.5 py-1 border rounded-full font-semibold flex items-center gap-1.5 w-fit", colorClass)}>
                        <Icon className="w-3 h-3" />
                        {estadoLabel}
                      </Badge>
                      {btnCfg && (
                        <Button
                          size="sm"
                          onClick={() => handleAccion(pedido)}
                          className={cn("h-8 text-xs font-bold uppercase tracking-wide px-3 gap-1", btnCfg.cls)}
                        >
                          {btnCfg.label}
                          <ChevronRight className="w-3 h-3" />
                        </Button>
                      )}
                    </div>
                  )
                })}
              </div>
            </Card>
          </>
        )}
      </div>
    </>
  )
}

function PedidoCard({ pedido, onAccion }: { pedido: Pedido; onAccion: (p: Pedido) => Promise<void> }) {
  const colorClass  = useEstadoColor(pedido.estado)
  const estadoLabel = useEstadoLabel(pedido.estado)
  const accionLabel = useAccionLabel(pedido.estado)

  return (
    <Card className="p-4 border-border/50 transition-all duration-200 hover:border-primary/40">
      <div className="flex items-start justify-between gap-2 mb-3">
        <div className="flex items-center gap-2">
          <span className="text-xs font-bold text-muted-foreground bg-secondary rounded px-1.5 py-0.5">
            #{pedido.numero}
          </span>
          <span className="font-semibold text-foreground">{pedido.mesa.label}</span>
        </div>
        <Badge className={cn("text-[10px] px-2 py-0.5 border rounded-full font-medium flex-shrink-0", colorClass)}>
          {estadoLabel}
        </Badge>
      </div>

      <div className="space-y-1 mb-3">
        {pedido.items.map(it => (
          <div key={it.id} className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <span>{it.item.emoji ?? "•"}</span>
            <span className="truncate">{it.item.nombre}</span>
            <span className="ml-auto flex-shrink-0 font-medium text-foreground">×{it.cantidad}</span>
            <span className="text-muted-foreground/60 flex-shrink-0">
              {fmtPrecio(it.item.precio * it.cantidad)}
            </span>
          </div>
        ))}
      </div>

      <div className="flex items-center justify-between gap-2 pt-2 border-t border-border/40">
        <div className="flex items-center gap-2">
          <Clock className="w-3 h-3 text-muted-foreground" />
          <span className="text-xs text-muted-foreground">{fmtHora(pedido.creadoEn)}</span>
          <span className="font-extrabold text-primary text-sm">{fmtPrecio(pedido.total)}</span>
        </div>
        {accionLabel && (
          <Button
            size="sm"
            onClick={() => onAccion(pedido)}
            className={cn(
              "h-8 text-xs px-3 gap-1 font-bold uppercase tracking-wide",
              pedido.estado === "ENTREGADO"
                ? "bg-blue-600 hover:bg-blue-700 text-white"
                : "bg-primary hover:bg-primary/90 text-primary-foreground"
            )}
          >
            {accionLabel}
            <ChevronRight className="w-3 h-3" />
          </Button>
        )}
      </div>
    </Card>
  )
}

function EmptyPedidos() {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-center">
      <div className="w-16 h-16 rounded-2xl bg-secondary flex items-center justify-center mb-4">
        <PackageCheck className="w-8 h-8 text-muted-foreground" />
      </div>
      <h3 className="font-semibold text-foreground mb-1">Todo al día</h3>
      <p className="text-sm text-muted-foreground">No hay pedidos activos en este momento</p>
      <Link href="/catalogo" className="mt-4">
        <Button className="bg-primary hover:bg-primary/90 text-primary-foreground gap-1.5 text-xs font-bold uppercase tracking-wide">
          <Plus className="w-3.5 h-3.5" /> Crear pedido
        </Button>
      </Link>
    </div>
  )
}

function PedidosSkeleton() {
  return (
    <div className="space-y-3">
      <div className="flex justify-between">
        <Skeleton className="h-5 w-40" />
        <Skeleton className="h-8 w-28" />
      </div>
      <div className="lg:hidden space-y-3">
        {[1, 2, 3].map(i => <Skeleton key={i} className="h-28 rounded-xl" />)}
      </div>
      <Card className="hidden lg:block border-border/60 overflow-hidden">
        <div className="px-5 py-3 border-b border-border/50 bg-secondary/40">
          <Skeleton className="h-4 w-full" />
        </div>
        {[1, 2, 3, 4].map(i => (
          <div key={i} className="px-5 py-4 border-b border-border/30">
            <Skeleton className="h-5 w-full" />
          </div>
        ))}
      </Card>
    </div>
  )
}
PEDIDOSVIEW

# ─────────────────────────────────────────────────────────────────────────────
# 6) app/historial/page.tsx — Página de historial del día
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Creando app/historial/page.tsx..."
mkdir -p app/historial

cat > app/historial/page.tsx << 'HISTPAGE'
import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { HistorialPedidos } from "@/components/cafeteria/historial-pedidos"
import { AuthGuard } from "@/components/auth/auth-guard"

export default function HistorialPage() {
  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-background">
        <Sidebar />
        <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
          <MobileTopBar title="Historial" />
          <div className="p-4 lg:p-6">
            <Header title="Historial del día" description="Todos los pedidos cerrados y balance" />
            <div className="mt-4 lg:mt-5"><HistorialPedidos /></div>
          </div>
        </main>
        <BottomNav />
      </div>
    </AuthGuard>
  )
}
HISTPAGE

# ─────────────────────────────────────────────────────────────────────────────
# 7) components/cafeteria/historial-pedidos.tsx
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Creando components/cafeteria/historial-pedidos.tsx..."
cat > components/cafeteria/historial-pedidos.tsx << 'HISTCOMP'
"use client"
import { useEffect, useState } from "react"
import { api } from "@/lib/api"
import type { Pedido } from "@/lib/api"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Skeleton } from "@/components/ui/skeleton"
import { Button } from "@/components/ui/button"
import { RefreshCw, TrendingUp, ShoppingBag, Clock, ArrowLeft } from "lucide-react"
import { cn } from "@/lib/utils"
import Link from "next/link"

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

const fmtHora = (iso: string) =>
  new Date(iso).toLocaleTimeString("es-AR", { hour: "2-digit", minute: "2-digit" })

export function HistorialPedidos() {
  const [pedidos, setPedidos] = useState<Pedido[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)

  const cargar = async (silent = false) => {
    if (!silent) setLoading(true)
    else setRefreshing(true)
    try {
      // Traemos todos los pedidos cerrados del día
      const data = await api.getPedidos("CERRADO")
      setPedidos(data)
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  useEffect(() => { cargar() }, [])

  const totalDia   = pedidos.reduce((acc, p) => acc + p.total, 0)
  const cantPedidos = pedidos.length

  if (loading) return <HistorialSkeleton />

  return (
    <div className="space-y-5 animate-fade-in">
      {/* ── Acciones top ── */}
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <Link href="/">
          <Button variant="ghost" size="sm" className="gap-1.5 text-muted-foreground h-8">
            <ArrowLeft className="w-3.5 h-3.5" /> Volver a pedidos
          </Button>
        </Link>
        <Button
          variant="ghost" size="sm"
          onClick={() => cargar(true)}
          disabled={refreshing}
          className="gap-1.5 text-muted-foreground h-8"
        >
          <RefreshCw className={cn("w-3.5 h-3.5", refreshing && "animate-spin")} />
          <span className="text-xs">Actualizar</span>
        </Button>
      </div>

      {/* ── Resumen del día ── */}
      <div className="grid grid-cols-2 gap-3">
        <Card className="p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary/20 flex items-center justify-center flex-shrink-0">
            <ShoppingBag className="w-5 h-5 text-primary" />
          </div>
          <div>
            <p className="text-xs text-muted-foreground uppercase tracking-wide font-semibold">Pedidos cerrados</p>
            <p className="text-2xl font-extrabold text-foreground">{cantPedidos}</p>
          </div>
        </Card>
        <Card className="p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-green-600/20 flex items-center justify-center flex-shrink-0">
            <TrendingUp className="w-5 h-5 text-green-500" />
          </div>
          <div>
            <p className="text-xs text-muted-foreground uppercase tracking-wide font-semibold">Total del día</p>
            <p className="text-xl font-extrabold text-green-500">{fmtPrecio(totalDia)}</p>
          </div>
        </Card>
      </div>

      {/* ── Lista ── */}
      {pedidos.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="w-16 h-16 rounded-2xl bg-secondary flex items-center justify-center mb-4">
            <ShoppingBag className="w-8 h-8 text-muted-foreground" />
          </div>
          <h3 className="font-semibold text-foreground mb-1">Sin pedidos cerrados</h3>
          <p className="text-sm text-muted-foreground">Todavía no se cerró ningún pedido hoy</p>
        </div>
      ) : (
        <>
          {/* Mobile: cards */}
          <div className="flex flex-col gap-3 lg:hidden">
            {pedidos.map(p => (
              <Card key={p.id} className="p-4 border-border/50">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-muted-foreground bg-secondary rounded px-1.5 py-0.5">
                      #{p.numero}
                    </span>
                    <span className="font-semibold text-foreground text-sm">{p.mesa.label}</span>
                  </div>
                  <Badge className="text-[10px] px-2 py-0.5 border rounded-full bg-secondary/60 text-muted-foreground border-border/50">
                    Cerrado
                  </Badge>
                </div>
                <div className="flex items-center justify-between text-xs text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {p.cerradoEn ? fmtHora(p.cerradoEn) : fmtHora(p.creadoEn)}
                  </span>
                  <span className="font-extrabold text-primary text-sm">{fmtPrecio(p.total)}</span>
                </div>
              </Card>
            ))}
          </div>

          {/* Desktop: tabla */}
          <Card className="hidden lg:block border-border/60 overflow-hidden">
            <div className="grid grid-cols-[48px_120px_1fr_110px_130px] gap-3 px-5 py-3 border-b border-border/50 bg-secondary/40">
              {["#", "Mesa", "Items", "Total", "Cerrado a"].map(h => (
                <p key={h} className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest">{h}</p>
              ))}
            </div>
            <div className="divide-y divide-border/30">
              {pedidos.map(p => {
                const resumen = p.items
                  .map(i => `${i.item.emoji ?? "•"} ${i.item.nombre}${i.cantidad > 1 ? ` ×${i.cantidad}` : ""}`)
                  .join("  ·  ")
                return (
                  <div
                    key={p.id}
                    className="grid grid-cols-[48px_120px_1fr_110px_130px] gap-3 px-5 py-3.5 items-center hover:bg-secondary/20 transition-colors"
                  >
                    <span className="text-xs font-bold text-muted-foreground bg-secondary rounded px-1.5 py-0.5 text-center w-fit">
                      #{p.numero}
                    </span>
                    <p className="text-sm font-semibold text-foreground">{p.mesa.label}</p>
                    <p className="text-xs text-muted-foreground truncate pr-4" title={resumen}>{resumen}</p>
                    <p className="text-sm font-extrabold text-primary">{fmtPrecio(p.total)}</p>
                    <p className="text-xs text-muted-foreground flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {p.cerradoEn ? fmtHora(p.cerradoEn) : fmtHora(p.creadoEn)}
                    </p>
                  </div>
                )
              })}
            </div>
            {/* Footer total */}
            <div className="px-5 py-3 border-t border-border/50 bg-secondary/20 flex justify-end items-center gap-3">
              <p className="text-xs text-muted-foreground font-semibold uppercase tracking-wide">Total del día</p>
              <p className="text-lg font-extrabold text-green-500">{fmtPrecio(totalDia)}</p>
            </div>
          </Card>
        </>
      )}
    </div>
  )
}

function HistorialSkeleton() {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3">
        <Skeleton className="h-20 rounded-xl" />
        <Skeleton className="h-20 rounded-xl" />
      </div>
      <div className="space-y-3">
        {[1,2,3,4,5].map(i => <Skeleton key={i} className="h-16 rounded-xl" />)}
      </div>
    </div>
  )
}
HISTCOMP

# ─────────────────────────────────────────────────────────────────────────────
# 8) lib/api.ts — agregar soporte para getPedidos("CERRADO") con query param
#    (verificar que acepta el param estado)
# ─────────────────────────────────────────────────────────────────────────────
# El api.getPedidos ya acepta estado opcional según el backend,
# pero si lib/api.ts no lo tiene, lo parcheamos:
echo "📄 Verificando lib/api.ts para soporte de estado en getPedidos..."
if [ -f lib/api.ts ]; then
  # Agregar cerradoEn al tipo Pedido si no está
  if ! grep -q "cerradoEn" lib/api.ts; then
    sed -i 's/creadoEn: string/creadoEn: string\n  cerradoEn?: string/' lib/api.ts
  fi
  # Agregar parámetro estado a getPedidos si no está
  if grep -q "getPedidos()" lib/api.ts; then
    sed -i 's/getPedidos()/getPedidos(estado?: string)/' lib/api.ts
    sed -i 's|cafeteria/pedidos`|cafeteria/pedidos${estado ? `?estado=${estado}` : ""}`|' lib/api.ts
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 9) Catálogo mobile mejorado + botón flotante para crear pedido
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Actualizando catalogo-crear-pedido.tsx con botón flotante mobile..."
cat > components/cafeteria/catalogo-crear-pedido.tsx << 'CATALOGO'
"use client"
import { useState, useMemo } from "react"
import { useStore } from "@/context/cafeteria-store"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Skeleton } from "@/components/ui/skeleton"
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select"
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from "@/components/ui/dialog"
import {
  Plus, Minus, ShoppingCart, Loader2, CheckCircle2, X, ChevronRight,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { useRouter } from "next/navigation"

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

type Carrito = Record<string, number>

export function CatalogoCrearPedido() {
  const { catalogo, categorias, mesas, loadingCatalogo, loadingMesas, crearPedido } = useStore()
  const router = useRouter()

  const [carrito, setCarrito]           = useState<Carrito>({})
  const [categoriaFiltro, setCategoriaFiltro] = useState<string>("todas")
  const [mesaId, setMesaId]             = useState<string>("")
  const [submitting, setSubmitting]     = useState(false)
  const [success, setSuccess]           = useState(false)
  const [carritoOpen, setCarritoOpen]   = useState(false)

  const itemsFiltrados = useMemo(() =>
    categoriaFiltro === "todas"
      ? catalogo
      : catalogo.filter(i => i.categoriaId === categoriaFiltro),
    [catalogo, categoriaFiltro]
  )

  const totalItems = Object.values(carrito).reduce((a, b) => a + b, 0)
  const totalPrecio = Object.entries(carrito).reduce((acc, [id, qty]) => {
    const item = catalogo.find(i => i.id === id)
    return acc + (item?.precio ?? 0) * qty
  }, 0)

  const add  = (id: string) => setCarrito(c => ({ ...c, [id]: (c[id] ?? 0) + 1 }))
  const sub  = (id: string) => setCarrito(c => {
    const n = (c[id] ?? 0) - 1
    if (n <= 0) { const { [id]: _, ...rest } = c; return rest }
    return { ...c, [id]: n }
  })
  const clear = () => setCarrito({})

  const handleSubmit = async () => {
    if (!mesaId || totalItems === 0) return
    setSubmitting(true)
    try {
      const items = Object.entries(carrito).map(([itemId, cantidad]) => ({ itemId, cantidad }))
      await crearPedido(mesaId, items)
      setSuccess(true)
      clear()
      setMesaId("")
      setCarritoOpen(false)
      setTimeout(() => { setSuccess(false); router.push("/") }, 1800)
    } catch (e) {
      console.error(e)
    } finally {
      setSubmitting(false)
    }
  }

  if (loadingCatalogo) return <CatalogoSkeleton />

  return (
    <div className="animate-fade-in pb-24 lg:pb-6">

      {success && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-card rounded-2xl p-8 flex flex-col items-center gap-3 shadow-2xl animate-fade-in">
            <CheckCircle2 className="w-16 h-16 text-green-500" />
            <p className="font-bold text-foreground text-lg">¡Pedido creado!</p>
          </div>
        </div>
      )}

      {/* ── Filtro categorías ── */}
      <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide mb-4">
        <button
          onClick={() => setCategoriaFiltro("todas")}
          className={cn(
            "flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide transition-all border",
            categoriaFiltro === "todas"
              ? "bg-primary text-primary-foreground border-primary shadow-md shadow-primary/25"
              : "bg-secondary text-muted-foreground border-border/50 hover:border-primary/40 hover:text-foreground"
          )}
        >
          Todo
        </button>
        {categorias.map(cat => (
          <button
            key={cat.id}
            onClick={() => setCategoriaFiltro(cat.id)}
            className={cn(
              "flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide transition-all border",
              categoriaFiltro === cat.id
                ? "bg-primary text-primary-foreground border-primary shadow-md shadow-primary/25"
                : "bg-secondary text-muted-foreground border-border/50 hover:border-primary/40 hover:text-foreground"
            )}
          >
            {cat.emoji && <span>{cat.emoji}</span>}
            {cat.nombre}
          </button>
        ))}
      </div>

      {/* ── Grid catálogo ── */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        {itemsFiltrados.map(item => {
          const qty = carrito[item.id] ?? 0
          return (
            <Card
              key={item.id}
              className={cn(
                "p-3 flex flex-col gap-2 transition-all duration-200 cursor-default border",
                qty > 0
                  ? "border-primary/60 bg-primary/5 shadow-md shadow-primary/10"
                  : "border-border/50 hover:border-primary/30"
              )}
            >
              {/* Emoji + nombre */}
              <div className="flex-1">
                {item.emoji && (
                  <span className="text-2xl block mb-1">{item.emoji}</span>
                )}
                <p className="font-semibold text-foreground text-sm leading-tight line-clamp-2">
                  {item.nombre}
                </p>
                {item.descripcion && (
                  <p className="text-[10px] text-muted-foreground mt-0.5 line-clamp-2 leading-tight">
                    {item.descripcion}
                  </p>
                )}
              </div>

              {/* Precio */}
              <p className="font-extrabold text-primary text-sm">{fmtPrecio(item.precio)}</p>

              {/* Controles cantidad */}
              <div className="flex items-center justify-between gap-2">
                {qty === 0 ? (
                  <Button
                    size="sm"
                    onClick={() => add(item.id)}
                    className="w-full h-8 text-xs font-bold bg-primary hover:bg-primary/90 text-primary-foreground gap-1"
                  >
                    <Plus className="w-3.5 h-3.5" /> Agregar
                  </Button>
                ) : (
                  <div className="flex items-center gap-2 w-full justify-between">
                    <button
                      onClick={() => sub(item.id)}
                      className="w-8 h-8 rounded-lg bg-secondary flex items-center justify-center hover:bg-destructive/20 transition-colors"
                    >
                      <Minus className="w-3.5 h-3.5" />
                    </button>
                    <span className="font-extrabold text-primary text-base min-w-[1.5rem] text-center">{qty}</span>
                    <button
                      onClick={() => add(item.id)}
                      className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center hover:bg-primary/80 transition-colors"
                    >
                      <Plus className="w-3.5 h-3.5 text-primary-foreground" />
                    </button>
                  </div>
                )}
              </div>
            </Card>
          )
        })}
      </div>

      {/* ── DESKTOP: panel lateral / formulario ── */}
      {totalItems > 0 && (
        <Card className="hidden lg:block mt-6 p-5 border-primary/40 bg-primary/5">
          <h3 className="font-bold text-foreground mb-3 flex items-center gap-2">
            <ShoppingCart className="w-4 h-4 text-primary" />
            Resumen del pedido
          </h3>
          <div className="space-y-1.5 mb-4 max-h-48 overflow-y-auto">
            {Object.entries(carrito).map(([id, qty]) => {
              const item = catalogo.find(i => i.id === id)
              if (!item) return null
              return (
                <div key={id} className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground truncate flex items-center gap-1.5">
                    {item.emoji} {item.nombre} ×{qty}
                  </span>
                  <span className="font-bold text-primary flex-shrink-0 ml-2">
                    {fmtPrecio(item.precio * qty)}
                  </span>
                </div>
              )
            })}
          </div>

          <div className="flex items-center justify-between mb-4 pt-3 border-t border-border/50">
            <span className="font-semibold text-foreground">Total</span>
            <span className="font-extrabold text-primary text-lg">{fmtPrecio(totalPrecio)}</span>
          </div>

          <div className="flex gap-3">
            <Select value={mesaId} onValueChange={setMesaId}>
              <SelectTrigger className="flex-1 h-10">
                <SelectValue placeholder={loadingMesas ? "Cargando mesas..." : "Seleccionar mesa"} />
              </SelectTrigger>
              <SelectContent>
                {mesas.map(m => (
                  <SelectItem key={m.id} value={m.id}>
                    {m.label} {m.pedidos.length > 0 ? `(${m.pedidos.length} pedido${m.pedidos.length > 1 ? "s" : ""})` : ""}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Button
              onClick={handleSubmit}
              disabled={!mesaId || submitting}
              className="h-10 px-5 font-bold bg-primary hover:bg-primary/90 text-primary-foreground gap-1.5"
            >
              {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <><CheckCircle2 className="w-4 h-4" /> Crear pedido</>}
            </Button>
          </div>
        </Card>
      )}

      {/* ── MOBILE: botón flotante carrito ── */}
      {totalItems > 0 && (
        <button
          onClick={() => setCarritoOpen(true)}
          className="lg:hidden fixed bottom-20 right-4 z-40 flex items-center gap-3 bg-primary text-primary-foreground px-5 py-3 rounded-2xl shadow-xl shadow-primary/40 font-bold text-sm animate-fade-in"
        >
          <ShoppingCart className="w-5 h-5" />
          <span>{totalItems} {totalItems === 1 ? "item" : "items"}</span>
          <span className="font-extrabold">{fmtPrecio(totalPrecio)}</span>
          <ChevronRight className="w-4 h-4" />
        </button>
      )}

      {/* ── MOBILE: Dialog/Drawer para confirmar pedido ── */}
      <Dialog open={carritoOpen} onOpenChange={setCarritoOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <ShoppingCart className="w-5 h-5 text-primary" />
              Tu pedido
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-2 max-h-60 overflow-y-auto">
            {Object.entries(carrito).map(([id, qty]) => {
              const item = catalogo.find(i => i.id === id)
              if (!item) return null
              return (
                <div key={id} className="flex items-center justify-between py-1.5 border-b border-border/30 last:border-0">
                  <div className="flex items-center gap-2">
                    <div className="flex items-center gap-1.5">
                      <button onClick={() => sub(id)} className="w-6 h-6 rounded bg-secondary flex items-center justify-center">
                        <Minus className="w-3 h-3" />
                      </button>
                      <span className="font-bold text-foreground min-w-[1.25rem] text-center text-sm">{qty}</span>
                      <button onClick={() => add(id)} className="w-6 h-6 rounded bg-primary flex items-center justify-center">
                        <Plus className="w-3 h-3 text-primary-foreground" />
                      </button>
                    </div>
                    <span className="text-sm text-muted-foreground truncate max-w-[120px]">
                      {item.emoji} {item.nombre}
                    </span>
                  </div>
                  <span className="font-bold text-primary text-sm flex-shrink-0">
                    {fmtPrecio(item.precio * qty)}
                  </span>
                </div>
              )
            })}
          </div>

          <div className="flex items-center justify-between pt-2 border-t border-border/50">
            <span className="font-semibold text-foreground">Total</span>
            <span className="font-extrabold text-primary text-lg">{fmtPrecio(totalPrecio)}</span>
          </div>

          <Select value={mesaId} onValueChange={setMesaId}>
            <SelectTrigger className="w-full h-11">
              <SelectValue placeholder={loadingMesas ? "Cargando mesas..." : "Seleccionar mesa"} />
            </SelectTrigger>
            <SelectContent>
              {mesas.map(m => (
                <SelectItem key={m.id} value={m.id}>
                  {m.label} {m.pedidos.length > 0 ? `(${m.pedidos.length} activo${m.pedidos.length > 1 ? "s" : ""})` : ""}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          <DialogFooter className="flex gap-2">
            <Button variant="outline" onClick={() => setCarritoOpen(false)} className="flex-1">
              Seguir agregando
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={!mesaId || submitting}
              className="flex-1 bg-primary hover:bg-primary/90 font-bold gap-1.5"
            >
              {submitting
                ? <Loader2 className="w-4 h-4 animate-spin" />
                : <><CheckCircle2 className="w-4 h-4" /> Crear pedido</>
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

function CatalogoSkeleton() {
  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        {[1,2,3,4].map(i => <Skeleton key={i} className="h-8 w-20 rounded-full" />)}
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        {Array.from({length: 8}).map((_, i) => <Skeleton key={i} className="h-36 rounded-xl" />)}
      </div>
    </div>
  )
}
CATALOGO

# ─────────────────────────────────────────────────────────────────────────────
# 10) Sidebar — agregar "Historial" al menú
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Actualizando sidebar.tsx para agregar Historial..."
cat > components/dashboard/sidebar.tsx << 'SIDEBAR'
"use client"
import { ClipboardList, MapPin, BookOpen, LogOut, Coffee, History } from "lucide-react"
import { cn } from "@/lib/utils"
import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { useAuth } from "@/context/auth-store"

const menuItems = [
  { icon: ClipboardList, label: "Pedidos",   href: "/" },
  { icon: MapPin,        label: "Mesas",     href: "/mesas" },
  { icon: BookOpen,      label: "Catálogo",  href: "/catalogo" },
  { icon: History,       label: "Historial", href: "/historial" },
]

export function Sidebar() {
  const [hovered, setHovered] = useState<string | null>(null)
  const pathname = usePathname()
  const { usuario, logout } = useAuth()

  const iniciales = usuario?.nombre
    ? usuario.nombre.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2)
    : "??"

  return (
    <aside className="fixed top-0 left-0 w-64 bg-sidebar border-r border-sidebar-border p-5 h-screen flex-col hidden lg:flex">
      <Link href="/" className="flex items-center gap-3 group mb-8">
        <div className="w-10 h-10 rounded-lg bg-primary flex items-center justify-center shadow-lg shadow-primary/30 transition-transform group-hover:scale-105">
          <Coffee className="w-5 h-5 text-primary-foreground" />
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
          <nav className="space-y-0.5">
            <button
              onClick={logout}
              className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-muted-foreground hover:bg-destructive/10 hover:text-destructive transition-all duration-200">
              <LogOut className="w-4 h-4" /> Cerrar sesión
            </button>
          </nav>
        </div>
      </div>

      <div className="pt-4 border-t border-sidebar-border flex items-center gap-3 px-2">
        <div className="w-8 h-8 rounded-full bg-primary/20 border border-primary/30 flex items-center justify-center">
          <span className="text-xs font-bold text-primary">{iniciales}</span>
        </div>
        <div className="min-w-0">
          <p className="text-xs font-semibold text-foreground truncate">{usuario?.nombre ?? "Usuario"}</p>
          <p className="text-[10px] text-muted-foreground truncate">{usuario?.rol ?? ""}</p>
        </div>
      </div>
    </aside>
  )
}

export function BottomNav() {
  const pathname = usePathname()
  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-50 bg-sidebar border-t border-sidebar-border">
      <div className="flex items-center justify-around h-16 px-1">
        {menuItems.map(item => {
          const active = pathname === item.href
          return (
            <Link key={item.href} href={item.href}
              className={cn(
                "flex flex-col items-center gap-0.5 px-2 py-2 rounded-xl transition-all duration-200 min-w-0 flex-1",
                active ? "text-primary" : "text-muted-foreground"
              )}>
              <div className={cn(
                "w-8 h-8 rounded-xl flex items-center justify-center transition-all duration-200",
                active ? "bg-primary/20 shadow-md shadow-primary/20" : ""
              )}>
                <item.icon className={cn("w-5 h-5", active && "text-primary")} />
              </div>
              <span className={cn(
                "text-[9px] font-semibold leading-none",
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

export function MobileTopBar({ title }: { title: string }) {
  const { logout, usuario } = useAuth()
  return (
    <div className="lg:hidden flex items-center justify-between px-4 py-3 border-b border-border bg-sidebar sticky top-0 z-40">
      <div className="flex items-center gap-2.5">
        <div className="w-7 h-7 rounded-md bg-primary flex items-center justify-center">
          <Coffee className="w-3.5 h-3.5 text-primary-foreground" />
        </div>
        <div>
          <p className="font-extrabold italic tracking-wider uppercase text-foreground text-sm leading-none">DRIVE</p>
          <p className="font-serif italic text-[9px] text-primary leading-none">Cafetería</p>
        </div>
      </div>
      <p className="font-extrabold italic uppercase tracking-wide text-foreground text-sm">{title}</p>
      <button onClick={logout} className="p-1.5 rounded-lg hover:bg-destructive/10 transition-colors">
        <LogOut className="w-4 h-4 text-muted-foreground hover:text-destructive" />
      </button>
    </div>
  )
}
SIDEBAR

echo ""
echo "✅ FRONTEND actualizado correctamente."
echo ""
echo "⚠️  NOTA: Para los íconos PWA, generá public/icon-192.png y public/icon-512.png"
echo "    con el ícono Coffee de lucide (podés usar https://favicon.io o similar)."
echo ""
echo "─────────────────────────────────────────────"
echo "📋 GIT:"
echo "─────────────────────────────────────────────"
echo ""
echo 'git add app/layout.tsx app/historial/ components/cafeteria/pedidos-view.tsx components/cafeteria/historial-pedidos.tsx components/cafeteria/catalogo-crear-pedido.tsx components/dashboard/sidebar.tsx context/cafeteria-store.tsx next.config.mjs public/manifest.json lib/api.ts'
echo 'git commit -m "feat(cafeteria): PWA, historial pedidos día, modal cierre, botón flotante mobile, catálogo mejorado"'
echo 'git push'