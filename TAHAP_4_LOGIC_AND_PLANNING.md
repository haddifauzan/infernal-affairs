# 📜 INFERNAL AFFAIRS: TAHAP 4 — LOGIC & AUTOMATED PLANNING
> **Dokumen Perancangan Arsitektur & Spesifikasi Formal**  
> **Mata Kuliah:** Kecerdasan Buatan (Artificial Intelligence) — Semester 3  
> **Kelompok 10:**  
> - (2506827) Faridchi Trianda Safaraz  
> - (2507609) Haddi Fauzan Nurrosid  
> - (2508734) Farell Arrefa Zafhir  
>  
> **Fokus Tahap 4:** *Automated Planning (PDDL / STRIPS Supply Chain)* & *Knowledge-Based Logic (Propositional Logic, Inference Engine, & Guard Awakening)*  
> **Engine Target:** Godot Engine 4.3+ / 4.7+ (GDScript)

---

## 🏛️ 1. Ikhtisar Integrasi Sistem (Tahap 1 s.d. Tahap 4)

Game **Infernal Affairs** kini memadukan seluruh pilar utama kurikulum AI ke dalam satu siklus permainan (*gameplay loop*) yang utuh dan kohesif:

1. **Tahap 1 (Search & Pathfinding):** Algoritma *A\* Search* (Manhattan Distance) dan *Uniform-Cost Search (UCS)* untuk navigasi grid overworld.
2. **Tahap 2 (Adversarial Search):** Sistem pertarungan duel taktis 1-on-1 berbasis giliran (*Turn-Based*) dengan *Minimax*, *Alpha-Beta Pruning*, dan multi-fungsi evaluasi doktrin AI.
3. **Tahap 3 - Modul 5 (Constraint Satisfaction Problem - CSP):** Mesin inferensi kendala konsistensi dunia (*Backtracking + MRV + LCV + AC-3*) yang menetapkan relasi Guard Archetype, Gate Seal, dan Boss Weapon secara bebas konflik.
4. **Tahap 3 - Modul 4 (Local Search Dynamic Balancer):** Optimasi numerik real-time menggunakan *Simulated Annealing (SA)* dan *Hill Climbing (HC)* untuk menyeimbangkan statistik NPC berdasarkan metrik kekuatan pemain.
5. **Tahap 4 - Modul 6 (Logic & Knowledge-Based Agent):** Penalaran logis dengan observasi parsial (*Partial Observability*). Status segel gerbang (*Gate Seal*) disembunyikan (*Hidden / Unrevealed*) dan diungkap melalui pencapaian level (*Level 2 Trigger*), monolog kebangkitan penjaga (*Guard Awakening Event*), atau deduksi berbasis fakta (*Knowledge Base Forward Chaining*).
6. **Tahap 4 - Modul 7 (Automated Planning):** Minion bertransformasi menjadi *Autonomous Planning Agents* yang merancang sekuens aksi (*Action Plan*) menggunakan formulasi *Classical Planning (STRIPS/PDDL)* untuk memanen dan menyuplai serpihan elemen secara berkala dari 3 Altar Resource ke Penjaga dan Bos.

```
┌────────────────────────────────────────────────────────────────────────┐
│                      Awal Sesi Permainan (Inisialisasi)                │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│  Tahap 3 (Modul 5): CSPSolver.solve()                                  │
│  - Menghasilkan Cetak Biru (Blueprint): Guard Type, Seal, Weapon       │
│  - Menetapkan Doktrin AI & Konsistensi Elemen Bebas Konflik            │
└───────────────────┬────────────────────────────────────────────────────┘
                    │  (Cetak Biru Dunia)
                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│  Tahap 4 (Modul 7): Automated Planning Engine (STRIPS/PDDL)            │
│  - Minion merencanakan tugas: Harvest -> Transport -> Deliver          │
│  - Suplai berkala dialirkan ke Guard & Boss dari 3 Altar Wilderness    │
│  - Pergerakan fisik minion dieksekusi via A*/UCS (Tahap 1)             │
└───────────────────┬────────────────────────────────────────────────────┘
                    │
                    ▼ (Progresi Overworld & Eksplorasi)
┌────────────────────────────────────────────────────────────────────────┐
│  Tahap 4 (Modul 6): Knowledge-Based Logic & Guard Awakening            │
│  - Gerbang & Segel berstatus Tersembunyi (Hidden / Unknown [?])        │
│  - Player naik ke Level 2 -> Trigger Event: "I HAVE AWAKENED!"         │
│  - Guard terbangun & Segel ter-reveal secara dramatis ke HUD           │
│  - (Opsional: Deduksi logis KB jika player mencegat pembawa elemen)    │
└───────────────────┬────────────────────────────────────────────────────┘
                    │
                    ▼ (Encounter Terjadi: Pemain Menantang Musuh)
┌────────────────────────────────────────────────────────────────────────┐
│  Tahap 3 (Modul 4): Local Search Dynamic Balancer (SA / HC)           │
│  - Menerima Tingkat Pasif (Tier 0: Lemah s.d. Tier 2: Sangat Kuat)     │
│  - Kompensasi Terbalik: Jika pasif kuat, atribut fisik (HP/Def) turun  │
│  - Memaksimalkan f(S) = -|Power_NPC(dengan Pasif) - (r × Power_Player)|│
└───────────────────┬────────────────────────────────────────────────────┘
                    │  (Parameter Numerik S*)
                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│  Tahap 2: BattleManager + MinimaxDuel (Combat Arena)                   │
│  - Bertarung dengan parameter seimbang dan pasif elemen aktif          │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🗺️ 2. Penataan 3 Altar Elemen di Peta Wilderness

Peta permainan berukuran **$44 \times 46$ tiles**, dengan zona *Wilderness* terletak pada koordinat vertikal baris $y = 22 \dots 44$. Tiga Altar Elemen ditempatkan secara terdistribusi untuk menciptakan titik temu strategis:

| No | Nama Altar | Elemen | Koordinat Grid $(X, Y)$ | Ciri Visual Lingkungan |
| :-: | :--- | :--- | :-: | :--- |
| **1** | **Ignis Altar** | **Flame** (Api) | $(8, 38)$ | Dikelilingi lava dan batuan basal merah di barat daya |
| **2** | **Abyssal Fissure** | **Shadow** (Void) | $(35, 38)$ | Retakan kristal ungu kehitaman di tenggara |
| **3** | **Sanguine Well** | **Blood** (Darah/Bumi) | $(21, 32)$ | Sumber mata air merah pekat di tengah selatan dekat sungai |

### Mekanik Altar & Siklus Suplai:
- Setiap altar memancarkan aura partikel sesuai elemennya.
- Altar menyediakan pasokan *Resource Shards* yang dapat dipanen oleh Minion Harvester.
- Pemain dapat mendekati altar untuk melakukan sabotase atau menyergap minion yang sedang beroperasi.

---

## 🤖 3. Modul 7: Automated Planning (STRIPS / PDDL Supply Chain)

Minion di Tahap 4 tidak lagi sekadar berpatroli acak, melainkan bertindak sebagai agen otonom terencana (*Planning Agents*).

### 3.1 Formulasi Domain PDDL
```lisp
(define (domain infernal-supply-chain)
  (:requirements :strips :typing)
  (:types agent location resource-element entity)

  (:predicates
     (at ?a - agent ?l - location)
     (entity-at ?e - entity ?l - location)
     (connected ?from - location ?to - location)
     (carrying ?a - agent ?r - resource-element)
     (altar-available ?l - location ?r - resource-element)
     (guard-needs ?r - resource-element)
     (boss-needs ?r - resource-element)
     (supplied-guard ?r - resource-element)
     (supplied-boss ?r - resource-element)
  )

  ;; 1. Aksi Berpindah Antar Sektor
  (:action MoveTo
     :parameters (?a - agent ?from - location ?to - location)
     :precondition (and (at ?a ?from) (connected ?from ?to))
     :effect (and (at ?a ?to) (not (at ?a ?from)))
  )

  ;; 2. Aksi Menambang / Memanen Shard
  (:action HarvestShard
     :parameters (?a - agent ?loc - location ?r - resource-element)
     :precondition (and (at ?a ?loc) (altar-available ?loc ?r) (not (carrying ?a ?r)))
     :effect (carrying ?a ?r)
  )

  ;; 3. Aksi Menyetor Suplai ke Penjaga Gerbang
  (:action DeliverToGuard
     :parameters (?a - agent ?loc - location ?r - resource-element)
     :precondition (and (at ?a ?loc) (entity-at Guard ?loc) (carrying ?a ?r) (guard-needs ?r))
     :effect (and (supplied-guard ?r) (not (carrying ?a ?r)))
  )

  ;; 4. Aksi Menyetor Suplai ke Raja Iblis (Boss)
  (:action DeliverToBoss
     :parameters (?a - agent ?loc - location ?r - resource-element)
     :precondition (and (at ?a ?loc) (entity-at Boss ?loc) (carrying ?a ?r) (boss-needs ?r))
     :effect (and (supplied-boss ?r) (not (carrying ?a ?r)))
  )
)
```

### 3.2 Siklus Suplai Berkala (*Periodic Overworld Loop*)
1. **Perumusan Rencana (*Plan Generation*):**  
   Solver menghasilkan sekuens aksi menggunakan *Forward State-Space Planning*:
   $$\pi_1 = \langle \text{MoveTo}(\text{IgnisAltar}), \text{HarvestShard}(\text{Flame}), \text{MoveTo}(\text{Courtyard}), \text{DeliverToGuard}(\text{Flame}) \rangle$$
2. **Eksekusi Fisik (*Physical Execution*):**  
   Setiap langkah `MoveTo` diterjemahkan menjadi rute jalur aktual di atas tile grid menggunakan algoritma **A\* Search / UCS** (Tahap 1).
3. **Penyegaran Siklus (*Periodic Loop*):**  
   Setelah sukses menyetor, minion secara berkala kembali menyusun rencana baru menuju Altar untuk membawa suplai berikutnya ke Boss di tahta istana.

---

## 👁️ 4. Modul 6: Knowledge-Based Logic & Guard Awakening

Modul ini memodelkan penalaran pada kondisi informasi tidak lengkap (*Partial Observability*).

### 4.1 Keadaan Awal Segel (*Unrevealed State*)
Pada awal permainan, segel gerbang utama dan senjata bos diselimuti kabut sihir kuno:
$$\text{Status}(\text{GateSeal}) = \text{UNKNOWN} \quad (\text{Dilambangkan simbol } [?] \text{ di atas gerbang dan HUD})$$

### 4.2 Trigger Utama: Progresi Level 2 & Guard Awakening
Pemain menjelajahi dunia dan mengalahkan minion untuk mengumpulkan EXP ($100\text{ EXP} \implies \text{Level 2}$).
- **Saat Level 2 Tercapai:**
  1. Layar mengalami guncangan kamera dramatis (*Screen Shake*).
  2. Kamera bergeser sejenak ke arah gerbang kastil (*Camera Pan to Gate*).
  3. Penjaga gerbang bangkit dari tidur meditasinya dan menyerukan dialog kebangkitan:
     > 💬 **Guard:** *"I HAVE AWAKENED! The ancient seal shall burn all intruders who dare approach!"*
  4. Segel gerbang yang tadinya tertutup kabut $[?]$ resmi terungkap (*Revealed*) menjadi identitas aslinya (misal: **Seal of Flame**).
  5. UI memperbarui badge gerbang dan briefing modal dengan nama elemen serta tips *counter* kelemahan musuh.

### 4.3 Formulasi Formal Logika Proposisional ($KB \models \alpha$)
Representasi basis pengetahuan pemain diformulasikan dalam klausa Horn:
1. **Aksioma Kebangkitan:**
   $$\text{PlayerLevel}(\ge 2) \implies \text{Awakened}(\text{Guard})$$
   $$\text{Awakened}(\text{Guard}) \implies \text{Revealed}(\text{GateSeal})$$
2. **Aksioma Deduksi Berdasarkan Serpihan Hasil Sabotase:**
   Jika pemain mencegat dan mengalahkan minion pembawa barang sebelum Level 2:
   $$\text{DefeatedMinionWith}(\text{FlameShard}) \implies \text{ResidualEssence}(\text{Flame})$$
   $$\text{ResidualEssence}(\text{Flame}) \land \text{Supplying}(\text{Guard}) \implies \text{DeduceSeal}(\text{SealOfFlame})$$
3. **Mesin Inferensi (Forward Chaining):**  
   Fakta baru dimasukkan ke $KB$, kemudian algoritma *Forward Chaining* menarik kesimpulan identitas segel secara otomatis.

### 4.4 Pemulangan / Penghentian Suplai Minion (*Minion Dismissal*)
Ketika Penjaga Gerbang berhasil dikalahkan oleh Pemain:
- Misi suplai minion dinyatakan selesai (*Goal State Achieved / Lockdown*).
- Seluruh minion yang tersisa di *Wilderness* secara otomatis memudar mundur (*fade away / dismiss*) ke sarang mereka.
- Area overworld bersih dari gangguan minion sehingga pemain dapat berfokus penuh untuk memasuki istana dan menghadapi Demon Lord (Bos).

---

## ⚖️ 5. Rekalkulasi & Kompensasi Local Search Balancer

Kekuatan pasif yang berubah dinamis akibat suplai minion diintegrasikan langsung ke dalam fungsi objektif *Simulated Annealing* dan *Hill Climbing*.

### 5.1 Penentuan Tingkatan Pasif (*Passive Tiers*)
Berdasarkan akumulasi suplai yang berhasil disetorkan minion:
- **Tier 0 (Weakened):** $0$ suplai berhasil disetor (Semua minion dicegat pemain).
- **Tier 1 (Standard):** $1$ suplai berhasil disetor.
- **Tier 2 (Overcharged):** $\ge 2$ suplai berhasil disetor (Minion tidak diganggu).

### 5.2 Formula Daya Agregat Baru ($Power_{\text{NPC}}$)
$$Power_{\text{NPC}} = HP + 2.2 \cdot Atk + 1.2 \cdot HeavyAtk + 3.0 \cdot Def + 0.7 \cdot (Pot \times Heal) + 15 \cdot Depth + \mathbf{P_{\text{passive}}}$$

Di mana nilai kontribusi pasif $P_{\text{passive}}$ adalah:
$$P_{\text{passive}} = \begin{cases}
-25 & \text{pada Tier 0 (Kelemahan Pasif)} \\
0   & \text{pada Tier 1 (Pasif Standar)} \\
+35 & \text{pada Tier 2 (Pasif Sangat Kuat)}
\end{cases}$$

### 5.3 Mekanisme Kompensasi Terbalik (Balancing Dynamics)
Fungsi objektif yang dimaksimalkan menuju $0$:
$$f(S) = -|Power_{\text{NPC}} - (r \times Power_{\text{Player}})|$$

Karena Local Search menuntut $Power_{\text{NPC}} \approx TargetPower$:
1. **Saat Pasif Menguat ($P_{\text{passive}} = +35$):**  
   Kapasitas daya yang tersisa untuk atribut fisik mengecil. Algoritma (SA/HC) secara otomatis menurunkan atribut fisik musuh:
   $$\Downarrow HP, \quad \Downarrow Def, \quad \Downarrow Atk$$
   *Hasil Pertarungan:* Musuh bertipe **Glass Cannon** (HP tipis dan mudah diserang, namun sihir pasifnya membakar/menghisap HP pemain dengan cepat).
2. **Saat Pasif Melemah ($P_{\text{passive}} = -25$):**  
   Kapasitas daya yang tersisa untuk atribut fisik melonggar. Algoritma (SA/HC) mengkompensasi dengan menaikkan atribut fisik:
   $$\Uparrow HP, \quad \Uparrow Def, \quad \Uparrow Atk$$
   *Hasil Pertarungan:* Musuh bertipe **Bruiser Tank** (Sihir pasif tidak berpengaruh banyak, namun pemain harus menghadapi monster dengan tubuh tebal dan pukulan fisik keras).

---

## 📂 6. Rencana Arsitektur File & Struktur Kode Baru

Berikut adalah pemetaan kelas dan skrip yang akan diwujudkan dalam basis kode:

```text
infernal-affairs/
├── scripts/
│   ├── core/
│   │   ├── PlanSolver.gd             # [BARU] Modul 7: STRIPS Classical Planner (State-Space Forward Search)
│   │   ├── LogicEngine.gd            # [BARU] Modul 6: KB Proposisional & Forward Chaining Inference
│   │   ├── CSPSolver.gd              # [UPDATE] Menyalurkan blueprint elemen & relasi ke PlanSolver
│   │   └── LocalSearchBalancer.gd    # [UPDATE] Integrasi P_passive dan kompensasi terbalik
│   ├── entities/
│   │   ├── ResourceNode.gd           # [BARU] Entitas interaktif Altar Elemen di zona Wilderness
│   │   ├── Minion.gd                 # [UPDATE] Integrasi status Carrier/Harvester & eksekusi Plan
│   │   └── Guard.gd                  # [UPDATE] Status Unrevealed/Revealed, monolog Awakening, dan Tier Pasif
│   ├── UI/
│   │   ├── PreBattleBriefingModal.gd # [UPDATE] Tampilan intel [?] unrevealed vs status terungkap
│   │   └── AwakeningBannerModal.gd   # [BARU] Banner dramatis dialog "I HAVE AWAKENED" di overworld
│   └── Main.gd                       # [UPDATE] Orkestrasi spawn altar, event level 2, dan timer suplai berkala
├── TAHAP_4_LOGIC_AND_PLANNING.md     # [DOKUMEN INI] Spesifikasi lengkap arsitektur Tahap 4
└── README.md                         # [UPDATE NANTINYA] Pengkinian dokumentasi utama game
```

---

## 🎯 7. Kesimpulan & Status Validasi
Perancangan untuk **Tahap 4: Logic & Automated Planning** telah diselaraskan dengan kebutuhan akademik dan aturan game yang telah disepakati:
- [x] **3 Altar Elemen** di area Wilderness $(8, 38)$, $(35, 38)$, dan $(21, 32)$.
- [x] **Unrevealed Seal** dengan trigger utama pencapaian **Level 2** disertai sekuens **Guard Awakening Dialog**.
- [x] **Suplai Berkala Minion** yang diotaki oleh algoritma *Automated Planning* (STRIPS/PDDL).
- [x] **Local Search Balancer Adaptif** dengan kompensasi atribut fisik terhadap kekuatan pasif.
- [x] **Overworld Map Freeze** saat masuk duel/briefing dengan Minion, Penjaga (Guard), maupun Bos (Demon Lord).

*Dokumen ini menjadi acuan tunggal dalam penyusunan kode tahap berikutnya.*

