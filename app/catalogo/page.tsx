import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { CatalogoCrearPedido } from "@/components/cafeteria/catalogo-crear-pedido"

export default function CatalogoPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <Sidebar />
      <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
        <MobileTopBar title="Catálogo" />
        <div className="p-4 lg:p-6">
          <Header title="Catálogo" description="Seleccioná ítems para armar el pedido" />
          <div className="mt-4 lg:mt-5"><CatalogoCrearPedido /></div>
        </div>
      </main>
      <BottomNav />
    </div>
  )
}
