import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { PedidosView } from "@/components/cafeteria/pedidos-view"
import { Button } from "@/components/ui/button"
import Link from "next/link"

export default function PedidosPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <Sidebar />
      <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
        <MobileTopBar title="Pedidos" />
        {/* Mobile: botón nuevo flotante */}
        <div className="lg:hidden flex justify-end px-4 pt-4 pb-2">
          <Link href="/catalogo">
            <Button className="h-9 text-xs font-bold uppercase tracking-wide bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/30">
              <span className="mr-1 text-base font-bold leading-none">+</span> Nuevo pedido
            </Button>
          </Link>
        </div>

        <div className="p-4 lg:p-6">
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
          <div className="mt-4 lg:mt-5"><PedidosView /></div>
        </div>
      </main>
      <BottomNav />
    </div>
  )
}
