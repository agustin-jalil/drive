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
