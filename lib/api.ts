// Fallback explícito: si la var de entorno no llega, usamos el puerto del backend
const BASE =
  process.env.NEXT_PUBLIC_API_URL ||
  "http://localhost:3000/api/v1"

function getToken(): string | null {
  if (typeof window === "undefined") return null
  return localStorage.getItem("drive_token")
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = getToken()
  const url = `${BASE}${path}`

  const res = await fetch(url, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(init.headers ?? {}),
    },
  })

  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error(err.message ?? `HTTP ${res.status}`)
  }
  return res.json()
}

export const api = {
  // Auth
  login: (email: string, password: string) =>
    request<{ access_token: string; usuario: Usuario }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),
  me: () => request<Usuario>("/auth/me"),

  // Categorías
  getCategorias: () => request<Categoria[]>("/cafeteria/categorias"),

  // Catálogo
  getCatalogo: (categoriaId?: string) =>
    request<ItemCatalogo[]>(
      `/cafeteria/catalogo${categoriaId ? `?categoriaId=${categoriaId}` : ""}`
    ),

  // Mesas
  getMesas: () => request<Mesa[]>("/cafeteria/mesas"),
  getMesa:  (id: string) => request<MesaDetalle>(`/cafeteria/mesas/${id}`),

  // Pedidos
  getPedidos: (estado?: string) =>
    request<Pedido[]>(`/cafeteria/pedidos${estado ? `?estado=${estado}` : ""}`),
  getPedido: (id: string) => request<Pedido>(`/cafeteria/pedidos/${id}`),
  crearPedido: (mesaId: string, items: { itemId: string; cantidad: number }[]) =>
    request<Pedido>("/cafeteria/pedidos", {
      method: "POST",
      body: JSON.stringify({ mesaId, items }),
    }),
  avanzarEstado: (id: string) =>
    request<Pedido>(`/cafeteria/pedidos/${id}/avanzar`, { method: "PATCH" }),
  cerrarPedido: (id: string) =>
    request<Pedido>(`/cafeteria/pedidos/${id}/cerrar`, { method: "PATCH" }),
}

// ── Tipos ────────────────────────────────────────────────────────────────────
export type Rol             = "ADMIN" | "MOZO" | "BARISTA" | "LUBRICENTRO"
export type EstadoPedidoAPI = "PENDIENTE" | "EN_PREPARACION" | "LISTO" | "ENTREGADO" | "CERRADO"
export type TipoMesa        = "MESA" | "BARRA"

export interface Usuario {
  id: string; email: string; nombre: string; rol: Rol; activo: boolean
}
export interface Categoria {
  id: string; nombre: string; emoji: string | null; orden: number; activo: boolean
}
export interface ItemCatalogo {
  id: string; nombre: string; emoji: string | null; precio: number
  descripcion: string | null; activo: boolean; categoriaId: string; categoria: Categoria
}
export interface Mesa {
  id: string; numero: number; label: string; tipo: TipoMesa; activo: boolean
  pedidos: { id: string; estado: EstadoPedidoAPI; total: number; numero: number }[]
}
export interface MesaDetalle extends Mesa { pedidos: Pedido[] }
export interface ItemPedidoAPI {
  id: string; itemId: string; cantidad: number; precioUnit: number; subtotal: number; item: ItemCatalogo
}
export interface Pedido {
  id: string; numero: number; estado: EstadoPedidoAPI; total: number
  creadoEn: string; cerradoEn: string | null
  mesa: Mesa; items: ItemPedidoAPI[]; usuario: { id: string; nombre: string }
}
