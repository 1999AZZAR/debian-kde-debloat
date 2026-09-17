# Rollback and Recovery Guide

Procedures to restore Akonadi, KDE PIM applications, and Baloo file indexing.

---

## 1. Remove APT Pinning

Remove the preference file that restricts package installation:

```bash
sudo rm -f /etc/apt/preferences.d/99-block-akonadi.pref
sudo apt-get update
```

Confirm that the pin is removed:
```bash
apt-cache policy akonadi-server
```
The output should no longer report `Pin-Priority: -1`.

---

## 2. Reinstall Packages

### Single Applications
To reinstall specific applications without the entire PIM suite:

```bash
# KMail
sudo apt-get install -y kmail akonadi-backend-sqlite

# KOrganizer
sudo apt-get install -y korganizer akonadi-backend-sqlite
```

### Complete PIM Suite
To reinstall all standard KDE PIM applications:

```bash
sudo apt-get install -y kdepim kmail korganizer kaddressbook akonadi-server
```

---

## 3. Re-enable Baloo File Indexing (Optional)

If desktop search indexing is required:

```bash
# Enable indexer
if command -v balooctl6 >/dev/null; then
    balooctl6 enable
elif command -v balooctl >/dev/null; then
    balooctl enable
fi

# Unmask and start systemd user unit
systemctl --user unmask kde-baloo.service
systemctl --user start kde-baloo.service
```

Set `Indexing-Enabled=true` in `~/.config/baloofilerc`:
```ini
[Basic Settings]
Indexing-Enabled=true
```

---

## 4. Verification

Start the Akonadi service and verify agent status:

```bash
akonadictl start
akonadictl status
```
