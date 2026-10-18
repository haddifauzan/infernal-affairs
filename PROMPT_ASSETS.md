# 🎨 PROMPT GENERASI ASET VISUAL TUBES TAHAP 3: INFERNAL AFFAIRS
## Panduan Prompt AI Generator (Midjourney / DALL-E 3 / Leonardo AI / Stable Diffusion)

Dokumen ini berisi daftar prompt siap pakai (*copy-paste ready*) dalam bahasa Inggris standar industri untuk men-generate seluruh aset visual yang tercantum pada **[PLAN.md](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/PLAN.md) poin 5.1 sampai 5.3**, termasuk **3 Base Archetype Guard**, **Senjata Modular**, **Attack VFX**, **Segel Gerbang**, dan **Grid 9 Avatar Portrait Duel**.

---

## 📌 Master Style Guide & Aturan Konsistensi Seni

Agar seluruh aset baru selaras dengan aset Tahap 1 dan 2 yang sudah ada di dalam game, gunakan prinsip visual berikut:
* **Tema Utama:** *Dark Fantasy Infernal Underworld* (Neraka, magma, batu obsidian hitam, api merah membara, dipadukan aksen ungu void magis dan cyan AI).
* **Perspektif Sprite Game:** *Top-down 2D game asset* (sedikit sudut miring $45^\circ$ isometrik/overhead).
* **Format & Background:** Latar belakang putih polos (*isolated on solid white background*) agar mudah dihapus menjadi PNG transparan di Canva / Photoshop / remove.bg.
* **Negative Prompt Umum:**  
  `photorealistic, 3d render, blurred, realistic human, watermark, signature, text, noisy background, gradient background, cutoff border, bad anatomy, deformed limbs`

---

## 5.1 Kategori Karakter Guard Archetype (3 Varian Base)

### 1. `guard_knight.png` (Archetype 1: Hell Gatekeeper Knight - Fisik)
* **Target File:** `assets/sprites/characters/guard/guard_knight.png`
* **Format:** Sprite Sheet (Grid $4 \times 4$ untuk Idle & Stance Attack)
* **Resolusi:** `1024 x 1024`
* **Prompt AI:**
```text
2D top-down game sprite sheet of an elite hell gatekeeper knight, dark armored demon warrior with black spiked obsidian plate armor, glowing lava cracks, holding a heavy spiked tower shield and a flaming broadsword. 4x4 grid character spritesheet with idle and ready combat animations facing 4 directions: front, back, left, right. Clean stylized 2D RPG game art, vibrant magma orange glow, isolated on solid plain white background, no floor texture --v 6.0 --ar 1:1
```

---

### 2. `guard_shaman.png` (Archetype 2: Abyssal Shaman - Sihir/Void)
* **Target File:** `assets/sprites/characters/guard/guard_shaman.png`
* **Format:** Sprite Sheet (Grid $4 \times 4$ untuk Idle & Casting Spell)
* **Resolusi:** `1024 x 1024`
* **Prompt AI:**
```text
2D top-down game sprite sheet of a dark demonic abyssal shaman mage, floating demonic sorcerer wearing tattered dark purple and black hooded robes, levitating slightly above ground, wearing a horned bone mask, holding a mystical void crystal staff emitting purple dark magic flames. 4x4 grid character spritesheet with floating idle and spellcasting animations facing 4 directions: front, back, left, right. Clean stylized 2D RPG game art, glowing void runes, isolated on solid plain white background, no floor shadow --v 6.0 --ar 1:1
```

---

### 3. `guard_gargoyle.png` (Archetype 3: Obsidian Gargoyle - Tank/Batu)
* **Target File:** `assets/sprites/characters/guard/guard_gargoyle.png`
* **Format:** Sprite Sheet (Grid $4 \times 4$ untuk Idle & Heavy Stomp)
* **Resolusi:** `1024 x 1024`
* **Prompt AI:**
```text
2D top-down game sprite sheet of a hulking obsidian stone gargoyle guardian, muscular grey demonic beast carved from volcanic rock, broad stone wings on back, glowing red molten eyes, menacing hunched stance, holding a giant spiked magma war mace. 4x4 grid character spritesheet with idle and ground slam animations facing 4 directions: front, back, left, right. Stylized 2D RPG game art, sharp dark outlines, isolated on solid plain white background, no ground texture --v 6.0 --ar 1:1
```

---

## 5.2 Kategori Senjata Modular & Senjata Bos

### 4. Senjata Modular Penjaga (Sheet 3 Senjata: Pedang, Tongkat, Gada)
* **Format:** Sprite Sheet Grid 3 Senjata (Tampak samping/diagonal untuk slot tangan)
* **Target File:** `assets/sprites/characters/guard/weapons_guard_sheet.png`
* **Prompt AI:**
```text
A clean 2D game weapon item sheet containing 3 distinct fantasy weapons in a row, dark fantasy RPG underworld theme, isolated on solid plain white background:
1. Flame Greatsword: Heavy jagged obsidian broadsword with burning fiery orange edges and demonic crossguard.
2. Void Staff: Ancient dark twisted root staff topped with a hovering glowing violet ethereal crystal orb.
3. Chaos Mace: Heavy spiked volcanic stone flanged war mace with burning crimson magma cracks.
High resolution stylized clean vector 2D game art, sharp outlines, vibrant glowing highlights, side-view isolated sprites --v 6.0 --ar 3:1
```

---

### 5. Senjata Utama Bos Ruang Tahta (Sheet 3 Senjata Bos)
* **Format:** Sprite Sheet Grid 3 Senjata Legendaris Bos
* **Target File:** `assets/sprites/characters/demon/weapons_boss_sheet.png`
* **Prompt AI:**
```text
A clean 2D game boss weapon sprite sheet containing 3 colossal legendary underworld weapons in a row, isolated on solid plain white background:
1. Flame Scythe: Gigantic grim reaper scythe forged from demon bone with a massive curved blade made of roaring hellfire.
2. Cursed Blade: Terrifying jagged dark-matter obsidian cursed sword pulsing with necrotic purple soul-draining energy and glowing cursed runes along the blade edge.
3. Blood Trident: Colossal three-pronged demonic trident made of dark crimson obsidian with glowing magma spikes.
High resolution stylized RPG fantasy game assets, glowing runes, sharp clean borders, isolated on plain white background --v 6.0 --ar 3:1
```

---

## 5.3 Kategori Attack Visual Effects (VFX Serangan)

### 6. `vfx_flame_slash.png` (Animasi Sabetan Api - Fisik/Api)
* **Target File:** `assets/sprites/effects/vfx_flame_slash.png`
* **Format:** Horizontal Sprite Sheet (4 Frame Efek Sabetan)
* **Prompt AI:**
```text
2D game VFX animation sprite sheet of a fiery crescent sword slash arc, 4 sequential animation frames in a horizontal strip showing ignition, wide curved flame slash impact, blazing fire trail, and dissipation. Stylized anime RPG battle effect, intense bright orange and yellow fire core with dark red ember smoke, transparent-friendly isolated on solid plain white background, game ready VFX strip --v 6.0 --ar 4:1
```

---

### 7. `vfx_void_orb.png` (Animasi Proyektil Sihir - Void/Magic)
* **Target File:** `assets/sprites/effects/vfx_void_orb.png`
* **Format:** Horizontal Sprite Sheet (4 Frame Proyektil & Ledakan)
* **Prompt AI:**
```text
2D game VFX animation sprite sheet of a dark void magic projectile and explosion, 4 sequential animation frames in a horizontal strip: glowing purple dark magic orb traveling, expanding vortex, explosive cosmic shockwave burst, and fading shadow particles. Stylized 2D RPG spell effect, vibrant magenta and deep violet glow, isolated on solid plain white background --v 6.0 --ar 4:1
```

---

### 8. `vfx_earth_bash.png` (Animasi Hantaman Tanah - Tank/Batu)
* **Target File:** `assets/sprites/effects/vfx_earth_bash.png`
* **Format:** Horizontal Sprite Sheet (4 Frame Hantaman & Retakan)
* **Prompt AI:**
```text
2D game VFX animation sprite sheet of a ground smash earthquake shockwave, 4 sequential animation frames in a horizontal strip: heavy mace impact flash, volcanic rock spikes erupting from ground, bursting magma debris, and settling dust. Stylized 2D RPG combat impact, glowing molten lava sparks, isolated on solid plain white background --v 6.0 --ar 4:1
```

---

## 5.4 Kategori Emblem Segel Gerbang (3 Elemental Seals)

### 9. `seals_gate_sheet.png` (Sheet 3 Segel Magis Gerbang)
* **Target File:** `assets/sprites/map/obstacles/seals_gate_sheet.png`
* **Format:** Grid 3 Emblem Lingkaran Segel ($1 \times 3$)
* **Prompt AI:**
```text
A clean 2D game UI icon sheet of 3 ancient circular demonic magical seals in a horizontal row, dark fantasy RPG theme, isolated on solid plain white background:
1. Seal of Flame: Glowing burning infernal red circular runic glyph with roaring fire patterns and molten rock bezel.
2. Seal of Shadow: Dark violet and black cosmic circular seal with glowing arcane eye and void tendrils.
3. Seal of Blood: Crimson gothic circular seal with demonic bat-wing engravings and glowing blood runes.
High resolution stylized clean vector UI icons, high contrast, glowing magical borders, perfectly spaced --v 6.0 --ar 3:1
```

---

## 5.5 Kategori 9 Avatar Portrait Duel (Guard Archetype $\times$ Weapon)

> 💡 **Master Grid 9 Avatar ($3 \times 3$):**  
> Prompt ini menghasilkan lembaran grid berisi 9 portrait unik untuk HUD pertarungan, mewakili seluruh 9 kombinasi CSP antara 3 Tipe Penjaga dengan 3 Tipe Senjata!

### 10. `avatar_grid_9guards.png` (Grid 9 Portrait Pertarungan Duel)
* **Target File:** `assets/sprites/characters/guard/avatar_grid_9guards.png`
* **Format:** Grid $3 \times 3$ (9 Square Battle Portrait Icons)
* **Prompt AI:**
```text
A clean 2D game UI avatar portrait sheet in a neat 3x3 grid containing 9 distinct square RPG battle portraits with dark metallic gothic borders, dark fantasy hell theme, isolated on solid plain white background:
Row 1 (Infernal Knight Archetype):
1. Hell Knight wearing horned helmet holding a glowing fiery broadsword.
2. Hell Knight holding an ancient void staff with purple magical eye reflections.
3. Hell Knight holding a heavy spiked chaos war mace with glowing molten cracks.
Row 2 (Abyssal Shaman Archetype):
4. Hooded purple demonic shaman channeling flames onto an obsidian sword.
5. Hooded purple demonic shaman clutching a glowing purple crystal void staff.
6. Hooded purple demonic shaman holding a heavy dark ceremonial chaos mace.
Row 3 (Obsidian Gargoyle Archetype):
7. Menacing grey stone gargoyle wielding a burning molten greatsword.
8. Menacing grey stone gargoyle with glowing purple eyes holding a void staff.
9. Menacing grey stone gargoyle holding a giant spiked magma chaos mace.
Consistent stylized 2D digital art style, high contrast, clean square icon frames, game ready HUD portraits, no background noise --v 6.0 --ar 1:1
```

---

## 5.6 Kategori Standing Battle Portraits (Arena Duel Turn-Based)

> 💡 **Perbedaan Battle Portrait vs Avatar:**  
> Avatar (`avatar_*.png`) adalah foto profil bulat kecil $64 \times 64$ untuk kartu HP di atas layar. Sedangkan **Battle Portrait** (`*_portrait.png`) adalah ilustrasi karakter berdiri penuh ukuran besar ($256 \times 256$ / $512 \times 512$) di atas panggung arena pertarungan turn-based menghadap lawan (menghadap kiri ke arah pemain).

### 11. minion_portrait.png (Full Battle Stance Minion Imp - Kroco / Low-Level Monster)
* **Target File:** ssets/sprites/characters/minion/minion_portrait.png
* **Format:** Full Standing Illustration / Battle Portrait (256x256 atau 512x512)
* **Status:** Selesai / Terintegrasi (Ekstraksi Spritesheet Aktif, Siap HD Remaster)
* **Karakteristik Visual In-Game:** Berukuran kecil/kroco (goblin-sized), kepala bulat besar dengan kuping lancip panjang, mata kuning menyala usil/tengil, bertanduk kecil melengkung, tubuh mungil agak buncit memakai cawat kain cokelat compang-camping, ekor panah iblis kecil, **TANPA SAYAP**, dan bukan iblis berotot kekar.
* **Prompt AI Rekomendasi (Akurat Sesuai In-Game Sprite):**
`	ext
2D stylized RPG game battle portrait of a tiny mischievous lesser imp demon, small stubby goblin-sized creature standing in a cheeky combat stance facing left, oversized round head with smooth bright red skin, pair of short ridged dark horns, big pointed elf ears, large glowing bright yellow eyes, mischievous sharp-toothed grin, small chubby body with little limbs, wearing a simple tattered brown cloth loincloth, thin pointy devil tail with arrow tip, NO wings, clean 2D game character art, bright vibrant colors, high contrast, isolated on solid plain white background, full body illustration, no floor shadow --v 6.0 --ar 1:1
`
* **Negative Prompt (Wajib Digunakan agar Tidak Terlalu Seram / Kekar):**
`	ext
wings, bat wings, dragon wings, muscular, buff, ripped six-pack, tall, giant monster, scary raid boss, demonic armor, rock armor, photorealistic, complex background, shadow on floor, realistic human anatomy
`

---

### 12. `guard_portrait.png` / `guard_knight_portrait.png` (Infernal Knight Battle Stance)
* **Target File:** `assets/sprites/characters/guard/guard_portrait.png`
* **Format:** Full Standing Illustration / Battle Portrait (256x256 atau 512x512)
* **Status:** Selesai / Terintegrasi (Ekstraksi Spritesheet Aktif, Siap HD Remaster)
* **Prompt AI (HD Remaster):**
```text
2D stylized dark fantasy game battle portrait of an elite hell gatekeeper knight, standing battle stance facing left towards opponent, wearing menacing heavy black spiked obsidian plate armor with molten lava veins, horned dark steel helm with glowing red eye slits, holding a heavy tower shield in front and a massive flaming broadsword ablaze with roaring orange fire. High quality 2D RPG turn-based duel character art, sharp clean outlines, epic infernal lighting, isolated on solid plain white background, full body illustration --v 6.0 --ar 1:1
```

---

### 13. `guard_shaman_portrait.png` (Abyssal Shaman Battle Stance)
* **Target File:** `assets/sprites/characters/guard/guard_shaman_portrait.png`
* **Format:** Full Standing Illustration / Battle Portrait (256x256 atau 512x512)
* **Status:** Siap Generate
* **Prompt AI:**
```text
2D stylized dark fantasy game battle portrait of a sinister abyssal demonic shaman sorcerer, levitating floating stance facing left towards opponent, tattered dark purple and obsidian-black hooded robes, demonic horned bone skull mask, glowing ethereal violet void magic swirling around hands and ancient gnarly crystal staff topped with a hovering pulsing purple dark-matter orb. Clean 2D turn-based RPG battle character art, high contrast glowing magical aura, isolated on solid plain white background --v 6.0 --ar 1:1
```

---

### 14. `guard_gargoyle_portrait.png` (Obsidian Gargoyle Battle Stance)
* **Target File:** `assets/sprites/characters/guard/guard_gargoyle_portrait.png`
* **Format:** Full Standing Illustration / Battle Portrait (256x256 atau 512x512)
* **Status:** Siap Generate
* **Prompt AI:**
```text
2D stylized dark fantasy game battle portrait of a monstrous obsidian stone gargoyle guardian, hulking aggressive crouched stance facing left towards opponent, massive muscular volcanic rock body, broad stone gargoyle wings spread, glowing molten crimson eyes and magma fissures along chest and shoulders, gripping a colossal spiked volcanic stone war mace with burning red cracks. Clean 2D turn-based RPG battle character art, heavy dark fantasy aesthetic, isolated on solid plain white background --v 6.0 --ar 1:1
```

---

## ✂️ Panduan Ekstraksi & Implementasi Aset

1. **Hapus Background:**
   * Buka hasil generasi di browser dan gunakan tool gratis seperti [remove.bg](https://www.remove.bg/) atau Canva Background Remover.
2. **Crop Sesuai Ukuran:**
   * Untuk sheet grid (senjata, segel, avatar), potong (*crop*) tiap kotak ikon ke resolusi standar game (`64x64` atau `128x128`).
3. **Simpan ke Direktori Proyek Godot:**
   * Masukkan ke dalam folder `infernal-affairs/assets/sprites/`.
   * Buka Godot Engine agar texture di-import secara otomatis sebagai `CompressedTexture2D`.
