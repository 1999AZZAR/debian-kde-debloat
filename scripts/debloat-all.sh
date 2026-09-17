#!/usr/bin/env bash
# ==============================================================================
# Script: debloat-all.sh
# Description: Master orchestrator to fully debloat Debian KDE Plasma
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
for arg in "$@"; do
    if [ "${arg}" == "--dry-run" ] || [ "${arg}" == "-d" ]; then
        DRY_RUN=true
    fi
done

echo -e "${BOLD}${BLUE}======================================================${NC}"
echo -e "${BOLD}${BLUE}      Debian KDE Plasma Debloat Toolkit Master        ${NC}"
echo -e "${BOLD}${BLUE}======================================================${NC}"

if [ "${DRY_RUN}" = true ]; then
    echo -e "${YELLOW}Mode: DRY-RUN (Previewing actions without modifying system)${NC}\n"
    EXTRA_FLAGS="--dry-run"
else
    echo -e "${GREEN}Mode: LIVE EXECUTION${NC}\n"
    EXTRA_FLAGS=""
fi

# Step 1: Preflight
echo -e "${BOLD}--- STEP 1: PREFLIGHT INSPECTION ---${NC}"
bash "${SCRIPT_DIR}/01-preflight-check.sh"

echo -e "\n${BOLD}--- STEP 2: PURGING AKONADI & KDE PIM SUITE ---${NC}"
bash "${SCRIPT_DIR}/02-debloat-pim-akonadi.sh" ${EXTRA_FLAGS}

echo -e "\n${BOLD}--- STEP 3: DISABLING BALOO FILE INDEXER ---${NC}"
bash "${SCRIPT_DIR}/03-tune-baloo.sh" ${EXTRA_FLAGS}

echo -e "\n${BOLD}--- STEP 4: PURGING AUXILIARY BLOATWARE ---${NC}"
bash "${SCRIPT_DIR}/04-purge-bloat-apps.sh" ${EXTRA_FLAGS}

echo -e "\n${BOLD}--- STEP 5: PREVENTING REINSTALLATION ---${NC}"
bash "${SCRIPT_DIR}/05-prevent-reinstall.sh" ${EXTRA_FLAGS}

echo -e "\n${BOLD}${GREEN}======================================================${NC}"
echo -e "${BOLD}${GREEN}  🎉 All debloat stages finished successfully!       ${NC}"
echo -e "${BOLD}${GREEN}======================================================${NC}"
echo -e "Your KDE Plasma environment is now lightweight, bloat-free,"
echo -e "and shielded against Akonadi background memory consumption.\n"
