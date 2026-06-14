export type EstadoPedido = "pendiente" | "en_preparacion" | "listo" | "entregado"

export type ItemPedido = {
  id: string
  nombre: string
  emoji: string
  precio: number
  cantidad: number
}

export type Pedido = {
  id: string
  numero: number
  mesaId: string
  mesaLabel: string
  items: ItemPedido[]
  estado: EstadoPedido
  total: number
  hora: string
}
