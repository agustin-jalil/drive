"use client"

import { useState, useEffect, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { useStore, CATEGORIAS, ITEMS_CATALOGO, MESAS_CONFIG } from "@/context/cafeteria-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet"
import { Minus, Plus, ShoppingCart, Tag, Trash2 } from "lucide-react"
import type { ItemPedido } from "@/types/cafeteria"

const fmtPrecio = (n: number) =>
  new Intl.NumberFormat("es-AR", { style: "currency", currency: "ARS", maximumFractionDigits: 0 }).format(n)

function CatalogoInner() {
  const router = useRouter()
  const params = useSearchParams()
  const { crearPedido } = useStore()

  const [mesaId,    setMesaId]    = useState(params.get("mesa") ?? "")
  const [catActiva, setCatActiva] = useState("all")
  const [carrito,   setCarrito]   = useState<ItemPedido[]>([])
  const [sheetOpen, setSheetOpen] = useState(false)

  useEffect(() => { const m = params.get("mesa"); if (m) setMesaId(m) }, [params])

  const itemsFiltrados = catActiva === "all"
    ? ITEMS_CATALOGO
    : ITEMS_CATALOGO.filter(i => i.categoriaId === catActiva)

  const total      = carrito.reduce((a, i) => a + i.precio * i.cantidad, 0)
  const totalItems = carrito.reduce((a, i) => a + i.cantidad, 0)
  const getCant    = (id: string) => carrito.find(i => i.id === id)?.cantidad ?? 0

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

  // Carrito compartido (usado en sidebar desktop y sheet mobile)
  const CarritoContent = () => (
    <div className="flex flex-col h-full">
      {carrito.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center gap-2 py-10 text-center">
          <ShoppingCart className="w-10 h-10 text-muted-foreground/30" />
          <p className="text-xs text-muted-foreground font-serif italic">Agregá ítems del catálogo</p>
        </div>
      ) : (
        <div className="flex-1 overflow-y-auto space-y-2 mb-4 pr-1">
          {carrito.map(it => (
            <div key={it.id} className="flex items-center gap-2.5 p-2.5 bg-secondary/50 rounded-xl">
              <span className="text-lg flex-shrink-0">{it.emoji}</span>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-foreground truncate">{it.nombre}</p>
                <p className="text-[10px] text-muted-foreground">x{it.cantidad} · {fmtPrecio(it.precio * it.cantidad)}</p>
              </div>
              <button onClick={() => setCarrito(prev => prev.filter(i => i.id !== it.id))}
                className="w-6 h-6 flex items-center justify-center rounded-lg hover:bg-destructive/20 transition-colors flex-shrink-0">
                <Trash2 className="w-3 h-3 text-muted-foreground" />
              </button>
            </div>
          ))}
        </div>
      )}

      {carrito.length > 0 && (
        <div className="flex justify-between items-center py-3 border-t border-border/50 mb-3">
          <span className="font-extrabold italic uppercase text-xs text-foreground">Total</span>
          <span className="font-extrabold text-primary text-xl">{fmtPrecio(total)}</span>
        </div>
      )}

      <Button onClick={() => { confirmar(); setSheetOpen(false) }}
        disabled={carrito.length === 0 || !mesaId}
        className="w-full h-11 font-bold uppercase tracking-wide text-xs bg-primary text-primary-foreground hover:bg-primary/90 hover:shadow-lg hover:shadow-primary/30 disabled:opacity-40 transition-all rounded-xl">
        <ShoppingCart className="w-3.5 h-3.5 mr-1.5" /> Confirmar pedido
      </Button>
      {!mesaId && carrito.length > 0 && (
        <p className="text-[10px] text-center text-muted-foreground mt-2 font-serif italic">
          Seleccioná una mesa primero
        </p>
      )}
    </div>
  )

  return (
    <div className="flex flex-col lg:grid lg:grid-cols-3 gap-4 lg:gap-5 relative">

      {/* ── Catálogo ── */}
      <div className="lg:col-span-2 space-y-4">
        {/* Selector mesa */}
        <Card className="p-3.5 lg:p-4 border-border/60">
          <div className="flex items-center gap-3">
            <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider flex-shrink-0 hidden sm:block">
              Mesa / Barra
            </p>
            <Select value={mesaId} onValueChange={setMesaId}>
              <SelectTrigger className="bg-secondary border-border text-foreground h-9 text-sm flex-1">
                <SelectValue placeholder="¿Para qué mesa?" />
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

        {/* Filtro categorías — scroll horizontal en mobile */}
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide -mx-4 px-4 lg:mx-0 lg:px-0 lg:flex-wrap">
          <button onClick={() => setCatActiva("all")}
            className={`flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
              catActiva === "all" ? "bg-primary text-primary-foreground shadow-md" : "bg-secondary text-muted-foreground"
            }`}>
            <Tag className="w-3 h-3" /> Todo
          </button>
          {CATEGORIAS.map(c => (
            <button key={c.id} onClick={() => setCatActiva(c.id)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                catActiva === c.id ? "bg-primary text-primary-foreground shadow-md" : "bg-secondary text-muted-foreground"
              }`}>
              {c.emoji} {c.nombre}
            </button>
          ))}
        </div>

        {/* Grid ítems — 2 cols mobile, 3 cols desktop */}
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-2.5 lg:gap-3">
          {itemsFiltrados.map(item => {
            const cant = getCant(item.id)
            return (
              <Card key={item.id}
                className={`p-3 lg:p-3.5 border-2 transition-all duration-150 ${
                  cant > 0 ? "border-primary/60 bg-primary/5 shadow-md shadow-primary/10" : "border-border/50 active:scale-95"
                }`}>
                <div className="flex items-start gap-2 mb-3">
                  <span className="text-xl lg:text-2xl">{item.emoji}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs lg:text-sm font-semibold text-foreground leading-tight">{item.nombre}</p>
                    <p className="text-sm lg:text-sm font-extrabold text-primary mt-0.5">{fmtPrecio(item.precio)}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <button onClick={() => modificar(item, -1)}
                    className="w-7 h-7 rounded-lg bg-secondary flex items-center justify-center active:bg-primary/20 transition-colors">
                    <Minus className="w-3.5 h-3.5 text-foreground" />
                  </button>
                  <span className={`text-base font-extrabold w-6 text-center ${cant > 0 ? "text-primary" : "text-muted-foreground"}`}>
                    {cant}
                  </span>
                  <button onClick={() => modificar(item, 1)}
                    className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center active:bg-primary/80 transition-colors">
                    <Plus className="w-3.5 h-3.5 text-primary-foreground" />
                  </button>
                </div>
              </Card>
            )
          })}
        </div>

        {/* Espacio para el FAB en mobile */}
        <div className="h-20 lg:hidden" />
      </div>

      {/* ── DESKTOP: Carrito sidebar sticky ── */}
      <div className="hidden lg:block lg:sticky lg:top-6 self-start">
        <Card className="p-4 border-border/60 flex flex-col" style={{ maxHeight: "calc(100vh - 120px)" }}>
          <div className="flex items-center gap-2 mb-4 flex-shrink-0">
            <ShoppingCart className="w-4 h-4 text-primary" />
            <h2 className="font-extrabold italic uppercase tracking-wide text-foreground text-sm">Pedido</h2>
            {totalItems > 0 && (
              <span className="ml-auto bg-primary text-primary-foreground text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center">
                {totalItems}
              </span>
            )}
          </div>
          <CarritoContent />
        </Card>
      </div>

      {/* ── MOBILE: FAB flotante + Sheet ── */}
      {carrito.length > 0 && (
        <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
          <SheetTrigger asChild>
            <button
              className="lg:hidden fixed bottom-20 right-4 z-50 flex items-center gap-2.5 bg-primary text-primary-foreground px-4 py-3 rounded-2xl shadow-2xl shadow-primary/40 active:scale-95 transition-transform"
            >
              <ShoppingCart className="w-4 h-4" />
              <span className="font-bold text-sm">{fmtPrecio(total)}</span>
              <span className="bg-primary-foreground/20 text-primary-foreground text-[10px] font-extrabold w-5 h-5 rounded-full flex items-center justify-center">
                {totalItems}
              </span>
            </button>
          </SheetTrigger>
          <SheetContent side="bottom" className="bg-card border-border rounded-t-2xl h-[75vh] flex flex-col">
            <SheetHeader className="flex-shrink-0 pb-3 border-b border-border/50">
              <SheetTitle className="font-extrabold italic uppercase tracking-wide text-foreground text-left flex items-center gap-2">
                <ShoppingCart className="w-4 h-4 text-primary" />
                Tu pedido
                <span className="text-primary font-extrabold">{fmtPrecio(total)}</span>
              </SheetTitle>
            </SheetHeader>
            <div className="flex-1 overflow-hidden flex flex-col pt-3">
              <CarritoContent />
            </div>
          </SheetContent>
        </Sheet>
      )}
    </div>
  )
}

export function CatalogoCrearPedido() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center h-40">
        <p className="text-muted-foreground text-sm font-serif italic">Cargando catálogo...</p>
      </div>
    }>
      <CatalogoInner />
    </Suspense>
  )
}
