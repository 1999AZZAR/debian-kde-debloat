# Restoration & Rollback Guide

If you ever need to restore Akonadi, KMail, KOrganizer, or the KDE PIM suite in the future, follow these simple steps to revert changes cleanly.

---

## 1. Remove the APT Pinning Restriction

To allow APT to install Akonadi packages again:

```bash
sudo rm -f /etc/apt/preferences.d/99-block-akonadi.pref
```

Update package lists to refresh policies:
```bash
sudo apt-get update
```

Verify that the pin is cleared:
```bash
apt-cache policy akonadi-server
# The Pin-Priority should no longer show -1
```

---

## 2. Reinstall KDE PIM Applications

You can reinstall only the specific applications you need, or the full suite:

### Option A: Install Specific Apps Only (Recommended)
If you only need KMail:
```bash
sudo apt-get install -y kmail akonadi-backend-sqlite
```

If you only need KOrganizer:
```bash
sudo apt-get install -y korganizer akonadi-backend-sqlite
```

### Option B: Reinstall Complete KDE PIM Suite
```bash
sudo apt-get install -y kdepim kmail korganizer kaddressbook akonadi-server
```

---

## 3. Re-enable Baloo File Indexer (Optional)

If you wish to turn desktop file indexing back on:

```bash
# Using balooctl (Plasma 5) or balooctl6 (Plasma 6)
balooctl6 enable
balooctl6 check

# Unmask the systemd user service
systemctl --user unmask kde-baloo.service
systemctl --user start kde-baloo.service
```

Update `~/.config/baloofilerc` to re-enable indexing:
```ini
[Basic Settings]
Indexing-Enabled=true
```

---

## 4. Verify Functionality

Start the Akonadi server manually or open KMail:
```bash
akonadictl start
akonadictl status
```

You should see all agents registered and active.
