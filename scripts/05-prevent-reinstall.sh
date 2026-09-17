#!/usr/bin/env bash
# ==============================================================================
# Script: 05-prevent-reinstall.sh
# Description: Installs APT pin preferences to prevent Akonadi from returning
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "${SCRIPT_DIR}")"
PREF_SRC="${REPO_DIR}/configs/apt-preferences/99-block-akonadi.pref"
PREF_DEST="/etc/apt/preferences.d/99-block-akonadi.pref"

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

echo -e "${BLUE}==> [1/2] Installing APT Pin Preference...${NC}"
if [ ! -f "${PREF_SRC}" ]; then
    echo -e "${RED}❌ Missing source preference file: ${PREF_SRC}${NC}"
    exit 1
fi

if [ "${DRY_RUN}" = true ]; then
    echo -e "${YELLOW}    [DRY-RUN] Would copy ${PREF_SRC} to ${PREF_DEST}${NC}"
else
    ${SUDO} mkdir -p "/etc/apt/preferences.d"
    ${SUDO} cp "${PREF_SRC}" "${PREF_DEST}"
    ${SUDO} chmod 644 "${PREF_DEST}"
    echo -e "${GREEN}✔️  Installed ${PREF_DEST}.${NC}"
fi

echo -e "\n${BLUE}==> [2/2] Verifying APT Pin Policy...${NC}"
if [ "${DRY_RUN}" = false ]; then
    PIN_CHECK=$(apt-cache policy akonadi-server 2>/dev/null | grep -i "Pin:" || true)
    if [ -n "${PIN_CHECK}" ]; then
        echo -e "    ${PIN_CHECK}"
        echo -e "${GREEN}✔️  Akonadi server is now locked with Pin-Priority -1 (Never Install).${NC}"
    else
        echo -e "${YELLOW}⚠️  Pin check output empty. Please verify manual apt-cache policy.${NC}"
    fi
else
    echo -e "${YELLOW}    [DRY-RUN] Verification skipped.${NC}"
fi

echo -e "\n${GREEN}✔️  Future APT upgrades are now protected from bloat regression!${NC}"
