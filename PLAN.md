# RANCANGAN IMPLEMENTASI TUBES TAHAP 3: INFERNAL AFFAIRS
## Hybrid AI System: Constraint Satisfaction Problem (CSP) & Local Search Dynamic Balancer

Dokumen ini merangkum seluruh perencanaan arsitektur, formulasi algoritma AI (CSP & Local Search), alur gameplay terintegrasi, desain *Pre-Battle Loading Debug Overlay*, serta daftar aset visual dan audio tambahan yang dibutuhkan untuk menyelesaikan **Tubes Tahap 3 (Kecerdasan Buatan)**.

---

## 1. Ringkasan Visi & Alur Gameplay Terintegrasi

Tubes Tahap 3 mengombinasikan seluruh capaian dari tahap sebelumnya menjadi satu ekosistem game RPG taktis neraka yang utuh:
* **Tahap 1 (Pathfinding - A*):** Digunakan untuk pergerakan NPC di map labirin dan pengejaran patroli.
* **Tahap 2 (Adversarial Search - Minimax with Alpha-Beta):** Digunakan saat masuk ke arena turn-based duel.
* **Tahap 3 (Konfigurasi Optimal - CSP & Local Search):** Digunakan sebagai **AI Sutradara (*Encounter Director*)** yang mengatur komposisi formasi benteng (CSP) dan mengoptimasi stat/loadout musuh secara dinamis (Local Search) sebelum duel dimulai agar pertarungan seimbang (*tidak terlalu gampang, tidak terlalu sulit*).

```
[SPAWN PLAYER] 
  (Level 1, 100 HP, 1 Potion, Basic Stats)
         │
         ▼
[FASE 1: GRINDING & LOOTING]
  - Minion berkeliaran dengan jalan lambat (A*).
  - Player duel turn-based dengan Minion (Minimax Depth 1-2).
  - Menang duel -> Naik ke Level 2 + Loot Potion & EXP.
         │
         ▼
[FASE 2: GERBANG PENJAGA ISTANA]
  - Menuju gerbang istana (Ada Unary Constraint CSP: Syarat Min. Level 2).
  - Jika level cukup, gerbang terbuka untuk duel.
  - [PRE-BATTLE LOADING OVERLAY AKTIF]:
    Local Search (Hill Climbing / Simulated Annealing) membaca stat Player
    dan mengoptimasi konfigurasi Penjaga (HP, Atk, Def, Item, Minimax Depth).
  - Kalahkan Penjaga -> Drop "Castle Key" + Naik ke Level 3.
         │
         ▼
[FASE 3: RUANG TAHTA BOS ISTANA]
  - Menggunakan Castle Key untuk membuka pintu tahta Bos Neraka.
  - [PRE-BATTLE LOADING OVERLAY AKTIF]:
    Local Search mengoptimasi loadout Bos (HP tebal, Heavy Damage, Potion, Depth 3-4).
  - Duel final klimaks melawan Bos Neraka.
  - Bos kalah -> [VICTORY SCREEN] Penaklukan Istana Neraka Sukses!
```

---

## 2. Formulasi CSP (Constraint Satisfaction Problem)

Sesuai materi kuliah Modul 6, CSP menentukan **aturan penugasan benteng (*Castle Defense Assignment*)** sebelum musuh di-spawn. CSP menjamin solusi bersifat **Complete** dan **Consistent**.

### 2.1 Komponen Triplet $\langle X, D, C \rangle$

#### A. Variabel ($X$)
1. $X_{\text{guard\_type}}$: Tipe karakter Penjaga Gerbang.
2. $X_{\text{boss\_weapon}}$: Senjata / Elemen Bos Tahta.
3. $X_{\text{gate\_req}}$: Syarat level minimal untuk menantang Penjaga Gerbang.
4. $X_{\text{castle\_potions}}$: Kuota total potion yang disediakan oleh gudang logistik istana.

#### B. Domain ($D$)
1. $D(X_{\text{guard\_type}}) = \{\text{Hell Knight (Fisik)}, \text{Fire Shaman (Sihir)}, \text{Gargoyle (Tank)}\}$
2. $D(X_{\text{boss\_weapon}}) = \{\text{Flame Sword}, \text{Cursed Scythe}, \text{Dark Trident}\}$
3. $D(X_{\text{gate\_req}}) = \{2, 3\}$
4. $D(X_{\text{castle\_potions}}) = \{2, 3, 4\}$

#### C. Batasan / Constraints ($C$)
1. **Unary Constraint (Satu Variabel):**
   * Syarat gerbang tidak boleh mengizinkan player Level 1 langsung masuk:
     $$X_{\text{gate\_req}} \ge 2$$
   * Senjata Bos tidak boleh berstatus unequipped/kosong:
     $$X_{\text{boss\_weapon}} \neq \text{None}$$
2. **Binary Constraint (Dua Variabel):**
   * **Diversifikasi Taktik Benteng:** Elemen/tipe Penjaga Gerbang tidak boleh identik dengan elemen senjata Bos agar Player dituntut menggunakan taktik berbeda di tiap tahap:
     $$\text{Element}(X_{\text{guard\_type}}) \neq \text{Element}(X_{\text{boss\_weapon}})$$
3. **Global Constraint (Banyak Variabel):**
   * **Alokasi Logistik Istana:** Jumlah total potion yang dibawa Penjaga dan Bos tidak boleh melebihi pasokan logistik istana:
     $$\text{Potion}_{\text{Guard}} + \text{Potion}_{\text{Boss}} \le X_{\text{castle\_potions}}$$

### 2.2 Syarat Keabsahan Solusi CSP
* **Complete:** Seluruh variabel ($X_1, X_2, X_3, X_4$) terisi nilai (*assigned*).
* **Consistent:** Tidak ada pelanggaran terhadap constraint unary, binary, maupun global.
* **Metode Penyelesaian:** Algoritma **Backtracking Search** dipercepat dengan heuristik **MRV (Minimum Remaining Values)**, tie-breaker **Degree Heuristic**, urutan nilai **LCV (Least Constraining Value)**, dan inferensi propagasi **AC-3 (Arc Consistency)**.

---

## 3. Formulasi Local Search & Optimization (Dynamic Balancer)

Setelah CSP menentukan kerangka legal benteng, algoritma Local Search dipanggil tepat sebelum duel (pada fase loading transition) untuk menemukan **titik keseimbangan optimal** (*difficulty curve*).

### 3.1 State Representation (Vektor Konfigurasi Musuh)
Satu konfigurasi musuh sebelum bertarung direpresentasikan sebagai vektor parameter berukuran memori $O(1)$:
$$S = [HP, Atk, HeavyAtk, Def, PotionCount, PotionHeal, MinimaxDepth]$$

*Rentang Nilai Variabel:*
* $HP \in [60, 250]$
* $Atk \in [8, 30]$
* $HeavyAtk \in [16, 50]$
* $Def \in [2, 12]$
* $PotionCount \in [0, 3]$
* $PotionHeal \in [20, 45]$
* $MinimaxDepth \in [1, 4]$

### 3.2 Neighbourhood Function (Langkah Tetangga / Successor)
State tetangga $S'$ diperoleh melalui 1 langkah perubahan lokal (perturbasi acak):
* $HP \leftarrow HP \pm 10$
* $Atk \leftarrow Atk \pm 2$
* $HeavyAtk \leftarrow HeavyAtk \pm 3$
* $Def \leftarrow Def \pm 1$
* $PotionCount \leftarrow PotionCount \pm 1$
* $MinimaxDepth \leftarrow MinimaxDepth \pm 1$
*(Dengan validasi clamping batas min-max).*

### 3.3 Objective / Fitness Function $f(S)$ (Formula Keseimbangan Game)
Target desain: **Win Rate Player $\approx 55\%$ (duel seru & adil) dan Durasi Duel $\approx 5 - 7$ Ronde.**

Nilai evaluasi dihitung berdasarkan gap kekuatan teoretis (*Combat Power Gap*) terhadap kondisi aktual Player:
$$\text{Power}_{\text{Player}} = HP_{\text{Player}} + (Atk_{\text{Player}} \times 2.5) + (Def_{\text{Player}} \times 3.0) + (Potion_{\text{Player}} \times 20)$$
$$\text{Power}_{\text{NPC}}(S) = HP + (Atk \times 2.2) + (HeavyAtk \times 1.2) + (Def \times 3.0) + (PotionCount \times PotionHeal \times 0.7) + (MinimaxDepth \times 15)$$

Fungsi objektif yang ingin **dimaksimalkan** (semakin mendekati 0 semakin sempurna):
$$f(S) = - \left( |\text{Power}_{\text{NPC}}(S) - (\text{Power}_{\text{Player}} \times \text{TargetRatio})| \right)$$
* Untuk Penjaga: $\text{TargetRatio} = 1.05$ (sedikit lebih kuat dari player).
* Untuk Bos: $\text{TargetRatio} = 1.25$ (bos menantang, membutuhkan taktik potion & defend yang matang).

### 3.4 Algoritma yang Disediakan & Dibandingkan
1. **Hill Climbing (Steepest-Ascent):** Selalu memilih tetangga terbaik. Jika tidak ada perbaikan, berhenti (mendeteksi *Local Maximum* / *Plateau*).
2. **Hill Climbing + Random Restart:** Mengulang pencarian dari seed acak baru jika buntu di *local optimum*.
3. **Simulated Annealing (SA):**
   * Suhu awal $T_0 = 100.0$, Cooling schedule $T \leftarrow T \times 0.95$, Ambang henti $\epsilon = 0.05$.
   * Jika $\Delta E = f(S') - f(S) > 0$, selalu terima state baru.
   * Jika $\Delta E \le 0$, terima langkah lebih buruk (*downhill*) dengan probabilitas:
     $$P = e^{\frac{\Delta E}{T}}$$
   * Mengizinkan eksplorasi keluar dari jurang (*ridge*) dan puncak palsu (*local optimum*).

---

## 4. Desain Pre-Battle Loading Debug Overlay

Untuk kebutuhan presentasi akademis, saat player menabrak/menantang Penjaga atau Bos, game menampilkan **Layar Transisi / Loading Screen Berisi Live Debug Overlay**:

### 4.1 Elemen Tampilan Loading Overlay
1. **Panel Player Profile (Kondisi Nyata):**
   * Menampilkan HP saat ini, Level, Jumlah Potion, dan Perkiraan Combat Power.
2. **Visualizer Proses Pencarian (Real-Time):**
   * Progress bar iterasi langkah ($t = 1 \dots 50$).
   * Teks log pergerakan state:
     * `[Step 04] Try: +1 Potion, -2 Atk -> Score: -24.5 -> ACCEPTED`
     * `[Step 07] Try: +1 Depth -> Score: -38.0 -> DOWNHILL ACCEPTED (P=0.62, T=45.2)` *(khusus SA)*
     * `[Step 15] No better neighbour -> STUCK AT LOCAL MAXIMUM` *(khusus HC)*
3. **Panel Hasil Konfigurasi Akhir:**
   * Kartu Stat Musuh sebelum vs sesudah dioptimasi:
     * HP Awal $\to$ HP Optimal
     * Minimax Depth Awal $\to$ Depth Optimal
     * Potion & Stat Damage Terpilih
4. **Kontrol Interaktif Presentasi:**
   * Tombol `[Lanjut ke Battle]` (atau countdown otomatis 2.5 detik).
   * Tombol `[Ganti Algoritma: HC vs SA]` untuk demo langsung di depan dosen.

---

## 5. Rincian Kebutuhan Aset Tambahan (Lengkap & Detail)

### 5.1 Aset Visual: Karakter & NPC
| Nama Aset | Tipe | Deskripsi & Spesifikasi | Status Saat Ini |
| :--- | :--- | :--- | :--- |
| `minion_imp.png` | Spritesheet | Karakter minion kecil bertanduk merah, jalan lambat, animasi Idle & Walk. | Perlu Dibuat |
| `guard_knight.png` | Spritesheet | Penjaga gerbang berperisai hitam & pedang api, badan tegap, animasi Idle & Attack. | Perlu Dibuat |
| `demon_boss.png` | Spritesheet | Bos besar penguasa istana neraka (sudah ada basisnya, perlu penyesuaian avatar tahta). | Sudah Ada / Poles |
| `avatar_minion.png` | UI Portrait | Foto profil bulat/persegi untuk HUD pertarungan Minion (64x64). | Perlu Dibuat |
| `avatar_guard.png` | UI Portrait | Foto profil bulat/persegi untuk HUD pertarungan Penjaga Gerbang (64x64). | Perlu Dibuat |

### 5.2 Aset Visual: Map, Environment & Props
| Nama Aset | Tipe | Deskripsi & Spesifikasi | Status Saat Ini |
| :--- | :--- | :--- | :--- |
| `gate_hell_closed.png` | Sprite / Tile | Gerbang besi neraka tertutup rantai magis (menghalangi masuk jika level < 2). | Perlu Dibuat |
| `gate_hell_open.png` | Sprite / Tile | Gerbang besi neraka terbuka lebar setelah syarat level / kunci terpenuhi. | Perlu Dibuat |
| `castle_walls.png` | Tileset | Dinding benteng bata batu hitam obsidian untuk area ruang tahta Bos. | Perlu Dibuat |
| `throne_boss.png` | Prop Sprite | Kursi tahta tengkorak berapi di belakang posisi berdiri Bos Istana. | Perlu Dibuat |
| `gate_warning_sign.png`| Prop / UI | Tanda seru menyala di depan gerbang bertuliskan simbol larangan Level 1. | Perlu Dibuat |

### 5.3 Aset Visual: UI & Icon Khusus
| Nama Aset | Tipe | Deskripsi & Spesifikasi | Status Saat Ini |
| :--- | :--- | :--- | :--- |
| `icon_castle_key.png` | UI Icon | Kunci emas kuno berukir kepala iblis (32x32 / 64x64). | Perlu Dibuat |
| `icon_level_badge.png` | UI Icon | Badge emblem level player (Level 1, 2, 3) di HUD utama. | Perlu Dibuat |
| `panel_loading_bg.png` | UI Background| Latar gelap transparan beraksen neon/magma untuk layar transisi kalkulasi AI. | Perlu Dibuat |
| `icon_algorithm_chip.png`| UI Icon | Ikon chip sirkuit / otak AI untuk indikator Local Search aktif. | Perlu Dibuat |
| `icon_heavy_attack.png` | UI Icon | Ikon pedang menyala ganda untuk aksi Heavy Attack (32x32). | Perlu Dibuat |

### 5.4 Aset Audio & Sound Effects (SFX)
| Nama Aset | Format | Deskripsi Suara | Status Saat Ini |
| :--- | :--- | :--- | :--- |
| `sfx_encounter_alert.wav` | SFX | Bunyi drum dentuman tegang saat menabrak penjaga / bos. | Perlu Ditambah |
| `sfx_balancer_tick.wav` | SFX | Suara klik digital cepat saat Local Search menguji iterasi tetangga di loading overlay. | Perlu Ditambah |
| `sfx_gate_unlock.wav` | SFX | Suara rantai berat putus dan gerbang batu bergeser terbuka. | Perlu Ditambah |
| `sfx_level_up.wav` | SFX | Denting kemenangan fanfare pendek saat naik level. | Perlu Ditambah |
| `bgm_boss_chamber.ogg` | BGM | Musik orkestra dramatis ritme cepat untuk pertarungan ruang tahta Bos. | Perlu Ditambah |

---

## 6. Rencana Tahapan Eksekusi (Implementation Steps)

1. **Step 1 - Data Architecture & Player Stats:**
   * Tambahkan sistem `Level`, `Exp`, dan inventory `CastleKey` pada `PlayerData`.
   * Perluas `BattleState` agar mendukung parameter dinamis: `HeavyAttack`, `PotionCount`, `PotionHealValue`, dan `MinimaxDepth`.

2. **Step 2 - CSP Solver Module (`CSPSolver.gd`):**
   * Implementasikan struktur data $X, D, C$.
   * Tulis algoritma Backtracking dengan MRV, LCV, dan AC-3.
   * Uji coba pembangkitan konfigurasi benteng konsisten dan komplit saat game dimuat.

3. **Step 3 - Local Search Dynamic Balancer (`LocalSearchBalancer.gd`):**
   * Tulis fungsi penghitung Fitness/Objective $f(S)$.
   * Implementasikan Hill Climbing (dengan deteksi local maximum) dan Simulated Annealing (dengan parameter suhu $T$ dan cooling schedule).

4. **Step 4 - Pre-Battle Loading Screen & Debug Visualizer Scene:**
   * Buat scene transisi UI baru (`PreBattleLoadingScene.tscn`).
   * Hubungkan pemanggilan Local Search ke animasi visual step-by-step.
   * Tambahkan tombol toggle algoritma untuk demo dosen.

5. **Step 5 - Map Expansion & Level Gating:**
   * Pasang entitas Penjaga Gerbang di map dengan deteksi level player.
   * Pasang pintu ruang tahta Bos dengan syarat Kunci Istana.
   * Integrasikan transisi scene dari Map $\to$ Pre-Battle Loading $\to$ Turn-Based Arena $\to$ Map/Victory.

6. **Step 6 - Penulisan Laporan & Dokumentasi:**
   * Masukkan tabel komparasi matematis CSP (MRV vs tanpa MRV) dan Local Search (Hill Climbing vs SA).
   * Dokumentasikan screenshot Pre-Battle Loading Screen sebagai bukti implementasi nyata.
