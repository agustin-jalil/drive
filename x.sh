#!/usr/bin/env bash
set -e

echo "📄 Aplicando fix mínimo al catálogo..."

# Solo cambiar grid-cols-2 a grid-cols-1 en mobile
sed -i 's/grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4/grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4/' components/cafeteria/catalogo-crear-pedido.tsx
sed -i 's/grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4/grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4/' components/cafeteria/catalogo-crear-pedido.tsx

# Cambiar el contenedor de filtros para que wrappee en lugar de hacer scroll
sed -i 's/flex gap-2 overflow-x-auto pb-2 scrollbar-hide mb-4 -mx-4 px-4 lg:mx-0 lg:px-0/flex flex-wrap gap-2 mb-4/' components/cafeteria/catalogo-crear-pedido.tsx
sed -i 's/flex gap-2 overflow-x-auto pb-2 scrollbar-hide mb-4/flex flex-wrap gap-2 mb-4/' components/cafeteria/catalogo-crear-pedido.tsx

echo "✅ Listo"
echo ""
echo "git add components/cafeteria/catalogo-crear-pedido.tsx"
echo "git commit -m \"fix(catalogo): grid 1 col en mobile, filtros con wrap\""
echo "git push"