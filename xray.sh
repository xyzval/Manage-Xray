#!/bin/bash
# =========================================================
# Xray Manager by xyzval
# Auto Upgrade / Downgrade Xray-core
# =========================================================

REPO="XTLS/Xray-core"
INSTALL_DIR="/usr/local/bin"
SERVICE_NAME="xray"
BACKUP_DIR="$INSTALL_DIR"
DATE=$(date +%Y%m%d_%H%M%S)

# --- Fungsi: deteksi arsitektur
detect_arch() {
    case "$(uname -m)" in
        x86_64) ARCH="64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="arm32-v7a" ;;
        *) echo "❌ Arsitektur tidak didukung."; exit 1 ;;
    esac
}

# --- Fungsi: ambil versi terbaru dari GitHub
get_latest_version() {
    curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r .tag_name
}

# --- Fungsi: download & pasang Xray
install_xray() {
    VERSION=$1
    FORMAT=${2:-zip}

    detect_arch
    FILE="xray-linux-${ARCH}.${FORMAT}"
    URL="https://github.com/${REPO}/releases/download/${VERSION}/${FILE}"

    echo "🔄 Menyiapkan Xray versi ${VERSION} (${ARCH} / ${FORMAT})"
    echo "📥 Mengunduh: ${URL}"

    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR || exit 1

    curl -L -O "$URL" || { echo "❌ Gagal mengunduh binary."; exit 1; }

    if [ "${FORMAT}" = "zip" ]; then
        unzip "$FILE" >/dev/null 2>&1
    else
        tar -xf "$FILE"
    fi

    if [ -f "${INSTALL_DIR}/xray" ]; then
        echo "💾 Membackup versi lama..."
        mv "${INSTALL_DIR}/xray" "${BACKUP_DIR}/xray.bak.${DATE}"
    fi

    mv xray "${INSTALL_DIR}/xray"
    chmod +x "${INSTALL_DIR}/xray"

    echo "🛠️  Mengganti binary dan memulai ulang layanan..."
    systemctl stop ${SERVICE_NAME} >/dev/null 2>&1
    systemctl start ${SERVICE_NAME}

    echo "✅ Selesai! Xray kini berjalan di versi:"
    ${INSTALL_DIR}/xray version
}

# --- Main Program
if [ "$EUID" -ne 0 ]; then
    echo "⚠️ Jalankan sebagai root!"
    exit 1
fi

detect_arch
LATEST=$(get_latest_version)

echo "=========================================="
echo "  Manage-Xray by xyzval"
echo "=========================================="
echo ""
echo "💡 Versi terbaru yang tersedia: ${LATEST}"
echo ""

read -p "Masukkan versi (kosongkan untuk ${LATEST}): " VERSION
VERSION=${VERSION:-$LATEST}

read -p "Gunakan format (zip/tar.xz) [zip]: " FORMAT
FORMAT=${FORMAT:-zip}

install_xray "${VERSION}" "${FORMAT}"
}

# Cek apakah user root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Harus dijalankan sebagai root (gunakan sudo)"
   exit 1
fi

# Jika argumen pertama adalah 'list', tampilkan daftar versi
if [[ "$1" == "list" ]]; then
    echo "📋 Daftar versi Xray tersedia (terbaru di atas):"
    curl -s "$API_URL" | jq -r '.[].tag_name' | grep '^v[0-9]' | head -20
    exit 0
fi

# Ambil argumen
VERSION="$1"
ARCH="${2:-$DEFAULT_ARCH}"
FORMAT="${3:-$DEFAULT_FORMAT}"

# Validasi versi
if [[ -z "$VERSION" ]]; then
    echo "❌ Harap tentukan versi Xray (contoh: v1.8.5)"
    usage
    exit 1
fi

# Validasi format
if [[ "$FORMAT" != "zip" && "$FORMAT" != "tar.xz" ]]; then
    echo "❌ Format hanya boleh 'zip' atau 'tar.xz'"
    exit 1
fi

# Validasi arsitektur
if [[ "$ARCH" != "64" && "$ARCH" != "arm64" ]]; then
    echo "❌ Arsitektur hanya boleh '64' atau 'arm64'"
    exit 1
fi

# Buat nama file
FILENAME="xray-linux-$ARCH.$FORMAT"

# URL unduhan dan checksum
DOWNLOAD_URL="$REPO_URL/download/$VERSION/$FILENAME"
CHECKSUM_URL="$REPO_URL/download/$VERSION/sha256sum.txt"

echo "🔄 Menyiapkan downgrade Xray ke: $VERSION ($ARCH / $FORMAT)"
echo "📥 Mengunduh: $DOWNLOAD_URL"

# Buat direktori sementara
TEMP_DIR="/tmp/xray-downgrade-$(date +%s)"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Unduh binary
if ! curl -L -o "$FILENAME" "$DOWNLOAD_URL" --fail; then
    echo "❌ Gagal mengunduh binary. Pastikan versi dan arsitektur benar."
    echo "   Coba cek rilis resmi: $REPO_URL"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Unduh checksum (jika ada)
if curl -s -f -o sha256sum.txt "$CHECKSUM_URL"; then
    echo "🔍 Memverifikasi checksum SHA256..."
    # Ekstrak checksum untuk file ini
    EXPECTED_CHECKSUM=$(grep "$FILENAME" sha256sum.txt | awk '{print $1}')
    ACTUAL_CHECKSUM=$(sha256sum "$FILENAME" | awk '{print $1}')

    if [[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]]; then
        echo "✅ SHA256 cocok: $ACTUAL_CHECKSUM"
    else
        echo "❌ SHA256 tidak cocok!"
        echo "   Diharapkan: $EXPECTED_CHECKSUM"
        echo "   Ditemukan:  $ACTUAL_CHECKSUM"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    echo "⚠️  File checksum tidak ditemukan. Melewati verifikasi (tidak aman)."
    echo "   Disarankan gunakan versi terbaru yang memiliki checksum."
fi

# Hentikan layanan Xray
echo "🛑 Menghentikan layanan Xray..."
sudo systemctl stop xray 2>/dev/null || echo "⚠️  Xray tidak aktif"

# Backup binary lama
if [[ -f "/usr/local/bin/xray" ]]; then
    BACKUP_NAME="/usr/local/bin/xray.bak.$(date +%Y%m%d_%H%M%S)"
    sudo cp "/usr/local/bin/xray" "$BACKUP_NAME"
    echo "💾 Backup binary lama: $BACKUP_NAME"
fi

# Ekstrak dan salin binary
if [[ "$FORMAT" == "zip" ]]; then
    unzip -q "$FILENAME"
elif [[ "$FORMAT" == "tar.xz" ]]; then
    tar -xf "$FILENAME"
fi

# Pastikan binary ada
if [[ ! -f "xray" ]]; then
    echo "❌ Binary 'xray' tidak ditemukan setelah ekstraksi!"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Salin ke lokasi bin
sudo cp xray /usr/local/bin/xray
sudo chmod +x /usr/local/bin/xray

# Verifikasi versi baru
NEW_VERSION=$(/usr/local/bin/xray version 2>&1 | head -n1)
echo "✅ Berhasil downgrade ke: $NEW_VERSION"

# Mulai ulang layanan
echo "🚀 Memulai ulang layanan Xray..."
sudo systemctl start xray
sleep 2
sudo systemctl status xray --no-pager

# Bersihkan
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 Downgrade selesai! Xray berjalan di versi $VERSION"
echo "ℹ️  Untuk kembali ke versi terbaru: sudo bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"
