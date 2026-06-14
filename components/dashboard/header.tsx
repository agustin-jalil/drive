"use client"

import type React from "react"
import { Bell } from "lucide-react"
import { Button } from "@/components/ui/button"

interface HeaderProps {
  title: string
  description?: string
  actions?: React.ReactNode
}

export function Header({ title, description, actions }: HeaderProps) {
  return (
    <div className="hidden lg:flex flex-row items-center justify-between gap-4 pb-5 border-b border-border">
      <div>
        <h1 className="font-extrabold italic tracking-wide uppercase text-2xl text-foreground">{title}</h1>
        {description && <p className="font-serif italic text-sm text-primary mt-0.5">{description}</p>}
      </div>
      <div className="flex items-center gap-3">
        <Button variant="outline" size="icon"
          className="h-9 w-9 bg-secondary border-border hover:bg-primary hover:text-primary-foreground hover:border-primary transition-all duration-200 relative">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-primary rounded-full" />
        </Button>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </div>
    </div>
  )
}
