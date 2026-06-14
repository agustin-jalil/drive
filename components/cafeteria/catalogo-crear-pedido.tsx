"use client"
import { useState, useMemo } from "react"
import { useStore } from "@/context/cafeteria-store"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import { ShoppingCart, Plus, Minus, Trash2, SendHorizonal, ChevronDown, Loader2 } from "lucide-react"
import { cn } from "@/lib/utils"
import type { ItemCatalogo, Mesa } from "@/lib/api"

type CarritoItem = { item: ItemCatalogo; cantidad: number }

export function CatalogoCrearPedido() {
  const { catalogo, categorias, mesas, loadingCatalogo, crearPedido } = useStore()
  const [catActiva, setCatActiva] = useState<string | null>(null)
  const [carrito,   setCarrito]   = useState<CarritoItem[]>([])
  const [mesaId,    setMesaId]    = useState<string>("")
  const [sending,   setSending]   = useState(false)
  const [exito,     setExito]     = useState(false)

  const itemsFiltrados = useMemo(() =>
    catActiva ? catalogo.filter(i => i.categoriaId === catActiva) : catalogo,
  [catalogo, catActiva])

  const mesasActivas = mesas.filter(m => m.activo)

  const totalCarrito = carrito.reduce((a, c) => a + c.item.precio * c.cantidad, 0)
  const cantTotal    = carrito.reduce((a, c) => a + c.cantidad, 0)

  const agregarItem = (item: ItemCatalogo) => {
    setCarrito(prev => {
      const ex = prev.find(c => c.item.id === item.id)
      if (ex) return prev.map(c => c.item.id === item.id ? { ...c, cantidad: c.cantidad + 1 } : c)
      return [...prev, { item, cantidad: 1 }]
    })
  }

  const cambiarCantidad = (itemId: string, delta: number) => {
    setCarrito(prev =>
      prev
        .map(c => c.item.id === itemId ? { ...c, cantidad: c.cantidad + delta } : c)
        .filter(c => c.cantidad > 0)
    )
  }

  const enviarPedido = async () => {
    if (!mesaId || carrito.length === 0) return
    setSending(true)
    try {
      await crearPedido(mesaId, carrito.map(c => ({ itemId: c.item.id, cantidad: c.cantidad })))
      setCarrito([])
      setMesaId("")
      setExito(true)
      setTimeout(() => setExito(false), 3000)
    } catch (e) {
      console.error(e)
    } finally {
      setSending(false)
    }
  }

  if (loadingCatalogo) return <CatalogoSkeleton />

  return (
    <div className="flex flex-col xl:flex-row gap-4 xl:gap-6">
      {/* Columna catálogo */}
      <div className="flex-1 min-w-0 space-y-4">
        {/* Filtro categorías */}
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
          <button
            onClick={() => setCatActiva(null)}
            className={cn(
              "flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all border",
              !catActiva
                ? "bg-primary text-primary-foreground border-primary shadow-md shadow-primary/25"
                : "bg-card border-border text-muted-foreground hover:border-primary/50 hover:text-foreground"
            )}
          >
            Todos
          </button>
          {categorias.map(cat => (
            <button
              key={cat.id}
              onClick={() => setCatActiva(cat.id === catActiva ? null : cat.id)}
              className={cn(
                "flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all border",
                catActiva === cat.id
                  ? "bg-primary text-primary-foreground border-primary shadow-md shadow-primary/25"
                  : "bg-card border-border text-muted-foreground hover:border-primary/50 hover:text-foreground"
              )}
            >
              {cat.emoji && <span>{cat.emoji}</span>}
              {cat.nombre}
            </button>
          ))}
        </div>

        {/* Grid items */}
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 xl:grid-cols-3 2xl:grid-cols-4 gap-2.5">
          {itemsFiltrados.map(item => {
            const enCarrito = carrito.find(c => c.item.id === item.id)
            return (
              <button
                key={item.id}
                onClick={() => agregarItem(item)}
                className={cn(
                  "relative rounded-xl border p-3 text-left transition-all duration-200 active:scale-95",
                  enCarrito
                    ? "border-primary/60 bg-primary/8 shadow-md shadow-primary/15"
                    : "border-border/50 bg-card hover:border-primary/40 hover:bg-secondary/50"
                )}
              >
                {enCarrito && (
                  <span className="absolute top-2 right-2 w-5 h-5 rounded-full bg-primary text-primary-foreground text-[10px] font-bold flex items-center justify-center">
                    {enCarrito.cantidad}
                  </span>
                )}
                <div className="text-2xl mb-2">{item.emoji ?? "🍽️"}</div>
                <p className="text-xs font-semibold text-foreground leading-tight line-clamp-2 mb-1.5">
                  {item.nombre}
                </p>
                <p className="text-xs font-bold text-primary">
                  ${item.precio.toLocaleString("es-AR")}
                </p>
              </button>
            )
          })}
        </div>
      </div>

      {/* Panel carrito */}
      <div className="xl:w-80 xl:flex-shrink-0">
        <Card className="border-border/50 overflow-hidden sticky top-[4.5rem]">
          <div className="p-4 border-b border-border/50 bg-secondary/30">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <ShoppingCart className="w-4 h-4 text-primary" />
                <span className="font-semibold text-sm text-foreground">Pedido</span>
              </div>
              {cantTotal > 0 && (
                <Badge className="bg-primary/15 text-primary border-primary/30 text-xs border rounded-full px-2">
                  {cantTotal} ítem{cantTotal !== 1 ? "s" : ""}
                </Badge>
              )}
            </div>
          </div>

          <div className="p-4 space-y-4">
            {/* Selector mesa */}
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">Mesa / Barra</label>
              <div className="relative">
                <select
                  value={mesaId}
                  onChange={e => setMesaId(e.target.value)}
                  className="w-full h-10 rounded-lg bg-secondary border border-border text-sm text-foreground px-3 pr-8 appearance-none focus:outline-none focus:border-primary transition-colors"
                >
                  <option value="">Seleccioná una mesa...</option>
                  <optgroup label="Mesas">
                    {mesasActivas.filter(m => m.tipo === "MESA").map(m => (
                      <option key={m.id} value={m.id}>{m.label}</option>
                    ))}
                  </optgroup>
                  <optgroup label="Barra">
                    {mesasActivas.filter(m => m.tipo === "BARRA").map(m => (
                      <option key={m.id} value={m.id}>{m.label}</option>
                    ))}
                  </optgroup>
                </select>
                <ChevronDown className="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
              </div>
            </div>

            {/* Items carrito */}
            {carrito.length === 0 ? (
              <div className="py-8 text-center">
                <ShoppingCart className="w-10 h-10 text-muted-foreground/30 mx-auto mb-2" />
                <p className="text-xs text-muted-foreground">Tocá un ítem del catálogo para agregarlo</p>
              </div>
            ) : (
              <div className="space-y-2 max-h-64 overflow-y-auto">
                {carrito.map(({ item, cantidad }) => (
                  <div key={item.id} className="flex items-center gap-2 rounded-lg bg-secondary/50 p-2">
                    <span className="text-lg flex-shrink-0">{item.emoji ?? "🍽️"}</span>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-medium text-foreground truncate">{item.nombre}</p>
                      <p className="text-[10px] text-muted-foreground">
                        ${(item.precio * cantidad).toLocaleString("es-AR")}
                      </p>
                    </div>
                    <div className="flex items-center gap-1 flex-shrink-0">
                      <button
                        onClick={() => cambiarCantidad(item.id, -1)}
                        className="w-6 h-6 rounded-md bg-secondary border border-border flex items-center justify-center hover:bg-destructive/10 hover:border-destructive/40 transition-colors"
                      >
                        {cantidad === 1 ? <Trash2 className="w-3 h-3 text-destructive" /> : <Minus className="w-3 h-3" />}
                      </button>
                      <span className="text-xs font-bold text-foreground w-4 text-center">{cantidad}</span>
                      <button
                        onClick={() => cambiarCantidad(item.id, 1)}
                        className="w-6 h-6 rounded-md bg-secondary border border-border flex items-center justify-center hover:bg-primary/10 hover:border-primary/40 transition-colors"
                      >
                        <Plus className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Total + enviar */}
            {carrito.length > 0 && (
              <>
                <div className="flex items-center justify-between pt-2 border-t border-border/50">
                  <span className="text-sm font-semibold text-muted-foreground">Total</span>
                  <span className="text-lg font-bold text-foreground">
                    ${totalCarrito.toLocaleString("es-AR")}
                  </span>
                </div>
                <Button
                  onClick={enviarPedido}
                  disabled={!mesaId || sending}
                  className="w-full bg-primary hover:bg-primary/90 font-semibold gap-2 shadow-lg shadow-primary/25"
                >
                  {sending ? (
                    <><Loader2 className="w-4 h-4 animate-spin" /> Enviando...</>
                  ) : exito ? (
                    "✅ ¡Pedido enviado!"
                  ) : (
                    <><SendHorizonal className="w-4 h-4" /> Enviar pedido</>
                  )}
                </Button>
              </>
            )}
          </div>
        </Card>
      </div>
    </div>
  )
}

function CatalogoSkeleton() {
  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        {[1,2,3,4].map(i => <Skeleton key={i} className="h-8 w-20 rounded-full" />)}
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2.5">
        {Array.from({ length: 8 }).map((_, i) => <Skeleton key={i} className="h-24 rounded-xl" />)}
      </div>
    </div>
  )
}
