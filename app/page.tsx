import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { PedidosView } from "@/components/cafeteria/pedidos-view"
import { AuthGuard } from "@/components/auth/auth-guard"

export default function HomePage() {
  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-background">
        <Sidebar />
        <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
          <MobileTopBar title="Pedidos" />
          <div className="p-4 lg:p-6">
            <Header title="Pedidos" description="Estado en tiempo real · se actualiza cada 15 s" />
            <div className="mt-4 lg:mt-5"><PedidosView /></div>
          </div>
        </main>
        <BottomNav />
      </div>
    </AuthGuard>
  )
}
