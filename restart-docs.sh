#!/bin/bash

echo "🧹 Limpando cache do Mintlify..."

# Limpar cache do Next.js se existir
if [ -d ".next" ]; then
    rm -rf .next
    echo "✅ Cache .next removido"
fi

# Limpar node_modules do mintlify se existir
if [ -d "node_modules" ]; then
    rm -rf node_modules
    echo "✅ node_modules removido"
fi

echo "🔄 Atualizando Mintlify CLI..."
mint update

echo "🚀 Iniciando servidor de desenvolvimento..."
mint dev
