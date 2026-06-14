import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { HistorialPedidos } from "@/components/cafeteria/historial-pedidos"
import { AuthGuard } from "@/components/auth/auth-guard"

export default function HistorialPage() {
  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-background">
        <Sidebar />
        <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
          <MobileTopBar title="Historial" />
          <div className="p-4 lg:p-6">
            <Header title="Historial del día" description="Todos los pedidos cerrados y balance" />
            <div className="mt-4 lg:mt-5"><HistorialPedidos /></div>
          </div>
        </main>
        <BottomNav />
      </div>
    </AuthGuard>
  )
}
