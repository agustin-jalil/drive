"use client"

import { useState, useEffect, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { useStore, CATEGORIAS, ITEMS_CATALOGO, MESAS_CONFIG } from "@/context/cafeteria-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Minus, Plus, ShoppingCart, Tag, Trash2 } from "lucide-react"
import type { ItemPedido } from "@/types/cafeteria"

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

function CatalogoInner() {
  const router  = useRouter()
  const params  = useSearchParams()
  const { crearPedido } = useStore()

  const [mesaId,    setMesaId]    = useState(params.get("mesa") ?? "")
  const [catActiva, setCatActiva] = useState("all")
  const [carrito,   setCarrito]   = useState<ItemPedido[]>([])

  useEffect(() => {
    const m = params.get("mesa")
    if (m) setMesaId(m)
  }, [params])

  const itemsFiltrados = catActiva === "all"
    ? ITEMS_CATALOGO
    : ITEMS_CATALOGO.filter(i => i.categoriaId === catActiva)

  const total    = carrito.reduce((a, i) => a + i.precio * i.cantidad, 0)
  const getCant  = (id: string) => carrito.find(i => i.id === id)?.cantidad ?? 0

  const modificar = (item: typeof ITEMS_CATALOGO[0], delta: number) => {
    setCarrito(prev => {
      const existe = prev.find(i => i.id === item.id)
      if (!existe) {
        if (delta < 1) return prev
        return [...prev, { id: item.id, nombre: item.nombre, emoji: item.emoji, precio: item.precio, cantidad: 1 }]
      }
      const nueva = existe.cantidad + delta
      if (nueva <= 0) return prev.filter(i => i.id !== item.id)
      return prev.map(i => i.id === item.id ? { ...i, cantidad: nueva } : i)
    })
  }

  const confirmar = () => {
    if (!mesaId || carrito.length === 0) return
    const mesa = MESAS_CONFIG.find(m => m.id === mesaId)!
    crearPedido(mesaId, mesa.label, carrito)
    router.push("/")
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

      {/* ── Catálogo ── */}
      <div className="lg:col-span-2 space-y-4">

        {/* Selector mesa */}
        <Card className="p-4 border-border/60">
          <div className="flex items-center gap-3">
            <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider flex-shrink-0">Mesa / Barra</p>
            <Select value={mesaId} onValueChange={setMesaId}>
              <SelectTrigger className="bg-secondary border-border text-foreground h-9 text-sm">
                <SelectValue placeholder="Seleccioná dónde..." />
              </SelectTrigger>
              <SelectContent className="bg-card border-border">
                <p className="text-[10px] font-bold text-muted-foreground uppercase px-2 pt-1.5 pb-0.5">Mesas</p>
                {MESAS_CONFIG.filter(m => m.tipo === "mesa").map(m => (
                  <SelectItem key={m.id} value={m.id} className="text-foreground hover:bg-secondary">{m.label}</SelectItem>
                ))}
                <p className="text-[10px] font-bold text-muted-foreground uppercase px-2 pt-2 pb-0.5">Barra</p>
                {MESAS_CONFIG.filter(m => m.tipo === "barra").map(m => (
                  <SelectItem key={m.id} value={m.id} className="text-foreground hover:bg-secondary">{m.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </Card>

        {/* Filtro categorías */}
        <div className="flex flex-wrap gap-2">
          <button onClick={() => setCatActiva("all")}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
              catActiva === "all" ? "bg-primary text-primary-foreground shadow-md" : "bg-secondary text-muted-foreground hover:text-foreground"
            }`}>
            <Tag className="w-3 h-3" /> Todo
          </button>
          {CATEGORIAS.map(c => (
            <button key={c.id} onClick={() => setCatActiva(c.id)}
              className={`px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                catActiva === c.id ? "bg-primary text-primary-foreground shadow-md" : "bg-secondary text-muted-foreground hover:text-foreground"
              }`}>
              {c.emoji} {c.nombre}
            </button>
          ))}
        </div>

        {/* Grid ítems */}
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
          {itemsFiltrados.map(item => {
            const cant = getCant(item.id)
            return (
              <Card key={item.id}
                className={`p-3.5 border-2 transition-all duration-200 ${
                  cant > 0 ? "border-primary/60 bg-primary/5 shadow-md shadow-primary/10" : "border-border/50 hover:border-primary/30"
                }`}>
                <div className="flex items-start gap-2 mb-3">
                  <span className="text-2xl">{item.emoji}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-foreground truncate">{item.nombre}</p>
                    <p className="text-sm font-extrabold text-primary">{fmtPrecio(item.precio)}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <button onClick={() => modificar(item, -1)}
                    className="w-7 h-7 rounded-lg bg-secondary flex items-center justify-center hover:bg-primary/20 transition-colors">
                    <Minus className="w-3.5 h-3.5 text-foreground" />
                  </button>
                  <span className={`text-base font-extrabold w-6 text-center ${cant > 0 ? "text-primary" : "text-muted-foreground"}`}>
                    {cant}
                  </span>
                  <button onClick={() => modificar(item, 1)}
                    className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center hover:bg-primary/90 transition-colors">
                    <Plus className="w-3.5 h-3.5 text-primary-foreground" />
                  </button>
                </div>
              </Card>
            )
          })}
        </div>
      </div>

      {/* ── Carrito sticky ── */}
      <div className="lg:sticky lg:top-6 self-start">
        <Card className="p-4 border-border/60">
          <div className="flex items-center gap-2 mb-4">
            <ShoppingCart className="w-4 h-4 text-primary" />
            <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-sm">Pedido</h2>
            {carrito.length > 0 && (
              <span className="ml-auto bg-primary text-primary-foreground text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center">
                {carrito.reduce((a, i) => a + i.cantidad, 0)}
              </span>
            )}
          </div>

          {carrito.length === 0 ? (
            <div className="py-8 text-center">
              <ShoppingCart className="w-8 h-8 text-muted-foreground/30 mx-auto mb-2" />
              <p className="text-xs text-muted-foreground font-serif italic">Agregá ítems del catálogo</p>
            </div>
          ) : (
            <div className="space-y-2 mb-4 max-h-64 overflow-y-auto pr-1">
              {carrito.map(it => (
                <div key={it.id} className="flex items-center gap-2 p-2 bg-secondary/50 rounded-lg">
                  <span className="text-base flex-shrink-0">{it.emoji}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-semibold text-foreground truncate">{it.nombre}</p>
                    <p className="text-[10px] text-muted-foreground">x{it.cantidad} · {fmtPrecio(it.precio * it.cantidad)}</p>
                  </div>
                  <button onClick={() => setCarrito(prev => prev.filter(i => i.id !== it.id))}
                    className="w-5 h-5 flex items-center justify-center rounded hover:bg-destructive/20 transition-colors flex-shrink-0">
                    <Trash2 className="w-3 h-3 text-muted-foreground" />
                  </button>
                </div>
              ))}
            </div>
          )}

          {carrito.length > 0 && (
            <div className="flex justify-between items-center py-2.5 border-t border-border/50 mb-3">
              <span className="font-extrabold italic uppercase text-xs text-foreground">Total</span>
              <span className="font-extrabold text-primary text-xl">{fmtPrecio(total)}</span>
            </div>
          )}

          <Button onClick={confirmar} disabled={carrito.length === 0 || !mesaId}
            className="w-full h-10 font-bold uppercase tracking-wide text-xs bg-primary text-primary-foreground hover:bg-primary/90 hover:shadow-lg hover:shadow-primary/30 disabled:opacity-40 transition-all">
            <ShoppingCart className="w-3.5 h-3.5 mr-1.5" /> Confirmar pedido
          </Button>

          {!mesaId && carrito.length > 0 && (
            <p className="text-[10px] text-center text-muted-foreground mt-2 font-serif italic">
              Seleccioná una mesa primero
            </p>
          )}
        </Card>
      </div>
    </div>
  )
}

export function CatalogoCrearPedido() {
  return (
    <Suspense fallback={<div className="text-muted-foreground text-sm font-serif italic">Cargando catálogo...</div>}>
      <CatalogoInner />
    </Suspense>
  )
}
