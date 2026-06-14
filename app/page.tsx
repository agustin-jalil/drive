import { Sidebar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { PedidosView } from "@/components/cafeteria/pedidos-view"
import { Button } from "@/components/ui/button"
import Link from "next/link"

export default function PedidosPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <div className="hidden lg:block"><Sidebar /></div>
      <main className="flex-1 p-4 md:p-5 lg:p-6 lg:ml-64">
        <Header
          title="Pedidos"
          description="Gestión de pedidos activos"
          actions={
            <Link href="/catalogo">
              <Button className="h-9 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90 hover:shadow-lg hover:shadow-primary/30">
                + Nuevo pedido
              </Button>
            </Link>
          }
        />
        <div className="mt-5"><PedidosView /></div>
      </main>
    </div>
  )
}
