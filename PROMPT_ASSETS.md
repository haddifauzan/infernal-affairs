# 🎨 PROMPT GENERASI ASET VISUAL TUBES TAHAP 3: INFERNAL AFFAIRS
## Panduan Prompt AI Generator (Midjourney / DALL-E 3 / Leonardo AI / Stable Diffusion)

Dokumen ini berisi daftar prompt siap pakai (*copy-paste ready*) dalam bahasa Inggris standar industri untuk men-generate seluruh aset visual yang tercantum pada **[PLAN.md](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/PLAN.md) poin 5.1 sampai 5.3**.

---

## 📌 Master Style Guide & Aturan Konsistensi Seni

Agar seluruh aset baru selaras dengan aset Tahap 1 dan 2 yang sudah ada di dalam game, gunakan prinsip visual berikut:
* **Tema Utama:** *Dark Fantasy Infernal Underworld* (Neraka, magma, batu obsidian hitam, api merah membara, dipadukan aksen cyan magis untuk player/UI AI).
* **Perspektif Sprite Game:** *Top-down 2D game asset* (sedikit sudut miring $45^\circ$ isometrik/overhead).
* **Format & Background:** Latar belakang putih polos (*isolated on solid white background*) agar mudah dihapus menjadi PNG transparan di Canva / Photoshop / remove.bg.
* **Negative Prompt Umum:**  
  `photorealistic, 3d render, blurred, realistic human, watermark, signature, text, noisy background, gradient background, cutoff border, bad anatomy, deformed limbs`

---

## 5.1 Kategori Karakter & NPC

### 1. `minion_imp.png` (Sprite Sheet Karakter Minion)
* **Target File:** `assets/sprites/characters/minion/minion_imp.png`
* **Format:** Sprite Sheet (Grid $4 \times 4$ untuk Idle & Walk 4-Arah)
* **Resolusi:** `1024 x 1024` atau `512 x 512`
* **Prompt AI:**
```text
2D top-down game sprite sheet of a tiny demonic imp minion, dark fantasy hell theme. Small red-skinned demon creature with small curved horns, pointy tail, and glowing yellow eyes. 4x4 grid character spritesheet showing walk cycle and idle animations facing 4 directions: front, back, left, right. Clean pixel-friendly stylized 2D game art, sharp dark outlines, isolated on solid plain white background, game ready asset, no shadows on ground --v 6.0 --ar 1:1
```

---

### 2. `guard_knight.png` (Sprite Sheet Penjaga Gerbang Istana)
* **Target File:** `assets/sprites/characters/guard/guard_knight.png`
* **Format:** Sprite Sheet (Grid $4 \times 4$ untuk Idle & Stance Attack)
* **Resolusi:** `1024 x 1024`
* **Prompt AI:**
```text
2D top-down game sprite sheet of an elite hell gatekeeper knight, dark armored demon warrior with black spiked obsidian plate armor, glowing lava cracks, holding a heavy spiked tower shield and a flaming broadsword. 4x4 grid character spritesheet with idle and ready combat animations facing 4 directions: front, back, left, right. Clean stylized 2D RPG game art, vibrant magma orange glow, isolated on solid plain white background, no floor texture --v 6.0 --ar 1:1
```

---

### 3. `demon_boss.png` (Ilustrasi Pose Tahta Bos Iblis)
* **Target File:** `assets/sprites/characters/demon/demon_boss.png`
* **Format:** Single Character Pose (Full Body Standing / Taunting)
* **Resolusi:** `512 x 512`
* **Prompt AI:**
```text
Full-body 2D top-down illustration of a towering Archdemon Lord boss, colossal horned demon emperor with obsidian plate armor, giant curved demonic ram horns, fiery bat wings, wields a glowing cursed hellfire trident, menacing combat stance. Dark fantasy Diablo inspired, vibrant red and fiery embers, clean stylized vector/digital art, isolated on solid plain white background --v 6.0 --ar 1:1
```

---

### 4 & 5. `avatar_minion.png` & `avatar_guard.png` (Portrait HUD Duel)
> 💡 *Hemat prompt:* Kedua avatar ini **sudah dimasukkan ke dalam Lembaran Grid Ikon (Bagian 5.3)** di bawah. Kamu cukup men-generate 1 lembar grid di Bagian 5.3 untuk mendapatkan seluruh ikon sekaligus avatar ini!
>
> *(Jika tetap ingin generate terpisah satuan, prompt individu tersedia di bawah):*

* **Prompt Terpisah Minion Avatar:**
```text
Square UI avatar portrait of a sneaky red imp minion head, sharp teeth, mischievous smirk, tiny yellow glowing eyes, small demon horns. High quality 2D game HUD icon, dark infernal gothic frame border, stylized clean digital painting, isolated on plain white background --v 6.0 --ar 1:1
```
* **Prompt Terpisah Guard Avatar:**
```text
Square UI avatar portrait of an elite hell gatekeeper helmet, menacing black iron helmet with glowing molten lava visor slits, sharp spikes on shoulders. Dark fantasy gothic circular steel border, stylized RPG battle portrait, isolated on plain white background --v 6.0 --ar 1:1
```

---

## 5.2 Kategori Map, Environment & Props

### 6. `gate_hell_closed.png` (Gerbang Neraka Tertutup / Terkunci)
* **Target File:** `assets/sprites/map/obstacles/gate_hell_closed.png`
* **Format:** Prop Sprite (Penghalang Jalan / Barrier)
* **Resolusi:** `256 x 256` atau `512 x 512`
* **Prompt AI:**
```text
Top-down 2D game prop of a massive closed hell castle iron gate, colossal gothic portcullis made of dark obsidian metal and demon skull ornaments, locked with heavy glowing purple chains and a runic seal lock. Flanked by two stone pillars with burning torches. Clean stylized 2D top-down view, isolated on solid plain white background, game ready obstacle sprite --v 6.0 --ar 1:1
```

---

### 7. `gate_hell_open.png` (Gerbang Neraka Terbuka)
* **Target File:** `assets/sprites/map/obstacles/gate_hell_open.png`
* **Format:** Prop Sprite (Jalan Masuk Terbuka)
* **Resolusi:** `256 x 256` atau `512 x 512`
* **Prompt AI:**
```text
Top-down 2D game prop of an open hell fortress iron gate, gothic demon-stone archway with gates swung wide open, revealing a dark stone staircase entrance leading inside with ambient red glow. Clean stylized 2D top-down view, sharp edges, isolated on solid plain white background, seamless game environment prop --v 6.0 --ar 1:1
```

---

### 8. `castle_walls.png` (Tileset Dinding Ruang Tahta Bos)
* **Target File:** `assets/sprites/map/obstacles/castle_walls.png`
* **Format:** Tileset Modular Grid (Dinding, Sudut, & Tiang)
* **Resolusi:** `1024 x 1024` (atau `512 x 512`)
* **Prompt AI:**
```text
Seamless top-down 2D tileset spritesheet of dark obsidian castle dungeon walls, modular black stone brick wall segments, wall corners, top-down perspective, embedded with glowing molten lava veins and gothic gargoyle carved pillars. Stylized top-down RPG dungeon tileset, clean flat lighting, isolated on solid white background --v 6.0 --ar 1:1
```

---

### 9. `throne_boss.png` (Kursi Tahta Bos Neraka)
* **Target File:** `assets/sprites/map/obstacles/throne_boss.png`
* **Format:** Prop Sprite Dekorasi Ruang Bos
* **Resolusi:** `256 x 256` atau `512 x 512`
* **Prompt AI:**
```text
Top-down 2D game sprite of a gigantic demonic throne of the underworld, carved out of black basalt rock and monster skull bones, cushioned with velvet red seat, burning dark flame braziers on both sides of the throne. Stylized dark fantasy RPG boss room prop, isolated on solid plain white background --v 6.0 --ar 1:1
```

---

### 10. `gate_warning_sign.png` (Tanda Peringatan / Obelisk Syarat Level)
* **Target File:** `assets/sprites/map/obstacles/gate_warning_sign.png`
* **Format:** Prop Sprite / Obelisk Tanda
* **Resolusi:** `128 x 128` atau `256 x 256`
* **Prompt AI:**
```text
Top-down 2D game prop of a demonic stone obelisk marker, carved runic stone pillar with a glowing fiery yellow exclamation mark symbol and ancient devil glyphs carved on its surface, warning marker for restricted level area. Stylized top-down RPG asset, isolated on solid plain white background --v 6.0 --ar 1:1
```

---

## 5.3 Kategori UI & Icon Khusus (All-in-One Icon Sheet Grid)

> 💡 **Satu Lembar untuk Semua Ikon:**  
> Seluruh aset ikon di bawah ini (termasuk ikon item, skill, badge, dan avatar pertarungan) digabung ke dalam **1 Prompt Lembaran Grid** ($3 \times 2$ atau $2 \times 3$). Kamu cukup men-generate 1 gambar utuh ini, lalu potong (*crop*) masing-masing kotak ikon di Canva / Photoshop.
>
> *(Catatan: Khusus `panel_loading_bg.png` tetap dipisah karena berformat background layar 16:9).*

### 🌟 Single Master Prompt: Lembaran Grid Seluruh Ikon (All-in-One)
* **Format Output:** 1 Lembar Gambar Berisi Grid 6 Ikon Game (3 Kolom $\times$ 2 Baris)
* **Rekomendasi Aspek Rasio:** `1:1` atau `3:2`
* **Prompt AI Siap Pakai:**
```text
A clean 2D game UI icon sheet spritesheet in a neat 3x2 grid, dark fantasy infernal hell RPG theme, isolated on solid plain white background. Containing exactly 6 distinct square RPG icons with dark metallic beveled borders:
1. An ornate ancient golden demonic castle skeleton key with curved ram horns headpiece and burning embers.
2. A gothic hellfire shield badge emblem with obsidian trim and a glowing red crimson jewel in the center.
3. A mystical cyber-gothic AI processor chip with glowing cyan rune circuit lines and a glowing demonic eye core.
4. A heavy attack combat skill icon showing a giant obsidian war-cleaver slashing downward with explosive red fire slash trail.
5. A circular battle portrait avatar of a mischievous red demon imp minion face with glowing yellow eyes.
6. A circular battle portrait avatar of an elite hell gatekeeper knight wearing a spiked black iron helmet with glowing molten lava visor.
High resolution stylized clean vector digital game icons, consistent visual style, high contrast, sharp borders, perfectly spaced grid layout, no background noise --v 6.0 --ar 1:1
```

---

### ✂️ Panduan Potong / Crop Lembaran Ikon (Tabel Referensi)

Setelah men-generate 1 gambar grid di atas, potong masing-masing kotak menjadi file berikut:

| Posisi Grid | Nama File | Target Folder | Ukuran Crop Rekomendasi | Keterangan / Fungsi |
| :---: | :--- | :--- | :---: | :--- |
| **Kotak 1 (Kiri Atas)** | `icon_castle_key.png` | `assets/sprites/ui/skills/` | `128 x 128` (scale ke `64x64`) | Kunci gerbang istana (drop dari Penjaga) |
| **Kotak 2 (Tengah Atas)** | `icon_level_badge.png` | `assets/sprites/ui/` | `128 x 128` | Emblem penunjuk Level 1, 2, 3 di HUD |
| **Kotak 3 (Kanan Atas)** | `icon_algorithm_chip.png` | `assets/sprites/ui/skills/` | `128 x 128` (scale ke `64x64`) | Ikon indikator Local Search aktif |
| **Kotak 4 (Kiri Bawah)** | `icon_heavy_attack.png` | `assets/sprites/ui/skills/` | `128 x 128` (scale ke `64x64`) | Tombol aksi jurus serangan berat |
| **Kotak 5 (Tengah Bawah)** | `avatar_minion.png` | `assets/sprites/characters/minion/` | `128 x 128` (scale ke `64x64`) | Foto profil Minion pada HUD duel |
| **Kotak 6 (Kanan Bawah)** | `avatar_guard.png` | `assets/sprites/characters/guard/` | `128 x 128` (scale ke `64x64`) | Foto profil Penjaga pada HUD duel |

---

### 15. `panel_loading_bg.png` (Background Layar Loading Balancer / Transisi 16:9)
*(Terpisah karena memerlukan resolusi layar lebar 16:9)*
* **Target File:** `assets/sprites/ui/panel_loading_bg.png`
* **Format:** 16:9 UI Card Frame / Modal Background
* **Resolusi:** `1920 x 1080` (atau `1280 x 720`)
* **Prompt AI:**
```text
Game UI dialog modal background frame, sleek dark obsidian glassmorphism panel with glowing magma orange neon border runes, subtle hex grid tech patterns blended with dark fantasy infernal magic circles in the background, semi-transparent center area for text, 16:9 aspect ratio, clean futuristic-gothic game UI layout --v 6.0 --ar 16:9
```

---

## 5.4 Gambaran Map & Level Design Mockup (Peta Lengkap Dunia Neraka)

> 🗺️ **Peta Visual Progresi Level:**  
> Prompt ini men-generate **1 gambar visualisasi utuh peta level 16:9**, yang memperlihatkan tata letak (*level layout*) dari zona awal spawn & looting hingga ke gerbang istana dan ruang tahta Bos. Sangat berguna sebagai referensi penyusunan TileMap di Godot maupun untuk ilustrasi di laporan tugas besar dan presentasi!

### 16. `map_level_overview.png` (Desain Konsep Peta Lengkap Dunia Neraka)
* **Format:** Concept Art / Level Layout Mockup (Top-Down RPG)
* **Rekomendasi Rasio:** `16:9` (Resolusi `1920 x 1080` atau `1280 x 720`)
* **Zona yang Digambarkan dalam 1 Peta:**
  1. **Zona Bawah (Spawn & Wilderness):** Tanah batu hitam abu retak-retak, pepohonan hangus, kristal magma, dan beberapa minion imp merah kecil yang berkeliaran untuk looting/grinding awal.
  2. **Zona Tengah (River of Lava & The Gate):** Sungai lahar merah menyala membelah peta horizontal, diseberangi jembatan batu sempit menuju **Gerbang Besi Neraka Raksasa** yang dijaga ketat oleh ksatria penjaga berzirah hitam (*Gatekeeper Knight*). Terdapat batu obelisk peringatan berapi di dekat gerbang.
  3. **Zona Atas (Istana & Ruang Tahta Bos):** Benteng megah berdinding obsidian hitam tebal dengan obor api gelap, menuju ruang tahta neraka dengan karpet merah hangus yang berujung pada **Kursi Tahta Tengkorak Berapi** tempat Bos Iblis agung menunggu.
* **Prompt AI Siap Pakai:**
```text
Comprehensive 2D top-down game level design map mockup of a dark fantasy underworld fortress, 16:9 aspect ratio, seamless playable game layout from bottom to top. 
Bottom area features a charred obsidian rocky wasteland with magma cracks, dead scorched trees, glowing red crystals, where a tiny lone soul knight wanders near wandering red imps. 
Middle area is split by a treacherous flowing river of glowing orange molten lava, crossed by a narrow stone bridge leading to a colossal fortified gothic iron gate guarded by a black armored hell gatekeeper knight and a runic warning obelisk. 
Top area reveals the grand infernal castle interior with obsidian brick walls, molten floor veins, and a burning skull throne chamber where a giant horned demon lord awaits. 
Stylized top-down 2D RPG video game screenshot aesthetic, clean readable level design, high contrast lighting, vibrant magma glow against dark basalt stone, bird-eye perspective, highly detailed game environment --v 6.0 --ar 16:9
```

---

1. **Hapus Background:**
   * Masukkan gambar hasil generasi ke situs gratis seperti [remove.bg](https://www.remove.bg/) atau fitur *Background Remover* di Canva.
2. **Crop & Rename:**
   * Simpan file sesuai penamaan `snake_case` di tabel di atas.
3. **Simpan ke Folder Godot:**
   * Masukkan file ke direktori tujuan di dalam proyek `infernal-affairs/assets/sprites/`.
   * Buka editor Godot agar file otomatis di-import sebagai `Texture2D`.
