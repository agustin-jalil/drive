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
