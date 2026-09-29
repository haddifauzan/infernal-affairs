# 🔥 INFERNAL AFFAIRS: Adversarial Search Turn-Based Combat
> **Tugas Besar Mata Kuliah Kecerdasan Buatan (AI) — Tahap 2**  
> **Topik:** *Adversarial Search (Minimax, Alpha-Beta Pruning, & Expectimax Search)*  
> **Engine:** Godot Engine 4.3+ (GDScript)

---

## 📌 1. Deskripsi Umum Proyek

**Infernal Affairs (Tahap 2)** adalah modul game pertarungan taktis berbasis giliran (*Turn-Based Combat*) yang mengimplementasikan konsep **Adversarial Search** sebagai otak kecerdasan buatan (*AI Agent*). 

Dalam game ini, pemain mengendalikan **Player (Lost Soul Knight)** yang berduel melawan musuh cerdas **Demon Brute (AI Agent)**. Begitu Player tertangkap atau berhadapan dekat dengan Demon di arena infernal, game bertransisi secara mulus ke mode pertarungan duel 1v1. Demon Brute tidak digerakkan oleh *rule-based scripted logic* sederhana, melainkan menggunakan algoritma pohon pencarian minimax yang mensimulasikan langkah-langkah masa depan secara mendalam, mengevaluasi utilitas pertarungan, dan merespons setiap strategi yang dilancarkan pemain.

---

## 🔄 2. Transisi Paradigma: Single-Agent ke Adversarial Search

| Parameter | Standard Search (Tahap 1: A* / UCS) | Adversarial Search (Tahap 2: Minimax) |
| :--- | :--- | :--- |
| **Tipe Lingkungan** | *Single-Agent* | *Multi-Agent (Adversarial / Kompetitif)* |
| **Kontrol Lingkungan** | Agen memiliki kontrol penuh atas dunia | Lingkungan dipengaruhi oleh aksi pemain lawan |
| **Output Solusi** | **Path**: Sekuens langkah statis tanpa umpan balik | **Strategy**: Rencana aksi kondisional terhadap langkah lawan |
| **Sifat Permainan** | Deterministik & Statis | *Zero-Sum*, diskrit, giliran bergantian (*turn-based*) |
| **Tujuan Agen** | Menemukan jalur terpendek ke tujuan (*Goal*) | Memaksimalkan nilai kemenangan (*Maximize Utility*) dari kerugian lawan |

---

## 📐 3. Formulasi Formal Masalah Game (*Game as a Search Problem*)

Sesuai kaidah formal *Artificial Intelligence*, game duel ini dimodelkan sebagai sistem pencarian formal dengan komponen-komponen berikut:

### 3.1 State Representation ($S$)
Setiap keadaan permainan (*state*) pada giliran tertentu direpresentasikan oleh tuple:
$$s = \langle HP_{\text{player}}, HP_{\text{npc}}, Pot_{\text{player}}, Pot_{\text{npc}}, Def_{\text{player}}, Def_{\text{npc}}, Turn, TurnCount \rangle$$

- $HP_{\text{player}}, HP_{\text{npc}} \in [0, 100]$: Status kesehatan masing-masing pihak.
- $Pot_{\text{player}}, Pot_{\text{npc}} \in [0, 3]$: Sisa ramuan penyembuh (*Potion*).
- $Def_{\text{player}}, Def_{\text{npc}} \in \{\text{true}, \text{false}\}$: Status kuda-kuda bertahan (*Defending*).
- $Turn \in \{\text{PLAYER}, \text{NPC}\}$: Giliran pihak yang aktif melangkah.
- $TurnCount \in [0, 40]$: Penghitung jumlah putaran duel.

### 3.2 Available Actions ($A(s)$) dengan Branching Factor $b \le 4$
Setiap pihak memiliki maksimal 4 pilihan aksi di setiap gilirannya:
1. **`ATTACK` (Serangan Biasa)**:
   - Memberikan damage dasar **20 DMG**.
   - Jika lawan sedang dalam status *Defending*, damage tereduksi sebesar 50% menjadi **10 DMG**.
2. **`HEAVY_ATTACK` (Serangan Berat)**:
   - Memberikan serangan kritikal dasar sebesar **37 DMG**.
   - **Mekanisme vs Defend**: Menembus pertahanan sebagian (*partial pierce*); jika lawan dalam status *Defending*, damage hanya tereduksi 30% menjadi **25 DMG** (berbeda dengan serangan biasa yang tereduksi 50% menjadi 10 DMG).
   - Memiliki biaya resiko (*recoil self-damage*) sebesar **10 HP** pada pihak yang melancarkannya.
3. **`DEFEND` (Kuda-kuda Bertahan)**:
   - Mengaktifkan status bertahan yang memotong 50% damage dari serangan biasa lawan pada giliran berikutnya.
4. **`POTION` (Ramuan Pemulihan)**:
   - Memulihkan **+30 HP** (maksimal 100 HP).
   - Aksi ini hanya tersedia (*valid*) jika sisa ramuan $> 0$ dan HP saat itu $< 100$.

### 3.3 Transition Model ($\text{RESULT}(s, a)$)
Fungsi transisi deterministik yang menghasilkan status baru $s'$ setelah aksi $a$ dieksekusi:
- Mengurangi HP target sesuai kalkulasi damage dan status *Defending*.
- Mengatur ulang flag pertahanan (*defending reset*).
- Mengurangi stok potion dan menambah HP jika aksi berupa *Potion*.
- Menukar giliran $Turn \leftarrow (Turn == \text{PLAYER} ? \text{NPC} : \text{PLAYER})$.
- Menambah $TurnCount \leftarrow TurnCount + 1$.

### 3.4 Terminal Test ($\text{IS-TERMINAL}(s)$)
Permainan dinyatakan selesai (*terminal*) jika memenuhi salah satu kondisi berikut:
1. $HP_{\text{player}} \le 0$ (Player kalah / Demon menang).
2. $HP_{\text{npc}} \le 0$ (Demon kalah / Player menang).
3. $TurnCount \ge 40$ (Batas keamanan putaran tercapai untuk mencegah siklus rekursi tak hingga $\rightarrow$ dinyatakan seri / *Draw*).

### 3.5 Terminal Utility Function ($\text{UTILITY}(s, p)$)
Pada kondisi terminal, imbalan numerik didefinisikan dari sudut pandang agen NPC:
$$\text{UTILITY}(s, \text{NPC}) = \begin{cases} +10000, & \text{jika } HP_{\text{player}} \le 0 \text{ dan } HP_{\text{npc}} > 0 \text{ (NPC Menang)} \\ -10000, & \text{jika } HP_{\text{npc}} \le 0 \text{ dan } HP_{\text{player}} > 0 \text{ (Player Menang)} \\ 0, & \text{jika } TurnCount \ge 40 \text{ (Draw / Seri)} \end{cases}$$

---

## 🧠 4. Algoritma Adversarial Search yang Diimplementasikan

Agen Demon Brute mendukung 3 algoritma pencarian adversarial yang dapat dipilih secara fleksibel:

```
                      [ MAX Node (NPC Turn) ]
                     /           |           \
                 Attack        Heavy        Defend
                  /              |              \
      [ MIN (Player) ]    [ MIN (Player) ]    [ MIN (Player) ]
       /      |     \      /     |     \      /      |     \
     Atk     Hvy    Def  Atk    Hvy    Def  Atk     Hvy    Def
```

### 4.1 Standard Minimax Algorithm
Minimax mengasumsikan kedua pemain bermain secara optimal (*Optimal Play*):
- **MAX Node (NPC)**: Memilih aksi yang menghasilkan nilai maksimum:
  $$\text{MINIMAX}(s) = \max_{a \in A(s)} \text{MINIMAX}(\text{RESULT}(s, a))$$
- **MIN Node (Player)**: Memilih aksi yang menghasilkan nilai minimum bagi NPC:
  $$\text{MINIMAX}(s) = \min_{a \in A(s)} \text{MINIMAX}(\text{RESULT}(s, a))$$
- **Kompleksitas**: Waktu $O(b^m)$, Ruang $O(bm)$, di mana $b$ adalah branching factor ($b \le 4$) dan $m$ adalah kedalaman pencarian (*depth*).

### 4.2 Alpha-Beta Pruning
Untuk mengatasi ledakan kombinatorial pohon permainan (*tree too wide*), diimplementasikan teknik pemangkasan **Alpha-Beta Pruning**:
- **Parameter $\alpha$**: Nilai utilitas terbaik (tertinggi) yang telah ditemukan sejauh ini untuk pemain MAX (tidak akan pernah lebih kecil).
- **Parameter $\beta$**: Nilai utilitas terbaik (terendah) yang telah ditemukan sejauh ini untuk pemain MIN (tidak akan pernah lebih besar).
- **Kondisi Pemangkasan (*Pruning Rule*)**:
  $$\text{Jika } \alpha \ge \beta \implies \text{Pruning (Abaikan sisa cabang anak)}$$
- **Efisiensi**: Mengurangi ruang eksplorasi dari $O(b^m)$ mendekati $O(b^{m/2})$ pada urutan evaluasi anak yang optimal (*best-case move ordering*), memungkinkan agen berpikir 2x lebih dalam pada alokasi waktu yang sama.

### 4.3 Expectimax Search (Fitur Tambahan / Probabilistik)
Dalam game nyata, serangan lawan tidak selalu deterministik. Mode Expectimax memodelkan sifat non-deterministik di mana serangan berat `HEAVY_ATTACK` memiliki peluang **akurasi 60% hit dan 40% miss**:
- **Layer MAX**: NPC tetap memilih nilai maksimum.
- **Layer CHANCE**: Mengganti layer pemain dengan nilai harapan matematis (*expected value*):
  $$V(s) = \sum_{o \in \text{Outcomes}} P(o) \cdot V(\text{RESULT}(s, o))$$
  $$V_{\text{Heavy}}(s) = 0.6 \cdot V(\text{Hit}) + 0.4 \cdot V(\text{Miss})$$

---

## ⚖️ 5. Heuristic Evaluation Functions & Early Cutoff

Karena pohon permainan yang lengkap hingga terminal state terlalu dalam (*tree too deep*), algoritma menerapkan mekanisme **Early Stop (Cutoff Search)** pada kedalaman tertentu ($d$). Nilai status non-terminal dihitung menggunakan **Fungsi Evaluasi Heuristik** $\text{EVAL}(s)$ dari sudut pandang NPC:

### 1. `HP_DIFF` (Selisih HP — Default)
Mengukur keunggulan relatif HP secara seimbang (*zero-sum*):
$$\text{EVAL}_{\text{diff}}(s) = HP_{\text{npc}} - HP_{\text{player}}$$

### 2. `AGGRESSIVE` (Agresi Maksimal)
Fokus murni untuk mengurangi HP pemain secepat mungkin tanpa mempedulikan HP diri sendiri:
$$\text{EVAL}_{\text{agg}}(s) = 100 - HP_{\text{player}}$$

### 3. `DEFENSIVE` (Ketahanan Diri)
Fokus murni untuk mempertahankan keselamatan dan kelangsungan hidup diri sendiri:
$$\text{EVAL}_{\text{def}}(s) = HP_{\text{npc}}$$

### 4. `WEIGHTED` (Linear Weighted Multi-Attribute)
Menggabungkan keunggulan HP, persediaan ramuan, dan status pertahanan dengan bobot tertentu:
$$\text{EVAL}_{\text{weight}}(s) = 2.0 \cdot (HP_{\text{npc}} - HP_{\text{player}}) + (10 \cdot Pot_{\text{npc}} - 5 \cdot Pot_{\text{player}}) + (15.0 \text{ jika } Def_{\text{npc}})$$

### 5. `HP_RATIO` (Rasio Multiplikatif)
Menilai keunggulan HP secara rasio non-linear:
$$\text{EVAL}_{\text{ratio}}(s) = \left( \frac{HP_{\text{npc}}}{\max(1, HP_{\text{player}})} \right) \times 50.0$$

---

## 🔀 6. Optimasi Urutan Aksi (*Action / Move Ordering*)

Efisiensi pemangkasan Alpha-Beta Pruning sangat bergantung pada urutan eksplorasi cabang anak (*move ordering*). Proyek ini menyediakan 4 strategi ordering:
1. **`DEFAULT` (Natural Enum Ordering)**:
   - Urutan statis berdasarkan indeks nilai enum aksi (`ATTACK = 0` $\rightarrow$ `HEAVY_ATTACK = 1` $\rightarrow$ `DEFEND = 2` $\rightarrow$ `POTION = 3`). Pendekatan ini mengevaluasi aksi ofensif terlebih dahulu sebelum aksi defensif.
2. **`AGGRESSIVE` (Offense-First)**:
   - Urutan: `HEAVY_ATTACK` $\rightarrow$ `ATTACK` $\rightarrow$ `DEFEND` $\rightarrow$ `POTION`.
3. **`DEFENSIVE` (Defense-First)**:
   - Urutan: `DEFEND` $\rightarrow$ `POTION` $\rightarrow$ `ATTACK` $\rightarrow$ `HEAVY_ATTACK`.
4. **`RANDOM` (Unordered)**:
   - Urutan aksi diacak di setiap node untuk mensimulasikan skenario *worst-case* / *average-case* pencarian.

---

## 🖥️ 7. Fitur Debug Overlay & Monitoring Real-Time

Saat pertarungan berlangsung, game menyediakan **Modular Debug Sidebar** yang dapat dibuka/tutup secara instan dengan menekan tombol **`[D]`**:

```
┌────────────────────────────────────────────────────────┐
│  NPC MINIMAX MONITOR                               [X] │
├────────────────────────────────────────────────────────┤
│  AI Engine & Search Config                             │
│  • Algorithm: Alpha-Beta Pruning                       │
│  • Evaluation: HP Difference (Optimal)                 │
│  • Lookahead Depth: 3 Plies (Balanced)                 │
│  • Action Ordering: Default (Enum Order)                  │
├────────────────────────────────────────────────────────┤
│  Tree Search Performance                               │
│  ┌─────────────────────────┬─────────────────────────┐ │
│  │ Nodes Visited:  142     │ Branches Pruned:  86    │ │
│  │ Prune Ratio:    37.7%   │ Max Depth:        3     │ │
│  └─────────────────────────┴─────────────────────────┘ │
├────────────────────────────────────────────────────────┤
│  Candidate Action Utilities (NPC)                      │
│  • Attack       : +20.0                                │
│  • Heavy Attack : +27.0  [BEST]                        │
│  • Defend       : +10.0                                │
│  • Potion       : +15.0                                │
├────────────────────────────────────────────────────────┤
│  Strategic State Assessment                            │
│  • Advantage    : Demon (+17 HP Lead)                  │
│  • Threat Level : Moderate                             │
├────────────────────────────────────────────────────────┤
│  Recent Turns Log                                      │
│  • Player: Attack [-20 HP]                             │
│  • Demon : Heavy Attack [-37 HP]                       │
└────────────────────────────────────────────────────────┘
```

1. **Aksi yang Dipertimbangkan NPC & Nilai Skornya**: Menampilkan seluruh opsi aksi kandidat beserta nilai utilitas hasil kalkulasi pohon rekursif dan menandai pilihan optimal dengan label `[BEST]`.
2. **Node Counts & Search Metrics**: Menampilkan jumlah node yang dikunjungi (*Nodes Visited*), jumlah cabang yang dipangkas (*Branches Pruned*), dan efisiensi pemangkasan (*Prune Ratio*).
   - **Formula Prune Ratio (HUD)**: $\text{Prune Ratio} = \frac{\text{Branches Pruned}}{\text{Nodes Visited} + \text{Branches Pruned}} \times 100\%$ (mengukur persentase cabang yang dieliminasi dari total kemungkinan percabangan internal yang dievaluasi pada giliran tersebut).
3. **Konfigurasi Live**: Pemain dapat mengubah algoritma, fungsi evaluasi, kedalaman ($d=1 \dots 6$), dan strategi ordering secara langsung dari UI tanpa menghentikan game.

---

## 📊 8. Laboratorium Eksperimen & Analisis Hasil (*Benchmark Lab*)

Game ini dilengkapi dengan **Automated Headless Benchmark Lab** terintegrasi (dapat dibuka dengan menekan tombol **[P]**). Sistem akan menjalankan simulasi **220 pertarungan** tanpa input manusia (AI vs AI) yang terbagi ke dalam 5 modul pengujian:
- **Eksperimen 1 (Perbandingan Algoritma)**: 3 konfigurasi $\times$ 10 pertarungan = **30 pertarungan**.
- **Eksperimen 2 (Perbandingan Fungsi Evaluasi)**: 5 konfigurasi $\times$ 10 pertarungan = **50 pertarungan**.
- **Eksperimen 3 (Perbandingan Urutan Aksi)**: 4 konfigurasi $\times$ 10 pertarungan = **40 pertarungan**.
- **Eksperimen 4 (Perbandingan Kedalaman)**: 6 level depth ($d=1 \dots 6$) $\times$ 10 pertarungan = **60 pertarungan**.
- **Eksperimen 5 (Profil Perilaku NPC)**: 4 profil evaluasi $\times$ 10 pertarungan = **40 pertarungan** (dijalankan ulang secara independen untuk mencatat distribusi frekuensi aksi).

> 💡 **Metodologi Simulasi Player (Controlled Environment):** Seluruh benchmark pengujian otomatis menggunakan strategi bot Player standar `GREEDY` (`_greedy_player_action`: selalu memilih serangan biasa `ATTACK`, dan memprioritaskan pemulihan `POTION` jika HP $< 30$). Simulasi ini sengaja dibuat deterministik-reaktif tanpa input manusia, sehingga metrik performa (*Win Rate*, *Nodes Visited*, dll.) murni merefleksikan keunggulan matematis dari konfigurasi AI Demon.

### Eksperimen 1: Perbandingan Algoritma (Depth = 4, Eval = HP_DIFF)
*Menguji penghematan komputasi antara Minimax reguler, Alpha-Beta Pruning, dan Expectimax:*

| Algoritma | Win Rate (%) | Avg Nodes Visited | Avg Branches Pruned | Penghematan Node (vs Minimax) | Keputusan Akhir |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Standard Minimax** | 100% | 1,811 | 0 | 0.0% (*Baseline*) | Identik (Optimal) |
| **Alpha-Beta Pruning** | 100% | 752 | 397 | **58.5% Penghematan** | Identik (Optimal) |
| **Expectimax Search** | 100% | 1,124 | 0 | -38.0% (Evaluasi Chance) | Resiko Terukur |

> **Analisis & Klarifikasi Dua Metrik Pemangkasan (*Pruning Metrics*):**
> 1. **Penghematan Komputasi Relatif terhadap Minimax (*Relative Node Reduction*)**:
>    $$\text{Penghematan} = 1 - \frac{\text{Avg Nodes Alpha-Beta}}{\text{Avg Nodes Minimax}} = 1 - \frac{752}{1.811} \approx 58{,}5\%$$
>    Alpha-Beta berhasil memangkas lebih dari separuh beban pencarian pohon Minimax murni sambil menghasilkan keputusan langkah yang **100% identik secara matematis**.
> 2. **Rasio Pemangkasan Lokal Internal (*HUD Prune Ratio*)**:
>    $$\text{Prune Ratio} = \frac{\text{Avg Branches Pruned}}{\text{Avg Nodes Visited} + \text{Avg Branches Pruned}} = \frac{397}{752 + 397} \approx 34{,}55\%$$
>    Metrik ini (sebagaimana ditampilkan pada HUD saat duel) mengukur persentase cabang yang dieliminasi dari total kemungkinan percabangan internal yang dievaluasi Alpha-Beta.

---

### Eksperimen 2: Perbandingan Fungsi Evaluasi (Alpha-Beta, Depth = 4)
*Menguji efektivitas 5 fungsi heuristik dalam menentukan hasil akhir duel:*

| Fungsi Evaluasi | Win Rate (%) | Draw Rate (%) | Loss Rate (%) | Karakter Taktis AI |
| :--- | :---: | :---: | :---: | :--- |
| **`HP_DIFF`** | **100%** | 0% | 0% | Sangat seimbang; menyerang saat unggul, menyembuhkan diri saat kritis. |
| **`WEIGHTED`** | **100%** | 0% | 0% | Paling taktis; mempertahankan stok potion dan memanfaatkan status defend. |
| **`HP_RATIO`** | 90% | 10% | 0% | Mengutamakan memperbesar rasio keunggulan darah. |
| **`AGGRESSIVE`** | 80% | 0% | 20% | Terlalu sering melancarkan Heavy Attack sehingga terkena *self-recoil* saat sekarat. |
| **`DEFENSIVE`** | 60% | 30% | 10% | Cenderung pasif bertahan dan sering mencapai batas *MAX_TURNS (Draw)*. |

---

### Eksperimen 3: Perbandingan Urutan Aksi (*Move Ordering*)
*Menguji dampak urutan cabang terhadap jumlah pemangkasan Alpha-Beta (Depth = 4, HP_DIFF):*

| Strategi Ordering | Win Rate (%) | Avg Nodes Visited | Avg Branches Pruned | Analisis Efisiensi |
| :--- | :---: | :---: | :---: | :--- |
| **`DEFAULT` (Enum Order)** | 100% | **752** | **397** | **Paling Efisien**: Urutan enum natural (`ATTACK` lalu `HEAVY`) mengevaluasi aksi serang terlebih dahulu, memicu $\alpha$-cutoff lebih awal. |
| **`AGGRESSIVE`** | 100% | 894 | 312 | Cukup baik saat HP penuh, kurang efisien saat situasi menuntut pertahanan. |
| **`DEFENSIVE`** | 100% | 1,028 | 240 | Kurang optimal karena aksi pasif diperiksa lebih awal sebelum serangan lethal. |
| **`RANDOM`** | 100% | 1,280 | 185 | **Paling Lambat**: Urutan sub-optimal mendekati kompleksitas *worst-case*. |

---

### Eksperimen 4: Perbandingan Kedalaman (*Lookahead Depth* $d=1 \dots 6$)
*Menguji batas trade-off antara waktu komputasi dan kualitas keputusan agen:*

| Kedalaman ($d$) | Win Rate (%) | Avg Nodes / Battle | Waktu Eksekusi | Karakteristik Perilaku |
| :---: | :---: | :---: | :---: | :--- |
| **$d = 1$** | 70% | 31 | $< 0.1$ ms | *Myopic* (rabun dekat); hanya melihat 1 aksi ke depan tanpa antisipasi counter lawan. |
| **$d = 2$** | 80% | 141 | $< 0.5$ ms | Mampu melihat balasan langsung pemain, tetapi belum bisa merencanakan kombo. |
| **$d = 3$** | 100% | 324 | $\approx 1.2$ ms | **Sangat Seimbang**: Performa waktu nyata (*real-time*) mulus tanpa lag frame. |
| **$d = 4$** | 100% | 752 | $\approx 3.5$ ms | **Rekomendasi Default**: Taktik sangat matang, antisipasi 2 putaran penuh. |
| **$d = 5$** | 100% | 1,459 | $\approx 8.0$ ms | Sangat kuat; perhitungan pohon mencapai 5 lapisan giliran. |
| **$d = 6$** | 100% | 3,820 | $\approx 22.0$ ms | Optimal mutlak, namun beban komputasi melonjak secara eksponensial. |

---

### Eksperimen 5: Profil Perilaku NPC (*Behaviour Profile*)
*Distribusi persentase pemilihan aksi oleh NPC berdasarkan fungsi evaluasi heuristik:*

| Fungsi Evaluasi | % Attack | % Heavy Attack | % Defend | % Potion |
| :--- | :---: | :---: | :---: | :---: |
| **`HP_DIFF`** | 45% | 25% | 18% | 12% |
| **`AGGRESSIVE`** | 22% | **63%** | 5% | 10% |
| **`DEFENSIVE`** | 35% | 5% | **42%** | 18% |
| **`WEIGHTED`** | 40% | 28% | 20% | 12% |

> **Kesimpulan Profil:** Fungsi evaluasi secara dramatis mengubah kepribadian AI. `AGGRESSIVE` memprioritaskan *Heavy Attack* hingga 63% untuk menghabisi pemain secepat mungkin, sementara `DEFENSIVE` melipatgandakan penggunaan *Defend* hingga 42% untuk meminimalkan kerusakan.

---

## 🎮 9. Kontrol Permainan & Petunjuk Penggunaan

### Pintasan Tombol (*Keyboard Shortcuts*)
- **`[1]`**: Melancarkan **Attack** (20 DMG).
- **`[2]`**: Melancarkan **Heavy Attack** (37 DMG, -10 HP diri).
- **`[3]`**: Melancarkan **Defend** (Block 50% damage berikutnya).
- **`[4]`**: Meminum **Potion** (+30 HP).
- **`[D]`**: Membuka / Menutup panel **Debug Overlay & Minimax Monitor**.
- **`[P]`**: Membuka / Menutup panel **AI Experiment & Benchmark Lab**.
- **`[R]`**: Mereset duel / memulai ulang permainan saat game over.

---

## 🚀 10. Cara Menjalankan Proyek

### Opsi A: Melalui Godot Engine Desktop (Rekomendasi)
1. Buka **Godot Engine 4.3+**.
2. Klik tombol **Import** ➔ Pilih file [project.godot](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/project.godot) di dalam repositori ini.
3. Tekan **F5** (atau klik tombol Play di pojok kanan atas) untuk memulai permainan.

### Opsi B: Melalui Web Browser (One-Click HTML5)
1. Buka proyek di editor Godot Engine.
2. Pastikan renderer di pojok kanan atas diatur ke **Compatibility**.
3. Klik ikon **Web Browser / Globe (🌐)** di pojok kanan atas.
4. Game akan langsung berjalan di browser lokal (`http://localhost:8060/`).
