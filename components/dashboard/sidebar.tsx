"use client"

import { ClipboardList, MapPin, BookOpen, Settings, LogOut, Wrench } from "lucide-react"
import { cn } from "@/lib/utils"
import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"

const menuItems = [
  { icon: ClipboardList, label: "Pedidos",  href: "/" },
  { icon: MapPin,        label: "Mesas",    href: "/mesas" },
  { icon: BookOpen,      label: "Catálogo", href: "/catalogo" },
]
const generalItems = [
  { icon: Settings, label: "Config", href: "/settings" },
  { icon: LogOut,   label: "Salir",  href: "/logout" },
]

// ── Desktop sidebar ──────────────────────────────────────────
export function Sidebar() {
  const [hovered, setHovered] = useState<string | null>(null)
  const pathname = usePathname()

  return (
    <aside className="fixed top-0 left-0 w-64 bg-sidebar border-r border-sidebar-border p-5 h-screen flex-col hidden lg:flex">
      <Link href="/" className="flex items-center gap-3 group mb-8">
        <div className="w-10 h-10 rounded-lg bg-primary flex items-center justify-center shadow-lg shadow-primary/30 transition-transform group-hover:scale-105">
          <Wrench className="w-5 h-5 text-primary-foreground" />
        </div>
        <div>
          <p className="font-extrabold italic tracking-wider uppercase text-foreground text-lg leading-none">DRIVE</p>
          <p className="font-serif italic text-xs text-primary tracking-wide leading-none mt-0.5">Café & Lubricentro</p>
        </div>
      </Link>

      <div className="space-y-6 flex-1">
        <div>
          <p className="text-[10px] font-semibold text-muted-foreground mb-2 uppercase tracking-widest px-2">Cafetería</p>
          <nav className="space-y-0.5">
            {menuItems.map(item => {
              const active = pathname === item.href
              return (
                <Link key={item.href} href={item.href}
                  onMouseEnter={() => setHovered(item.label)}
                  onMouseLeave={() => setHovered(null)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200",
                    active ? "bg-primary text-primary-foreground shadow-lg shadow-primary/25"
                           : "text-muted-foreground hover:bg-secondary hover:text-foreground",
                    hovered === item.label && !active && "translate-x-1"
                  )}>
                  <item.icon className="w-4 h-4 flex-shrink-0" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </div>
        <div>
          <p className="text-[10px] font-semibold text-muted-foreground mb-2 uppercase tracking-widest px-2">General</p>
          <nav className="space-y-0.5">
            {generalItems.map(item => {
              const active = pathname === item.href
              return (
                <Link key={item.href} href={item.href}
                  onMouseEnter={() => setHovered(item.label)}
                  onMouseLeave={() => setHovered(null)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200",
                    active ? "bg-primary text-primary-foreground shadow-lg shadow-primary/25"
                           : "text-muted-foreground hover:bg-secondary hover:text-foreground",
                    hovered === item.label && !active && "translate-x-1"
                  )}>
                  <item.icon className="w-4 h-4 flex-shrink-0" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </div>
      </div>

      <div className="pt-4 border-t border-sidebar-border flex items-center gap-3 px-2">
        <div className="w-8 h-8 rounded-full bg-primary/20 border border-primary/30 flex items-center justify-center">
          <span className="text-xs font-bold text-primary">AD</span>
        </div>
        <div>
          <p className="text-xs font-semibold text-foreground">Admin</p>
          <p className="text-[10px] text-muted-foreground">drive@sistema.com</p>
        </div>
      </div>
    </aside>
  )
}

// ── Mobile bottom nav ────────────────────────────────────────
export function BottomNav() {
  const pathname = usePathname()

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-50 bg-sidebar border-t border-sidebar-border">
      <div className="flex items-center justify-around h-16 px-2">
        {menuItems.map(item => {
          const active = pathname === item.href
          return (
            <Link key={item.href} href={item.href}
              className={cn(
                "flex flex-col items-center gap-0.5 px-4 py-2 rounded-xl transition-all duration-200 min-w-0 flex-1",
                active ? "text-primary" : "text-muted-foreground"
              )}>
              <div className={cn(
                "w-8 h-8 rounded-xl flex items-center justify-center transition-all duration-200",
                active ? "bg-primary/20 shadow-md shadow-primary/20" : ""
              )}>
                <item.icon className={cn("w-5 h-5", active && "text-primary")} />
              </div>
              <span className={cn(
                "text-[10px] font-semibold leading-none",
                active ? "text-primary" : "text-muted-foreground"
              )}>
                {item.label}
              </span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}

// ── Mobile header ────────────────────────────────────────────
export function MobileTopBar({ title }: { title: string }) {
  return (
    <div className="lg:hidden flex items-center justify-between px-4 py-3 border-b border-border bg-sidebar sticky top-0 z-40">
      <div className="flex items-center gap-2.5">
        <div className="w-7 h-7 rounded-md bg-primary flex items-center justify-center">
          <Wrench className="w-3.5 h-3.5 text-primary-foreground" />
        </div>
        <div>
          <p className="font-extrabold italic tracking-wider uppercase text-foreground text-sm leading-none">DRIVE</p>
          <p className="font-serif italic text-[9px] text-primary leading-none">Cafetería</p>
        </div>
      </div>
      <p className="font-extrabold italic uppercase tracking-wide text-foreground text-sm">{title}</p>
    </div>
  )
}
