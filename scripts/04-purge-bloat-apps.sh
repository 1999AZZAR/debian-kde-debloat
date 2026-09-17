#!/usr/bin/env bash
# 04-purge-bloat-apps.sh: Removes auxiliary media and utility packages commonly bundled with KDE.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo "==> [1/2] Checking Auxiliary Packages"
AUX_BLOAT=(
    "akregator"
    "dragonplayer"
    "sweeper"
    "kamera"
    "knotes"
    "kmines"
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
    echo "    Detected: ${FOUND_APPS[*]}"
    echo -e "\n==> [2/2] Purging Packages"
    if [ "${DRY_RUN}" = true ]; then
        echo -e "    ${YELLOW}[DRY-RUN] Would run: apt-get purge -y ${FOUND_APPS[*]}${NC}"
        echo -e "    ${YELLOW}[DRY-RUN] Would run: apt-get autoremove --purge -y${NC}"
    else
        ${SUDO} apt-get purge -y "${FOUND_APPS[@]}"
        ${SUDO} apt-get autoremove --purge -y
        echo -e "    ${GREEN}[OK] Packages purged.${NC}"
    fi
else
    echo -e "    ${GREEN}[OK] No auxiliary packages detected.${NC}"
fi

echo -e "\n${GREEN}[OK] Auxiliary cleanup complete.${NC}"
