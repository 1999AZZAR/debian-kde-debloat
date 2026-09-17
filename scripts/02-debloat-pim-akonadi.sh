#!/usr/bin/env bash
# 02-debloat-pim-akonadi.sh: Purges Akonadi and KDE PIM suite packages and removes stale data.

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

echo "==> [1/4] Protecting Core KDE Plasma Desktop Packages"
CORE_PKGS=("plasma-desktop" "plasma-workspace")
if dpkg -l "kde-plasma-desktop" 2>/dev/null | grep -q "^ii"; then
    CORE_PKGS+=("kde-plasma-desktop")
fi

if [ "${DRY_RUN}" = false ]; then
    ${SUDO} apt-mark manual "${CORE_PKGS[@]}" >/dev/null
    echo -e "    ${GREEN}[OK] Core desktop packages marked manual.${NC}"
else
    echo -e "    ${YELLOW}[DRY-RUN] Would mark manual: ${CORE_PKGS[*]}${NC}"
fi

echo -e "\n==> [2/4] Stopping Running Akonadi Daemons"
if command -v akonadictl >/dev/null 2>&1; then
    akonadictl stop 2>/dev/null || true
fi
for proc in akonadiserver akonadi_control akonadi_indexing_agent akonadi_archivemail_agent akonadi_mailfilter_agent; do
    pkill -u "$USER" -x "${proc}" 2>/dev/null || true
done
echo -e "    ${GREEN}[OK] Daemons stopped.${NC}"

echo -e "\n==> [3/4] Purging Akonadi and KDE PIM Packages"
TARGET_PURGE=(
    "akonadi-server"
    "kdepim-runtime"
    "kmail"
    "korganizer"
    "kaddressbook"
    "kalendarac"
    "akonadi-backend-sqlite"
    "akonadi-backend-mysql"
    "akonadi-backend-postgresql"
    "pim-data-exporter"
    "pim-sieve-editor"
    "mbox-importer"
    "accountwizard"
    "kdepim-themeeditors"
    "kdepim-addons"
)

INSTALLED_TARGETS=()
for pkg in "${TARGET_PURGE[@]}"; do
    if dpkg -l "${pkg}" 2>/dev/null | grep -q "^ii"; then
        INSTALLED_TARGETS+=("${pkg}")
    fi
done

if [ ${#INSTALLED_TARGETS[@]} -gt 0 ]; then
    echo "    Packages to purge: ${INSTALLED_TARGETS[*]}"
    if [ "${DRY_RUN}" = true ]; then
        echo -e "    ${YELLOW}[DRY-RUN] Would run: apt-get purge -y ${INSTALLED_TARGETS[*]}${NC}"
        echo -e "    ${YELLOW}[DRY-RUN] Would run: apt-get autoremove --purge -y${NC}"
    else
        ${SUDO} apt-get purge -y "${INSTALLED_TARGETS[@]}"
        ${SUDO} apt-get autoremove --purge -y
        echo -e "    ${GREEN}[OK] Packages purged.${NC}"
    fi
else
    echo -e "    ${GREEN}[OK] No target PIM packages installed.${NC}"
fi

echo -e "\n==> [4/4] Removing Stale User Runtime Directories"
CLEANUP_DIRS=(
    "${HOME}/.local/share/akonadi"
    "${HOME}/.config/akonadi"
    "${HOME}/.local/share/kmail2"
    "${HOME}/.local/share/contacts"
    "${HOME}/.local/share/korganizer"
)

for dir in "${CLEANUP_DIRS[@]}"; do
    if [ -d "${dir}" ]; then
        if [ "${DRY_RUN}" = true ]; then
            echo -e "    ${YELLOW}[DRY-RUN] Would remove: ${dir}${NC}"
        else
            rm -rf "${dir}"
            echo -e "    ${GREEN}[REMOVED] ${dir}${NC}"
        fi
    fi
done

echo -e "\n${GREEN}[OK] Akonadi and KDE PIM removal complete.${NC}"
