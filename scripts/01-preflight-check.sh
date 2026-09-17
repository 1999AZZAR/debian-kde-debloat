#!/usr/bin/env bash
# 01-preflight-check.sh: Inspects system state, installed PIM packages, and Plasma protection.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo "==> [1/4] Checking Distribution and Desktop Environment"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "    OS: ${PRETTY_NAME:-Linux}"
else
    echo -e "    ${RED}[FAIL] Cannot identify distribution (/etc/os-release missing).${NC}"
    exit 1
fi

CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-unknown}"
echo "    Desktop: ${CURRENT_DESKTOP}"
if [[ "${CURRENT_DESKTOP}" != *"KDE"* ]]; then
    echo -e "    ${YELLOW}[WARN] Active desktop session is not KDE Plasma.${NC}"
fi

echo -e "\n==> [2/4] Inspecting Akonadi and KDE PIM Packages"
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
        echo -e "    ${YELLOW}[INSTALLED] ${pkg}${NC}"
        FOUND_PIM=$((FOUND_PIM + 1))
    fi
done

if [ "${FOUND_PIM}" -eq 0 ]; then
    echo -e "    ${GREEN}[OK] No primary Akonadi or PIM packages found.${NC}"
else
    echo -e "    ${YELLOW}[INFO] Found ${FOUND_PIM} target packages installed.${NC}"
fi

echo -e "\n==> [3/4] Inspecting Running Daemons"
AKONADI_PIDS=$(pgrep -i akonadi || true)
if [ -n "${AKONADI_PIDS}" ]; then
    AKONADI_RAM=$(ps -o rss= -p ${AKONADI_PIDS} 2>/dev/null | awk '{sum+=$1} END {printf "%.1f MB", sum/1024}')
    echo -e "    ${YELLOW}[RUNNING] Akonadi processes active (${AKONADI_RAM} RSS).${NC}"
else
    echo -e "    ${GREEN}[OK] Akonadi daemons inactive.${NC}"
fi

BALOO_PIDS=$(pgrep -i baloo_file || true)
if [ -n "${BALOO_PIDS}" ]; then
    BALOO_RAM=$(ps -o rss= -p ${BALOO_PIDS} 2>/dev/null | awk '{sum+=$1} END {printf "%.1f MB", sum/1024}')
    echo -e "    ${YELLOW}[RUNNING] Baloo file indexer active (${BALOO_RAM} RSS).${NC}"
else
    echo -e "    ${GREEN}[OK] Baloo indexer inactive.${NC}"
fi

echo -e "\n==> [4/4] Verifying Core KDE Plasma Desktop Protection"
CORE_PKGS=("plasma-desktop" "plasma-workspace")
for core in "${CORE_PKGS[@]}"; do
    if dpkg -l "${core}" 2>/dev/null | grep -q "^ii"; then
        MARK_STATUS=$(apt-mark showmanual "${core}" 2>/dev/null || true)
        if [ -n "${MARK_STATUS}" ]; then
            echo -e "    ${GREEN}[OK] ${core} is marked manual (protected from autoremove).${NC}"
        else
            echo -e "    ${YELLOW}[WARN] ${core} is marked auto. Will be set to manual during cleanup.${NC}"
        fi
    fi
done

echo -e "\n${GREEN}[OK] Preflight inspection complete.${NC}"
