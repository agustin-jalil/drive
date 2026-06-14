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
