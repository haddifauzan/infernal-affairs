# RANCANGAN IMPLEMENTASI TUBES TAHAP 4: INFERNAL AFFAIRS
## Keputusan di Bawah Ketidakpastian (Decisions Under Uncertainty) & Markov Decision Processes (MDP)

Dokumen ini memuat perencanaan arsitektur, formulasi matematis, mekanika gameplay, modul teknis, dan visualisasi interaktif untuk **Tubes Tahap 4 (Kecerdasan Buatan)** berdasarkan materi kuliah **`09_Decision under uncertainity.pdf`**.

---

## 1. Visi & Latar Belakang Konseptual

Pada tahap-tahap sebelumnya, sistem game dibangun di atas lingkungan yang bersifat **Deterministik**:
* **Tahap 1 (Pathfinding A* / UCS):** Menemukan lintasan terpendek pada grid statis dengan kepastian biaya langkah.
* **Tahap 2 (Adversarial Search Minimax):** Duel turn-based dengan pohon minimax di mana efek aksi damage/heal bersifat pasti.
* **Tahap 3 (CSP & Local Search):** Penugasan kendala benteng (CSP) dan penyeimbangan stat musuh (Local Search) yang menghasilkan konfigurasi tunggal optimal.
* **Tahap 4 Bagian A (Classical Planning STRIPS):** Sekuens aksi fixed deterministik: `MOVE -> HARVEST -> MOVE -> DELIVER`.

**Tubes Tahap 4 Bagian B** mentransformasikan game ke dalam lingkungan **Stokastik (*Stochastic Environment*)**, di mana dunia memiliki ketidakpastian (*uncertainty*):
1. **Aksi Tidak Lagi 100% Pasti:** Menyeberangi koridor pintas berisiko mengalami semburan magma atau sergapan Player ($P(\text{Hazard}) = f$).
2. **Plan Digantikan oleh Policy ($\pi(s)$):** Alih-alih daftar langkah kaku (*Plan*), agen dipandu oleh **Kebijakan (*Policy*)** yang memetakan setiap kondisi (*State*) ke aksi terbaiknya berdasarkan **Maximum Expected Utility (MEU)** dan **Bellman Equation**.
3. **Pembelajaran Sensor & Aturan Bayes:** Agen memperbarui keyakinannya (*Belief*) secara dinamis ketika menerima sinyal bahaya (asap retakan / deteksi keberadaan Player), lalu menghitung ulang keputusannya (*Update belief & redo decision*).

---

## 2. Formulasi Matematis & Teori AI (Mengacu PDF 09)

### 2.1. Definisi Markov Decision Process (MDP)
Sistem logistik minion kurir dimodelkan sebagai tuple MDP $\langle S, A, P, R, \gamma \rangle$:

1. **State Space ($S$):**
   * $s_0$: `Altar` (Titik panen kristal)
   * $s_1$: `Simpang_Lembah` (Titik bifurkasi keputusan)
   * $s_2$: `Jalur_Pintas` (Koridor retakan magma / chokepoint)
   * $s_3$: `Jalur_Utama` (Jalur berputar benteng, aman tapi jauh)
   * $s_4$: `Pos_Penjaga` (Terminal Goal pengiriman, State Penyerap / End State)
   * $s_5$: `Magma_Trap` (Terminal Failure / Terbakar / Tercegat, State Penyerap / End State)

2. **Action Space ($A$):**
   * $a_{\text{Pintas}}$: Memilih jalan pintas berisiko magma.
   * $a_{\text{Raya}}$: Memilih jalan utama aman bebas bahaya.
   * $a_{\text{Wait}}$: Berhenti sejenak di petak aman menunggu semburan padam.
   * $a_{\text{Balik}}$: Berbalik arah mundur ke state sebelumnya.

3. **Transition Model ($P(s' \mid s, a)$):**
   * Dari `Simpang_Lembah` mengambil $a_{\text{Pintas}}$:
     * Menuju `Pos_Penjaga`: $P(s_4 \mid s_1, a_{\text{Pintas}}) = 1 - f$
     * Terbakar/Gagal di `Magma_Trap`: $P(s_5 \mid s_1, a_{\text{Pintas}}) = f$
   * Dari `Simpang_Lembah` mengambil $a_{\text{Raya}}$:
     * Menuju `Jalur_Utama`: $P(s_3 \mid s_1, a_{\text{Raya}}) = 1.0$ (Pasti aman)
   * Dari `Jalur_Utama` melangkah ke `Pos_Penjaga`:
     * $P(s_4 \mid s_3, a_{\text{Jalan}}) = 1.0$

4. **Reward Function ($R(s')$):**
   * $R(\text{Pos\_Penjaga}) = +10$ (Reward delivery berhasil)
   * $R(\text{Magma\_Trap}) = -20$ (Penalti kegagalan kristal hangus/tumpah)
   * $R(s') = -2$ untuk semua state non-terminal (Biaya langkah / *living cost* agar agen efisien dan tidak looping, sesuai peringatan Slide 23).

5. **Discount Factor ($\gamma$):**
   * $\gamma = 0.8$ (Mengacu Slide 9 & 13, merefleksikan preferensi waktu: pengiriman yang lebih cepat bernilai lebih tinggi).

---

### 2.2. Expected Value & Maximum Expected Utility (MEU)
Sesuai Slide 4–6, utilitas ekspektasi dari sebuah aksi dihitung sebagai:
$$\text{Expected Utility}(a) = \sum_{s'} P(s' \mid s, a) \cdot \left[ R(s') + \gamma V(s') \right]$$

Prinsip **MEU Rule:**
$$\pi(s) = \arg\max_{a \in A} \text{Expected Utility}(a)$$

---

### 2.3. Aturan Bayes (*Bayesian Updating: Update Belief & Redo Decision*)
Sesuai Slide 7–8, keyakinan agen atas bahaya letupan magma atau sergapan diperbarui melalui observasi sinyal sensor $W$ (retakan berasap / alarm deteksi Player):

1. **Prior Belief:**
   * $P(\text{Bahaya}) = 0.10$
   * $P(\text{Aman}) = 0.90$
2. **Likelihood Sensor:**
   * $P(W \mid \text{Bahaya}) = 0.90$ (Jika bahaya aktif, 90% kemungkinan sinyal asap/sensor terpicu)
   * $P(W \mid \text{Aman}) = 0.10$ (False alarm 10%)
3. **Probabilitas Total Sinyal $P(W)$:**
   $$P(W) = P(W \mid \text{Bahaya}) \cdot P(\text{Bahaya}) + P(W \mid \text{Aman}) \cdot P(\text{Aman})$$
   $$P(W) = 0.90 \times 0.10 + 0.10 \times 0.90 = 0.09 + 0.09 = 0.18$$
4. **Posterior Belief (*Bayes Rule*):**
   $$P(\text{Bahaya} \mid W) = \frac{P(W \mid \text{Bahaya}) \cdot P(\text{Bahaya})}{P(W)} = \frac{0.09}{0.18} = 0.50$$
5. **Redo Decision:**
   * Sebelum sinyal ($f = 0.10$): $Q(\text{Pintas}) = 7.0 > Q(\text{Raya}) = 6.0 \rightarrow$ Pilih **Pintas**.
   * Setelah sinyal ($f = 0.50$): $Q(\text{Pintas}) = -5.0 < Q(\text{Raya}) = 6.0 \rightarrow$ **Policy Shift ke Jalur Utama!**

---

### 2.4. Bellman Equation & Value Iteration
Sesuai Slide 14–21, nilai $V(s)$ dan $Q(s, a)$ dihitung secara berulang:
$$Q(s, a) = \sum_{s'} P(s' \mid s, a) \left[ R(s') + \gamma V(s') \right]$$
$$V(s) = \max_a Q(s, a)$$

#### Tabel Komputasi Value Iteration (Kondisi Normal, $f=0.1, \gamma=0.8$):
| Iterasi ($k$) | $V(\text{Altar})$ | $Q(\text{Simpang, Pintas})$ | $Q(\text{Simpang, Raya})$ | $Q(\text{Simpang, Balik})$ | $V(\text{Simpang})$ (Terpilih) | $V(\text{Jalur Utama})$ |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **0** | $0$ | — | — | — | $0$ | $0$ |
| **1** | $-2.0$ | $7.0$ | $-2.0$ | $-2.0$ | **$7.0$ (Pintas)** | $10.0$ |
| **2** | $3.6$ | $7.0$ | $6.0$ | $-3.6$ | **$7.0$ (Pintas)** | $10.0$ |
| **3** | $3.6$ | $7.0$ | $6.0$ | $0.88$ | **$7.0$ (Konvergen)**| $10.0$ |

#### Tabel Komputasi Value Iteration (Kondisi Waspada / Sensor Aktif, $f=0.25$ s/d $0.50$):
| Iterasi ($k$) | $V(\text{Altar})$ | $Q(\text{Simpang, Pintas})$ | $Q(\text{Simpang, Raya})$ | $Q(\text{Simpang, Balik})$ | $V(\text{Simpang})$ (Terpilih) | $V(\text{Jalur Utama})$ |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | $-2.0$ | $2.5$ | $-2.0$ | $-2.0$ | **$2.5$ (Pintas)** | $10.0$ |
| **2** | $0.0$ | $2.5$ | $6.0$ | $-3.6$ | **$6.0$ (Raya - Shift!)**| $10.0$ |
| **3** | $2.8$ | $2.5$ | $6.0$ | $-2.0$ | **$6.0$ (Konvergen)**| $10.0$ |

---

### 2.5. Perbandingan Paradigma: Plan vs Policy (Slide 12)

```
┌──────────────────────────────────────────────┬──────────────────────────────────────────────┐
│       CLASSICAL PLAN (STRIPS / TAHAP 4A)     │         MDP POLICY (MARKOV / TAHAP 4B)       │
├──────────────────────────────────────────────┼──────────────────────────────────────────────┤
│ Berupa daftar sekuensial langkah tetap:      │ Berupa aturan universal untuk setiap state:  │
│ Plan = [Move(A), Harvest, Move(B), Deliver]  │ π: S → A                                     │
├──────────────────────────────────────────────┼──────────────────────────────────────────────┤
│ Mengasumsikan dunia deterministik tanpa cacat│ Mengakomodasi ketidakpastian dan risiko      │
├──────────────────────────────────────────────┼──────────────────────────────────────────────┤
│ Jika ada magma meletup mendadak, eksekusi    │ Jika kondisi state berubah (misal bahaya     │
│ rencana macet total (broken preconditions)   │ terdeteksi), policy langsung menunjuk aksi   │
│                                              │ terbaik baru (putar balik / tunggu)          │
└──────────────────────────────────────────────┴──────────────────────────────────────────────┘
```

---

## 3. Desain Mekanika Game & Interaksi Player

### 3.1. Rintangan Retakan Magma Semi-Stokastik (*Magma Fissures*)
* **Penempatan:** Pada koridor sempit (*chokepoint*) antara lembah Altar dan gerbang istana.
* **Siklus 3 Fase Visual (Telegraphing):**
  1. **Dormant (Padam, 3.0–5.0 detik):** Ubin berupa batu vulkanik hitam. Aman dilewati minion dan player.
  2. **Warning (Berasap / Berpendar, 1.2–1.8 detik):** Retakan batu memerah dan mengeluarkan kepulan asap belerang. Mengaktifkan sensor bahaya bagi minion ($f = 0.50$).
  3. **Eruption (Semburan Aktif, 1.5 detik):** Kolom api dan lahar menyembur ke atas.

### 3.2. Dampak Bagi Minion Kurir
* **Keberhasilan ($1 - f$):** Minion tiba di Pos Penjaga dengan selamat $\rightarrow$ Penjaga menerima suplai kristal ($+10$).
* **Kegagalan ($f$ / Terkena Semburan Magma):**
  * Minion terkena knockback dan animasi panik.
  * Keranjang pikul terbakar $\rightarrow$ Shard kristal rontok/hangus ($-20$).
  * Minion mundur kembali ke Altar dengan tangan kosong untuk mengulang siklus panen.
* **Perilaku Berhenti Sejenak (*Wait Action*):**
  * Jika minion sudah terlanjur berada di tengah lorong saat magma meletup, policy mengarahkan aksi `WAIT` di petak aman sebelum retakan hingga semburan padam, alih-alih nekat menerobos atau mundur jauh.

### 3.3. Interaksi & Dampak Bagi Player (*Risk vs. Reward*)
* **Dampak Rintangan Magma ke Player:**
  * Jika Player menginjak ubin saat semburan aktif: Player terkena **Lava Damage (-12 HP)** dan efek gerak melambat (*slow*) selama 1 detik.
* **Peluang Sabotase / Begal Suplai (*Intercept & Loot*):**
  * Player bisa mengejar minion kurir di jalan pintas.
  * Menabrak/menyerang kurir membuat keranjang kristal tumpah $\rightarrow$ Player memungut kristal tersebut untuk **EXP / Bonus Potion gratis**, sekaligus menggagalkan penguatan senjata Bos.
* **Taktik Gertakan (*Bluffing via Bayes Update*):**
  * Player cukup berdiri di mulut lorong jalan pintas. Sensor minion mendeteksi keberadaan musuh $\rightarrow$ Bayes update menaikkan $P(\text{Hazard})$ menjadi $0.50$ $\rightarrow$ minion membatalkan niat lewat jalan pintas dan berbalik arah memutar ke jalan utama yang sangat jauh.

---

## 4. Arsitektur Teknis & Modul Kode (Godot Engine)

```
res://scripts/
├── core/
│   ├── MDPSolver.gd                  <-- [BARU] Engine Bellman Equation & Value Iteration
│   ├── StochasticHazardManager.gd    <-- [BARU] Pengatur siklus retakan magma semi-stokastik
│   ├── PlanSolver.gd                 <-- Classical Planning STRIPS (Komparasi Plan vs Policy)
│   ├── LogicEngine.gd                <-- Forward Chaining & Horn Clauses
│   ├── GridManager.gd                <-- Topologi grid & koordinat
│   └── ArenaMap.gd                   <-- Rendering ubin lava & visual telegraph
├── entities/
│   ├── Minion.gd                     <-- Integrasi Sensor Bayes & Eksekutor Policy MDP
│   ├── ResourceNode.gd               <-- Altar kristal
│   └── Player.gd                     <-- Deteksi damage magma & interaksi sabotase kurir
└── UI/
    └── MDPDebugHUD.gd                <-- [BARU] Panel tabel Value Iteration & visualisasi Policy
```

### 4.1. Spesifikasi Modul Baru

#### 1. `scripts/core/MDPSolver.gd`
* **Tanggung Jawab:**
  * Menyimpan representasi State, Aksi, Transition Matrix $P(s' \mid s, a)$, Reward $R(s')$, dan Discount $\gamma = 0.8$.
  * Menghitung algoritma **Value Iteration** hingga konvergen ($\Delta V < 0.001$).
  * Menghitung **Aturan Bayes** saat menerima bukti sinyal observasi.
  * Menghasilkan tabel matriks $Q(s, a)$, vektor $V(s)$, dan tabel kebijakan optimal $\pi^*(s)$.

#### 2. `scripts/core/StochasticHazardManager.gd`
* **Tanggung Jawab:**
  * Mengatur koordinat ubin retakan magma di grid map (`Jalur Pintas`).
  * Mengontrol *timer stochastic state machine* (Dormant $\rightarrow$ Warning $\rightarrow$ Eruption).
  * Mengirim sinyal `hazard_warning_started(pos)` dan `hazard_erupted(pos)`.
  * Memeriksa benturan (*hitbox collision*) dengan Player dan Minion.

#### 3. Integrasi ke `scripts/entities/Minion.gd`
* Menambahkan variabel:
  * `current_mdp_policy: Dictionary`
  * `hazard_belief: float = 0.10`
* Saat memasuki node simpang: memanggil `MDPSolver.get_optimal_action(current_state, hazard_belief)`.
* Menghubungkan sinyal `hazard_warning_started` $\rightarrow$ memicu kalkulasi `_update_belief_and_redo_decision()`.

#### 4. `scripts/UI/MDPDebugHUD.gd`
* Menampilkan panel transparansi AI di pojok layar:
  * Tabel real-time $V(s)$ dan nilai $Q(s, a)$.
  * Indikator teks *Belief*: `Belief P(Hazard): 0.10 [NORMAL: PINTAS]`.
  * Saat sensor aktif: teks berkedip `Belief P(Hazard|Warning): 0.50 [ALERT: REDO DECISION -> JALUR AMAN]`.
  * Tombol interaktif untuk dosen/penguji: `[Force Trigger Warning]` untuk mendemonstrasikan pergeseran kebijakan (*Policy Shift*) secara langsung.

---

## 5. Rencana Tahapan Kerja (Implementation Roadmap)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                             ROADMAP TAHAP 4                              │
├────────────┬─────────────────────────────────────────────────────────────┤
│ Milestone 1│ Pembuatan Modul Inti MDP (`MDPSolver.gd` & Value Iteration) │
│ Milestone 2│ Sistem Rintangan Magma Stokastik (`StochasticHazard.gd`)     │
│ Milestone 3│ Integrasi Minion: Sensor Bayes & Eksekutor Policy π(s)      │
│ Milestone 4│ Interaksi Player (Lava Damage, Begal Kristal, Bluffing)     │
│ Milestone 5│ Debug HUD: Visualizer Tabel Value Iteration & Policy Shift  │
│ Milestone 6│ Pengujian Headless, Verifikasi Matematis & Dokumentasi      │
└────────────┴─────────────────────────────────────────────────────────────┘
```

### Rincian Eksekusi Tiap Milestone:
1. **Milestone 1 - MDPSolver.gd:**
   * Tulis kelas murni RefCounted untuk Bellman Equation.
   * Lengkapi dengan fungsi `solve_value_iteration(hazard_prob: float)` dan `update_bayesian_belief(has_warning: bool)`.
   * Unit test komputasi numerik agar angka $V(s)$ dan $Q(s, a)$ presisi sama persis dengan tabel Slide 17 & 20 ($7.0 \rightarrow -5.0$).

2. **Milestone 2 - Stochastic Hazard:**
   * Tentukan set ubin koordinat retakan magma pada map *wilderness* menuju gerbang istana.
   * Pasang partikel asap untuk fase *warning* dan semburan api untuk fase *eruption*.

3. **Milestone 3 - Perilaku Minion Kurir:**
   * Hubungkan minion kurir ke `MDPSolver`.
   * Uji coba gerakan: saat normal minion mengambil jalur pintas; saat retakan berasap atau player mendekat, minion berbalik mengambil rute utama.
   * Pasang mekanisme jatuh kristal jika minion terkena letupan magma saat melintas.

4. **Milestone 4 - Gameplay Player:**
   * Tambahkan deteksi jika Player melangkah di ubin aktif magma $\rightarrow$ kena damage $-12$ HP.
   * Tambahkan interaksi menabrak minion kurir di lorong pintas $\rightarrow$ minion drop item kristal yang dapat diambil Player.

5. **Milestone 5 - UI Visualizer:**
   * Tambahkan panel debug lipat (collapsible panel) di layar utama yang menampilkan tabel $V(s)$ dan grafik transisi policy secara visual.

6. **Milestone 6 - Finalisasi & Laporan:**
   * Verifikasi dengan `Godot --check-only` dan `--quit-after 60`.
   * Sajikan tabel komparasi matematis Classical Planning vs MDP Policy untuk bab pembahasan laporan tugas besar.

---

## 6. Format Pembahasan untuk Laporan Akhir

Dengan implementasi di atas, laporan Tahap 4 akan memiliki analisis ilmiah yang sangat kaya:
1. **Bab Formulasi Masalah:** Penurunan formal tuple MDP $\langle S, A, P, R, \gamma \rangle$ dan perbandingannya dengan representasi aksi STRIPS.
2. **Bab Analisis Keputusan:** Bukti matematis penurunan nilai $Q(\text{Pintas})$ dari $7.0$ menjadi $-5.0$ saat probabilitas bahaya naik dari $0.10$ ke $0.50$ akibat inferensi Bayes.
3. **Bab Evaluasi Eksperimental:** Grafik waktu tempuh suplai minion pada skenario tanpa gangguan vs dengan gangguan bahaya stokastik.
4. **Bab Analisis Reward Shaping:** Pembahasan bahaya pemberian reward positif pada aktivitas melangkah (Slide 23) dan pentingnya biaya penalti hidup (*living cost* $-2$) untuk menjamin konvergensi kebijakan optimal.
