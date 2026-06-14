import type React from "react"
import type { Metadata } from "next"
import { Montserrat, Playfair_Display } from "next/font/google"
import { Analytics } from "@vercel/analytics/next"
import { ThemeProvider } from "@/components/theme-provider"
import { CafeteriaStore } from "@/context/cafeteria-store"
import "./globals.css"

const montserrat = Montserrat({ subsets: ["latin"], variable: "--font-sans", weight: ["400","500","600","700","800","900"] })
const playfair   = Playfair_Display({ subsets: ["latin"], variable: "--font-serif", style: ["normal","italic"], weight: ["400","500","600","700"] })

export const metadata: Metadata = {
  title: "DRIVE — Café & Lubricentro",
  description: "Sistema de gestión DRIVE",
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" className="dark">
      <body className={`${montserrat.variable} ${playfair.variable} font-sans antialiased`}>
        <ThemeProvider defaultTheme="dark" storageKey="drive-theme">
          <CafeteriaStore>{children}</CafeteriaStore>
        </ThemeProvider>
        <Analytics />
      </body>
    </html>
  )
}
