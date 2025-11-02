
---

# 🔄 xray-downgrade

Skrip Bash fleksibel untuk **menurunkan versi (downgrade)** [Xray-core](https://github.com/XTLS/Xray-core) dengan dukungan:
- Deteksi otomatis arsitektur sistem
- Pemilihan arsitektur & format file secara manual
- Verifikasi checksum SHA256 untuk keamanan
- Backup otomatis binary lama
- Restart layanan Xray setelah downgrade

---

## 📦 Fitur Utama

- ✅ **Downgrade cepat** ke versi Xray tertentu
- 🔍 **Verifikasi SHA256** untuk memastikan integritas file
- 🧠 **Deteksi arsitektur otomatis**: `x86_64` → `64`, `aarch64`/`arm64` → `arm64`
- 🛠️ Dukungan format: `zip` (default) dan `tar.xz`
- 💾 **Backup otomatis** binary lama sebelum mengganti
- 🔄 **Restart layanan systemd** (`xray.service`) setelah downgrade
- 📋 Mode `list` untuk melihat daftar versi rilis terbaru

---

## 🚀 Penggunaan

### Instalasi Skrip
Simpan skrip sebagai file executable, misalnya `/usr/local/bin/xray-downgrade`:

```bash
sudo curl -L -o /usr/local/bin/xray-downgrade https://raw.githubusercontent.com/<your-username>/xray-downgrade/main/xray-downgrade
sudo chmod +x /usr/local/bin/xray-downgrade
```

> Ganti `<your-username>` dengan username GitHub Anda.

### Contoh Perintah

```bash
# Downgrade otomatis (deteksi arsitektur & format zip)
sudo xray-downgrade v1.8.5

# Downgrade ke versi tertentu dengan arsitektur arm64
sudo xray-downgrade v1.8.5 arm64

# Downgrade ke arsitektur 64-bit dengan format tar.xz
sudo xray-downgrade v1.8.5 64 tar.xz

# Lihat daftar 20 versi terbaru
sudo xray-downgrade list
```

### Format Argumen
```bash
sudo xray-downgrade <versi> [arsitektur] [format]
```
- **`versi`**: wajib, contoh: `v1.8.5`
- **`arsitektur`**: opsional → `64` atau `arm64` (default: deteksi otomatis)
- **`format`**: opsional → `zip` atau `tar.xz` (default: `zip`)

---

## ⚠️ Persyaratan

- Sistem Linux dengan `systemd`
- Xray terinstal di `/usr/local/bin/xray`
- Layanan Xray terdaftar sebagai `xray.service`
- Akses root (gunakan `sudo`)
- Dependensi:
  - `curl`
  - `jq` (untuk mode `list`)
  - `unzip` (jika pakai format `zip`)
  - `tar` (jika pakai format `tar.xz`)
  - `sha256sum`

> Untuk menginstal dependensi di Debian/Ubuntu:
> ```bash
> sudo apt install curl jq unzip tar
> ```

---

## 🔒 Keamanan

- Skrip **akan gagal** jika checksum SHA256 tidak cocok.
- Jika file `sha256sum.txt` tidak tersedia untuk versi lama, skrip akan memberi peringatan dan melanjutkan **tanpa verifikasi** — disarankan hindari versi sangat lama tanpa checksum.

---

## 🔄 Kembali ke Versi Terbaru

Gunakan skrip resmi Xray untuk kembali ke versi terbaru:

```bash
sudo bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
```

---

## 📄 Lisensi

MIT License — bebas digunakan, dimodifikasi, dan didistribusikan.

---

## 💡 Catatan

- Skrip ini **hanya mendukung Linux**.
- Pastikan versi yang Anda tuju **benar-benar tersedia** di [releases Xray-core](https://github.com/XTLS/Xray-core/releases).
- Format nama file mengikuti pola resmi: `xray-linux-64.zip`, `xray-linux-arm64.tar.xz`, dll.

---