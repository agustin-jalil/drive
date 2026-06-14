#!/usr/bin/env bash
set -e

echo "📄 Actualizando pedidos-view.tsx con FAB + modal resumen..."

cat > components/cafeteria/pedidos-view.tsx << 'EOF'
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
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  RefreshCw, Clock, ChevronRight, PackageCheck,
  Plus, CheckCircle2, Circle, Timer, Truck, History,
  ClipboardList,
} from "lucide-react"
import { cn } from "@/lib/utils"
import Link from "next/link"
import type { Pedido } from "@/lib/api"

// ── Helpers puros ─────────────────────────────────────────────────────────────
const ESTADO_COLOR: Record<string, string> = {
  PENDIENTE:      "bg-yellow-500/15 text-yellow-400 border-yellow-500/30",
  EN_PREPARACION: "bg-primary/15 text-primary border-primary/30",
  LISTO:          "bg-green-500/15 text-green-400 border-green-500/30",
  ENTREGADO:      "bg-blue-500/15 text-blue-400 border-blue-500/30",
}
const ESTADO_LABEL: Record<string, string> = {
  PENDIENTE:      "Pendiente",
  EN_PREPARACION: "En preparación",
  LISTO:          "Listo",
  ENTREGADO:      "Entregado",
}
const ACCION_LABEL: Record<string, string> = {
  PENDIENTE:      "Preparar",
  EN_PREPARACION: "Marcar listo",
  LISTO:          "Entregar",
  ENTREGADO:      "Cobrar y cerrar",
}
const ACCION_CLS: Record<string, string> = {
  PENDIENTE:      "bg-yellow-500 hover:bg-yellow-600 text-white",
  EN_PREPARACION: "bg-primary hover:bg-primary/90 text-primary-foreground",
  LISTO:          "bg-green-600 hover:bg-green-700 text-white",
  ENTREGADO:      "bg-blue-600 hover:bg-blue-700 text-white",
}
const ESTADO_ICON: Record<string, React.FC<{ className?: string }>> = {
  PENDIENTE:      Circle,
  EN_PREPARACION: Timer,
  LISTO:          CheckCircle2,
  ENTREGADO:      Truck,
}

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

const fmtHora = (iso: string) =>
  new Date(iso).toLocaleTimeString("es-AR", { hour: "2-digit", minute: "2-digit" })

// ─────────────────────────────────────────────────────────────────────────────

export function PedidosView() {
  const { refreshing, lastUpdated } = useStore()
  const { pedidos, loading, refetchPedidos, avanzarEstado, cerrarPedido } = usePedidosActivos()

  const [pedidoACerrar, setPedidoACerrar] = useState<Pedido | null>(null)
  const [resumenOpen,   setResumenOpen]   = useState(false)

  if (loading) return <PedidosSkeleton />

  const handleAccion = async (pedido: Pedido) => {
    if (pedido.estado === "ENTREGADO") setPedidoACerrar(pedido)
    else await avanzarEstado(pedido.id)
  }

  const confirmarCierre = async () => {
    if (!pedidoACerrar) return
    await cerrarPedido(pedidoACerrar.id)
    setPedidoACerrar(null)
  }

  const totalGeneral = pedidos.reduce((acc, p) => acc + p.total, 0)

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
            <AlertDialogAction className="bg-blue-600 hover:bg-blue-700 text-white" onClick={confirmarCierre}>
              Confirmar cobro y cerrar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* ── Modal resumen pedidos ── */}
      <Dialog open={resumenOpen} onOpenChange={setResumenOpen}>
        <DialogContent className="max-w-sm w-[calc(100%-2rem)] rounded-2xl p-0 overflow-hidden gap-0">
          <DialogHeader className="px-5 pt-5 pb-3 border-b border-border/50">
            <DialogTitle className="flex items-center gap-2 text-base">
              <ClipboardList className="w-4 h-4 text-primary" />
              Resumen activo
            </DialogTitle>
          </DialogHeader>

          {pedidos.length === 0 ? (
            <div className="px-5 py-8 text-center text-sm text-muted-foreground">
              No hay pedidos activos
            </div>
          ) : (
            <div className="px-5 py-3 space-y-2 max-h-[55vh] overflow-y-auto">
              {pedidos.map(p => {
                const colorClass  = ESTADO_COLOR[p.estado] ?? ""
                const estadoLabel = ESTADO_LABEL[p.estado] ?? p.estado
                const accionCls   = ACCION_CLS[p.estado]
                const accionLabel = ACCION_LABEL[p.estado]
                return (
                  <div key={p.id} className="flex items-center gap-3 py-2.5 border-b border-border/20 last:border-0">
                    {/* Número + mesa */}
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-1.5 mb-0.5">
                        <span className="text-[10px] font-bold text-muted-foreground bg-secondary rounded px-1.5 py-0.5">
                          #{p.numero}
                        </span>
                        <span className="text-sm font-semibold text-foreground truncate">{p.mesa.label}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge className={cn("text-[10px] px-2 py-0.5 border rounded-full font-semibold", colorClass)}>
                          {estadoLabel}
                        </Badge>
                        <span className="text-xs font-bold text-primary tabular-nums">{fmtPrecio(p.total)}</span>
                      </div>
                    </div>
                    {/* Botón acción */}
                    {accionLabel && (
                      <button
                        onClick={async () => {
                          await handleAccion(p)
                          // si no abre modal de cierre, cerrar resumen
                          if (p.estado !== "ENTREGADO") setResumenOpen(false)
                        }}
                        className={cn(
                          "flex-shrink-0 h-8 px-3 rounded-lg text-xs font-bold uppercase tracking-wide transition-colors",
                          accionCls
                        )}
                      >
                        {accionLabel}
                      </button>
                    )}
                  </div>
                )
              })}
            </div>
          )}

          {/* Footer total */}
          {pedidos.length > 0 && (
            <div className="px-5 py-3 border-t border-border/50 flex items-center justify-between">
              <span className="text-sm text-muted-foreground">
                {pedidos.length} pedido{pedidos.length !== 1 ? "s" : ""} activo{pedidos.length !== 1 ? "s" : ""}
              </span>
              <span className="font-extrabold text-primary text-lg tabular-nums">{fmtPrecio(totalGeneral)}</span>
            </div>
          )}
        </DialogContent>
      </Dialog>

      <div className="space-y-4">

        {/* ── Barra superior ── */}
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-2">
            <p className="text-sm text-muted-foreground">
              {pedidos.length === 0
                ? "Sin pedidos activos"
                : `${pedidos.length} pedido${pedidos.length !== 1 ? "s" : ""} activo${pedidos.length !== 1 ? "s" : ""}`}
            </p>
            {refreshing && <RefreshCw className="w-3.5 h-3.5 text-primary animate-spin" />}
            {lastUpdated && !refreshing && (
              <span className="text-[10px] text-muted-foreground/60 hidden sm:inline">
                · {lastUpdated.toLocaleTimeString("es-AR", { hour: "2-digit", minute: "2-digit" })}
              </span>
            )}
          </div>
          <div className="flex items-center gap-1.5">
            <Button
              variant="ghost" size="sm"
              onClick={refetchPedidos}
              disabled={refreshing}
              className="gap-1 text-muted-foreground hover:text-foreground h-8 px-2"
            >
              <RefreshCw className={cn("w-3.5 h-3.5", refreshing && "animate-spin")} />
              <span className="text-xs hidden sm:inline">Actualizar</span>
            </Button>
            <Link href="/historial">
              <Button variant="outline" size="sm"
                className="h-8 text-xs font-bold uppercase tracking-wide gap-1 border-border/60 text-muted-foreground hover:text-foreground px-2 sm:px-3"
              >
                <History className="w-3.5 h-3.5" />
                <span className="hidden sm:inline">Historial</span>
              </Button>
            </Link>
            <Link href="/catalogo" className="hidden lg:block">
              <Button className="h-8 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90 gap-1">
                <Plus className="w-3.5 h-3.5" /> Nuevo pedido
              </Button>
            </Link>
          </div>
        </div>

        {pedidos.length === 0 ? <EmptyPedidos /> : (
          <>
            {/* ══ MOBILE / TABLET: cards ══ */}
            <div className="flex flex-col gap-3 lg:hidden">
              {pedidos.map(p => (
                <PedidoCard key={p.id} pedido={p} onAccion={handleAccion} />
              ))}
            </div>

            {/* ══ DESKTOP: tabla ══ */}
            <Card className="hidden lg:block border-border/60 overflow-hidden">
              <div className="grid grid-cols-[40px_130px_1fr_100px_140px_120px] gap-3 px-5 py-3 border-b border-border/50 bg-secondary/40">
                {["#", "Mesa", "Items", "Total", "Estado", "Acción"].map(h => (
                  <p key={h} className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest">{h}</p>
                ))}
              </div>
              <div className="divide-y divide-border/30">
                {pedidos.map(pedido => {
                  const colorClass  = ESTADO_COLOR[pedido.estado] ?? ""
                  const estadoLabel = ESTADO_LABEL[pedido.estado] ?? pedido.estado
                  const accionCls   = ACCION_CLS[pedido.estado]
                  const accionLabel = ACCION_LABEL[pedido.estado]
                  const Icon        = ESTADO_ICON[pedido.estado] ?? Circle
                  const resumen     = pedido.items
                    .map(i => `${i.item.emoji ?? "•"} ${i.item.nombre}${i.cantidad > 1 ? ` ×${i.cantidad}` : ""}`)
                    .join("  ·  ")
                  return (
                    <div
                      key={pedido.id}
                      className="grid grid-cols-[40px_130px_1fr_100px_140px_120px] gap-3 px-5 py-3.5 items-center hover:bg-secondary/20 transition-colors"
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
                      <p className="text-xs text-muted-foreground truncate pr-2" title={resumen}>{resumen}</p>
                      <p className="text-sm font-extrabold text-primary tabular-nums">{fmtPrecio(pedido.total)}</p>
                      <Badge className={cn("text-[10px] px-2.5 py-1 border rounded-full font-semibold flex items-center gap-1.5 w-fit", colorClass)}>
                        <Icon className="w-3 h-3" />
                        {estadoLabel}
                      </Badge>
                      {accionLabel && (
                        <Button
                          size="sm"
                          onClick={() => handleAccion(pedido)}
                          className={cn("h-8 text-xs font-bold uppercase tracking-wide px-3 gap-1", accionCls)}
                        >
                          {accionLabel}
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

      {/* ── FAB resumen — sticky abajo a la derecha, solo mobile ── */}
      {pedidos.length > 0 && (
        <button
          onClick={() => setResumenOpen(true)}
          className="lg:hidden fixed bottom-20 right-4 z-40 flex items-center gap-2 bg-primary text-primary-foreground pl-4 pr-3 py-3 rounded-2xl shadow-xl shadow-primary/40 font-bold text-sm animate-fade-in"
        >
          <ClipboardList className="w-4 h-4" />
          <span>{pedidos.length}</span>
          <span className="tabular-nums text-xs font-semibold opacity-90">{fmtPrecio(totalGeneral)}</span>
          <ChevronRight className="w-4 h-4 opacity-70" />
        </button>
      )}
    </>
  )
}

// ── Card mobile ───────────────────────────────────────────────────────────────
function PedidoCard({ pedido, onAccion }: { pedido: Pedido; onAccion: (p: Pedido) => Promise<void> }) {
  const colorClass  = ESTADO_COLOR[pedido.estado] ?? ""
  const estadoLabel = ESTADO_LABEL[pedido.estado] ?? pedido.estado
  const accionLabel = ACCION_LABEL[pedido.estado]
  const accionCls   = ACCION_CLS[pedido.estado]

  return (
    <Card className={cn(
      "p-4 border transition-all duration-200",
      pedido.estado === "LISTO"     ? "border-green-500/40 bg-green-500/5"
      : pedido.estado === "ENTREGADO" ? "border-blue-500/40 bg-blue-500/5"
      : "border-border/50 hover:border-primary/40"
    )}>
      <div className="flex items-center justify-between gap-2 mb-3">
        <div className="flex items-center gap-2 min-w-0">
          <span className="text-xs font-bold text-muted-foreground bg-secondary rounded px-1.5 py-0.5 flex-shrink-0">
            #{pedido.numero}
          </span>
          <span className="font-bold text-foreground text-sm truncate">{pedido.mesa.label}</span>
        </div>
        <Badge className={cn("text-[10px] px-2 py-0.5 border rounded-full font-semibold flex-shrink-0", colorClass)}>
          {estadoLabel}
        </Badge>
      </div>

      <div className="space-y-1.5 mb-3 pl-1">
        {pedido.items.map(it => (
          <div key={it.id} className="flex items-center gap-2 text-xs">
            <span className="text-base leading-none flex-shrink-0">{it.item.emoji ?? "•"}</span>
            <span className="text-muted-foreground truncate flex-1">{it.item.nombre}</span>
            <span className="font-semibold text-foreground flex-shrink-0">×{it.cantidad}</span>
            <span className="text-muted-foreground/70 flex-shrink-0 tabular-nums">
              {fmtPrecio(it.item.precio * it.cantidad)}
            </span>
          </div>
        ))}
      </div>

      <div className="flex items-center justify-between gap-2 pt-2.5 border-t border-border/40">
        <div className="flex items-center gap-2">
          <Clock className="w-3 h-3 text-muted-foreground flex-shrink-0" />
          <span className="text-xs text-muted-foreground">{fmtHora(pedido.creadoEn)}</span>
          <span className="font-extrabold text-primary text-sm tabular-nums">{fmtPrecio(pedido.total)}</span>
        </div>
        {accionLabel && (
          <Button
            size="sm"
            onClick={() => onAccion(pedido)}
            className={cn("h-9 text-xs px-4 gap-1 font-bold uppercase tracking-wide flex-shrink-0", accionCls)}
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
      <div className="flex justify-between items-center">
        <Skeleton className="h-5 w-36" />
        <Skeleton className="h-8 w-24" />
      </div>
      <div className="lg:hidden space-y-3">
        {[1, 2, 3].map(i => <Skeleton key={i} className="h-36 rounded-xl" />)}
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
EOF

echo "✅ pedidos-view.tsx actualizado"
echo ""
echo "git add components/cafeteria/pedidos-view.tsx"
echo "git commit -m \"feat(pedidos): FAB resumen con modal en mobile, acciones directas desde el modal\""
echo "git push"