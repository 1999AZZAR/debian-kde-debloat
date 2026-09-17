#!/usr/bin/env bash
# 05-prevent-reinstall.sh: Installs APT pin preference to prevent Akonadi reinstallation.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo "==> [1/2] Installing APT Pin Preference"
if [ ! -f "${PREF_SRC}" ]; then
    echo -e "    ${RED}[FAIL] Missing source file: ${PREF_SRC}${NC}"
    exit 1
fi

if [ "${DRY_RUN}" = true ]; then
    echo -e "    ${YELLOW}[DRY-RUN] Would copy ${PREF_SRC} to ${PREF_DEST}${NC}"
else
    ${SUDO} mkdir -p "/etc/apt/preferences.d"
    ${SUDO} cp "${PREF_SRC}" "${PREF_DEST}"
    ${SUDO} chmod 644 "${PREF_DEST}"
    echo -e "    ${GREEN}[OK] Installed ${PREF_DEST}.${NC}"
fi

echo -e "\n==> [2/2] Verifying APT Pin Policy"
if [ "${DRY_RUN}" = false ]; then
    PIN_CHECK=$(apt-cache policy akonadi-server 2>/dev/null | grep -i "Pin:" || true)
    if [ -n "${PIN_CHECK}" ]; then
        echo "    ${PIN_CHECK}"
        echo -e "    ${GREEN}[OK] akonadi-server pin active (Pin-Priority: -1).${NC}"
    else
        echo -e "    ${YELLOW}[WARN] Could not read pin policy from apt-cache.${NC}"
    fi
else
    echo -e "    ${YELLOW}[DRY-RUN] Verification skipped.${NC}"
fi

echo -e "\n${GREEN}[OK] Preference configuration complete.${NC}"
