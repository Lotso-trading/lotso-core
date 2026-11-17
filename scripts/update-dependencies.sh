#!/usr/bin/env bash
# ==============================================================================
# Script: update-dependencies.sh
# Description: Met à jour les dépendances npm dans les workspaces Deno
#              en appliquant un délai de sécurité (cooldown de 7 jours par défaut)
#              pour se prémunir contre les attaques de chaîne d'approvisionnement.
#              Supporte le mode --dev pour mettre à jour @lotso-trading/shared
#              vers sa dernière version dev sur l'ensemble des services.
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
DEV_MODE=false

# Affichage de l'aide
usage() {
  cat <<EOF
${BOLD}Usage:${NC} $(basename "$0") [options] [projet]

${BOLD}Description:${NC}
  Recherche et met à jour les dépendances déclarées dans les fichiers deno.json
  (packages/*/deno.json et services/*/deno.json) via npm-check-updates (ncu),
  en appliquant un cooldown de sécurité (par défaut 7 jours) pour bloquer
  les versions trop récentes potentiellement compromises.

  En mode ${BOLD}--dev${NC}, met à jour le package ${BOLD}@lotso-trading/shared${NC}
  vers la dernière version dev (tag 'dev' ou dernière pre-release) sur tous les services.

${BOLD}Options:${NC}
  -d, --dev               Met à jour @lotso-trading/shared vers la dernière version dev sur tous les services
  -c, --cooldown <jours>  Délai de quarantaine en jours (défaut: 7)
  -n, --dry-run           Vérifie les mises à jour sans modifier les fichiers
  -t, --target <cible>    Stratégie semver (latest, minor, patch, etc. défaut: latest)
  -p, --project <nom>     Cible un projet spécifique (ex: api, bot, dashboard, shared)
  -h, --help              Affiche cette aide

${BOLD}Exemples:${NC}
  $(basename "$0")                     # Met à jour tous les projets avec cooldown 7j
  $(basename "$0") --dev               # Met à jour @lotso-trading/shared vers la dernière version dev
  $(basename "$0") --dry-run           # Inspecte les mises à jour disponibles sans modifier
  $(basename "$0") --cooldown 14       # Applique un cooldown de 14 jours
  $(basename "$0") api                 # Met à jour uniquement services/api
EOF
  exit 0
}

# Parsing des arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dev|dev)
      DEV_MODE=true
      shift
      ;;
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

# ==============================================================================
# Mode --dev : Mise à jour de @lotso-trading/shared sur les services
# ==============================================================================
if [[ "$DEV_MODE" == true ]]; then
  echo -e "${BLUE}${BOLD}📦 Mode DEV activé : Recherche de la dernière version dev de @lotso-trading/shared...${NC}"

  # Récupération de la version dev via le tag 'dev', ou dernière pre-release develop, ou latest
  LATEST_DEV=$(npm view @lotso-trading/shared dist-tags.dev --registry=https://npm.pkg.github.com 2>/dev/null || true)
  if [[ -z "$LATEST_DEV" ]]; then
    LATEST_DEV=$(npm view @lotso-trading/shared versions --json --registry=https://npm.pkg.github.com 2>/dev/null | grep -o '"[^"]*develop[^"]*"' | tr -d '"' | tail -n 1 || true)
  fi
  if [[ -z "$LATEST_DEV" ]]; then
    LATEST_DEV=$(npm view @lotso-trading/shared dist-tags.latest --registry=https://npm.pkg.github.com 2>/dev/null || true)
  fi

  if [[ -z "$LATEST_DEV" ]]; then
    echo -e "${RED}❌ Impossible de déterminer la version dev de @lotso-trading/shared sur GitHub Packages.${NC}" >&2
    exit 1
  fi

  echo -e "   • Dernière version dev détectée : ${GREEN}${BOLD}${LATEST_DEV}${NC}"
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "   • Mode                          : ${BLUE}Lecture seule (Dry-Run)${NC}"
  else
    echo -e "   • Mode                          : ${GREEN}Mise à jour en place${NC}"
  fi

  # Cibles des services
  TARGET_SERVICES=()
  if [[ -n "$PROJECT" ]]; then
    case "$PROJECT" in
      api|bot|dashboard)
        TARGET_SERVICES=("services/$PROJECT/deno.json")
        ;;
      *)
        if [[ -f "services/$PROJECT/deno.json" ]]; then
          TARGET_SERVICES=("services/$PROJECT/deno.json")
        else
          echo -e "${RED}Service introuvable pour la mise à jour de shared : '$PROJECT'${NC}" >&2
          exit 1
        fi
        ;;
    esac
  else
    TARGET_SERVICES=("services/api/deno.json" "services/bot/deno.json" "services/dashboard/deno.json")
    if [[ -f "deno.json" ]]; then
      TARGET_SERVICES+=("deno.json")
    fi
  fi

  echo -e "   • Fichiers ciblés               : ${TARGET_SERVICES[*]}\n"

  for SVC_FILE in "${TARGET_SERVICES[@]}"; do
    if [[ -f "$SVC_FILE" ]]; then
      echo -e "${BLUE}▶ Traitement de : ${SVC_FILE}${NC}"
      if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}→ Metterait à jour @lotso-trading/shared vers npm:@lotso-trading/shared@${LATEST_DEV}${NC}"
      else
        deno eval '
          const filePath = Deno.args[0];
          const newVersion = Deno.args[1];
          const raw = await Deno.readTextFile(filePath);
          const json = JSON.parse(raw);
          if (json.imports) {
            json.imports["@lotso-trading/shared"] = `npm:@lotso-trading/shared@${newVersion}`;
            if (json.imports["@lotso-trading/shared"]) {
              json.imports["@lotso-trading/shared"] = `npm:@lotso-trading/shared@${newVersion}`;
            }
          }
          await Deno.writeTextFile(filePath, JSON.stringify(json, null, 4) + "\n");
        ' "$SVC_FILE" "$LATEST_DEV"
        echo -e "  ${GREEN}✓ @lotso-trading/shared mis à jour vers v${LATEST_DEV}${NC}"
      fi
    fi
  done

  if [[ "$DRY_RUN" == false ]]; then
    echo -e "\n${BLUE}🔄 Synchronisation du fichier lock Deno (deno install)...${NC}"
    if command -v deno >/dev/null 2>&1; then
      deno install
      echo -e "${GREEN}✅ Dépendances et deno.lock synchronisés avec succès.${NC}"
    else
      echo -e "${YELLOW}⚠️  Deno non trouvé dans le PATH, synchronisation du lockfile ignorée.${NC}"
    fi
    echo -e "\n${GREEN}🎉 Version dev de shared déployée avec succès sur tous les services ciblés !${NC}"
  else
    echo -e "\n${GREEN}ℹ️  Mode lecture seule terminé. Relancez sans --dry-run pour appliquer.${NC}"
  fi

  exit 0
fi

# ==============================================================================
# Mode Standard : NCU avec cooldown de sécurité
# ==============================================================================
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
