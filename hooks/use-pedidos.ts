import { useStore } from "@/context/cafeteria-store"
import type { Pedido } from "@/lib/api"

const ORDEN_ESTADO: Record<string, number> = {
  PENDIENTE: 0, EN_PREPARACION: 1, LISTO: 2, ENTREGADO: 3, CERRADO: 4,
}

export function usePedidosActivos() {
  const { pedidos, loadingPedidos, refreshing, lastUpdated, refetchPedidos, avanzarEstado, cerrarPedido } = useStore()
  const activos = pedidos
    .filter(p => p.estado !== "CERRADO")
    .sort((a, b) => ORDEN_ESTADO[a.estado] - ORDEN_ESTADO[b.estado])
  return { pedidos: activos, loading: loadingPedidos, refreshing, lastUpdated, refetchPedidos, avanzarEstado, cerrarPedido }
}

export function useEstadoColor(estado: Pedido["estado"]) {
  const map: Record<string, string> = {
    PENDIENTE:      "bg-yellow-500/15 text-yellow-400 border-yellow-500/30",
    EN_PREPARACION: "bg-primary/15 text-primary border-primary/30",
    LISTO:          "bg-green-500/15 text-green-400 border-green-500/30",
    ENTREGADO:      "bg-blue-500/15 text-blue-400 border-blue-500/30",
    CERRADO:        "bg-muted text-muted-foreground border-border",
  }
  return map[estado] ?? map.PENDIENTE
}

export function useEstadoLabel(estado: string) {
  const map: Record<string, string> = {
    PENDIENTE:      "Pendiente",
    EN_PREPARACION: "En preparación",
    LISTO:          "¡Listo!",
    ENTREGADO:      "Entregado",
    CERRADO:        "Cerrado",
  }
  return map[estado] ?? estado
}

export function useAccionLabel(estado: string) {
  const map: Record<string, string> = {
    PENDIENTE:      "Preparar",
    EN_PREPARACION: "Marcar listo",
    LISTO:          "Entregar",
    ENTREGADO:      "Cerrar",
    CERRADO:        "",
  }
  return map[estado] ?? ""
}
