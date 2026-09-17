#!/usr/bin/env bash
# ==============================================================================
# Script: 03-tune-baloo.sh
# Description: Disables Baloo file indexer and purges index database to save I/O
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

echo -e "${BLUE}==> [1/3] Disabling Baloo File Indexer...${NC}"
BALOO_BIN=""
if command -v balooctl6 >/dev/null 2>&1; then
    BALOO_BIN="balooctl6"
elif command -v balooctl >/dev/null 2>&1; then
    BALOO_BIN="balooctl"
fi

if [ -n "${BALOO_BIN}" ]; then
    if [ "${DRY_RUN}" = true ]; then
        echo -e "${YELLOW}    [DRY-RUN] Would run: ${BALOO_BIN} suspend && ${BALOO_BIN} disable${NC}"
    else
        ${BALOO_BIN} suspend 2>/dev/null || true
        ${BALOO_BIN} disable 2>/dev/null || true
        ${BALOO_BIN} purge 2>/dev/null || true
        echo -e "${GREEN}✔️  Baloo indexer disabled via ${BALOO_BIN}.${NC}"
    fi
else
    echo "    Baloo control binary not found (already inactive or uninstalled)."
fi

# Stop systemd user service if present
if systemctl --user is-active kde-baloo.service >/dev/null 2>&1; then
    if [ "${DRY_RUN}" = false ]; then
        systemctl --user stop kde-baloo.service || true
        systemctl --user mask kde-baloo.service || true
    fi
    echo -e "${GREEN}✔️  kde-baloo user service stopped and masked.${NC}"
fi

echo -e "\n${BLUE}==> [2/3] Applying Persistent Configuration (~/.config/baloofilerc)...${NC}"
CONFIG_DIR="${HOME}/.config"
CONFIG_FILE="${CONFIG_DIR}/baloofilerc"

if [ "${DRY_RUN}" = true ]; then
    echo -e "${YELLOW}    [DRY-RUN] Would set Indexing-Enabled=false in ${CONFIG_FILE}${NC}"
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
    echo -e "${GREEN}✔️  Indexing-Enabled=false written to ${CONFIG_FILE}.${NC}"
fi

echo -e "\n${BLUE}==> [3/3] Purging Cached Baloo Index Database...${NC}"
BALOO_DATA="${HOME}/.local/share/baloo"
if [ -d "${BALOO_DATA}" ]; then
    SIZE=$(du -sh "${BALOO_DATA}" 2>/dev/null | cut -f1 || echo "0B")
    if [ "${DRY_RUN}" = true ]; then
        echo -e "${YELLOW}    [DRY-RUN] Would remove ${BALOO_DATA} (${SIZE})${NC}"
    else
        rm -rf "${BALOO_DATA}"
        echo -e "${GREEN}✔️  Removed stale Baloo index data (${SIZE} freed).${NC}"
    fi
else
    echo -e "${GREEN}✔️  No Baloo index database found.${NC}"
fi

echo -e "\n${GREEN}✔️  Baloo tuning complete!${NC}"
