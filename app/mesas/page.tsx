import { Sidebar, BottomNav, MobileTopBar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { MesasContent } from "@/components/cafeteria/mesas-content"
import { AuthGuard } from "@/components/auth/auth-guard"

export default function MesasPage() {
  return (
    <AuthGuard>
      <div className="flex min-h-screen bg-background">
        <Sidebar />
        <main className="flex-1 lg:ml-64 pb-20 lg:pb-0">
          <MobileTopBar title="Mesas" />
          <div className="p-4 lg:p-6">
            <Header title="Mesas & Barra" description="Estado en tiempo real del salón" />
            <div className="mt-4 lg:mt-5"><MesasContent /></div>
          </div>
        </main>
        <BottomNav />
      </div>
    </AuthGuard>
  )
}
