#!/usr/bin/env bash
# ==============================================================================
# Script: 04-purge-bloat-apps.sh
# Description: Removes auxiliary bloat applications commonly pre-installed with KDE
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
for arg in "$@"; do
    if [ "${arg}" == "--dry-run" ] || [ "${arg}" == "-d" ]; then
        DRY_RUN=true
    fi
done

if [ "$EUID" -ne 0 ] && [ "${DRY_RUN}" = false ]; then
    SUDO="sudo"
else
    SUDO=""
fi

echo -e "${BLUE}==> [1/2] Identifying Auxiliary KDE Bloat Packages...${NC}"
AUX_BLOAT=(
    "akregator"      # RSS reader (usually pulls kdepim libs)
    "dragonplayer"   # Legacy media player
    "sweeper"        # Redundant system cleaner
    "kamera"         # Digital camera configure tool
    "kaddressbook"   # Redundant contacts app
    "knotes"         # Legacy sticky notes (pulls Akonadi)
    "kmines"         # Games (if installed)
    "kpat"
    "kmahjongg"
    "ksudoku"
)

FOUND_APPS=()
for app in "${AUX_BLOAT[@]}"; do
    if dpkg -l "${app}" 2>/dev/null | grep -q "^ii"; then
        FOUND_APPS+=("${app}")
    fi
done

if [ ${#FOUND_APPS[@]} -gt 0 ]; then
    echo "    Detected bloat packages: ${FOUND_APPS[*]}"
    echo -e "\n${BLUE}==> [2/2] Purging Packages...${NC}"
    if [ "${DRY_RUN}" = true ]; then
        echo -e "${YELLOW}    [DRY-RUN] Would run: apt-get purge -y ${FOUND_APPS[*]}${NC}"
        echo -e "${YELLOW}    [DRY-RUN] Would run: apt-get autoremove --purge -y${NC}"
    else
        ${SUDO} apt-get purge -y "${FOUND_APPS[@]}"
        ${SUDO} apt-get autoremove --purge -y
        echo -e "${GREEN}✔️  Auxiliary bloat packages successfully purged.${NC}"
    fi
else
    echo -e "    ${GREEN}✔️  No auxiliary bloatware detected.${NC}"
fi

echo -e "\n${GREEN}✔️  Auxiliary cleanup complete!${NC}"
