import { Sidebar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { CatalogoCrearPedido } from "@/components/cafeteria/catalogo-crear-pedido"

export default function CatalogoPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <div className="hidden lg:block"><Sidebar /></div>
      <main className="flex-1 p-4 md:p-5 lg:p-6 lg:ml-64">
        <Header
          title="Catálogo"
          description="Seleccioná ítems para armar el pedido"
        />
        <div className="mt-5"><CatalogoCrearPedido /></div>
      </main>
    </div>
  )
}
