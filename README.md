# Debian KDE Plasma Debloat Toolkit

Scripts and documentation for removing Akonadi, KDE PIM, Baloo, and related packages from Debian systems running KDE Plasma without breaking the desktop environment.

Tested on Debian 12 (Bookworm) with KDE Plasma 5 and Debian 13 (Trixie) with KDE Plasma 6.

---

## Background

Installing KDE Plasma via Debian tasks (`kde-desktop`, `kde-standard`, or `kde-full`) pulls in the KDE PIM suite (`kmail`, `korganizer`, `kaddressbook`, and related packages).

Even if these applications are never launched or configured, KDE starts Akonadi on login:
- A user-space database server (SQLite or MariaDB) and several background indexing and synchronization agents.
- Persistent memory usage of approximately 300 MB to 600 MB at idle.
- Background disk writes for database journals and search index updates.

KDE Plasma core components (`plasma-desktop`, `plasma-workspace`, KWin, Dolphin, and System Settings) do not depend on Akonadi. Only the PIM applications and optional calendar event integration in the digital clock widget use it.

This toolkit provides standalone scripts and manual instructions to:
1. Mark core desktop packages as manually installed to protect them from `apt autoremove`.
2. Purge Akonadi, KDE PIM applications, and their backends.
3. Disable Baloo file indexing and clear its index cache.
4. Remove residual user configuration and database directories.
5. Configure APT pinning to prevent Akonadi from being reinstalled during future upgrades.

---

## Usage

### Option 1: Automated Script

Clone the repository and inspect the planned actions using dry-run mode:

```bash
git clone https://github.com/your-username/debian-kde-debloat.git # or local path
cd debian-kde-debloat
chmod +x scripts/*.sh

# Preview changes without modifying the system
./scripts/debloat-all.sh --dry-run

# Apply changes
./scripts/debloat-all.sh
```

### Option 2: Modular Scripts

Run individual scripts as needed:

| Script | Action | Sudo Required |
| :--- | :--- | :---: |
| `scripts/01-preflight-check.sh` | Checks system desktop, installed PIM packages, active daemons, and package hold status. | No |
| `scripts/02-debloat-pim-akonadi.sh` | Marks desktop manual, stops daemons, purges Akonadi/PIM, and removes `~/.local/share/akonadi`. | Yes |
| `scripts/03-tune-baloo.sh` | Disables Baloo indexer, sets `Indexing-Enabled=false` in `~/.config/baloofilerc`, and clears index cache. | No |
| `scripts/04-purge-bloat-apps.sh` | Purges auxiliary media and utility packages (`dragonplayer`, `sweeper`, `kamera`, `akregator`). | Yes |
| `scripts/05-prevent-reinstall.sh` | Installs APT pin preference to prevent automatic reinstallation. | Yes |

---

## Manual Procedure

If you prefer running commands manually without executing scripts, follow these steps in order.

### 1. Protect Core Desktop Packages

Ensure APT does not remove core desktop packages when autoremoving orphaned PIM dependencies:

```bash
sudo apt-mark manual plasma-desktop plasma-workspace kde-plasma-desktop
```

### 2. Stop Running Akonadi Daemons

```bash
command -v akonadictl >/dev/null && akonadictl stop || true
for proc in akonadiserver akonadi_control akonadi_indexing_agent akonadi_archivemail_agent akonadi_mailfilter_agent; do
    pkill -u "$USER" -x "$proc" 2>/dev/null || true
done
```

### 3. Purge Akonadi and KDE PIM

```bash
sudo apt-get purge -y \
  akonadi-server \
  kdepim-runtime \
  kmail \
  korganizer \
  kaddressbook \
  kalendarac \
  akonadi-backend-sqlite \
  akonadi-backend-mysql \
  akonadi-backend-postgresql \
  pim-data-exporter \
  pim-sieve-editor \
  mbox-importer \
  accountwizard \
  kdepim-themeeditors \
  kdepim-addons

sudo apt-get autoremove --purge -y
```

### 4. Remove User Data and Database Files

```bash
rm -rf ~/.local/share/akonadi
rm -rf ~/.config/akonadi
rm -rf ~/.local/share/kmail2
rm -rf ~/.local/share/contacts
rm -rf ~/.local/share/korganizer
```

### 5. Disable Baloo File Indexer

```bash
# Disable indexing via CLI
if command -v balooctl6 >/dev/null; then
    balooctl6 disable && balooctl6 purge
elif command -v balooctl >/dev/null; then
    balooctl disable && balooctl purge
fi

# Stop and mask systemd user unit if present
systemctl --user stop kde-baloo.service 2>/dev/null || true
systemctl --user mask kde-baloo.service 2>/dev/null || true

# Write configuration
mkdir -p ~/.config
cat << 'EOF' > ~/.config/baloofilerc
[Basic Settings]
Indexing-Enabled=false

[General]
dbVersion=2
only basic indexing=false
EOF

# Remove existing database file
rm -rf ~/.local/share/baloo
```

### 6. Remove Auxiliary Packages (Optional)

```bash
sudo apt-get purge -y dragonplayer sweeper kamera akregator
sudo apt-get autoremove --purge -y
```

### 7. Block Reinstallation via APT Pinning

Debian packages sometimes list `akonadi-server` or `kdepim-runtime` as recommended dependencies. To prevent them from installing during future upgrades:

```bash
sudo tee /etc/apt/preferences.d/99-block-akonadi.pref << 'EOF'
Package: akonadi-server akonadi-backend-sqlite akonadi-backend-mysql akonadi-backend-postgresql kdepim-runtime kmail korganizer kaddressbook kalendarac akregator
Pin: release *
Pin-Priority: -1
EOF
```

Verify the pinning policy:
```bash
apt-cache policy akonadi-server
# Verify that Pin-Priority is -1
```

---

## Verification and Resource Impact

On a freshly installed Debian 13 (Trixie) system running KDE Plasma 6:
- **Baseline idle RAM**: ~1.4 GB with Akonadi and Baloo active.
- **Debloated idle RAM**: ~850 MB to 950 MB.
- **Running processes**: Eliminated 8 to 12 background daemon threads (`akonadiserver`, `baloo_file`, and PIM agents).
- **Desktop functionality**: Plasma panels, system settings, application launcher, and digital clock retain full functionality.

---

## Documentation

- [docs/akonadi-deep-dive.md](docs/akonadi-deep-dive.md): Technical analysis of Akonadi architecture, daemon structure, and dependencies.
- [docs/recovery-guide.md](docs/recovery-guide.md): Instructions to revert changes and reinstall KDE PIM applications.

---

## License

MIT
