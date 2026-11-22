# Aset

Folder ini adalah satu-satunya tempat menaruh art. Nama file menentukan slot
yang diganti; tidak perlu menyentuh `.tscn` atau `.tres`.

Aturan singkat: simpan file `.png`/`.webp` dengan nama lowercase + underscore
sesuai struktur folder di panduan, jalankan `--headless --import` sekali, lalu
tekan **F1** di island untuk memuat ulang tanpa restart.

Panduan lengkap (daftar slot, ukuran, arah, state, fallback):
**`docs/editable/ASSET_GUIDE.md`**.

Pemeriksa cepat tanpa membuka editor:

```
GODOT --headless --path . -s tools/check_assets.gd
```
