#!/usr/bin/env bash
# debloat-all.sh: Runs all debloat stages in sequence.

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
for arg in "$@"; do
    if [ "${arg}" == "--dry-run" ] || [ "${arg}" == "-d" ]; then
        DRY_RUN=true
    fi
done

if [ "${DRY_RUN}" = true ]; then
    echo -e "${YELLOW}Running in dry-run mode (previewing actions without modifying system)${NC}\n"
    EXTRA_FLAGS="--dry-run"
else
    EXTRA_FLAGS=""
fi

echo -e "${BOLD}[1/5] Preflight inspection${NC}"
bash "${SCRIPT_DIR}/01-preflight-check.sh"

echo -e "\n${BOLD}[2/5] Purging Akonadi and KDE PIM suite${NC}"
bash "${SCRIPT_DIR}/02-debloat-pim-akonadi.sh" ${EXTRA_FLAGS}

echo -e "\n${BOLD}[3/5] Disabling Baloo file indexer${NC}"
bash "${SCRIPT_DIR}/03-tune-baloo.sh" ${EXTRA_FLAGS}

echo -e "\n${BOLD}[4/5] Purging auxiliary bloatware${NC}"
bash "${SCRIPT_DIR}/04-purge-bloat-apps.sh" ${EXTRA_FLAGS}

echo -e "\n${BOLD}[5/5] Configuring APT pinning${NC}"
bash "${SCRIPT_DIR}/05-prevent-reinstall.sh" ${EXTRA_FLAGS}

echo -e "\n${GREEN}All debloat stages completed successfully.${NC}"
