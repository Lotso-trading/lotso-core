#!/usr/bin/env bash
# ==============================================================================
# Script: lint.sh
# Description: Lance Biome linter & formatter sur tous les projets situés dans
#              packages/ et services/, ou sur un projet ciblé.
# ==============================================================================

set -euo pipefail

# Couleurs pour le terminal
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
BLUE=$(printf '\033[0;34m')
BOLD=$(printf '\033[1m')
NC=$(printf '\033[0m')

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FIX=false
SPECIFIC_TARGET=""

usage() {
  cat <<EOF
${BOLD}Usage:${NC} $(basename "$0") [options] [nom_ou_chemin_projet]

${BOLD}Description:${NC}
  Exécute Biome (linter, formatter, imports) sur chaque projet situé
  dans packages/ et services/, ou sur un projet spécifique.

${BOLD}Options:${NC}
  -f, --fix      Applique les corrections automatiques (--write)
  -h, --help     Affiche cette aide

${BOLD}Exemples:${NC}
  $(basename "$0")              # Vérifie tous les projets dans packages/ et services/
  $(basename "$0") --fix        # Corrige automatiquement dans packages/ et services/
  $(basename "$0") api          # Vérifie uniquement services/api
  $(basename "$0") shared --fix # Corrige uniquement packages/shared
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
      SPECIFIC_TARGET="$1"
      shift
      ;;
  esac
done

# Résolution des commandes Biome
BIOME_CMD=()
if [[ -x "$ROOT_DIR/node_modules/.bin/biome" ]]; then
  BIOME_CMD=("$ROOT_DIR/node_modules/.bin/biome")
elif command -v biome >/dev/null 2>&1; then
  BIOME_CMD=(biome)
else
  BIOME_CMD=(deno run -A npm:@biomejs/biome)
fi

# Détermination des projets ciblés
PROJECTS=()

resolve_project() {
  local target="$1"
  if [[ -d "$target" && -f "$target/deno.json" ]]; then
    echo "$target"
  elif [[ -d "packages/$target" && -f "packages/$target/deno.json" ]]; then
    echo "packages/$target"
  elif [[ -d "services/$target" && -f "services/$target/deno.json" ]]; then
    echo "services/$target"
  else
    return 1
  fi
}

if [[ -n "$SPECIFIC_TARGET" ]]; then
  if resolved=$(resolve_project "$SPECIFIC_TARGET"); then
    PROJECTS+=("$resolved")
  else
    echo -e "${RED}Projet introuvable : '$SPECIFIC_TARGET' (cherché dans packages/ et services/)${NC}" >&2
    exit 1
  fi
else
  for p in packages/* services/*; do
    if [[ -d "$p" && -f "$p/deno.json" ]]; then
      PROJECTS+=("$p")
    fi
  done
fi

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  echo -e "${YELLOW}Aucun projet trouvé dans packages/ et services/.${NC}" >&2
  exit 0
fi

BIOME_ACTION="check"
ACTION_LABEL="Vérification"
if [[ "$FIX" == true ]]; then
  ACTION_LABEL="Vérification & Auto-Fix"
fi

echo -e "${BLUE}${BOLD}🔍 Biome - ${ACTION_LABEL} sur les projets (packages & services)${NC}"
echo -e "   • Cibles : ${PROJECTS[*]}\n"

HAS_ERRORS=0

for proj in "${PROJECTS[@]}"; do
  echo -e "${BLUE}▶ Projet : ${BOLD}${proj}${NC}"
  pushd "$ROOT_DIR/$proj" >/dev/null
  if [[ "$FIX" == true ]]; then
    if ! "${BIOME_CMD[@]}" check --write .; then
      HAS_ERRORS=1
    fi
  else
    if ! "${BIOME_CMD[@]}" check .; then
      HAS_ERRORS=1
    fi
  fi
  popd >/dev/null
  echo ""
done

if [[ "$HAS_ERRORS" -ne 0 ]]; then
  echo -e "${RED}❌ Des erreurs de linting/formatage ont été détectées dans un ou plusieurs projets.${NC}"
  echo -e "   Pour corriger automatiquement, exécutez : ${YELLOW}make lint-fix${NC} (ou ${YELLOW}./scripts/lint.sh --fix${NC})"
  exit 1
fi

echo -e "${GREEN}✅ Tous les projets dans packages et services sont conformes.${NC}"
