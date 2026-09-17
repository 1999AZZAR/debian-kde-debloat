#!/usr/bin/env bash
# ==============================================================================
# Script: 01-preflight-check.sh
# Description: Inspects Debian KDE Plasma environment before debloating
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==> [1/4] Checking Distribution & Desktop Environment...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "    OS Detected: ${PRETTY_NAME:-Linux}"
else
    echo -e "${RED}❌ Unable to identify distribution (/etc/os-release missing).${NC}"
    exit 1
fi

CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-unknown}"
echo "    Desktop Environment: ${CURRENT_DESKTOP}"
if [[ "${CURRENT_DESKTOP}" != *"KDE"* ]]; then
    echo -e "${YELLOW}⚠️  Warning: Active desktop does not appear to be KDE Plasma.${NC}"
fi

echo -e "\n${BLUE}==> [2/4] Inspecting Akonadi & KDE PIM Packages...${NC}"
PIM_PKGS=(
    "akonadi-server"
    "kdepim-runtime"
    "kmail"
    "korganizer"
    "kaddressbook"
    "kalendarac"
    "akregator"
    "akonadi-backend-sqlite"
    "akonadi-backend-mysql"
    "akonadi-backend-postgresql"
)

FOUND_PIM=0
for pkg in "${PIM_PKGS[@]}"; do
    if dpkg -l "${pkg}" 2>/dev/null | grep -q "^ii"; then
        echo -e "    ${YELLOW}• ${pkg} is installed${NC}"
        FOUND_PIM=$((FOUND_PIM + 1))
    fi
done

if [ "${FOUND_PIM}" -eq 0 ]; then
    echo -e "    ${GREEN}✔️  No primary Akonadi/PIM packages installed.${NC}"
else
    echo -e "    ${YELLOW}⚠️  Found ${FOUND_PIM} target packages installed.${NC}"
fi

echo -e "\n${BLUE}==> [3/4] Inspecting Active Daemons & Memory Footprint...${NC}"
AKONADI_PIDS=$(pgrep -i akonadi || true)
if [ -n "${AKONADI_PIDS}" ]; then
    AKONADI_RAM=$(ps -o rss= -p ${AKONADI_PIDS} 2>/dev/null | awk '{sum+=$1} END {printf "%.1f MB", sum/1024}')
    echo -e "    ${YELLOW}⚠️  Akonadi processes running. Consuming: ${AKONADI_RAM}${NC}"
else
    echo -e "    ${GREEN}✔️  Akonadi daemons: inactive (0 MB used).${NC}"
fi

BALOO_PIDS=$(pgrep -i baloo_file || true)
if [ -n "${BALOO_PIDS}" ]; then
    BALOO_RAM=$(ps -o rss= -p ${BALOO_PIDS} 2>/dev/null | awk '{sum+=$1} END {printf "%.1f MB", sum/1024}')
    echo -e "    ${YELLOW}⚠️  Baloo file indexer running. Consuming: ${BALOO_RAM}${NC}"
else
    echo -e "    ${GREEN}✔️  Baloo indexer: inactive.${NC}"
fi

echo -e "\n${BLUE}==> [4/4] Verifying Core KDE Plasma Desktop Protection...${NC}"
CORE_PKGS=("plasma-desktop" "plasma-workspace")
PROTECTED=true
for core in "${CORE_PKGS[@]}"; do
    if dpkg -l "${core}" 2>/dev/null | grep -q "^ii"; then
        MARK_STATUS=$(apt-mark showmanual "${core}" 2>/dev/null || true)
        if [ -n "${MARK_STATUS}" ]; then
            echo -e "    ${GREEN}✔️  ${core} is marked manual (protected from autoremove).${NC}"
        else
            echo -e "    ${YELLOW}⚠️  ${core} is marked auto! Will be marked manual before debloating.${NC}"
            PROTECTED=false
        fi
    fi
done

echo -e "\n${GREEN}✔️  Preflight inspection complete.${NC}"
