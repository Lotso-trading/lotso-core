#!/usr/bin/env bash
# ==============================================================================
# Script: lint.sh
# Description: Lance Biome linter & formatter sur tous les projets ou un dossier ciblé.
# ==============================================================================

set -euo pipefail

# Couleurs pour le terminal
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
BLUE=$(printf '\033[0;34m')
BOLD=$(printf '\033[1m')
NC=$(printf '\033[0m')

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FIX=false
TARGET="."

usage() {
  cat <<EOF
${BOLD}Usage:${NC} $(basename "$0") [options] [chemin_ou_projet]

${BOLD}Description:${NC}
  Exécute Biome (linter, formatter, imports) sur l'ensemble du monorepo
  ou sur un projet spécifique.

${BOLD}Options:${NC}
  -f, --fix      Applique les corrections automatiques (--write)
  -h, --help     Affiche cette aide

${BOLD}Exemples:${NC}
  $(basename "$0")              # Vérifie tout le projet
  $(basename "$0") --fix        # Corrige automatiquement les erreurs de format/lint
  $(basename "$0") services/api # Vérifie uniquement services/api
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--fix|--write)
      FIX=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

BIOME_CMD=()
if [[ -x "$ROOT_DIR/node_modules/.bin/biome" ]]; then
  BIOME_CMD=("$ROOT_DIR/node_modules/.bin/biome")
elif command -v biome >/dev/null 2>&1; then
  BIOME_CMD=(biome)
else
  BIOME_CMD=(deno run -A npm:@biomejs/biome)
fi

if [[ "$FIX" == true ]]; then
  echo -e "${BLUE}${BOLD}🧹 Exécution de Biome (vérification & auto-fix)...${NC}"
  "${BIOME_CMD[@]}" check --write "$TARGET"
else
  echo -e "${BLUE}${BOLD}🔍 Exécution de Biome (vérification)...${NC}"
  "${BIOME_CMD[@]}" check "$TARGET"
fi

echo -e "${GREEN}✅ Analyse Biome terminée.${NC}"
