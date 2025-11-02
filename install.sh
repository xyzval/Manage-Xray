#!/bin/bash
# =========================================================
# Manage-Xray Auto Installer by xyzval
# Supports: Ubuntu 20.04–25.10 & Debian 11–13
# =========================================================

clear
echo "=========================================="
echo "   Manage-Xray Auto Installer (xyzval)"
echo "=========================================="
echo ""

# --- Check root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Jalankan sebagai root!"
    exit 1
fi

# --- Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "🧩 Detected OS: $NAME $VERSION"
else
    echo "❌ Tidak bisa mendeteksi OS."
    exit 1
fi

# --- Update system
echo "🔄 Updating system packages..."
apt update -y >/dev/null 2>&1
apt install -y curl jq unzip tar >/dev/null 2>&1

# --- Download Manage-Xray script (from xyzval repo)
echo "⬇️  Mengunduh skrip Manage-Xray dari repo xyzval..."
curl -L -o /usr/local/bin/xray-downgrade \
https://raw.githubusercontent.com/xyzval/Manage-Xray/main/xray.sh

# --- Permission
chmod +x /usr/local/bin/xray-downgrade

# --- Verification
if [ -f /usr/local/bin/xray-downgrade ]; then
    echo "✅ Instalasi selesai!"
    echo ""
    echo "Gunakan perintah berikut untuk downgrade Xray:"
    echo "  sudo xray-downgrade v1.8.5"
    echo ""
    echo "Atau tampilkan daftar versi yang tersedia:"
    echo "  sudo xray-downgrade list"
    echo ""
else
    echo "❌ Gagal menginstal skrip!"
    exit 1
fi
