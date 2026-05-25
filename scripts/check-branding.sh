#!/usr/bin/env bash
# check-branding.sh — detecta vazamento de branding de outra marca no repositório.
# Uso: scripts/check-branding.sh [branch] [scan_dir]
#   branch   : branch corrente (default: branch git atual, ou "main")
#   scan_dir : diretório a escanear (default: ".")
# Saída: exit 0 se limpo; exit 1 se houver vazamento; exit 2 em erro de uso.
set -euo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)}"
SCAN_DIR="${2:-.}"

[[ -d "$SCAN_DIR" ]] || { echo "::error::scan_dir '$SCAN_DIR' não encontrado"; exit 2; }

# STRICT e LOOSE são strings de alternância ERE (separadas por '|'), não arrays.
# STRICT: palavra inteira (grep -iwE) p/ tokens com risco de falso-positivo.
# LOOSE : substring (grep -iE) p/ nomes compostos, domínios, env prefixes, assets externos.
case "$BRANCH" in
  main|ntxpay)  # marca mantida: NTX Pay
    STRICT='avista'
    LOOSE='firebanking|fire banking|goforge|safirapay|safira pay|avista\.global|firebanking\.com\.br|goforge\.com\.br|safirapay\.com|AVISTA_|FIREBANKING_|GOFORGE_|FORGE_|SAFIRAPAY_|framerusercontent|res\.cloudinary\.com'
    ;;
  *)
    echo "::warning::branch '$BRANCH' sem mapa de branding definido — pulando check"
    exit 0
    ;;
esac

# Só conteúdo publicável (.mdx/.json). docs/superpowers/ (specs/plans) e dirs de infra
# ficam fora via --exclude-dir (path-safe; não filtra por conteúdo da linha).
# CLAUDE.md (.md) já não entra no scan por causa do --include.
EXCLUDES=(--include='*.mdx' --include='*.json'
          --exclude-dir='.claude' --exclude-dir='.git'
          --exclude-dir='node_modules' --exclude-dir='superpowers')

found=0
tmp_out="$(mktemp)"
trap 'rm -f "$tmp_out"' EXIT

# grep retorna 1 quando não há match; o 'if' isenta do set -e.
if grep -rniwE "${EXCLUDES[@]}" "$STRICT" "$SCAN_DIR" >> "$tmp_out"; then
  found=1
fi
if grep -rniE "${EXCLUDES[@]}" "$LOOSE" "$SCAN_DIR" >> "$tmp_out"; then
  found=1
fi

if [[ "$found" -eq 1 ]]; then
  echo "❌ Vazamento de branding detectado na branch '$BRANCH' (marca esperada: NTX Pay):"
  sort -u "$tmp_out"
  exit 1
fi

echo "✅ Sem vazamento de branding na branch '$BRANCH'."
exit 0
