# Aset

Folder ini adalah satu-satunya tempat menaruh art. Nama file menentukan slot
yang diganti; tidak perlu menyentuh `.tscn` atau `.tres`.

Aturan singkat: simpan file `.png`/`.webp` dengan nama lowercase + underscore
sesuai struktur folder di panduan, jalankan `--headless --import` sekali, lalu
tekan **Backtick (`)** di island untuk memuat ulang tanpa restart (atau **Home**
untuk melihat kotak slot aset).

Panduan lengkap (daftar slot, ukuran, arah, state, fallback):
**`docs/editable/ASSET_GUIDE.md`**. Panduan itu juga mendata semua ikon item
(`assets/icons/items/<id>.png`), art item di tangan (`assets/held/<id>.png`),
seluruh resep crafting, dan cakupan file yang masih kosong. Panduan digenerate:
jangan edit bagian bertanda HTML dengan tangan, jalankan
`GODOT --headless --path . -s tools/generate_guides.gd`.

Pemeriksa cepat tanpa membuka editor:

```
GODOT --headless --path . -s tools/check_assets.gd
```

Alat itu mengecek slot registry, ikon item (`icons/items/<id>.png`), held item
(`held/<id>.png`), typo nama file, duplikat `.png`/`.webp`, strip animasi, dan
rasio aspek.
