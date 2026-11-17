#!/usr/bin/env bash
# ==============================================================================
# Script: update-dependencies.sh
# Description: Met à jour les dépendances npm dans les workspaces Deno
#              en appliquant un délai de sécurité (cooldown de 7 jours par défaut)
#              pour se prémunir contre les attaques de chaîne d'approvisionnement.
# ==============================================================================

set -euo pipefail

# Couleurs pour le terminal
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
BLUE=$(printf '\033[0;34m')
BOLD=$(printf '\033[1m')
NC=$(printf '\033[0m') # No Color

# Répertoire racine du projet
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Configuration par défaut
COOLDOWN_DAYS="${COOLDOWN_DAYS:-7}"
TARGET="${TARGET:-latest}"
DRY_RUN=false
PROJECT=""

# Affichage de l'aide
usage() {
  cat <<EOF
${BOLD}Usage:${NC} $(basename "$0") [options] [projet]

${BOLD}Description:${NC}
  Recherche et met à jour les dépendances déclarées dans les fichiers deno.json
  (packages/*/deno.json et services/*/deno.json) via npm-check-updates (ncu),
  en appliquant un cooldown de sécurité (par défaut 7 jours) pour bloquer
  les versions trop récentes potentiellement compromises.

${BOLD}Options:${NC}
  -c, --cooldown <jours>  Délai de quarantaine en jours (défaut: 7)
  -n, --dry-run           Vérifie les mises à jour sans modifier les fichiers
  -t, --target <cible>    Stratégie semver (latest, minor, patch, etc. défaut: latest)
  -p, --project <nom>     Cible un projet spécifique (ex: api, bot, dashboard, shared)
  -h, --help              Affiche cette aide

${BOLD}Exemples:${NC}
  $(basename "$0")                     # Met à jour tous les projets avec cooldown 7j
  $(basename "$0") --dry-run           # Inspecte les mises à jour disponibles sans modifier
  $(basename "$0") --cooldown 14       # Applique un cooldown de 14 jours
  $(basename "$0") api                 # Met à jour uniquement services/api
EOF
  exit 0
}

# Parsing des arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--cooldown)
      COOLDOWN_DAYS="$2"
      shift 2
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -t|--target)
      TARGET="$2"
      shift 2
      ;;
    -p|--project)
      PROJECT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -z "$PROJECT" && ! "$1" =~ ^- ]]; then
        PROJECT="$1"
        shift
      else
        echo -e "${RED}Option inconnue: $1${NC}" >&2
        usage
      fi
      ;;
  esac
done

echo -e "${BLUE}${BOLD}🛡️  Vérification des dépendances (Sécurité Chaîne d'Approvisionnement)${NC}"
echo -e "   • Cooldown de sécurité : ${YELLOW}${COOLDOWN_DAYS} jours${NC} (les paquets publiés il y a moins de ${COOLDOWN_DAYS}j sont ignorés)"
echo -e "   • Cible semver          : ${YELLOW}${TARGET}${NC}"
if [[ "$DRY_RUN" == true ]]; then
  echo -e "   • Mode                  : ${BLUE}Lecture seule (Dry-Run)${NC}"
else
  echo -e "   • Mode                  : ${GREEN}Mise à jour en place (-u)${NC}"
fi

# Détermination des fichiers à cibler
PACKAGE_FILES=()
if [[ -n "$PROJECT" ]]; then
  case "$PROJECT" in
    shared)
      PACKAGE_FILES=("packages/shared/deno.json")
      ;;
    api|bot|dashboard)
      PACKAGE_FILES=("services/$PROJECT/deno.json")
      ;;
    *)
      if [[ -f "$PROJECT" ]]; then
        PACKAGE_FILES=("$PROJECT")
      elif [[ -f "packages/$PROJECT/deno.json" ]]; then
        PACKAGE_FILES=("packages/$PROJECT/deno.json")
      elif [[ -f "services/$PROJECT/deno.json" ]]; then
        PACKAGE_FILES=("services/$PROJECT/deno.json")
      else
        echo -e "${RED}Projet introuvable : '$PROJECT'${NC}" >&2
        exit 1
      fi
      ;;
  esac
else
  PACKAGE_FILES=("{packages,services}/*/deno.json")
fi

echo -e "   • Fichiers ciblés       : ${PACKAGE_FILES[*]}\n"

# Construction des arguments ncu
NCU_ARGS=(
  --packageManager deno
  --target "$TARGET"
  --cooldown "$COOLDOWN_DAYS"
  --format cooldown
)

if [[ "$DRY_RUN" == false ]]; then
  NCU_ARGS+=(-u)
fi

# Exécution de ncu via npx (@latest pour garantir le support natif de --cooldown)
for TARGET_PATTERN in "${PACKAGE_FILES[@]}"; do
  echo -e "${BLUE}▶ Analyse de : ${TARGET_PATTERN}${NC}"
  npx -y npm-check-updates@latest --packageFile "$TARGET_PATTERN" "${NCU_ARGS[@]}"
done

# Si des mises à jour ont été appliquées, synchroniser le deno.lock
if [[ "$DRY_RUN" == false ]]; then
  echo -e "\n${BLUE}🔄 Synchronisation du fichier lock Deno (deno install)...${NC}"
  if command -v deno >/dev/null 2>&1; then
    deno install
    echo -e "${GREEN}✅ Dépendances et deno.lock synchronisés avec succès.${NC}"
  else
    echo -e "${YELLOW}⚠️  Deno non trouvé dans le PATH, synchronisation du lockfile ignorée.${NC}"
  fi
else
  echo -e "\n${GREEN}ℹ️  Mode lecture seule terminé. Pour appliquer les mises à jour, relancez sans --dry-run ou via 'make update'.${NC}"
fi
