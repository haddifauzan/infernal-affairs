# 🔥 INFERNAL AFFAIRS: Hybrid AI Game Architecture
> **Tugas Besar Mata Kuliah Kecerdasan Buatan (Artificial Intelligence)**  
> **Program Studi Ilmu Komputer — Semester 3**  
> **Kelompok 10:**  
> - **(2506827) Faridchi Trianda Safaraz**  
> - **(2507609) Haddi Fauzan Nurrosid**  
> - **(2508734) Farell Arrefa Zafhir**  
>  
> **Tahap 3 (Final):** *Constraint Satisfaction Problems (CSP) & Local Search Dynamic Balancer*  
> **Engine:** Godot Engine 4.3+ / 4.7+ (GDScript)

---

## 📌 1. Deskripsi Umum Proyek

**Infernal Affairs** adalah game petualangan taktis infernal berbasis 2D yang mengintegrasikan seluruh spektrum kurikulum kecerdasan buatan (*Artificial Intelligence*) ke dalam satu ekosistem terpadu. Proyek ini memadukan empat pilar utama algoritma AI:

1. **Tahap 1 (Pathfinding & Pursuit):** Pelacakan rute terpendek dinamis (*A\* Search* dengan Manhattan Heuristic vs *Uniform-Cost Search*).
2. **Tahap 2 (Adversarial Search):** Sistem pertarungan taktis berbasis giliran 1-on-1 (*Turn-Based Duel*) yang diotaki oleh algoritma *Minimax* dengan *Alpha-Beta Pruning* dan *Expectimax*.
3. **Tahap 3 - Modul 5 (Constraint Satisfaction Problem - CSP):** Mesin penata variabel dunia global (*World Procedural Rules*) yang menugaskan identitas, segel, senjata, dan doktrin AI musuh bebas konflik menggunakan *Backtracking Search*, *MRV*, *LCV*, dan *AC-3 Arc Consistency*.
4. **Tahap 3 - Modul 4 (Local Search Dynamic Balancer):** Sistem penyeimbang tingkat kesulitan adaptif secara *real-time* sebelum memasuki pertarungan menggunakan *Simulated Annealing (SA)* dan *Hill Climbing (HC)* berdasarkan metrik kondisi nyata pemain.

---

## 🏛️ 2. Arsitektur Hibrida Integrasi Sistem

Sistem menggabungkan penalaran kendala global kualitatif dengan optimasi numerik dinamis lokal:

```
[ Awal Sesi Permainan ]
        │
        ▼
┌────────────────────────────────────────┐
│  CSPSolver.solve() (Modul 5)          │
│  Backtracking + MRV + LCV + AC-3       │
│  - Guard Archetype, Gate Seal, Weapon  │
│  - Doktrin AI Minimax & Syarat Gerbang │
└───────────────────┬────────────────────┘
                    │  (Modifier Aturan Kualitatif)
                    │
[ Encounter Terjadi ]│
        │           │
        ▼           │
┌───────────────────┴────────────────────┐      ┌────────────────────────────────────────┐
│  PreBattleBriefingModal                │      │  Pemain Menantang Musuh                │
│  Intel musuh, elemen, & tips counter   │      │  Baca status aktual -> Hitung P_Player │
└───────────────────┬────────────────────┘      └───────────────────┬────────────────────┘
                    │                                               │
                    │               ┌───────────────────────────────┘
                    ▼               ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  LocalSearchBalancer (Modul 4)                                                         │
│  Simulated Annealing / Hill Climbing                                                   │
│  Fungsi Objektif: f(S) = - | Power_NPC - (r × Power_Player) |                         │
│  Output: Parameter Numerik Optimal S* (HP, Atk, Heavy, Def, Potion, Depth)             │
└───────────────────────────────────┬────────────────────────────────────────────────────┘
                                    │  (Parameter Kuantitatif S*)
                                    ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  Konfigurasi Pertempuran (Battle Configuration)                                        │
│  Sintesis: Parameter Kuantitatif S* + Modifier Aturan Solusi CSP                       │
└───────────────────────────────────┬────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  BattleManager + MinimaxSolver (Modul 2)                                               │
│  Arena duel turn-based dengan pohon pencarian Minimax / Alpha-Beta Pruning            │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

> **Prinsip Desain Kunci:** Luaran CSP tidak menjadi masukan fungsi objektif *Local Search*; keduanya berjalan secara independen dan bertemu pada tahap **Konfigurasi Pertempuran Final**.

---

## 🧩 3. Modul 5: Constraint Satisfaction Problem (CSP)

Modul ini bertanggung jawab mengatur konsistensi tematik dunia permainan saat sesi baru dimulai.

### 3.1 Variabel ($X$) dan Domain ($D$)
| Variabel | Domain ($D$) | Deskripsi |
| :--- | :--- | :--- |
| `guard_type` | {Infernal Knight, Obsidian Gargoyle, Abyssal Shaman} | Tipe arketipe penjaga gerbang |
| `gate_seal` | {Seal of Flame, Seal of Shadow, Seal of Blood} | Beban elemen segel gerbang utama |
| `boss_weapon` | {Flame Scythe, Cursed Blade, Blood Trident} | Senjata modular Demon Lord |
| `guard_strategy` | {Aggressive, Defensive, Tactical} | Doktrin AI Minimax untuk Penjaga |
| `boss_strategy` | {Aggressive, Defensive, Tactical} | Doktrin AI Minimax untuk Demon Lord |
| `gate_req` | {Level 2, Level 3} | Syarat level minimum membuka gerbang |
| `castle_potions` | {(G:1, B:1), (G:2, B:0), (G:0, B:2)} | Distribusi stok ramuan pemulihan |

### 3.2 Relasi Kendala Biner ($C_1 - C_5$) & Global
1. **$C_1$ (Afinitas Elemen):** `guard_type` selaras dengan elemen `gate_seal` (Knight $\leftrightarrow$ Flame, Gargoyle $\leftrightarrow$ Blood, Shaman $\leftrightarrow$ Shadow).
2. **$C_2$ (Kesesuaian Doktrin):** `guard_type` cocok dengan `guard_strategy` (Knight $\leftrightarrow$ Aggressive, Gargoyle $\leftrightarrow$ Defensive, Shaman $\leftrightarrow$ Tactical).
3. **$C_3$ (Resonansi Elemen):** `gate_seal` memiliki resonansi dengan `boss_weapon`.
4. **$C_4$ (Diversitas Doktrin):** `guard_strategy` $\neq$ `boss_strategy` (memastikan dinamika taktik bervariasi).
5. **$C_5$ (Anti-Monopoli Elemen):** Elemen `boss_weapon` tidak boleh memonopoli elemen `guard_type`.
6. **$C_{\text{global}}$ (Konservasi Potion):** Total alokasi ramuan kastil berjumlah tetap ($\sum = 2$).

### 3.3 Heuristik & Inferensi Pencarian
- **Minimum Remaining Values (MRV):** Memilih variabel dengan sisa domain terkecil untuk dieksplorasi lebih dahulu (*Fail-First Principle*).
- **Least Constraining Value (LCV):** Memilih nilai yang paling sedikit membatasi pilihan variabel tetangga (*Succeed-First Principle*).
- **AC-3 (Arc Consistency):** Memangkas nilai domain yang tidak konsisten secara propagatif sebelum percabangan pohon pencarian.

---

## ⚖️ 4. Modul 4: Local Search Dynamic Balancer

Modul ini memastikan pertarungan tetap adil dan menantang secara dinamis (*Adaptive Difficulty*) berdasarkan perkembangan nyata pemain.

### 4.1 Formulasi State Space ($S$)
State parameter musuh direpresentasikan oleh tuple:
$$S = \langle HP, Atk, HeavyAtk, Def, Potions, MinimaxDepth \rangle$$

### 4.2 Fungsi Kekuatan & Fungsi Objektif ($f(S)$)
Kekuatan entitas dihitung melalui formula daya agregat:
$$Power = HP + 2.2 \cdot Atk + 1.2 \cdot HeavyAtk + 3.0 \cdot Def + 0.7 \cdot PotHeal + 15 \cdot Depth$$

Fungsi objektif yang dimaksimalkan menuju $0$:
$$f(S) = -|Power_{\text{NPC}} - (r \times Power_{\text{Player}})|$$
- **Rasio Penjaga ($r = 1.05$):** Musuh dirancang seimbang dengan sedikit keunggulan taktis.
- **Rasio Bos Neraka ($r = 1.30$):** Pertarungan klimaks yang menuntut persiapan maksimal pemain.

### 4.3 Algoritma Optimasi
1. **Simulated Annealing (SA):**
   - Menggunakan jadwal pendinginan geometrik: $T_{k+1} = T_k \times \alpha$ dengan $\alpha = 0.93$.
   - Menerima langkah memburuk (*Downhill Moves*) dengan probabilitas Boltzmann:
     $$P = \exp\left(\frac{\Delta E}{T}\right)$$
   - Efektif meloloskan diri dari jebakan optimum lokal (*local optima escape*).
2. **Hill Climbing (HC):**
   - Pendekatan serakah (*Greedy Ascent*) yang hanya menerima tetangga dengan $\Delta E \ge 0$.
   - Menunjukkan konvergensi cepat namun rentan mengalami stagnasi pada *plateau* atau *local maximum*.

---

## ⚔️ 5. Turn-Based Adversarial Combat (Minimax Engine)

- **Minimax Search dengan Alpha-Beta Pruning:** Mengevaluasi pohon pencarian aksi hingga kedalaman *lookahead* $d \in [1, 3]$ dengan pemangkasan cabang tak berguna (*Pruning Ratio* mencapai 60-80%).
- **Fungsi Evaluasi Multi-Doktrin:**
  - **Aggressive:** Memprioritaskan selisih HP lawan dan penalti pertahanan pasif.
  - **Defensive:** Menghargai pemulihan HP, mitigasi damage, dan stok Potion.
  - **Tactical:** Mempertimbangkan momentum tempo, prediksi *cooldown*, dan counter serangan lawan.
- **Efek Pasif Segel & Senjata:**
  - *Medan Panas (Seal of Flame):* DoT api 3 HP per ronde.
  - *Hisap Jiwa (Seal of Shadow):* Lifesteal 15% damage.
  - *Kulit Iblis (Seal of Blood):* Reduksi flat -4 damage fisik.
  - *Armor Pierce (Blood Trident):* Menembus status Defend hingga 80%.
  - *Infernal Burn (Flame Scythe):* Status Burn 5 HP/ronde selama 2 ronde.

---

## 🎨 6. Aset Visual Baru & User Interface (Tahap 3)

1. **Katalog Karakter & Penjaga:**
   - *Lesser Imp* (Minion Overworld)
   - *Infernal Knight* (Guard - Api)
   - *Obsidian Gargoyle* (Guard - Darah/Bumi)
   - *Abyssal Shaman* (Guard - Bayangan/Void)
2. **Spritesheets Senjata & Segel:**
   - Senjata Bos: *Flame Scythe*, *Cursed Blade*, *Blood Trident*.
   - Segel Gerbang: *Seal of Flame*, *Seal of Shadow*, *Seal of Blood*.
   - Matriks Grid 9-Avatar Combat (Kombinasi Arketipe $\times$ Elemen Segel).
3. **Efek Partikel Animatif (Attack VFX - 4 Frames):**
   - *Flame Slash* (Tebasan pedang api).
   - *Void Orb* (Ledakan energi gelap).
   - *Earth Bash* (Hantaman seismik batu lava).
4. **Komponen UI Interaktif:**
   - *PreBattleBriefingModal:* Panel intel pra-battle lengkap dengan identitas lawan dan rekomendasi counter taktis.
   - *PreBattleLoadingOverlay:* Visualizer real-time proses pencarian lokal (SA vs HC), live step logs, dan kurva konvergensi.
   - *Overhead Status Badges:* Label melayang di atas kepala musuh overworld yang menampilkan status arketipe, segel, dan senjata.
   - *Debug HUD Panel (F3):* Inspektur runtime CSP, kontrol teleportasi, dan pengujian duel instan.

---

## 📁 7. Struktur Direktori Proyek

```text
infernal-affairs/
├── assets/
│   ├── audio/                     # SFX serangan, klik UI, dan balancer tick
│   └── sprites/
│       ├── characters/            # Sprite & portrait Player, Demon, Guard, Minion
│       ├── effects/               # Spritesheet VFX serangan (Flame Slash, Void Orb, Earth Bash)
│       └── map/obstacles/         # Rintangan peta & spritesheet segel gerbang
├── scenes/
│   ├── Main.tscn                  # Scene utama overworld, grid, dan HUD
│   ├── Player.tscn                # Entitas pemain
│   └── Demon.tscn                 # Entitas bos iblis
├── scripts/
│   ├── Main.gd                    # Orkestrasi alur game, encounter, dan state transition
│   ├── core/
│   │   ├── CSPSolver.gd           # Modul 5: Mesin CSP (MRV, LCV, AC-3)
│   │   ├── LocalSearchBalancer.gd # Modul 4: Mesin Local Search (SA vs HC)
│   │   ├── GameState.gd           # State global pemain & progres permainan
│   │   ├── GridManager.gd         # Navigasi grid & kalkulasi peta
│   │   └── MinHeap.gd             # Priority Queue untuk pencarian jalur
│   ├── entities/
│   │   ├── Demon.gd               # Logika NPC Bos overworld & modular weapon
│   │   └── Guard.gd               # Logika Penjaga gerbang & modular seal
│   ├── battle/
│   │   ├── BattleHUD.gd           # Antarmuka pertarungan turn-based & animasi VFX
│   │   ├── BattleManager.gd       # Wasit giliran duel & sinkronisasi aksi
│   │   ├── BattleState.gd         # Representasi state matematis pertarungan
│   │   └── MinimaxSolver.gd       # Modul 2: Pohon pencarian AI Minimax / Alpha-Beta
│   └── UI/
│       ├── PreBattleBriefingModal.gd   # Modal intel taktis pra-battle
│       └── PreBattleLoadingOverlay.gd  # Visualisasi proses Local Search live
├── project.godot                  # Konfigurasi proyek Godot 4
└── README.md                      # Dokumentasi komprehensif proyek
```

---

## 🎮 8. Panduan Kontrol & Shortcut Keyboard

### Overworld (Eksplorasi):
- `W / A / S / D` atau `Tombol Panah`: Bergerak di peta labirin.
- `F3`: Membuka / Menutup **Debug HUD & CSP Inspector**.
- `P` / `ESC`: Mengaktifkan **Game Pause & Konsep AI Briefing**.
- `L`: Naik level instan (*Debug Level Up*).

### Modal Briefing Pra-Battle:
- `Enter` / `X`: Melanjutkan ke persiapan pertarungan (*Pre-Battle Balancer*).
- `ESC`: Mundur / Membatalkan pertempuran.

### Overlay Local Search Balancer:
- `Enter` / `X`: Mulai Duel (masuk arena turn-based combat).
- `ESC`: Membatalkan pertempuran.
- `Tab` / `Spasi`: Mengganti algoritma (*Simulated Annealing* $\leftrightarrow$ *Hill Climbing*).

### Arena Duel Turn-Based:
- `1`: Normal Attack (Serangan biasa 24 DMG).
- `2`: Heavy Attack (Serangan kuat 43 DMG, recoil -10 HP).
- `3`: Defend (Kuda-kuda bertahan, reduksi damage 50%).
- `4`: Potion (Meminum ramuan pemulihan +30 HP).
- `D`: Toggle **NPC Minimax AI Monitor Sidebar** (Analisis pohon pencarian real-time).
- `P`: Toggle **AI Benchmark Lab** (Uji komparasi fungsi evaluasi).
- `R`: Mengulang duel dari awal (*Restart Battle*).
- `ESC`: Menyerah / Mundur dari duel.
