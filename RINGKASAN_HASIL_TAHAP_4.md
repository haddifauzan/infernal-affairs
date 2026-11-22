# 📌 DOKUMEN RINGKASAN & HASIL IMPLEMENTASI TAHAP 4: INFERNAL AFFAIRS
### Integrasi 3 Modul AI: *Logic & Knowledge Representation*, *Automated Planning (STRIPS)*, & *Decisions Under Uncertainty (MDP)*

> **Tugas Besar:** Kecerdasan Buatan (*Artificial Intelligence*) — Semester 3  
> **Kelompok 10:**  
> - Faridchi Trianda Safaraz (2506827)  
> - Haddi Fauzan Nurrosid (2507609)  
> - Farell Arrefa Zafhir (2508734)  
>  
> **Acuan Materi Kuliah:**  
> 1. **Modul 07:** `07_Logic & Representasi Pengetahuan.pdf` (*Propositional Logic, Knowledge Base, Horn Clauses, Forward Chaining, Partial Observability*)  
> 2. **Modul 08:** `08_Automated Planning.pdf` (*Classical Planning, STRIPS Operators, PDDL, State Progression, Goal-Directed Supply Chain*)  
> 3. **Modul 09:** `09_Decision under uncertainity.pdf` (*Stochastic Environment, Markov Decision Process (MDP), Bellman Equation, Value Iteration, MEU Rule, Bayesian Updating*)  
>  
> **Engine:** Godot Engine 4.3+ (GDScript)

---

## 1. Intisari Arsitektur: Integrasi 3 Modul AI dalam Gameplay Loop

Tahap 4 menyatukan penalaran simbolik (*Logic*), perencanaan terstruktur (*Planning*), dan pengambilan keputusan probabilistik (*MDP*) ke dalam satu alur permainan yang utuh:

```
┌────────────────────────────────────────────────────────────────────────┐
│ MODUL 07: KNOWLEDGE-BASED LOGIC (LogicEngine.gd)                       │
│ - Kondisi Awal: Status Segel Gerbang "TERSEMBUNYI" (Partially Observable)│
│ - Rule 1: IF PlayerLevel >= 2 THEN GuardAwakened                       │
│ - Rule 2: IF GuardAwakened THEN SealRevealed                           │
│ - Rule 3: IF ResidualEssence_Flame THEN Deduced_Flame (Sabotase Minion)│
│ - Inferensi: Forward Chaining membuktikan fakta baru saat event terpicu│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Memicu Kebutuhan Suplai & Awakening)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ MODUL 08: AUTOMATED PLANNING / STRIPS (PlanSolver.gd)                  │
│ - Minion menyusun sekuens aksi otonom:                                 │
│   Init State -> MOVE(Altar) -> HARVEST(Shard) -> MOVE(Dest) -> DELIVER│
│ - Closed World Assumption & Operator Prekondisi / Efek (PDDL)          │
│ - Menjamin pasokan elemen mengalir dari 3 Altar ke Penjaga/Bos        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Saat Minion Tiba di Persimpangan Sungai Lahar)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ MODUL 09: DECISIONS UNDER UNCERTAINTY / MDP (MDPSolver.gd)             │
│ - Lingkungan berubah menjadi Stokastik (Risiko Semburan Lahar f)       │
│ - Sensor W mengamati asap retakan jembatan (Likelihood P(W|Hazard)=0.9)│
│ - Bayesian Updating: Update keyakinan P(Hazard|W) dari 0.10 -> 0.50    │
│ - Bellman Value Iteration & MEU: Policy Shift dari Jalur Pintas        │
│   (Q anjlok ke -5.0) ke Jalur Utama Benteng (Q tetap aman +6.0)        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Jika Nekat / Terkena Semburan)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ SISTEM HAZARD & RECOIL FISIK (StochasticHazardManager.gd & Minion.gd)  │
│ - FSM Lahar: DORMANT (4.0s) -> WARNING (1.8s) -> ERUPTION (1.6s)       │
│ - Minion tersengat lahar: Terpental 2 petak ke selatan, status PANIC   │
│   selama 2.0s, kristal terlepas ke tanah, dan balon emote 'X' tengkorak │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Rincian Modul 07: Logic & Representasi Pengetahuan

Sesuai materi kuliah **Modul 07**, agen beroperasi di bawah kondisi **observasi parsial (*Partially Observable Environment*)**. Informasi penting tentang segel gerbang (*Gate Seal*) dan senjata bos sengaja disembunyikan (*Unknown*), dan hanya dapat diungkap melalui inferensi berbasis pengetahuan (*Knowledge-Based Inference*).

### A. Struktur Knowledge Base (KB) & Forward Chaining
Logika dimodelkan dalam bentuk proposisi logika dan aturan klausa Horn (*Horn Clauses*): $\text{Premis}_1 \wedge \text{Premis}_2 \dots \implies \text{Konklusi}$.

1. **Fakta Awal (Initial Facts):**
   - $\text{Tell}(\text{GateSeal\_Unknown})$
2. **Aturan Inferensi (Inference Rules):**
   - **Aturan Progresi Pemain (Level 2 Milestone):**
     $$\text{PlayerLevel\_2} \implies \text{GuardAwakened}$$
   - **Aturan Penyingkapan Segel (Full Seal Reveal):**
     $$\text{GuardAwakened} \implies \text{SealRevealed}$$
   - **Aturan Alternatif (Total Minion Defeated):**
     $$\text{AllMinionsDefeated} \implies \text{GuardAwakened}$$
   - **Aturan Deduksi Esensi Elemen (Sabotase Minion):**
     $$\text{ResidualEssence\_Flame} \implies \text{Deduced\_Flame}$$
     $$\text{ResidualEssence\_Shadow} \implies \text{Deduced\_Shadow}$$
     $$\text{ResidualEssence\_Blood} \implies \text{Deduced\_Blood}$$

### B. Implementasi Teknis: `LogicEngine.gd`
- **Algoritma `_forward_chain()`:** Menjalankan loop inferensi; saat pemain naik level ke level 2 (`update_player_level(2)`), mesin secara deduktif membuktikan `GuardAwakened`, yang kemudian secara berantai (*chaining*) membuktikan `SealRevealed`.
- **Event Penjaga Terbangun (*Guard Awakening*):** Memancarkan sinyal `guard_awakened` disertai monolog dramatis:
  > *"I HAVE AWAKENED! The ancient [SEAL] burns with infernal wrath. Turn back, mortal, or be consumed by the [GUARD]!"*
- **Penyingkapan Efek Segel ke HUD:** Status `[?] UNKNOWN` pada gerbang benteng berganti menjadi segel sebenarnya (misal: *Seal of Blood* - Mengurangi damage fisik musuh, *Seal of Flame* - Burn DoT, atau *Seal of Shadow* - Lifesteal).

---

## 3. Rincian Modul 08: Automated Planning (STRIPS / PDDL)

Mengacu pada materi **Modul 08**, minion kurir bertindak sebagai **Autonomous Planning Agents** yang menyusun sekuens aksi untuk memenuhi tujuan (*Goal-Directed Planning*) di bawah asumsi dunia tertutup (*Closed World Assumption*).

### A. Formulasi Formal Operator STRIPS
Setiap aksi didefinisikan dengan $\text{Action}(\text{Nama}, \text{Preconditions}, \text{Effects})$:

1. **Aksi Memanen Kristal (`HARVEST`):**
   ```lisp
   Action( HARVEST(?m, ?shard, ?altar),
     PRECOND: At(?m, ?altar) ∧ IsAltar(?altar) ∧ ShardAvailable(?shard, ?altar) ∧ Carrying(?m, NIL)
     EFFECT:  ¬Carrying(?m, NIL) ∧ Carrying(?m, ?shard) ∧ ¬ShardAvailable(?shard, ?altar)
   )
   ```
2. **Aksi Pergerakan Fisik (`MOVE`):**
   ```lisp
   Action( MOVE(?m, ?from, ?to),
     PRECOND: At(?m, ?from) ∧ Adjacent(?from, ?to) ∧ SafePath(?to)
     EFFECT:  ¬At(?m, ?from) ∧ At(?m, ?to)
   )
   ```
3. **Aksi Penyetoran Suplai (`DELIVER`):**
   ```lisp
   Action( DELIVER(?m, ?shard, ?entity, ?pos),
     PRECOND: At(?m, ?pos) ∧ EntityAt(?entity, ?pos) ∧ Carrying(?m, ?shard)
     EFFECT:  ¬Carrying(?m, ?shard) ∧ Carrying(?m, NIL) ∧ HasSupply(?entity, ?shard)
   )
   ```

### B. Implementasi Teknis: `PlanSolver.gd`
- **State Progression:**
  - Jika minion kosong: Plan yang dihasilkan = `[MOVE(Altar) -> HARVEST(Altar) -> MOVE(Guard) -> DELIVER(Guard)]`.
  - Jika minion sudah membawa kristal: Plan yang dihasilkan = `[MOVE(Guard) -> DELIVER(Guard)]`.
- **Integrasi dengan Pathfinding Tahap 1:** Aksi `MOVE` didelegasikan ke modul `AStar.gd` / `UCS.gd` untuk eksekusi langkah per langkah di atas grid arena overworld.
- **Tiga Altar Sumber Daya:**
  1. *Ignis Altar* (Api): koordinat grid $(8, 38)$ di barat daya.
  2. *Abyssal Fissure* (Bayangan): koordinat grid $(35, 38)$ di tenggara.
  3. *Sanguine Well* (Darah): koordinat grid $(21, 32)$ di tengah selatan dekat bibir sungai lahar.

---

## 4. Rincian Modul 09: Decisions Under Uncertainty & Markov Decision Processes (MDP)

Mengacu pada materi **Modul 09**, ketika minion menempuh jalur pengiriman melewati sungai lahar, aksi pergerakan tidak lagi deterministik 100%, melainkan mengandung risiko bahaya (*Stochastic Environment*).

### A. Tuple Formal MDP $\langle S, A, P, R, \gamma \rangle$
1. **State ($S$):**
   - $s_0$: `Altar` (Titik pemanenan kristal)
   - $s_1$: `Simpang Lembah` (Titik bifurkasi keputusan)
   - $s_2$: `Jalur Pintas` (Jembatan tengah di atas retakan lahar, berisiko semburan $f$)
   - $s_3$: `Jalur Utama` (Jembatan kanan benteng, aman tapi memutar jauh)
   - $s_4$: `Pos Penjaga` (Terminal Goal, reward $+10.0$)
   - $s_5$: `Magma Trap` (Terminal Failure, penalti $-20.0$)

2. **Aksi ($A$):**
   - $a_{\text{Pintas}}$: Melintasi jembatan retakan lahar.
   - $a_{\text{Raya}}$: Memutar lewat jembatan benteng yang aman.
   - $a_{\text{Wait}}$: Menunggu di petak aman hingga kondisi jembatan mereda.
   - $a_{\text{Balik}}$: Mundur kembali ke Altar.

3. **Model Transisi Stokastik ($P(s' \mid s, a)$):**
   - Pada $s_1$ ambil $a_{\text{Pintas}}$: $P(s_4 \mid s_1, a_{\text{Pintas}}) = 1 - f$ dan $P(s_5 \mid s_1, a_{\text{Pintas}}) = f$.
   - Pada $s_1$ ambil $a_{\text{Raya}}$: $P(s_3 \mid s_1, a_{\text{Raya}}) = 1.0$ (Pasti aman).
   - Pada $s_3$ menuju Pos Penjaga ($s_4$): $P(s_4 \mid s_3, a_{\text{Jalan}}) = 1.0$.

4. **Reward Function ($R(s')$):**
   - $R(s_4) = +10.0$ (Pengiriman kristal sukses).
   - $R(s_5) = -20.0$ (Kristal hancur tersengat lahar).
   - $R(s') = -2.0$ (Biaya langkah / *living cost* pada state non-terminal agar agen tidak berputar-putar tanpa henti, sesuai Slide 23).

5. **Discount Factor ($\gamma$):**
   - $\gamma = 0.8$ (Depresiasi utilitas masa depan sesuai Slide 9 & 13).

---

### B. Bellman Expectation Equation & Value Iteration
Formulasi komputasi rekursif:
$$Q(s, a) = \sum_{s'} P(s' \mid s, a) \left[ R(s') + \gamma V(s') \right]$$
$$V_{k+1}(s) = \max_{a \in A} Q(s, a)$$

#### Pembuktian Hitungan Manual Iterasi ($f = 0.10, \gamma = 0.8$):
- **Iterasi $k=0$:** $V_0(s) = 0, \forall s$.
- **Iterasi $k=1$:**
  - $V_1(s_4) = +10.0, \quad V_1(s_5) = -20.0$
  - $Q_1(s_1, \text{Pintas}) = 0.90(10) + 0.10(-20) = \mathbf{7.00}$
  - $Q_1(s_1, \text{Raya}) = 1.0 \times [-2.0 + 0.8(0)] = -2.00$
  - $\Rightarrow V_1(s_1) = \max(7.00, -2.00) = \mathbf{7.00} \quad [\pi_1(s_1) = \text{PINTAS}]$
- **Iterasi $k=2$:**
  - $V_2(s_3) = 1.0 \times [10.0 + 0] = \mathbf{10.00}$
  - $Q_2(s_1, \text{Raya}) = -2.0 + 0.8(10.0) = \mathbf{6.00}$
  - $Q_2(s_1, \text{Pintas}) = \mathbf{7.00}$
  - $V_2(s_0) = -2.0 + 0.8(7.0) = \mathbf{3.60}$
  - $\Rightarrow V_2(s_1) = \mathbf{7.00} \quad [\pi_2(s_1) = \text{PINTAS}]$
- **Iterasi $k=3$ (Konvergen):**
  - Nilai stabil pada: $V^*(s_0) = 3.60$, $V^*(s_1) = 7.00$, $V^*(s_3) = 10.00$. Selisih $\Delta V < 10^{-4}$.

---

### C. Bayesian Belief Updating & Policy Shifting (Slide 7–8)
Agen memiliki sensor peringatan $W \in \{0, 1\}$ (asap belerang / pijaran retakan):
- **Prior:** $P(\text{Hazard}) = 0.10, \quad P(\text{Safe}) = 0.90$
- **Likelihood Sensor:** $P(W=1 \mid \text{Hazard}) = 0.90$, $P(W=1 \mid \text{Safe}) = 0.10$

1. **Probabilitas Total Sinyal Sensor $P(W=1)$:**
   $$P(W=1) = (0.90 \times 0.10) + (0.10 \times 0.90) = 0.09 + 0.09 = \mathbf{0.18}$$

2. **Posterior Belief Saat Sensor Aktif ($W=1$):**
   $$P(\text{Hazard} \mid W=1) = \frac{P(W=1 \mid \text{Hazard}) \cdot P(\text{Hazard})}{P(W=1)} = \frac{0.09}{0.18} = \mathbf{0.50} \quad (50\%)$$

3. **Perubahan Keputusan (*Redo Decision*):**
   - **Kondisi Normal ($W=0, f \approx 0.10$):**
     $$Q(s_1, \text{Pintas}) = \mathbf{+7.00} > Q(s_1, \text{Raya}) = \mathbf{+6.00} \implies \mathbf{\pi^*(s_1) = \text{PINTAS}}$$
   - **Kondisi Peringatan Bahaya ($W=1, f = 0.50$):**
     $$Q(s_1, \text{Pintas}) = 0.50(10) + 0.50(-20) = \mathbf{-5.00}$$
     $$Q(s_1, \text{Raya}) = -2 + 0.8(10) = \mathbf{+6.00}$$
     $$\mathbf{Q(\text{Raya}) > Q(\text{Pintas})} \implies \mathbf{\pi^*(s_1) = \text{RAYA (JALUR UTAMA BENTENG)}}$$

> **Hasil:** Begitu sensor mencium asap bahaya ($W=1$), nilai ekspektasi jalan pintas anjlok menjadi negatif ($-5.00$), memicu agen secara otomatis membelokkan rute (*Policy Shift*) ke jalan raya aman ($+6.00$).

---

## 5. Rangkuman Penyempurnaan Sistem & Perbaikan Masalah

1. **Minion Terpental & Balon Emote (Bukan Teleportasi Kaku):**
   - *Sebelumnya:* Minion yang terkena letusan magma langsung diteleportasi secara kaku ke petak statis `(6, 21)` dan balon ekspresi tanda seru/tanya sering tidak muncul.
   - *Perbaikan:* Logika teleportasi dihapus total. Minion kini terpental halus (*smooth knockback recoil*) sejauh 2 petak ke selatan ($y \leftarrow y+2$), menjatuhkan kristal yang dibawanya ke tanah (`crystal_dropped.png`), masuk ke status `PANIC` selama 2 detik, serta memunculkan balon emote tengkorak `X` tepat di atas kepala ($y = -30\text{px}$).

2. **Fitur Dynamic Camera Zoom:**
   - Navigasi kamera bebas ditambahkan di `Main.gd`: Scroll roda mouse (*Mouse Wheel*) atau tombol keyboard `+`, `-`, dan `0` untuk reset. Mendukung pembesaran hingga `2.0x` dan pengecilan hingga `0.5x` dengan interpolasi halus `camera.zoom.lerp()`.

3. **Pembersihan Bocor Cahaya Lahar (*Road Glow Glitch*):**
   - *Sebelumnya:* Jalan raya aman di depan gerbang istana ikut berpijar oranye karena hardcoded koordinat lama ($y=20..21$).
   - *Perbaikan:* Efek glow dan deteksi letusan dibatasi secara ketat hanya pada jembatan tengah ($x=24..27, y=30..33$).

4. **Desain HUD Ringkas & Tombol Kontrol Kiri Bawah:**
   - *Sebelumnya:* Panel card debug terlalu panjang ke bawah dan memotong tampilan.
   - *Perbaikan:* Menghapus batas tinggi kaku (*auto-shrink*), serta memindahkan 4 tombol interaktif (`[⚠ Warn]`, `[Iter k+1]`, `[Reset]`, `[HUD [M]]`) ke panel pojok kiri bawah agar rapi dan tidak menghalangi arena pertarungan.

5. **Jarak Spawn Minion yang Aman:**
   - Menambahkan validasi jarak minimal 7 petak dari pemain saat inisialisasi awal agar minion tidak langsung memicu duel seketika saat sesi baru dimulai.

---

## 6. Katalog Aset Baru Terintegrasi

| Berkas Aset | Keterangan Teknis |
| :--- | :--- |
| `bridge_stone.png` | Struktur tileset modular jembatan batu penyeberangan sungai lahar. |
| `vfx_flame_column_sheet.png` | Sprite strip 6 frame animasi tiang api vertikal pada fase *Eruption*. |
| `vfx_warning_crack_sheet.png`| Sprite strip 4 frame retakan tanah berpijar jingga pada fase *Warning*. |
| `shards_spinning_sheet.png`  | Sprite strip 3 baris serpihan kristal elemen berputar di atas Altar. |
| `crystal_dropped.png`        | Item kristal yang terjatuh di atas tanah saat minion tersengat lahar. |
| `item_sparkle.png`           | Efek kilau partikel 3 frame pada kristal yang terjatuh. |
| `emote_balloons.png`         | Balon reaksi AI di atas kepala minion: `?` (evaluasi), `!` (waspada), `X` (panik). |
| `cliff_edge.png`             | Autotile tepian tebing pembatas antara benteng dan jurang lahar. |

---

## 7. Hasil Pengujian & Validasi Numerik

| Skenario Pengujian | Kondisi Lingkungan | Keyakinan $P(H)$ & $Q$-Value | Perilaku AI yang Teramati |
| :--- | :--- | :--- | :--- |
| **1. Kondisi Tenang** | Sensor $W=0$, fase *Dormant* | $P(H) = 0.10$<br>$Q(\text{Pintas}) = +7.00$<br>$Q(\text{Raya}) = +6.00$ | Minion kurir memilih Jalur Pintas; pengiriman kristal ke penjaga berlangsung 40% lebih cepat. |
| **2. Peringatan Magma** | Sensor $W=1$, retakan bercahaya | $P(H \mid W) = 0.50$<br>$Q(\text{Pintas}) = -5.00$<br>$Q(\text{Raya}) = +6.00$ | Balon tanda seru `!` muncul di kepala minion; minion otomatis memutar ke Jalur Utama Benteng (*Policy Shift*). |
| **3. Letusan Magma** | Minion melintas saat tiang api menyembur | $R = -20.0$ (Sengatan lahar) | Kristal terlepas ke tanah, minion terpental 2 petak ke selatan, memunculkan emote `X`, dan masuk status panik. |
| **4. Level 2 Reached** | Pemain mencapai level 2 | $\text{PlayerLevel\_2} \implies \text{GuardAwakened}$ | Monolog kebangkitan penjaga terpicu dan segel gerbang terungkap (*Seal Revealed*) dari `[?] UNKNOWN`. |
| **5. Validasi Numerik** | Iterasi $k=1, 2, 3$ di HUD | Identik dengan hitungan manual | Selisih galat antara teori matematis dengan output runtime Godot adalah **$0.00\%$ (Konvergen sempurna)**. |
