"use client"
import { useState, useMemo } from "react"
import { useStore } from "@/context/cafeteria-store"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select"
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from "@/components/ui/dialog"
import {
  Plus, Minus, ShoppingCart, Loader2, CheckCircle2, ChevronRight,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { useRouter } from "next/navigation"

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

type Carrito = Record<string, number>

export function CatalogoCrearPedido() {
  const { catalogo, categorias, mesas, loadingCatalogo, loadingMesas, crearPedido } = useStore()
  const router = useRouter()

  const [carrito, setCarrito]                 = useState<Carrito>({})
  const [categoriaFiltro, setCategoriaFiltro] = useState<string>("todas")
  const [mesaId, setMesaId]                   = useState<string>("")
  const [submitting, setSubmitting]           = useState(false)
  const [success, setSuccess]                 = useState(false)
  const [carritoOpen, setCarritoOpen]         = useState(false)

  const itemsFiltrados = useMemo(() =>
    categoriaFiltro === "todas"
      ? catalogo
      : catalogo.filter(i => i.categoriaId === categoriaFiltro),
    [catalogo, categoriaFiltro]
  )

  const totalItems  = Object.values(carrito).reduce((a, b) => a + b, 0)
  const totalPrecio = Object.entries(carrito).reduce((acc, [id, qty]) => {
    const item = catalogo.find(i => i.id === id)
    return acc + (item?.precio ?? 0) * qty
  }, 0)

  const add   = (id: string) => setCarrito(c => ({ ...c, [id]: (c[id] ?? 0) + 1 }))
  const sub   = (id: string) => setCarrito(c => {
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
    <>
      {/* ── Overlay éxito ── */}
      {success && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
          <div className="bg-card rounded-2xl p-8 flex flex-col items-center gap-3 shadow-2xl animate-fade-in mx-4">
            <CheckCircle2 className="w-16 h-16 text-green-500" />
            <p className="font-bold text-foreground text-lg">¡Pedido creado!</p>
          </div>
        </div>
      )}

      {/* ── FAB mobile — FUERA de cualquier div para que fixed funcione ── */}
      {totalItems > 0 && (
        <button
          onClick={() => setCarritoOpen(true)}
          className="lg:hidden fixed bottom-20 right-4 z-40 flex items-center gap-2 bg-primary text-primary-foreground pl-4 pr-3 py-3 rounded-2xl shadow-xl shadow-primary/40 font-bold text-sm animate-fade-in"
        >
          <ShoppingCart className="w-4 h-4" />
          <span>{totalItems}</span>
          <span className="tabular-nums text-xs font-semibold opacity-90">{fmtPrecio(totalPrecio)}</span>
          <ChevronRight className="w-4 h-4 opacity-70" />
        </button>
      )}

      {/* ── Dialog carrito — también fuera del div ── */}
      <Dialog open={carritoOpen} onOpenChange={setCarritoOpen}>
        <DialogContent className="max-w-sm w-[calc(100%-2rem)] rounded-2xl p-0 overflow-hidden gap-0">
          <DialogHeader className="px-5 pt-5 pb-3 border-b border-border/50">
            <DialogTitle className="flex items-center gap-2 text-base">
              <ShoppingCart className="w-4 h-4 text-primary" />
              Tu pedido
            </DialogTitle>
          </DialogHeader>

          <div className="px-5 py-3 space-y-1 max-h-[38vh] overflow-y-auto">
            {Object.entries(carrito).map(([id, qty]) => {
              const item = catalogo.find(i => i.id === id)
              if (!item) return null
              return (
                <div key={id} className="flex items-center gap-3 py-2 border-b border-border/20 last:border-0">
                  <div className="flex items-center gap-1.5 flex-shrink-0">
                    <button
                      onClick={() => sub(id)}
                      className="w-7 h-7 rounded-lg bg-secondary flex items-center justify-center"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <span className="font-bold text-foreground text-sm min-w-[1.25rem] text-center tabular-nums">{qty}</span>
                    <button
                      onClick={() => add(id)}
                      className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center"
                    >
                      <Plus className="w-3 h-3 text-primary-foreground" />
                    </button>
                  </div>
                  <span className="text-sm text-muted-foreground truncate flex-1">
                    {item.emoji} {item.nombre}
                  </span>
                  <span className="font-bold text-primary text-sm flex-shrink-0 tabular-nums">
                    {fmtPrecio(item.precio * qty)}
                  </span>
                </div>
              )
            })}
          </div>

          <div className="px-5 pb-5 pt-3 space-y-3 border-t border-border/50">
            <div className="flex items-center justify-between">
              <span className="font-semibold text-foreground">Total</span>
              <span className="font-extrabold text-primary text-xl tabular-nums">{fmtPrecio(totalPrecio)}</span>
            </div>
            <Select value={mesaId} onValueChange={setMesaId}>
              <SelectTrigger className="w-full h-11">
                <SelectValue placeholder={loadingMesas ? "Cargando mesas..." : "¿Para qué mesa?"} />
              </SelectTrigger>
              <SelectContent>
                {mesas.map(m => (
                  <SelectItem key={m.id} value={m.id}>
                    {m.label}{m.pedidos.length > 0 ? ` (${m.pedidos.length} activo${m.pedidos.length > 1 ? "s" : ""})` : ""}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => setCarritoOpen(false)} className="flex-1 h-11">
                Seguir
              </Button>
              <Button
                onClick={handleSubmit}
                disabled={!mesaId || submitting}
                className="flex-1 h-11 bg-primary hover:bg-primary/90 font-bold gap-1.5"
              >
                {submitting
                  ? <Loader2 className="w-4 h-4 animate-spin" />
                  : <><CheckCircle2 className="w-4 h-4" /> Confirmar</>
                }
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* ── Contenido principal ── */}
      <div className="animate-fade-in pb-28 lg:pb-6">

        {/* ── Filtro categorías ── */}
        <div className="flex flex-wrap gap-2 mb-4">
          <button
            onClick={() => setCategoriaFiltro("todas")}
            className={cn(
              "flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide transition-all border whitespace-nowrap",
              categoriaFiltro === "todas"
                ? "bg-primary text-primary-foreground border-primary shadow-md shadow-primary/25"
                : "bg-secondary text-muted-foreground border-border/50"
            )}
          >
            Todo
          </button>
          {categorias.map(cat => (
            <button
              key={cat.id}
              onClick={() => setCategoriaFiltro(cat.id)}
              className={cn(
                "flex-shrink-0 flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide transition-all border whitespace-nowrap",
                categoriaFiltro === cat.id
                  ? "bg-primary text-primary-foreground border-primary shadow-md shadow-primary/25"
                  : "bg-secondary text-muted-foreground border-border/50"
              )}
            >
              {cat.emoji && <span className="text-sm">{cat.emoji}</span>}
              {cat.nombre}
            </button>
          ))}
        </div>

        {/* ── Grid catálogo ── */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2.5">
          {itemsFiltrados.map(item => {
            const qty = carrito[item.id] ?? 0
            return (
              <div
                key={item.id}
                className={cn(
                  "bg-card text-card-foreground rounded-xl p-3 shadow-sm flex flex-col transition-all duration-200 border overflow-hidden",
                  qty > 0
                    ? "border-primary/60 bg-primary/5 shadow-md shadow-primary/10"
                    : "border-border/50"
                )}
              >
                <div className="flex flex-col gap-1 flex-1">
                  {item.emoji && (
                    <span className="text-lg leading-none">{item.emoji}</span>
                  )}
                  <p className="font-semibold text-foreground text-xs leading-tight line-clamp-2 min-h-[32px]">
                    {item.nombre}
                  </p>
                  {item.descripcion && (
                    <p className="hidden lg:block text-[10px] text-muted-foreground leading-tight line-clamp-2">
                      {item.descripcion}
                    </p>
                  )}
                  <p className="font-extrabold text-primary text-sm mt-1">
                    {fmtPrecio(item.precio)}
                  </p>
                </div>

                <div className="mt-2">
                  {qty === 0 ? (
                    <button
                      onClick={() => add(item.id)}
                      className="w-full h-8 rounded-lg bg-primary hover:bg-primary/90 text-primary-foreground text-xs font-bold flex items-center justify-center gap-1 transition-colors"
                    >
                      <Plus className="w-3.5 h-3.5" /> Agregar
                    </button>
                  ) : (
                    <div className="flex items-center justify-between gap-1">
                      <button
                        onClick={() => sub(item.id)}
                        className="w-8 h-8 rounded-lg bg-secondary flex items-center justify-center hover:bg-destructive/20 transition-colors"
                      >
                        <Minus className="w-3.5 h-3.5" />
                      </button>
                      <span className="font-extrabold text-primary text-base tabular-nums min-w-[1.5rem] text-center">
                        {qty}
                      </span>
                      <button
                        onClick={() => add(item.id)}
                        className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center hover:bg-primary/80 transition-colors"
                      >
                        <Plus className="w-3.5 h-3.5 text-primary-foreground" />
                      </button>
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>

        {/* ── DESKTOP: resumen pedido ── */}
        {totalItems > 0 && (
          <div className="hidden lg:block mt-6 bg-primary/5 border border-primary/40 rounded-xl p-5">
            <h3 className="font-bold text-foreground mb-3 flex items-center gap-2">
              <ShoppingCart className="w-4 h-4 text-primary" />
              Resumen del pedido
            </h3>
            <div className="space-y-1.5 mb-4 max-h-48 overflow-y-auto">
              {Object.entries(carrito).map(([id, qty]) => {
                const item = catalogo.find(i => i.id === id)
                if (!item) return null
                return (
                  <div key={id} className="flex items-center justify-between text-sm gap-3">
                    <span className="text-muted-foreground truncate flex items-center gap-1.5 min-w-0">
                      {item.emoji} {item.nombre} ×{qty}
                    </span>
                    <span className="font-bold text-primary flex-shrink-0">
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
                      {m.label}{m.pedidos.length > 0 ? ` (${m.pedidos.length} activo${m.pedidos.length > 1 ? "s" : ""})` : ""}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button
                onClick={handleSubmit}
                disabled={!mesaId || submitting}
                className="h-10 px-5 font-bold bg-primary hover:bg-primary/90 text-primary-foreground gap-1.5"
              >
                {submitting
                  ? <Loader2 className="w-4 h-4 animate-spin" />
                  : <><CheckCircle2 className="w-4 h-4" /> Crear pedido</>
                }
              </Button>
            </div>
          </div>
        )}

      </div>
    </>
  )
}

function CatalogoSkeleton() {
  return (
    <div className="space-y-4">
      <div className="flex gap-2 overflow-x-auto pb-2">
        {[1, 2, 3, 4].map(i => <Skeleton key={i} className="h-8 w-20 rounded-full flex-shrink-0" />)}
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2.5">
        {Array.from({ length: 8 }).map((_, i) => (
          <Skeleton key={i} className="h-32 rounded-xl" />
        ))}
      </div>
    </div>
  )
}
