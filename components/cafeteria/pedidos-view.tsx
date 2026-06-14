"use client"
import { useStore } from "@/context/cafeteria-store"
import { usePedidosActivos, useEstadoColor, useEstadoLabel, useAccionLabel } from "@/hooks/use-pedidos"
import { Badge }    from "@/components/ui/badge"
import { Button }   from "@/components/ui/button"
import { Card }     from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import {
  RefreshCw, Clock, ChevronRight, PackageCheck,
  Plus, CheckCircle2, Circle, Timer, Truck,
} from "lucide-react"
import { cn } from "@/lib/utils"
import Link from "next/link"
import type { Pedido } from "@/lib/api"

// Íconos por estado para la tabla
const ESTADO_ICON: Record<string, React.FC<{ className?: string }>> = {
  PENDIENTE:      Circle,
  EN_PREPARACION: Timer,
  LISTO:          CheckCircle2,
  ENTREGADO:      Truck,
}

// Config de botón por estado
const BTN_CFG: Record<string, { label: string; cls: string }> = {
  PENDIENTE:      { label: "Preparar",      cls: "bg-yellow-500 hover:bg-yellow-600 text-white" },
  EN_PREPARACION: { label: "Marcar listo",  cls: "bg-primary hover:bg-primary/90 text-primary-foreground" },
  LISTO:          { label: "Entregar",      cls: "bg-green-600 hover:bg-green-700 text-white" },
  ENTREGADO:      { label: "Cobrar y cerrar", cls: "bg-blue-600 hover:bg-blue-700 text-white" },
}

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

const fmtHora = (iso: string) =>
  new Date(iso).toLocaleTimeString("es-AR", { hour: "2-digit", minute: "2-digit" })

export function PedidosView() {
  const { refreshing, lastUpdated } = useStore()
  const { pedidos, loading, refetchPedidos, avanzarEstado, cerrarPedido } = usePedidosActivos()

  if (loading) return <PedidosSkeleton />

  const handleAccion = async (pedido: Pedido) => {
    if (pedido.estado === "ENTREGADO") await cerrarPedido(pedido.id)
    else await avanzarEstado(pedido.id)
  }

  return (
    <div className="space-y-4">

      {/* ── Barra superior ── */}
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div className="flex items-center gap-2">
          <p className="text-sm text-muted-foreground">
            {pedidos.length === 0
              ? "Sin pedidos activos"
              : `${pedidos.length} pedido${pedidos.length !== 1 ? "s" : ""} activo${pedidos.length !== 1 ? "s" : ""}`}
          </p>
          {refreshing && (
            <RefreshCw className="w-3.5 h-3.5 text-primary animate-spin" />
          )}
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
          {/* Botón nuevo — solo desktop, en mobile está en la nav */}
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
          {/* ══════════════════════════════════════════════════════════════ */}
          {/* MOBILE (< lg): cards verticales                               */}
          {/* ══════════════════════════════════════════════════════════════ */}
          <div className="flex flex-col gap-3 lg:hidden">
            {pedidos.map(p => (
              <PedidoCard key={p.id} pedido={p} onAccion={handleAccion} />
            ))}
          </div>

          {/* ══════════════════════════════════════════════════════════════ */}
          {/* DESKTOP (≥ lg): TABLA completa estilo original                */}
          {/* ══════════════════════════════════════════════════════════════ */}
          <Card className="hidden lg:block border-border/60 overflow-hidden">
            {/* Header tabla */}
            <div className="grid grid-cols-[48px_120px_1fr_110px_150px_130px] gap-3 px-5 py-3 border-b border-border/50 bg-secondary/40">
              {["#", "Mesa", "Pedido", "Total", "Estado", "Acción"].map(h => (
                <p key={h} className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest">
                  {h}
                </p>
              ))}
            </div>

            {/* Filas */}
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
                    {/* # */}
                    <span className="text-xs font-bold text-muted-foreground bg-secondary rounded px-1.5 py-0.5 text-center w-fit">
                      #{pedido.numero}
                    </span>

                    {/* Mesa */}
                    <div>
                      <p className="text-sm font-semibold text-foreground">{pedido.mesa.label}</p>
                      <p className="text-[10px] text-muted-foreground flex items-center gap-1">
                        <Clock className="w-3 h-3" />{fmtHora(pedido.creadoEn)}
                      </p>
                    </div>

                    {/* Pedido */}
                    <p className="text-xs text-muted-foreground truncate pr-4" title={resumen}>
                      {resumen}
                    </p>

                    {/* Total */}
                    <p className="text-sm font-extrabold text-primary">
                      {fmtPrecio(pedido.total)}
                    </p>

                    {/* Estado */}
                    <Badge className={cn("text-[10px] px-2.5 py-1 border rounded-full font-semibold flex items-center gap-1.5 w-fit", colorClass)}>
                      <Icon className="w-3 h-3" />
                      {estadoLabel}
                    </Badge>

                    {/* Acción */}
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
  )
}

// ── Card mobile ──────────────────────────────────────────────────────────────
function PedidoCard({ pedido, onAccion }: { pedido: Pedido; onAccion: (p: Pedido) => Promise<void> }) {
  const colorClass  = useEstadoColor(pedido.estado)
  const estadoLabel = useEstadoLabel(pedido.estado)
  const accionLabel = useAccionLabel(pedido.estado)

  return (
    <Card className="p-4 border-border/50 transition-all duration-200 hover:border-primary/40">
      {/* Top */}
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

      {/* Items */}
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

      {/* Footer */}
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
            {pedido.estado === "ENTREGADO"
              ? <PackageCheck className="w-3.5 h-3.5" />
              : <ChevronRight className="w-3 h-3" />
            }
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
      {/* Mobile skeleton */}
      <div className="lg:hidden space-y-3">
        {[1, 2, 3].map(i => <Skeleton key={i} className="h-28 rounded-xl" />)}
      </div>
      {/* Desktop skeleton */}
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
