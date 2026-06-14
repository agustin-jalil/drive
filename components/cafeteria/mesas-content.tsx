"use client"
import { useStore } from "@/context/cafeteria-store"
import { Skeleton } from "@/components/ui/skeleton"
import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"
import { UtensilsCrossed, Coffee, RefreshCw } from "lucide-react"
import { Button } from "@/components/ui/button"
import type { Mesa } from "@/lib/api"

export function MesasContent() {
  const { mesas, loadingMesas, refetchMesas } = useStore()

  if (loadingMesas) return <MesasSkeleton />

  const mesasTipo  = mesas.filter(m => m.tipo === "MESA")
  const barrasTipo = mesas.filter(m => m.tipo === "BARRA")

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          {mesas.filter(m => m.pedidos.length > 0).length} de {mesas.length} con pedidos activos
        </p>
        <Button variant="ghost" size="sm" onClick={refetchMesas} className="gap-1.5 text-muted-foreground hover:text-foreground">
          <RefreshCw className="w-3.5 h-3.5" />
          <span className="hidden sm:inline text-xs">Actualizar</span>
        </Button>
      </div>

      <Section titulo="Mesas" icono={<UtensilsCrossed className="w-4 h-4" />} mesas={mesasTipo} />
      <Section titulo="Barra" icono={<Coffee className="w-4 h-4" />} mesas={barrasTipo} />
    </div>
  )
}

function Section({ titulo, icono, mesas }: { titulo: string; icono: React.ReactNode; mesas: Mesa[] }) {
  return (
    <div>
      <div className="flex items-center gap-2 mb-3">
        <span className="text-muted-foreground">{icono}</span>
        <h3 className="text-sm font-semibold text-foreground uppercase tracking-widest">{titulo}</h3>
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-6 gap-3">
        {mesas.map(m => <MesaCard key={m.id} mesa={m} />)}
      </div>
    </div>
  )
}

function MesaCard({ mesa }: { mesa: Mesa }) {
  const ocupada = mesa.pedidos.length > 0
  const hayListo = mesa.pedidos.some(p => p.estado === "LISTO")
  const total    = mesa.pedidos.reduce((a, p) => a + p.total, 0)

  return (
    <div className={cn(
      "rounded-xl border p-4 flex flex-col gap-2 transition-all duration-200 cursor-default select-none",
      ocupada
        ? hayListo
          ? "border-green-500/50 bg-green-500/5 shadow-sm shadow-green-500/10"
          : "border-primary/50 bg-primary/5 shadow-sm shadow-primary/10"
        : "border-border/40 bg-card hover:border-border/70"
    )}>
      <div className="flex items-start justify-between">
        <span className={cn(
          "text-xs font-bold uppercase tracking-wide",
          ocupada ? (hayListo ? "text-green-400" : "text-primary") : "text-muted-foreground"
        )}>
          {mesa.label}
        </span>
        <div className={cn(
          "w-2.5 h-2.5 rounded-full mt-0.5",
          ocupada ? (hayListo ? "bg-green-400 shadow-sm shadow-green-400/60" : "bg-primary shadow-sm shadow-primary/60 animate-pulse") : "bg-muted-foreground/30"
        )} />
      </div>

      {ocupada ? (
        <div className="space-y-1">
          <div className="flex items-center justify-between">
            <Badge className={cn(
              "text-[10px] px-1.5 py-0.5 border rounded-full font-medium",
              hayListo
                ? "bg-green-500/15 text-green-400 border-green-500/30"
                : "bg-primary/15 text-primary border-primary/30"
            )}>
              {hayListo ? "¡Listo!" : `${mesa.pedidos.length} ped.`}
            </Badge>
          </div>
          <p className="text-xs font-semibold text-foreground">
            ${total.toLocaleString("es-AR")}
          </p>
        </div>
      ) : (
        <p className="text-xs text-muted-foreground/60">Libre</p>
      )}
    </div>
  )
}

function MesasSkeleton() {
  return (
    <div className="space-y-6">
      {[1, 2].map(s => (
        <div key={s} className="space-y-3">
          <Skeleton className="h-5 w-24" />
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-20 rounded-xl" />
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}
