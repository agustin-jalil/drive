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
