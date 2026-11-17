#!/usr/bin/env bash
# ==============================================================================
# Script: check-updates.sh
# Description: Lance update-dependencies.sh en mode dry-run (lecture seule).
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/update-dependencies.sh" --dry-run "$@"
