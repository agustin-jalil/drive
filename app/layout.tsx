import type React from "react"
import type { Metadata, Viewport } from "next"
import { Montserrat, Playfair_Display } from "next/font/google"
import { Analytics } from "@vercel/analytics/next"
import { ThemeProvider } from "@/components/theme-provider"
import { AuthStore } from "@/context/auth-store"
import { CafeteriaStore } from "@/context/cafeteria-store"
import "./globals.css"

const montserrat = Montserrat({ subsets: ["latin"], variable: "--font-sans", weight: ["400","500","600","700","800","900"] })
const playfair   = Playfair_Display({ subsets: ["latin"], variable: "--font-serif", style: ["normal","italic"], weight: ["400","500","600","700"] })

export const metadata: Metadata = {
  title: "Cafetería — DRIVE",
  description: "Sistema de gestión DRIVE",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Cafetería",
  },
}

export const viewport: Viewport = {
  themeColor: "#F57C00",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" className="dark" suppressHydrationWarning>
      <head>
        <link rel="apple-touch-icon" href="/icon-192.png" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="mobile-web-app-capable" content="yes" />
      </head>
      <body className={`${montserrat.variable} ${playfair.variable} font-sans antialiased`}>
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem={false} storageKey="drive-theme">
          <AuthStore>
            <CafeteriaStore>
              {children}
            </CafeteriaStore>
          </AuthStore>
        </ThemeProvider>
        <Analytics />
      </body>
    </html>
  )
}
