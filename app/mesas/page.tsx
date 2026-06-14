import { Sidebar } from "@/components/dashboard/sidebar"
import { Header } from "@/components/dashboard/header"
import { MesasContent } from "@/components/cafeteria/mesas-content"

export default function MesasPage() {
  return (
    <div className="flex min-h-screen bg-background">
      <div className="hidden lg:block"><Sidebar /></div>
      <main className="flex-1 p-4 md:p-5 lg:p-6 lg:ml-64">
        <Header
          title="Mesas & Barra"
          description="Estado en tiempo real del salón"
        />
        <div className="mt-5"><MesasContent /></div>
      </main>
    </div>
  )
}
