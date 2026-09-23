# 🎨 Master Guide: Crop, Ukuran, Penamaan File & Folder Aset

Dokumen ini adalah **panduan lengkap pemotongan (crop)** dari lembar aset Canva kamu. Semua aset telah dikelompokkan ke dalam tabel dengan ukuran resolusi yang presisi, format nama file (`snake_case`), dan folder tujuan penyimpanan di dalam proyek Godot (`godot-version/assets/`).

---

## 📑 Ringkasan Folder Tujuan Penyimpanan

Pastikan sub-folder berikut sudah ada di `godot-version/assets/sprites/`:
* `characters/player/`
* `characters/demon/`
* `map/ground/`
* `map/lava/`
* `map/obstacles/`
* `effects/`
* `ui/`

---

## 1. 🧙 Karakter: Player (Lost Soul Knight)
> **Folder Tujuan:** `godot-version/assets/sprites/characters/player/`

| No | Aset yang Dicrop | Penjelasan Posisi di Gambar | Ukuran Crop (Px) | Nama File Simpan |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **Player Idle Sheet** | 4 Baris $\times$ 4 Kolom di blok kiri IDLE | `512 x 512` (atau `256 x 256`) | `player_idle.png` |
| **2** | **Player Run Sheet** | 4 Baris $\times$ 4 Kolom di blok kanan RUN | `512 x 512` (atau `256 x 256`) | `player_run.png` |
| **3** | **Player Portrait** | Pose aksi ksatria lari ber-aura biru besar | `256 x 256` s/d `512 x 512` | `player_portrait.png` |
| **4** | **Player Avatar** | Ikon bulat kepala helm ksatria biru | `128 x 128` | `player_avatar.png` |

> 💡 **Catatan untuk Sprite Sheet (No 1 & 2):**  
> **Persegi panjang ke bawah (vertikal) SANGAT AMAN dan TIDAK MASALAH!**  
> Godot memotong frame berdasarkan pembagian **4 Kolom (Horizontal) dan 4 Baris (Vertical)**, bukan berdasarkan rasio 1:1. Jadi mau bentuknya persegi ataupun persegi panjang ke bawah, Godot akan otomatis membaginya dengan rata dan presisi. Yang penting, pastikan seluruh 16 karakter (kepala hingga kaki) tidak terpotong tepi crop!

---

## 2. 👹 Karakter: Demon (Hell Demon Brute)
> **Folder Tujuan:** `godot-version/assets/sprites/characters/demon/`

| No | Aset yang Dicrop | Penjelasan Posisi di Gambar | Ukuran Crop (Px) | Nama File Simpan |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **Demon Idle Sheet** | 4 Baris $\times$ 4 Kolom di blok kiri IDLE Demon | `512 x 512` s/d `1024 x 1024` | `demon_idle.png` |
| **2** | **Demon Chase Sheet**| 4 Baris $\times$ 4 Kolom di blok kanan CHASE | `512 x 512` s/d `1024 x 1024` | `demon_chase.png` |
| **3** | **Demon Boss Pose** | Ilustrasi monster iblis merah besar berapi | `512 x 512` | `demon_boss.png` |
| **4** | **Demon Avatar** | Ikon bulat kepala monster iblis bertanduk | `128 x 128` | `demon_avatar.png` |

---

## 3. 🌋 Environment: Lantai & Lava
> **Folder Tujuan:**  
> - Lantai: `godot-version/assets/sprites/map/ground/`  
> - Lava: `godot-version/assets/sprites/map/lava/`

| No | Aset yang Dicrop | Penjelasan Posisi di Gambar | Ukuran Crop (Px) | Nama File Simpan | Folder Simpan |
| :---: | :--- | :--- | :---: | :--- | :--- |
| **1** | **Tekstur Tanah Abu** | Kotak tanah batu hitam retakan lava | Ukuran penuh kotak | `ground_texture.png` | `map/ground/` |
| **2** | **Danau Lava Besar** | 1 Kolam lahar bulat besar (baris ke-3 lava) | `192 x 192` s/d `256 x 256` | `lava_pool_large.png` | `map/lava/` |
| **3** | **Danau Lava Sedang** | 1 Kolam lahar bulat sedang di sebelahnya | `128 x 128` | `lava_pool_medium.png` | `map/lava/` |
| **4** | **Danau Lava Kecil** | 1 Kolam lahar kecil | `64 x 64` atau `96 x 96` | `lava_pool_small.png` | `map/lava/` |
| **5** | **Lava Sheet (Opsional)**| Seluruh lembaran potongan aliran lava | Ukuran penuh sheet | `lava_tileset.png` | `map/lava/` |

---

## 4. 🪨 Obstacles: Bebatuan, Kristal, & Pohon Hangus
> **Folder Tujuan:** `godot-version/assets/sprites/map/obstacles/`

*(Cukup pilih 2 - 3 variasi terbaik dari tiap jenis, tidak perlu potong semuanya!)*  
> 💡 **Catatan Bentuk Crop:**  
> Obstacle **TIDAK HARUS PERSEGI!** Bentuknya bebas mengikuti bentuk alami objek (misal: pohon tinggi memanjang ke atas, batu melebar ke samping). Di Godot, masing-masing gambar ini menjadi 1 objek utuh independen (`Sprite2D`). Yang penting, crop sedekat mungkin ke tepian objek (*tight crop*) dengan background transparan.

| No | Aset yang Dicrop | Penjelasan Posisi di Gambar | Ukuran Crop (Px) | Nama File Simpan |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **Batu Tebing Besar** | 1 Bongkahan batu obsidian besar (baris 1 kiri) | `128 x 128` | `rock_large.png` |
| **2** | **Batu Sedang** | 1 Bongkahan batu sedang (baris 2) | `64 x 64` | `rock_medium.png` |
| **3** | **Batu Kecil** | 1 Kerikil batu kecil (baris 3 / 4) | `32 x 32` | `rock_small.png` |
| **4** | **Kristal Magma Besar**| 1 Rumpun kristal merah menyala besar | `96 x 96` | `crystal_large.png` |
| **5** | **Kristal Magma Satuan**| 1 Kristal runcing tunggal | `48 x 48` s/d `64 x 64` | `crystal_small.png` |
| **6** | **Pohon Neraka Besar** | 1 Pohon bercabang paling besar (baris 1 kanan) | `96 x 128` | `tree_large.png` |
| **7** | **Pohon Neraka Sedang**| 1 Pohon ukuran sedang (baris 2) | `64 x 96` | `tree_medium.png` |
| **8** | **Tunggul Kawah Lahar**| 1 Potongan batang pohon kawah lava (baris 4) | `64 x 64` | `tree_stump.png` |

---

## 5. ✨ VFX & Efek Jejak Rute AI
> **Folder Tujuan:** `godot-version/assets/sprites/effects/`

| No | Aset yang Dicrop | Penjelasan Posisi di Gambar | Ukuran Crop (Px) | Nama File Simpan |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **Titik Jejak AI** | **SATU** titik bulat oranye menyala di paling atas | `32 x 32` (atau `16 x 16`) | `path_dot.png` |
| **2** | **Aura Kaki Player** | **SATU** lingkaran sihir biru cyan (bentuk elips) | `128 x 128` | `aura_player.png` |
| **3** | **Aura Kaki Demon** | **SATU** lingkaran api merah membara (bentuk elips) | `128 x 128` | `aura_demon.png` |

---

## 6. 🛡️ UI / HUD Icons
> **Folder Tujuan:** `godot-version/assets/sprites/ui/`

| No | Aset yang Dicrop | Penjelasan Posisi di Gambar | Ukuran Crop (Px) | Nama File Simpan | Sub-Folder Tujuan Simpan |
| :---: | :--- | :--- | :---: | :--- | :--- |
| **1** | **Icon Pedang** | Kotak icon pedang biru | `64 x 64` | `icon_sword.png` | `assets/sprites/ui/skills/` |
| **2** | **Icon Perisai** | Kotak icon perisai besi emas | `64 x 64` | `icon_shield.png` | `assets/sprites/ui/skills/` |
| **3** | **Icon Potion** | Kotak icon ramuan botol merah | `64 x 64` | `icon_potion.png` | `assets/sprites/ui/skills/` |
| **4** | **Icon Hati Penuh** | Kotak icon hati merah menyala | `48 x 48` atau `64 x 64` | `icon_heart_full.png` | `assets/sprites/ui/hearts/` |
| **5** | **Icon Hati Kosong** | Kotak icon hati hitam kosong | `48 x 48` atau `64 x 64` | `icon_heart_empty.png` | `assets/sprites/ui/hearts/` |

---

## 💡 Tips Penting Sebelum Save di Canva:
1. **Download dengan Format PNG Transparan**: Selalu centang opsi *Transparent Background* agar tidak ada warna putih/abu-abu yang mengganggu.
2. **Karakter Tepat di Tengah (Centered)**: Khusus Sprite Sheet karakter dan aura, usahakan posisi objek pas di tengah kotak crop agar animasinya tidak bergeser aneh saat berputar/melangkah di Godot.
