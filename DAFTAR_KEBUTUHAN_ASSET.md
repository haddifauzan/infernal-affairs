# 🎨 DAFTAR KEBUTUHAN ASET GAME: INFERNAL AFFAIRS
## PANDUAN PENGGANTIAN ASET & SPESIFIKASI TAHAP 4 (HANDCRAFTED PIXEL ART)

Dokumen ini disusun sebagai panduan pengadaan, pencarian, dan standarisasi aset visual serta audio untuk game **Infernal Affairs**. Dokumen ini bertujuan untuk:
1. **Menghilangkan kesan kaku / *AI-generated placeholder*** (inkonsistensi resolusi, bentuk kotak kode primitif, dan tekstur statis).
2. **Memenuhi kebutuhan spesifik mekanika Tahap 4** (*Automated Planning*, 3 Altar Sumber Daya, Kristal Elemen, Minion Kurir, dan Semburan Api Jembatan `d` untuk *Markov Decision Process*).
3. **Membangun kohesi visual profesional** (*Handcrafted Dark Fantasy 2D Pixel Art*).

---

## 📌 1. Prinsip Desain & Kriteria Teknis (Art Guidelines)

Agar semua aset yang dikumpulkan tidak "tabrakan" dan terlihat menyatu secara alami, seluruh aset wajib memenuhi standar teknis berikut:

| Parameter | Spesifikasi Wajib | Keterangan & Alasan |
| :--- | :--- | :--- |
| **Gaya Visual (*Art Style*)** | **2D Top-Down Pixel Art (Perspektif 3/4 RPG)** | Menjaga konsistensi retro gelap. Hindari aset 3D render atau ilustrasi lukisan halus (*photorealistic / anime painting*). |
| **Ukuran Dasar Kotak (*Base Grid*)** | **32 × 32 Pixel** | Ukuran standar ubin map `Infernal Affairs`. Jika menemukan aset 16×16, lakukan *integer scaling* $2\times$ dengan filter **Nearest Neighbor** (tanpa blur). |
| **Format Berkas** | **PNG Transparan (RGBA)** | Menghindari latar belakang putih atau artefak kompresi JPG. |
| **Animasi** | **Spritesheet Horizontal / Vertikal** | Dimensi tiap *frame* wajib seragam (misal: tiap frame 32×32 atau 32×48 px) agar mudah dipotong otomatis oleh `SpriteFrames` Godot. |
| **Palet Warna Utama** | *Dark Fantasy Volcanic / Obsidian* | • Hitam Basalt & Abu Vulkanik (Tanah/Dinding)<br/>• Oranye Menyala & Kuning Magma (Lahar/Api)<br/>• Ungu Abyssal (Bayangan & Bos)<br/>• Merah Darah (Sanguine & Health) |

---

## 🏆 2. Kategori A: Kebutuhan Mendesak Tahap 4 (Prioritas Utama)

Bagian ini memuat aset yang langsung berinteraksi dengan mekanika kecerdasan buatan Tahap 4 (*STRIPS Classical Planning* & *Markov Decision Process*):

### 2.1. Jembatan Horisontal & Bahaya Semburan Api (Jalur `d`)
> **Lokasi Map**: Jembatan Kiri ($x = 7..20, y = 20..21$) & Jembatan Kanan ($x = 23..36, y = 20..21$).

| No | Nama Aset | Dimensi / Frame | Deskripsi Kebutuhan | Efek dalam Game |
| :---: | :--- | :--- | :--- | :--- |
| **A1** | **Modular Stone Bridge Tileset** | 32×32 per tile | Tileset jembatan batu top-down berukir: geladak jembatan (*deck pavers*), pagar pembatas batu atas-bawah (*stone parapets*), pilar sudut, dan bayangan ke arah jurang. | Menggantikan kotak-kotak garis yang digambar via kode `draw_rect`, memberikan tampilan jembatan kokoh di atas lahar. |
| **A2** | **Animated Flame Column / Magma Geyser VFX** | 32×48 atau 32×64 px<br/>(4–8 frames loop) | Animasi semburan pilar api vertikal bergejolak: dari letupan bara $\to$ lidah api tinggi membubung $\to$ asap padam. | Muncul di **seluruh 56 tile jembatan `d`** saat fase `ERUPTION` aktif (Lethal hazard). |
| **A3** | **Warning Magma Cracks & Steam Telegraph** | 32×32 px<br/>(3–5 frames loop) | Retakan batu yang berpendar oranye panas bertahap disertai kepulan uap sulfur tipis. | Ditampilkan saat fase `WARNING` (Sinyal sensor $W=1$) agar minion AI dan pemain tahu bahwa semburan akan segera meletus. |
| **A4** | **Dormant Basalt Fissure Tile** | 32×32 px statis / transparan | Retakan batu hitam dingin dengan rongga tipis di sela-sela lantai jembatan. | Tampilan jembatan saat fase `DORMANT` (Aman dilalui). |

---

### 2.2. Tiga Altar Elemen (Resource Nodes 1, 2, 3)
> **Lokasi Map**: Node 1 ($5, 21$), Node 2 ($38, 21$), Node 3 ($21, 38$).

Saat ini altar masih menggunakan batu/kristal generik. Dibutuhkan bangunan tugu interaktif yang merepresentasikan masing-masing elemen:

| No | Nama Altar | Dimensi | Konsep Visual Karakteristik | Status Stok (Tahap 4) |
| :---: | :--- | :--- | :--- | :--- |
| **A5** | **Ignis Altar (Node 1 - Flame)** | 32×32 atau 48×48 px<br/>(1.5×1.5 tile) | Tugu batu pemujaan api neraka dengan mangkuk perapian (*brazier*) di puncaknya yang menyala abadi. | Memiliki animasi api menyala saat stok $\ge 1$, dan api redup/padam saat stok habis ($0/3$). |
| **A6** | **Abyssal Fissure (Node 2 - Shadow)** | 32×32 atau 48×48 px | Monolit batu obsidian gelap dengan pecahan kristal ungu melayang mengitari portal kegelapan. | Memancarkan partikel aura ungu saat aktif. |
| **A7** | **Sanguine Well (Node 3 - Blood)** | 32×32 atau 48×48 px | Sumur batu melingkar berisi genangan darah beriak mistis dengan ornamen gargoyle kecil di bibir sumur. | Beriak tenang di area Ground `c`, menjadi pusat pertemuan jalur detour minion. |

---

### 2.3. Kristal Elemen & Aset Begal Overworld (*Shards & Drop Items*)

| No | Nama Aset | Dimensi / Format | Deskripsi Visual | Fungsi Game |
| :---: | :--- | :--- | :--- | :--- |
| **A8** | **Spinning Elemental Shard Spritesheet** | 32×32 px<br/>(4–6 frames) | 3 variasi kristal permata yang melayang dan berputar pelan:<br/>• **Flame Shard**: Batu Ruby merah membara.<br/>• **Shadow Shard**: Kristal Amethyst ungu gelap.<br/>• **Blood Shard**: Kristal Garnet / tetesan darah padat. | Melayang di atas kepala minion kurir yang sedang membawa bahan suplai. |
| **A9** | **Dropped Crystal Item (Overworld)** | 24×24 atau 32×32 px | Kristal yang tergeletak di atas ubin tanah/jembatan lengkap dengan bayangan oval kecil di bawahnya. | Dijatuhkan saat minion tersengat semburan api jembatan atau dibegal oleh pemain. |
| **A10** | **Item Sparkle / Pickup Pulse VFX** | 16×16 px<br/>(3–4 frames) | Kilauan cahaya bintang kecil atau cincin gelombang di sekitar item yang jatuh. | Menarik perhatian pemain bahwa kristal tersebut bisa dipungut (+25 EXP, +1 Potion, +15 HP). |

---

### 2.4. Minion Kurir & Indikator Keputusan AI (*Bayesian Belief*)

| No | Nama Aset | Dimensi / Format | Deskripsi Visual | Fungsi Game |
| :---: | :--- | :--- | :--- | :--- |
| **A11** | **Minion Carrier Walk Spritesheet** | 32×32 px<br/>(4 arah: Atas, Bawah, Kiri, Kanan) | Karakter Imp kecil bertanduk dengan animasi kedua tangan terangkat ke atas menopang beban kristal. | Memberikan kesan otentik bahwa minion sedang menjalankan tugas kurir (*STRIPS Planning*). |
| **A12** | **Pixel Emote Balloons / AI Reaction** | 16×16 px per icon | Ikon reaksi di atas kepala minion:<br/>• **Tanda Seru Oranye (`!`)**: Saat sensor bahaya mendeteksi asap ($W=1$).<br/>• **Tanda Tanya Biru (`?`)**: Saat minion mengevaluasi rute alternatif.<br/>• **Tengkorak / Keringat Panik**: Saat tersengat api dan kabur. | Memberikan transparansi visual langsung terhadap perubahan *Belief* dan *Policy Shift* tanpa harus membuka debug HUD. |

---

## 🌲 3. Kategori B: Aset Lingkungan & Map (Menghilangkan Kesan Kaku)

Bagian ini bertujuan mengganti elemen yang saat ini digambar manual lewat kode agar menyatu dengan visual grafis modern:

| No | Nama Aset | Tipe | Spesifikasi | Alasan Penggantian |
| :---: | :--- | :--- | :--- | :--- |
| **B1** | **Animated Lava River Autotile** | Tileset 32×32<br/>(Autotile 3×3) | Permukaan lahar dengan animasi gelembung meletup (*bubbling molten lava*, 3–4 frames) dan tepian batuan hitam (*basalt shoreline*). | Menggantikan lahar kode satu warna `Color(0.92, 0.22, 0.04)`. Memberikan kesan cairan lahar panas yang mengalir hidup. |
| **B2** | **Canyon / Cliff Edge Autotile** | Tileset 32×32 | Dinding jurang tebing batu bertingkat (*cliff side walls*). | Memberikan ilusi elevasi/kedalaman 2.5D: lahar mengalir di dasar jurang, sementara jembatan `d` dan tanah `c` berada di tebing atas. |
| **B3** | **Heavy Gothic Demon Gate** | Sprite 64×64 atau 96×64 px | Gerbang benteng besi tempa hitam (*portcullis*) dengan ornamen tengkorak neraka, memiliki frame pintu tertutup dan pintu terangkat terbuka. | Menggantikan dinding pembatas biasa di $y = 17..18$ saat gerbang terkunci oleh segel CSP. |
| **B4** | **Charred Wilderness Trees & Flora** | Prop 32×48 atau 48×64 px | Pohon kering terbakar tanpa daun dengan bara api kecil di batangnya, serta jamur fosfor vulkanis. | Menghidupkan suasana sunyi di area Tanah `c` dan pinggiran jalan aman `a`. |
| **B5** | **Obsidian Throne of Hell** | Prop 64×64 px | Singgasana takhta batu obsidian bertabur permata merah tempat Demon Lord duduk di Map 2 (Castle). | Pusat visual ruang takhta bos. |

---

## ⚔️ 4. Kategori C: Aset Karakter & Pertarungan (Konsistensi Resolusi)

| No | Nama Aset | Tipe | Format Ideal | Catatan |
| :---: | :--- | :--- | :--- | :--- |
| **C1** | **Portret Karakter Bergaya Pixel Art** | Portrait 64×64 atau 96×96 px | Pixel art berbingkai batu runik:<br/>• Pemain (*Demon Hunter*)<br/>• 3 Arketipe Penjaga (*Knight, Gargoyle, Shaman*)<br/>• Minion Imp<br/>• Demon Lord | Menggantikan portret hasil generate AI resolusi tinggi yang tidak senada dengan gameplay overworld pixel art. |
| **C2** | **Icon Skills & Status Bergaya Retro** | Icon 24×24 atau 32×32 px | Ikon Attack, Defend, Potion, Heavy Attack, Key, dan Seal Badge dengan outline tebal 1-pixel hitam. | Menyeragamkan tampilan Battle HUD dan Player Stats HUD. |

---

## 📊 5. Tabel Ringkasan Check-List Prioritas Pengadaan Aset

Gunakan tabel ini untuk mencatat aset yang sudah ditemukan:

| Kode | Nama Aset | Kebutuhan Utama | Sumber / Link Download | Status |
| :---: | :--- | :--- | :--- | :---: |
| `A1` | Top-Down Stone Bridge Tileset | Jembatan Horisontal `d` | *(Isi link)* | ⬜ Belum |
| `A2` | Animated Fire Column VFX | Semburan Api Seluruh Jembatan `d` | *(Isi link)* | ⬜ Belum |
| `A3` | Warning Crack & Smoke | Telegraph Peringatan Jembatan | *(Isi link)* | ⬜ Belum |
| `A5` | Ignis Altar (Fire Brazier) | Resource Node 1 (Kiri Atas) | *(Isi link)* | ⬜ Belum |
| `A6` | Abyssal Fissure (Void Shrine) | Resource Node 2 (Kanan Atas) | *(Isi link)* | ⬜ Belum |
| `A7` | Sanguine Well (Blood Well) | Resource Node 3 (Tengah Bawah) | *(Isi link)* | ⬜ Belum |
| `A8` | Spinning Shards (Flame, Shadow, Blood) | Kristal Bawaan Minion | *(Isi link)* | ⬜ Belum |
| `A9` | Dropped Crystal Overworld Item | Kristal Jatuh saat Terbakar/Dibegal | *(Isi link)* | ⬜ Belum |
| `A11`| Minion Carrying Spritesheet | Sprite Minion Membawa Kristal | *(Isi link)* | ⬜ Belum |
| `A12`| Pixel Emote Reactions (`!`, `?`) | Indikator Sensor Bayesian Minion | *(Isi link)* | ⬜ Belum |
| `B1` | Animated Lava Autotile | Danau Lahar `b` | *(Isi link)* | ⬜ Belum |
| `B2` | Cliff / Canyon Face Tileset | Tebing Jurang Lahar | *(Isi link)* | ⬜ Belum |

---

## 🔎 6. Rekomendasi Sumber Download & Kata Kunci Pencarian

Untuk mencari aset berkualitas buatan seniman pixel art (gratis maupun donasi sukarela), gunakan kata kunci bahasa Inggris berikut di situs-situs terpercaya:

### 1. [Itch.io (Game Assets - Tag: Pixel Art)](https://itch.io/game-assets/free/tag-pixel-art)
*Sangat disarankan karena kualitas visual seniman indie sangat konsisten.*
* **Kata Kunci Jembatan & Api**:
  * `"Top down stone bridge 32x32 pixel art"`
  * `"Pixel fire column animation spritesheet"`
  * `"Fire geyser vfx pixel art"`
* **Kata Kunci Altar & Kristal**:
  * `"RPG Shrine Altar pixel art topdown"`
  * `"Elemental crystal gem spinning spritesheet"`
  * `"Blood fountain well pixel art"`
* **Kata Kunci Lahar & Gua**:
  * `"Top down lava cave tileset"`
  * `"Dark fantasy volcanic dungeon tileset"`
* **Rekomendasi Kreator Terbaik di Itch.io**:
  * **Cainos** (Pixel Art Top Down series)
  * **Szadi art** (RPG World series)
  * **Seliel the Shaper** (VFX & particle pixel series)
  * **Bdragon1727** (RPG Icons & Props)

### 2. [OpenGameArt.org](https://opengameart.org/)
*Pusat aset lisensi terbuka (CC0 / Public Domain / CC-BY).*
* **Kata Kunci**:
  * `lava tileset 32x32`
  * `flame column animation`
  * `pixel art emotes 16x16`
  * `dark fantasy altar`

### 3. [Kenney.nl](https://kenney.nl/assets)
*Aset lisensi Public Domain (CC0) yang sangat rapi dan bebas dipakai tanpa atribusi wajib.*
* **Rekomendasi Paket**:
  * *Tiny Dungeon* & *Roguelike Cave*
  * *Pixel Platformer / Overworld Props*

---

## 🛠️ 7. Cara Memasang Aset Baru ke Dalam Proyek Godot

Setelah Anda menemukan dan mengunduh berkas aset yang cocok:
1. **Pindahkan berkas PNG** ke direktori proyek:
   - Jembatan & Tile Lahar $\to$ `assets/sprites/map/lava/` atau `assets/sprites/map/ground/`
   - Semburan Api & Partikel $\to$ `assets/sprites/map/hazards/` atau `assets/sprites/effects/`
   - Altar & Kristal $\to$ `assets/sprites/map/obstacles/`
   - Emote & Minion $\to$ `assets/sprites/characters/minion/` atau `assets/sprites/ui/effects/`
2. **Pengaturan Import di Godot Editor**:
   - Pilih berkas PNG di Godot FileSystem.
   - Buka tab **Import** di samping tab Scene.
   - Pada opsi **Texture**, pastikan filter diatur ke **Nearest** (agar pixel tetap tajam dan tidak blur).
   - Klik **Reimport**.
3. **Penyambungan Kode**:
   - Skrip seperti [ArenaMap.gd](file:///c:/Users/richi/Documents/GitHub/infernal-affairs/scripts/core/ArenaMap.gd), [StochasticHazardManager.gd](file:///c:/Users/richi/Documents/GitHub/infernal-affairs/scripts/core/StochasticHazardManager.gd), dan [ResourceNode.gd](file:///c:/Users/richi/Documents/GitHub/infernal-affairs/scripts/entities/ResourceNode.gd) sudah memiliki arsitektur modular yang otomatis me-load path tekstur dari folder tersebut.

