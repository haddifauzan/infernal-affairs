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
  - Konfigurasi Penjaga ditentukan oleh CSP Solver (Tipe, Senjata, Segel Gerbang).
  - [PRE-BATTLE LOADING OVERLAY AKTIF]:
    Local Search (Hill Climbing / Simulated Annealing) membaca stat Player
    dan mengoptimasi konfigurasi Penjaga (HP, Atk, Def, Item, Minimax Depth).
  - Kalahkan Penjaga -> Drop "Castle Key" + Naik ke Level 3.
         │
         ▼
[FASE 3: RUANG TAHTA BOS ISTANA]
  - Menggunakan Castle Key untuk membuka pintu tahta Bos Neraka.
  - Senjata Bos ditentukan oleh relasi CSP (Anti-Monopoly & Resonansi Segel).
  - [PRE-BATTLE LOADING OVERLAY AKTIF]:
    Local Search mengoptimasi loadout Bos (HP tebal, Heavy Damage, Potion, Depth 3-4).
  - Duel final klimaks melawan Bos Neraka.
  - Bos kalah -> [VICTORY SCREEN] Penaklukan Istana Neraka Sukses!
```

---

## 2. Formulasi CSP (Constraint Satisfaction Problem)

Sesuai materi perkuliahan Kecerdasan Buatan (Modul Constraint Satisfaction Problem), CSP menentukan **aturan penugasan benteng (*Castle Defense Assignment*)** sebelum musuh di-spawn ke dalam dunia game. CSP menjamin penugasan variabel bersifat **Complete** dan **Consistent** melalui representasi formal triplet $\langle X, D, C \rangle$.

Pada Tubes Tahap 3 ini, CSP diformulasikan untuk membentuk **graf kekangan yang saling mengunci (*cyclic/interconnected network*)** dengan **6 Variabel Utama**, sehingga inferensi pemangkasan domain **AC-3 (Arc Consistency)**, serta heuristik **MRV (Minimum Remaining Values)**, **Degree Heuristic**, dan **LCV (Least Constraining Value)** terbukti bekerja secara aktif dan terukur.

Seluruh konfigurasi dihasilkan dalam **satu kali eksekusi CSP** di awal sesi permainan dan langsung mengendalikan:
1. Jenis musuh Penjaga Gerbang (*Gate Guard*).
2. Segel Magis penghalang gerbang istana (*Gate Seal*) beserta efek pasif medan tempurnya.
3. Doktrin/Sifat strategi AI Penjaga (*Guard AI Strategy*).
4. Senjata legendaris Bos Neraka di Ruang Tahta (*Boss Weapon*) beserta efek pasif uniknya.
5. Doktrin/Sifat strategi AI Bos Neraka (*Boss AI Strategy*).
6. Kuota logistik potion istana (*Castle Potions*) & syarat level masuk gerbang (*Gate Level Requirement*).

---

### 2.1 Komponen Triplet $\langle X, D, C \rangle$

#### A. Himpunan Variabel ($X$)
1. $X_{\text{guard\_type}}$: Tipe/Archetype karakter Penjaga Gerbang istana.
2. $X_{\text{gate\_seal}}$: Jenis segel magis yang mengunci gerbang neraka (memiliki efek medan aktif).
3. $X_{\text{guard\_strategy}}$: Doktrin taktik Minimax yang diterapkan oleh Penjaga Gerbang.
4. $X_{\text{boss\_weapon}}$: Senjata utama Bos Neraka di Ruang Tahta (memiliki efek unik pasif).
5. $X_{\text{boss\_strategy}}$: Doktrin taktik Minimax yang diterapkan oleh Bos Neraka.
6. $X_{\text{gate\_req}}$: Syarat level minimal player untuk menantang Penjaga Gerbang.
7. $X_{\text{castle\_potions}}$: Kuota total potion logistik istana neraka.

#### B. Himpunan Domain ($D$)
1. $D(X_{\text{guard\_type}}) = \{\text{Infernal Knight}, \text{Abyssal Shaman}, \text{Obsidian Gargoyle}\}$
2. $D(X_{\text{gate\_seal}}) = \{\text{Seal of Flame}, \text{Seal of Shadow}, \text{Seal of Blood}\}$
3. $D(X_{\text{guard\_strategy}}) = \{\text{Aggressive}, \text{Defensive}, \text{Tactical}\}$
4. $D(X_{\text{boss\_weapon}}) = \{\text{Flame Scythe}, \text{Cursed Blade}, \text{Blood Trident}\}$
5. $D(X_{\text{boss\_strategy}}) = \{\text{Aggressive}, \text{Defensive}, \text{Tactical}\}$
6. $D(X_{\text{gate\_req}}) = \{2, 3\}$
7. $D(X_{\text{castle\_potions}}) = \{2, 3, 4\}$

#### C. Himpunan Batasan / Constraints ($C$)

##### 1. Unary Constraints (Node Consistency)
* **Kekangan Masuk Gerbang:** Syarat gerbang tidak boleh mengizinkan player Level 1 langsung masuk:
  $$X_{\text{gate\_req}} \ge 2$$
* **Kelayakan Persenjataan Bos:** Senjata Bos tidak boleh berstatus kosong:
  $$X_{\text{boss\_weapon}} \neq \text{None}$$

##### 2. Binary Constraints (Relasi Antar Dua Variabel pada Graf)
1. **Constraint 1 (Affinity: $X_{\text{guard\_type}} \leftrightarrow X_{\text{gate\_seal}}$):**
   Penjaga hanya mampu menyalurkan dan menjaga segel magis yang selaras dengan afinitas elemennya:
   * *Infernal Knight (Api)* $\in \{\text{Seal of Flame}, \text{Seal of Blood}\}$ *(tidak kompatibel dengan Seal of Shadow)*.
   * *Abyssal Shaman (Kegelapan)* $\in \{\text{Seal of Shadow}, \text{Seal of Blood}\}$ *(tidak kompatibel dengan Seal of Flame)*.
   * *Obsidian Gargoyle (Batu/Bumi)* $\in \{\text{Seal of Flame}, \text{Seal of Shadow}\}$ *(tidak kompatibel dengan Seal of Blood)*.

2. **Constraint 2 (Doctrine Compatibility: $X_{\text{guard\_type}} \leftrightarrow X_{\text{guard\_strategy}}$):**
   Gaya tempur Minimax Penjaga harus realistis dengan postur fisiknya:
   * *Infernal Knight (Agresif & Gesit)* $\in \{\text{Aggressive}, \text{Tactical}\}$.
   * *Abyssal Shaman (Rapuh tapi Licik)* $\in \{\text{Tactical}, \text{Defensive}\}$.
   * *Obsidian Gargoyle (Batu Keras Berzirah)* $\in \{\text{Defensive}, \text{Tactical}\}$.

3. **Constraint 3 (Resonance: $X_{\text{gate\_seal}} \leftrightarrow X_{\text{boss\_weapon}}$):**
   Segel pintu gerbang ditenagai langsung oleh resonansi aura dari senjata Bos di ruang tahta:
   $$\text{Resonates}(X_{\text{gate\_seal}}, X_{\text{boss\_weapon}}) = \text{True}$$
   * $\text{Seal of Flame} \iff \text{Flame Scythe}$
   * $\text{Seal of Shadow} \iff \text{Cursed Blade}$
   * $\text{Seal of Blood} \iff \text{Blood Trident}$

4. **Constraint 4 (Combat Tempo Diversity: $X_{\text{guard\_strategy}} \leftrightarrow X_{\text{boss\_strategy}}$):**
   Untuk menjamin variasi pengalaman bermain (*gameplay pacing*) dan mencegah repetisi taktik dalam satu siklus permainan:
   $$X_{\text{guard\_strategy}} \neq X_{\text{boss\_strategy}}$$
   *(Jika Penjaga berdoktrin Aggressive, Bos tidak boleh Aggressive; jika Penjaga Defensive, Bos harus Tactical atau Aggressive).*

5. **Constraint 5 (Element Anti-Monopoly: $X_{\text{guard\_type}} \leftrightarrow X_{\text{boss\_weapon}}$):**
   Elemen pertahanan Penjaga tidak boleh sama dengan senjata Bos, agar pemain terdorong mengubah pendekatan duel:
   $$\text{Element}(X_{\text{guard\_type}}) \neq \text{Element}(X_{\text{boss\_weapon}})$$
   * Jika *Infernal Knight (Fire)* $\implies X_{\text{boss\_weapon}} \neq \text{Flame Scythe}$.
   * Jika *Abyssal Shaman (Shadow)* $\implies X_{\text{boss\_weapon}} \neq \text{Cursed Blade}$.
   * Jika *Obsidian Gargoyle (Blood/Earth)* $\implies X_{\text{boss\_weapon}} \neq \text{Blood Trident}$.

##### 3. Global Constraint (Multi-Variabel)
* **Alokasi Potion Istana:** Jumlah total potion yang dibawa Penjaga dan Bos tidak boleh melebihi pasokan logistik istana:
  $$\text{Potion}_{\text{Guard}} + \text{Potion}_{\text{Boss}} \le X_{\text{castle\_potions}}$$
  *(Secara default: 1 potion dialokasikan untuk Penjaga, sisanya $\max(1, X_{\text{castle\_potions}} - 1)$ untuk Bos).*

---

### 2.2 Diagram Graf Kekangan (Constraint Graph)

```mermaid
graph TD
    GT["X_guard_type<br>(Knight / Shaman / Gargoyle)"]
    GS["X_gate_seal<br>(Flame / Shadow / Blood)"]
    G_ST["X_guard_strategy<br>(Aggressive / Defensive / Tactical)"]
    BW["X_boss_weapon<br>(Flame Scythe / Cursed Blade / Blood Trident)"]
    B_ST["X_boss_strategy<br>(Aggressive / Defensive / Tactical)"]
    GR["X_gate_req<br>(Level 2 / 3)"]
    CP["X_castle_potions<br>(2 / 3 / 4)"]

    GT ---|"C1: Affinity"| GS
    GT ---|"C2: Doctrine"| G_ST
    GS ---|"C3: Resonance"| BW
    G_ST ---|"C4: Diversity"| B_ST
    BW ---|"C5: Anti-Monopoly"| GT

    style GT fill:#4a1515,stroke:#ff5533,stroke-width:2px,color:#fff
    style GS fill:#153a4a,stroke:#33ccff,stroke-width:2px,color:#fff
    style G_ST fill:#2a1b40,stroke:#aa55ff,stroke-width:2px,color:#fff
    style BW fill:#4a1515,stroke:#ff5533,stroke-width:2px,color:#fff
    style B_ST fill:#2a3a15,stroke:#88ff33,stroke-width:2px,color:#fff
    style GR fill:#333333,stroke:#aaaaaa,stroke-width:1px,color:#fff
    style CP fill:#333333,stroke:#aaaaaa,stroke-width:1px,color:#fff
```

> **Dampak Akademis Arc Consistency (AC-3):**  
> Graf di atas memiliki siklus segitiga antara $X_{\text{guard\_type}}$, $X_{\text{gate\_seal}}$, dan $X_{\text{boss\_weapon}}$, serta rantai inferensi menuju $X_{\text{guard\_strategy}}$ dan $X_{\text{boss\_strategy}}$. Ketika Backtracking menetapkan suatu nilai variabel, AC-3 secara aktif memangkas domain variabel tetangga secara berantai (*cascade pruning*).

---

### 2.3 Dampak Mekanik Nyata ke Gameplay & Minimax

1. **Efek Pasif Segel Gerbang (*Gate Seal Effect* pada Duel Penjaga):**
   * **Seal of Flame (Medan Panas Neraka):** Suhu membara membakar stamina pemain. Setiap ronde pertempuran, player terkena 3 damage api tak langsung.
   * **Seal of Shadow (Kabut Penghisap Jiwa):** Penjaga memperoleh lifesteal pasif; setiap serangannya menyerap 15% damage menjadi pemulihan HP.
   * **Seal of Blood (Ketahanan Darah Iblis):** Kulit Penjaga mengeras; seluruh damage fisik yang diterima berkurang flat 4 poin.

2. **Efek Pasif Senjata Bos (*Boss Weapon Effect* pada Duel Tahta):**
   * **Flame Scythe (Infernal Burn):** Serangan Heavy Bos membakar player dengan efek DoT sebesar 5 HP per giliran selama 2 ronde.
   * **Cursed Blade (Soul Drain):** Serangan biasa Bos menyerap 20% damage menjadi HP bagi Bos.
   * **Blood Trident (Armor Piercing):** Serangan Bos menembus pertahanan player; aksi `Defend` player hanya mengurangi damage sebesar 20% (bukan 50%).

3. **Injeksi Doktrin CSP Langsung ke Mesin Minimax (`EvalFunc` & `ActionOrder`):**
   Variabel strategi dari CSP secara matematis mengendalikan parameter [MinimaxSolver.gd](file:///home/richi/Documents/GitHub/infernal-affairs/scripts/battle/MinimaxSolver.gd):
   * **AGGRESSIVE:**
     * `eval_func = EvalFunc.AGGRESSIVE` (Fungsi evaluasi berfokus mutlak meminimalisir HP pemain).
     * `action_order = ActionOrder.AGGRESSIVE` (Heuristik pemesanan aksi menguji `HEAVY_ATTACK` terlebih dahulu untuk pruning $\beta$ instan).
     * *Counter Pemain:* Pemain memanfaatkan sifat serakah ini dengan memasang `DEFEND` agar serangan berat musuh terblokir dan musuh menderita self-damage.
   * **DEFENSIVE:**
     * `eval_func = EvalFunc.DEFENSIVE` (Fungsi evaluasi berfokus memaksimalkan HP diri sendiri).
     * `action_order = ActionOrder.DEFENSIVE` (Menguji `DEFEND` & `POTION` pertama kali).
     * *Counter Pemain:* Pemain tidak tergesa-gesa menyerang saat perisai musuh aktif, melainkan memulihkan HP atau menyiapkan serangan berat.
   * **TACTICAL:**
     * `eval_func = EvalFunc.WEIGHTED` (Fungsi evaluasi mempertimbangkan selisih HP, stok potion, dan status defense seimbang).
     * `action_order = ActionOrder.DEFAULT`.
     * *Counter Pemain:* Duel murni adu taktik menguras potion musuh.

4. **Sistem Intelijen Pemain (Scouting via Warning Sign & Gerbang):**
   Pemain dapat memeriksa papan peringatan (*Gate Warning Sign*) di Courtyard sebelum bertarung untuk membaca laporan intelijen hasil CSP:
   * Mengidentifikasi nama Segel Gerbang, doktrin Penjaga, serta petunjuk resonansi senjata Bos di dalam tahta.
   * Pemain bertindak sebagai komandan taktis yang menyusun persiapan sebelum membuka duel.

### 2.3 Strategi Visualisasi 9 Variasi Karakter (Pendekatan Modular - Opsi A)

Untuk merepresentasikan 9 kemungkinan kombinasi Penjaga ($3 \text{ Guard Types} \times 3 \text{ Weapons}$) secara visual tanpa harus menggambar 9 spritesheet animasi raksasa dari nol, game menerapkan sistem **Modular Visuals**:

1. **3 Base Spritesheet Karakter Unik (Overworld & Battle):**
   * **Infernal Knight:** Tubuh zirah plate hitam obsidian tegap, helm tanduk api, animasi sabetan pedang.
   * **Abyssal Shaman:** Jubah bertudung ungu-hitam compang-camping, mengambang, animasi membaca mantra sihir.
   * **Obsidian Gargoyle:** Monster batu berkepak sayap, siluet bungkuk berotot, animasi hantaman tanah.
2. **3 Senjata / Aura Terpasang Dinamis:**
   * Node `Sprite2D` senjata dipasangkan (*attached*) ke bone/hand slot karakter, memancarkan efek partikel sesuai senjata terpilih (*Flame Greatsword*, *Void Staff*, atau *Chaos Mace*).
3. **9 Avatar Portrait Khusus untuk HUD Duel:**
   * Setiap kombinasi Guard Type + Weapon memiliki icon avatar portrait tersendiri pada HUD duel (contoh: *Knight with Greatsword*, *Knight with Mace*, *Shaman with Staff*, dst.).
4. **3 Efek Visual Serangan (Attack VFX Spritesheet):**
   * *Flame Slash VFX:* Sabetan pedang api melengkung membara.
   * *Void Orb VFX:* Bola proyektil sihir hitam-ungu meledak.
   * *Earth Bash VFX:* Hantaman gada batu retakan tanah berpendar.

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

## 5. Rincian Kebutuhan Aset Tambahan (Lengkap & Terstruktur)

### 5.1 Aset Visual: Karakter, Spritesheet & Standing Battle Portrait
| Nama Aset | Tipe | Deskripsi & Spesifikasi | Status |
| :--- | :--- | :--- | :--- |
| `minion_imp.png` | Spritesheet | Karakter imp merah kecil, bertanduk, animasi Idle & Walk 4-arah. | Selesai / Terintegrasi |
| `guard_knight.png` | Spritesheet | Base Guard Archetype 1: Ksatria zirah hitam berpedang api. | Selesai / Terintegrasi |
| `guard_shaman.png` | Spritesheet | Base Guard Archetype 2: Penyihir jubah bertudung ungu-hitam, melayang. | Selesai / Terintegrasi |
| `guard_gargoyle.png`| Spritesheet | Base Guard Archetype 3: Monster gargoyle batu bersayap kelabu. | Selesai / Terintegrasi |
| `player_portrait.png` | Battle Portrait | Ilustrasi berdiri Player Ksatria di panggung arena pertarungan turn-based. | Selesai / Terintegrasi |
| `minion_portrait.png` | Battle Portrait | Ilustrasi berdiri Minion Imp di panggung arena duel (menghadap kiri ke arah player). | Selesai / Terintegrasi |
| `guard_portrait.png` | Battle Portrait | Ilustrasi berdiri Penjaga Gerbang (Infernal Knight) zirah & perisai menara di arena duel. | Selesai / Terintegrasi |
| `guard_knight_portrait.png` | Battle Portrait | Ilustrasi berdiri Infernal Knight HD 512x512 berzirah obsidian membara. | Selesai / Terintegrasi |
| `guard_shaman_portrait.png` | Battle Portrait | Ilustrasi berdiri Abyssal Shaman melayang dengan tongkat void untuk panggung duel. | Selesai / Terintegrasi |
| `guard_gargoyle_portrait.png`| Battle Portrait | Ilustrasi berdiri Obsidian Gargoyle batu magma dengan gada raksasa untuk panggung duel. | Selesai / Terintegrasi |
| `demon_boss.png` | Spritesheet / Portrait | Bos besar iblis penguasa tahta neraka bermahkota tanduk di arena duel. | Selesai / Terintegrasi |

### 5.2 Aset Visual: Senjata Modular & VFX Serangan
| Nama Aset | Tipe | Deskripsi & Spesifikasi | Status |
| :--- | :--- | :--- | :--- |
| `weapons_guard_sheet.png` | Sprite Sheet | Sheet 3 senjata penjaga: Flame Greatsword, Void Staff, Chaos Mace. | Selesai / Terintegrasi |
| `weapons_boss_sheet.png` | Sprite Sheet | Sheet 3 senjata bos tahta: Flame Scythe, Cursed Blade, Blood Trident. | Selesai / Terintegrasi |
| `vfx_flame_slash.png` | VFX Spritesheet | Efek tebasan melengkung api membakar (4 frame animasi hit impact). | Selesai / Terintegrasi |
| `vfx_void_orb.png` | VFX Spritesheet | Efek tembakan bola energi gelap & ledakan (4 frame animasi hit impact). | Selesai / Terintegrasi |
| `vfx_earth_bash.png` | VFX Spritesheet | Efek retakan batu tanah magma saat dihantam (4 frame animasi hit impact). | Selesai / Terintegrasi |

### 5.3 Aset Visual: UI, Emblem Segel & Avatar HUD
| Nama Aset | Tipe | Deskripsi & Spesifikasi | Status |
| :--- | :--- | :--- | :--- |
| `seals_gate_sheet.png` | UI Emblem Sheet | Sheet 3 segel magis gerbang: Seal of Flame, Seal of Shadow, Seal of Blood. | Selesai / Terintegrasi |
| `avatar_grid_9guards.png` | UI Portrait Sheet | Sheet grid 9 avatar portrait duel (3x3) untuk tiap kombinasi Guard + Weapon. | Selesai / Terintegrasi |
| `icon_castle_key.png` | UI Icon | Kunci emas kuno berukir kepala iblis. | Selesai / Terintegrasi |
| `icon_level_badge.png` | UI Icon | Badge emblem level player (Level 1, 2, 3) di HUD. | Selesai / Terintegrasi |
| `panel_loading_bg.png` | UI Background | Latar kaca obsidian gelap transparan untuk layar transisi AI. | Selesai / Terintegrasi |
| `icon_algorithm_chip.png`| UI Icon | Ikon chip sirkuit / otak AI untuk indikator Local Search aktif. | Selesai / Terintegrasi |
| `icon_heavy_attack.png` | UI Icon | Ikon pedang menyala ganda untuk aksi Heavy Attack. | Selesai / Terintegrasi |

### 5.4 Aset Audio & Sound Effects (SFX)
| Nama Aset | Format | Deskripsi Suara | Status |
| :--- | :--- | :--- | :--- |
| `sfx_encounter_alert.wav` | SFX | Bunyi drum dentuman tegang saat menabrak penjaga / bos. | Selesai / Terintegrasi |
| `sfx_balancer_tick.wav` | SFX | Suara klik digital cepat saat Local Search menguji iterasi tetangga di loading overlay. | Selesai / Terintegrasi |
| `sfx_gate_unlock.wav` | SFX | Suara rantai berat putus dan gerbang batu bergeser terbuka. | Selesai / Terintegrasi |
| `sfx_level_up.wav` | SFX | Denting kemenangan fanfare pendek saat naik level. | Selesai / Terintegrasi |
| `bgm_boss_chamber.ogg` | BGM | Musik orkestra dramatis ritme cepat untuk pertarungan ruang tahta Bos. | Selesai / Terintegrasi |

---

## 6. Rencana Tahapan Eksekusi (Implementation Steps)

1. **Step 1 - Data Architecture & Player Stats:**
   * Tambahkan sistem `Level`, `Exp`, dan inventory `CastleKey` pada `PlayerData`.
   * Perluas `BattleState` agar mendukung parameter dinamis: `HeavyAttack`, `PotionCount`, `PotionHealValue`, dan `MinimaxDepth`.

2. **Step 2 - CSP Solver Module (`CSPSolver.gd`):**
   * Implementasikan struktur data $X, D, C$ dengan 5 Variabel & 4 Binary Constraints.
   * Tulis algoritma Backtracking dengan MRV, LCV, dan propagasi AC-3.
   * Uji coba pembangkitan konfigurasi benteng konsisten dan komplit saat game dimuat.

3. **Step 3 - Local Search Dynamic Balancer (`LocalSearchBalancer.gd`):**
   * Tulis fungsi penghitung Fitness/Objective $f(S)$.
   * Implementasikan Hill Climbing (dengan deteksi local maximum) dan Simulated Annealing (dengan parameter suhu $T$ dan cooling schedule).

4. **Step 4 - Pre-Battle Loading Screen & Debug Visualizer Scene:**
   * Buat scene transisi UI baru (`PreBattleLoadingScene.tscn`).
   * Hubungkan pemanggilan Local Search ke animasi visual step-by-step.
   * Tambahkan tombol toggle algoritma untuk demo dosen.

5. **Step 5 - Modular Guard & VFX Integration:**
   * Pasang sistem weapon slot modular pada Penjaga Gerbang berdasarkan hasil solusi CSP.
   * Pasang VFX serangan (Flame Slash, Void Orb, Earth Bash) pada aksi duel.

6. **Step 6 - Penulisan Laporan & Dokumentasi:**
   * Masukkan tabel komparasi matematis CSP (MRV vs tanpa MRV, iterasi AC-3) dan Local Search (Hill Climbing vs SA).
   * Dokumentasikan screenshot Pre-Battle Loading Screen dan visualisasi graf CSP sebagai bukti implementasi nyata.
