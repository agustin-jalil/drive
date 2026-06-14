"use client"
import { useRouter } from "next/navigation"
import { useAuth } from "@/context/auth-store"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { LogOut } from "lucide-react"

export default function LogoutPage() {
  const router = useRouter()
  const { logout } = useAuth()

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <Card className="p-8 max-w-md w-full text-center space-y-6 animate-fade-in">
        <div className="flex justify-center">
          <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center">
            <LogOut className="w-8 h-8 text-primary" />
          </div>
        </div>
        <div>
          <h1 className="text-2xl font-bold text-foreground mb-2">Cerrar sesión</h1>
          <p className="text-muted-foreground">¿Seguro que querés salir?</p>
        </div>
        <div className="flex gap-3">
          <Button variant="outline" className="flex-1 bg-transparent" onClick={() => router.back()}>
            Cancelar
          </Button>
          <Button className="flex-1 bg-primary hover:bg-primary/90" onClick={logout}>
            Salir
          </Button>
        </div>
      </Card>
    </div>
  )
}
