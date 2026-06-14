#!/bin/bash
set -e

# Corrige el error de hidratación causado por next-themes en app/layout.tsx
# Causas:
#  1. Falta suppressHydrationWarning en <html> (next-themes modifica ese nodo en cliente)
#  2. Falta attribute="class" en <ThemeProvider>, por lo que next-themes agrega
#     data-theme y style="color-scheme:..." que el servidor no renderizó
#
# Ejecutar desde la raíz del proyecto Next.js

LAYOUT_FILE="app/layout.tsx"

if [ ! -f "$LAYOUT_FILE" ]; then
  echo "No encontrado: $LAYOUT_FILE"
  exit 1
fi

# 1. Agregar suppressHydrationWarning al <html>
sed -i 's|<html lang="es" className="dark">|<html lang="es" className="dark" suppressHydrationWarning>|' "$LAYOUT_FILE"

# 2. Agregar attribute="class" al ThemeProvider para que solo toque la clase
#    (ya está hardcodeada como "dark" en <html>) y no inyecte data-theme/style
sed -i 's|<ThemeProvider defaultTheme="dark" storageKey="drive-theme">|<ThemeProvider attribute="class" defaultTheme="dark" enableSystem={false} storageKey="drive-theme">|' "$LAYOUT_FILE"

echo "Corregido: $LAYOUT_FILE"
echo "Listo. Reiniciá el servidor de desarrollo (next dev) para ver el cambio."