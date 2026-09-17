#!/usr/bin/env bash
# 03-tune-baloo.sh: Disables Baloo file indexer and removes cached database files.

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

echo "==> [1/3] Disabling Baloo File Indexer"
BALOO_BIN=""
if command -v balooctl6 >/dev/null 2>&1; then
    BALOO_BIN="balooctl6"
elif command -v balooctl >/dev/null 2>&1; then
    BALOO_BIN="balooctl"
fi

if [ -n "${BALOO_BIN}" ]; then
    if [ "${DRY_RUN}" = true ]; then
        echo -e "    ${YELLOW}[DRY-RUN] Would run: ${BALOO_BIN} suspend && ${BALOO_BIN} disable && ${BALOO_BIN} purge${NC}"
    else
        ${BALOO_BIN} suspend 2>/dev/null || true
        ${BALOO_BIN} disable 2>/dev/null || true
        ${BALOO_BIN} purge 2>/dev/null || true
        echo -e "    ${GREEN}[OK] Disabled via ${BALOO_BIN}.${NC}"
    fi
else
    echo "    Baloo control binary not present."
fi

if systemctl --user is-active kde-baloo.service >/dev/null 2>&1; then
    if [ "${DRY_RUN}" = false ]; then
        systemctl --user stop kde-baloo.service || true
        systemctl --user mask kde-baloo.service || true
    fi
    echo -e "    ${GREEN}[OK] kde-baloo.service stopped and masked.${NC}"
fi

echo -e "\n==> [2/3] Writing Configuration (~/.config/baloofilerc)"
CONFIG_DIR="${HOME}/.config"
CONFIG_FILE="${CONFIG_DIR}/baloofilerc"

if [ "${DRY_RUN}" = true ]; then
    echo -e "    ${YELLOW}[DRY-RUN] Would set Indexing-Enabled=false in ${CONFIG_FILE}${NC}"
else
    mkdir -p "${CONFIG_DIR}"
    if [ -f "${CONFIG_FILE}" ]; then
        if grep -q "Indexing-Enabled=" "${CONFIG_FILE}"; then
            sed -i 's/^Indexing-Enabled=.*/Indexing-Enabled=false/' "${CONFIG_FILE}"
        else
            printf "\n[Basic Settings]\nIndexing-Enabled=false\n" >> "${CONFIG_FILE}"
        fi
    else
        cat << 'EOF' > "${CONFIG_FILE}"
[Basic Settings]
Indexing-Enabled=false

[General]
dbVersion=2
only basic indexing=false
EOF
    fi
    echo -e "    ${GREEN}[OK] Configuration updated.${NC}"
fi

echo -e "\n==> [3/3] Removing Cached Index Database"
BALOO_DATA="${HOME}/.local/share/baloo"
if [ -d "${BALOO_DATA}" ]; then
    SIZE=$(du -sh "${BALOO_DATA}" 2>/dev/null | cut -f1 || echo "0B")
    if [ "${DRY_RUN}" = true ]; then
        echo -e "    ${YELLOW}[DRY-RUN] Would remove ${BALOO_DATA} (${SIZE})${NC}"
    else
        rm -rf "${BALOO_DATA}"
        echo -e "    ${GREEN}[OK] Removed index cache (${SIZE} freed).${NC}"
    fi
else
    echo -e "    ${GREEN}[OK] No index database present.${NC}"
fi

echo -e "\n${GREEN}[OK] Baloo tuning complete.${NC}"
