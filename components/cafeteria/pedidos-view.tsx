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
