# 🎬 PANDUAN ALUR DEMO VIDEO & NASKAH NARASI: TAHAP 4
## INFERNAL AFFAIRS: LOGIC, AUTOMATED PLANNING, & DECISIONS UNDER UNCERTAINTY

> **Tugas Besar:** Kecerdasan Buatan (*Artificial Intelligence*) — Semester 3  
> **Kelompok 10:**  
> - Faridchi Trianda Safaraz (2506827)  
> - Haddi Fauzan Nurrosid (2507609)  
> - Farell Arrefa Zafhir (2508734)  
>  
> **Acuan Materi Kuliah:**  
> 1. **Modul 07:** `07_Logic & Representasi Pengetahuan.pdf` (*Knowledge-Based Logic, Horn Clauses, Forward Chaining, Partial Observability*)  
> 2. **Modul 08:** `08_Automated Planning.pdf` (*Classical Planning, STRIPS Action Operators, PDDL, Supply Chain Progression*)  
> 3. **Modul 09:** `09_Decision under uncertainity.pdf` (*Stochastic Transitions, Markov Decision Process (MDP), Bellman Value Iteration, MEU, Bayesian Belief Updating*)  
>  
> **Estimasi Total Durasi Video:** 7 – 10 Menit  
> **Target Audiens:** Dosen Penguji, Asisten Praktikum, dan Rekan Mahasiswa Informatika.

---

## 🎯 1. RINGKASAN TUJUAN VIDEO DEMO

Video presentasi dan demonstrasi ini dirancang untuk:
1. **Menunjukkan Transisi Paradigma AI:** Memperlihatkan bagaimana game berevolusi dari lingkungan deterministik (Tahap 1–3) menjadi dunia stokastik yang penuh risiko dan observasi parsial di Tahap 4.
2. **Membuktikan Penerapan 3 Modul Sekaligus:**
   - **Modul 07:** Memperlihatkan gerbang misterius yang terkunci rapat (*Unknown*), lalu mendemonstrasikan penyingkapan segel secara otomatis saat pemain naik Level 2 melalui penalaran logika *Forward Chaining* dan kebangkitan penjaga (*Guard Awakening*).
   - **Modul 08:** Memperlihatkan agen minion yang tidak lagi bergerak acak, melainkan menjalankan rantai aksi terencana *STRIPS Classical Planning* (`MOVE` $\to$ `HARVEST` $\to$ `DELIVER`) dari 3 Altar Sumber Daya.
   - **Modul 09:** Memperlihatkan pengambilan keputusan rasional di bawah ketidakpastian semburan lahar (*MDP & Bayesian Updating*). Saat jembatan retak dan berasap ($W=1$), minion secara cerdas membatalkan jalur pintas dan memutar lewat jembatan aman (*Policy Shift*).
3. **Mendemonstrasikan Fitur & Aset Baru:** Menunjukkan navigasi kamera *Dynamic Zoom*, efek tolak fisik (*recoil*) minion yang tersengat lahar (bukan teleportasi kaku), balon ekspresi AI (`?`, `!`, `X`), dan *MDP Debug HUD*.

---

## 🗺️ 2. ALUR URUTAN DEMO GAME (STORYBOARD OVERVIEW)

Berikut adalah urutan adegan yang runut, logis, dan saling mengalir:

```
┌────────────────────────────────────────────────────────────────────────┐
│ BAGIAN 1: PEMBUKAAN & OVERVIEW LINGKUNGAN PETA TAHAP 4 (00:00 - 01:30) │
│ - Perkenalan Kelompok & Topik 3 Modul (07, 08, 09)                     │
│ - Fitur Dynamic Camera Zoom (Mouse Wheel / + / -) menyorot peta 52x56  │
│ - Menjelaskan topografi: Benteng Utara, Sungai Lahar, & 3 Altar Selatan │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ BAGIAN 2: MODUL 08 - STRIPS AUTOMATED PLANNING (01:30 - 03:15)         │
│ - Menyorot Minion Kurir di 3 Altar: Ignis (Api), Sanguine, Abyssal     │
│ - Menjelaskan operator PDDL: HARVEST -> MOVE -> DELIVER                │
│ - Memperlihatkan minion memanen kristal & membawanya ke benteng        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ BAGIAN 3: MODUL 07 - LOGIC & GUARD AWAKENING (03:15 - 05:00)           │
│ - Mendekati Gerbang Benteng: Status Segel masih [?] UNKNOWN            │
│ - Menekan tombol 'L' / 'C' untuk Debug Level Up (Pemain naik Level 2)  │
│ - Animasi Banner Modal: "I HAVE AWAKENED!" & Forward Chaining aktif    │
│ - Status Segel Gerbang di HUD terungkap menjadi "Seal of Flame/Blood"  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ BAGIAN 4: MODUL 09 - MDP, BELLMAN, & BAYESIAN UPDATING (05:00 - 07:45) │
│ - Menekan tombol 'M' membuka MDP Debug HUD                             │
│ - Kasus 1 (Normal / W=0): P(Hazard)=0.10 -> Minion pilih Jalur Pintas   │
│ - Kasus 2 (Warning / W=1): Tekan [Force Warning] -> Asap & Pijar Magma │
│ - Pembuktian Bayes: P(H|W)=0.50 -> Q(Pintas)=-5.0 -> Policy Shift Raya │
│ - Balon reaksi minion: Muncul tanda seru '!' & belok ke jembatan aman │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ BAGIAN 5: HAZARD ERUPTION & RECOIL FISIK MINION (07:45 - 08:45)        │
│ - Memperlihatkan fase ERUPTION (Tiang api 6-frame vfx membakar jembatan)│
│ - Minion yang terjebak: Terpental 2 petak ke selatan, status PANIC     │
│ - Shard terlepas di jembatan (crystal_dropped) & balon emote skull 'X' │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ BAGIAN 6: KESIMPULAN & PENUTUP (08:45 - 09:30)                         │
│ - Rangkuman sinergi: Logic (07) + Planning (08) + Uncertainty (09)     │
│ - Ucapan terima kasih & penutup video                                  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 3. DETAIL SETIAP BAGIAN DEMO, MATERI MODUL, & PANDUAN PRESENTASI

---

### BAGIAN 1: Pembukaan & Overview Lingkungan Peta Tahap 4
* **Estimasi Waktu:** 00:00 – 01:30 (Durasi: ~90 detik)
* **Tujuan:** Orientasi video, perkenalan tim, dan mendemonstrasikan peta baru berukuran besar dengan fitur zoom kamera.

#### A. Panduan Visual (Apa yang Ditampilkan di Layar):
1. **00:00 - 00:25:** Tampilkan judul proyek di slide/layar awal: *"Infernal Affairs: Tahap 4 - Logic, Planning, & Decisions Under Uncertainty"*, nama lengkap & NIM anggota Kelompok 10.
2. **00:25 - 01:30:** Masuk ke game Godot overworld. 
   - Gunakan **Roda Mouse (Scroll Down)** untuk memperkecil zoom hingga `0.5x` sehingga seluruh peta berukuran $52 \times 56$ petak terlihat jelas.
   - Gerakkan kursor menyorot 3 area utama: Benteng Istana di utara, Sungai Lahar besar di tengah dengan 3 jembatan penghubung, dan Wilayah Liar (*Wilderness*) di selatan tempat 3 Altar berada.
   - Kembalikan zoom ke `1.0x` menggunakan tombol keyboard `0`.

#### B. Keterkaitan Materi Modul:
- **Pengantar Lingkungan AI (Transisi Tahap 1–3 ke Tahap 4):**
  Mengaitkan latar belakang bahwa sebelumnya dunia game bersifat deterministik murni, kini bertransformasi menjadi lingkungan yang dinamis, teramati sebagian (*partially observable*), dan stokastik.

#### C. Saran Naskah Narasi:
> *"Halo semuanya! Selamat datang di presentasi dan demonstrasi Tugas Besar Tahap 4 Mata Kuliah Kecerdasan Buatan.*  
>  
> *Kami dari Kelompok 10, yang beranggotakan Faridchi Trianda Safaraz, Haddi Fauzan Nurrosid, dan Farell Arrefa Zafhir. Pada Tahap 4 ini, game Infernal Affairs mengalami ekspansi besar dengan mengintegrasikan tiga modul utama perkuliahan sekaligus: yaitu **Modul 07: Logic & Representasi Pengetahuan**, **Modul 08: Automated Planning**, dan **Modul 09: Decisions Under Uncertainty**.*  
>  
> *Bisa kita lihat di layar, sekarang ukuran peta overworld diperluas menjadi 52 kali 56 petak. Kami juga telah menambahkan fitur **Dynamic Camera Zoom** menggunakan scroll roda mouse atau keyboard. Jika kita zoom out, terlihat jelas lanskap infernal terbagi menjadi dua wilayah yang dipisahkan oleh Sungai Lahar raksasa: di bagian utara terdapat Benteng Penjaga dan Gerbang Segel Kuno, sedangkan di bagian selatan adalah wilayah liar tempat tiga Altar Elemen berada, yang dihubungkan oleh tiga buah jembatan strategis."*

#### D. Saran Improvisasi:
- Presenter dapat memainkan zoom in dan zoom out secara santai sambil menunjukkan batuan tebing tepi jurang (*cliff edge*) untuk memberi kesan visual yang responsif.

---

### BAGIAN 2: Modul 08 — STRIPS Automated Planning (Supply Chain Minion)
* **Estimasi Waktu:** 01:30 – 03:15 (Durasi: ~105 detik)
* **Tujuan:** Menunjukkan rantai pasok otonom minion yang bekerja memanen dan menyuplai kristal menggunakan perencanaan aksi formal STRIPS/PDDL.

#### A. Panduan Visual (Apa yang Ditampilkan di Layar):
1. **01:30 - 02:15:** Gerakkan kamera player mendekati area selatan. Perlihatkan 3 Altar Sumber Daya:
   - *Ignis Altar* (Api - barat daya) dengan partikel kristal merah berputar.
   - *Sanguine Well* (Darah - tengah selatan) dengan pilar air merah.
   - *Abyssal Fissure* (Bayangan - tenggara) dengan aura retakan ungu.
2. **02:15 - 03:15:** Sorot salah satu minion kurir.
   - Tunjukkan minion mendekati altar, status berubah memanen kristal (`HARVEST`), kristal muncul digendong di punggung minion, lalu minion mulai berjalan ke arah utara menuju penjaga benteng (`MOVE` & `DELIVER`).
   - Tampilkan balon reaksi tanda tanya `?` di atas kepala minion yang menandakan agen sedang memproses rencana aksi.

#### B. Keterkaitan Materi Modul:
- **Modul 08 (Automated Planning / STRIPS):**
  - **Closed World Assumption:** Semua fakta di luar *state* dianggap belum terpenuhi (*false*).
  - **Operator Klasik STRIPS:** Aksi didefinisikan dengan $\text{Action}(\text{Nama}, \text{Preconditions}, \text{Effects})$:
    - `HARVEST`: Prekondisi $\text{At}(m, Altar) \wedge \text{Carrying}(m, \text{NIL})$, Efek $\text{Carrying}(m, Shard)$.
    - `MOVE`: Navigasi grid fisik mendelegasikan lintasan ke algoritma A* / UCS (Tahap 1).
    - `DELIVER`: Menyetor kristal ke penjaga, menaikkan tingkat pasif penjaga dari Tier 0 ke Tier 1 atau 2.

#### C. Saran Naskah Narasi:
> *"Sekarang kita masuk ke implementasi **Modul 08: Automated Planning**. Pada tahap sebelumnya, minion hanya berpatroli secara sederhana. Namun di Tahap 4, minion bertransformasi menjadi **Autonomous Planning Agents**.*  
>  
> *Perhatikan minion di bagian bawah ini. Minion ini bertugas menjaga rantai pasokan kristal (*Supply Chain*) untuk menyuplai energi kepada Penjaga Gerbang dan Bos Iblis. Berdasarkan formalisme **STRIPS dan PDDL**, rencana aksi minion dibentuk berdasarkan tujuan atau Goal-Directed Planning.*  
>  
> *Siklus kerjanya adalah: Pertama, aksi `MOVE` menuju Altar. Kedua, begitu tiba, aksi `HARVEST` dieksekusi—prekondisinya minion harus berada di altar dan tidak sedang membawa barang, efeknya kristal terambil dan dibawa di punggung minion. Ketiga, minion merencanakan aksi `MOVE` melintasi jembatan menuju benteng, dan terakhir mengeksekusi aksi `DELIVER` untuk menyetorkan kristal kepada Penjaga. Rantai suplai ini berjalan secara otonom dan kontinu."*

#### D. Saran Improvisasi:
- Presenter bisa menambahkan kalimat ringan seperti: *"Bisa kita ibaratkan minion ini adalah kurir logistik kerajaan neraka yang sangat disiplin mengikuti urutan instruksi STRIPS tanpa tersesat."*

---

### BAGIAN 3: Modul 07 — Logic & Knowledge-Based Guard Awakening
* **Estimasi Waktu:** 03:15 – 05:00 (Durasi: ~105 detik)
* **Tujuan:** Mendemonstrasikan lingkungan teramati sebagian (*partially observable*), basis pengetahuan (*Knowledge Base*), inferensi *Forward Chaining*, dan event kebangkitan penjaga.

#### A. Panduan Visual (Apa yang Ditampilkan di Layar):
1. **03:15 - 03:45:** Bawa karakter Player ke depan Gerbang Benteng.
   - Arahkan kursor mouse ke status gerbang di HUD/Overworld yang bertuliskan: **`Gate Seal: [?] UNKNOWN (Tersembunyi)`**.
   - Tunjukkan penjaga benteng (*Infernal Knight*) yang masih dalam posisi tertidur/pasif dengan aura redup.
2. **03:45 - 04:30:** Lakukan trigger kebangkitan:
   - Tekan tombol keyboard `L` (atau `C`) untuk menaikkan level pemain dari Level 1 ke **Level 2** secara instan.
   - Layar menampilkan modal banner dramatis: **`AwakeningBannerModal`** dengan teks monolog: *"I HAVE AWAKENED! The ancient [SEAL] burns with infernal wrath..."*.
3. **04:30 - 05:00:** Perhatikan perubahan di HUD:
   - Status gerbang berubah secara dinamis dari `[?] UNKNOWN` menjadi **`SEAL OF FLAME (REVEALED)`** (atau elemen aktif hasil CSP).
   - Penjaga benteng berdiri tegak, memancarkan efek partikel menyala, dan statusnya menjadi **AGGRESSIVE**.

#### B. Keterkaitan Materi Modul:
- **Modul 07 (Logic & Representasi Pengetahuan):**
  - **Partially Observable Environment:** Fakta dunia tidak langsung diketahui agen secara instan; status segel awalnya berproposisi $\text{GateSeal\_Unknown}$.
  - **Knowledge Base (KB) & Horn Clauses:**
    $$\text{Rule 1: } \text{PlayerLevel\_2} \implies \text{GuardAwakened}$$
    $$\text{Rule 2: } \text{GuardAwakened} \implies \text{SealRevealed}$$
  - **Forward Chaining (Data-Driven Inference):** Ketika fakta baru $\text{Tell}(\text{PlayerLevel\_2})$ dimasukkan ke KB, mesin inferensi di `LogicEngine.gd` mencocokkan premis dan secara otomatis menarik kesimpulan logis hingga terbukti $\text{SealRevealed}$.

#### C. Saran Naskah Narasi:
> *"Berikutnya, kita masuk ke **Modul 07: Logic dan Representasi Pengetahuan**. Di sini kami menerapkan konsep **Observasi Parsial**.*  
>  
> *Bisa dilihat di gerbang benteng ini, segel gerbang awalnya bertuliskan `[?] UNKNOWN`. Artinya, player tidak tahu segel sihir apa yang sedang mengunci pintu ini, dan Penjaga gerbang pun masih dalam keadaan tertidur.*  
>  
> *Sistem logika kami bangun menggunakan **Knowledge Base dengan aturan Klausa Horn** di dalam skrip `LogicEngine.gd`. Sekarang, mari kita lihat apa yang terjadi jika Player naik ke Level 2. Saya akan menekan tombol shortcut `L`.*  
>  
> *[Tekan L - Banner Muncul] Boom! Penjaga langsung terbangun dengan dialog dramatis: 'I HAVE AWAKENED!'.*  
>  
> *Secara komputasi di balik layar, mesin **Forward Chaining** menerima fakta baru bahwa Player mencapai Level 2. Aturan satu terpicu: Player Level 2 menyebabkan Penjaga Bangkit (`GuardAwakened`). Kemudian secara berantai (*chaining*), aturan kedua terpicu: Penjaga bangkit membuktikan bahwa Segel Terungkap (`SealRevealed`). Kini status di HUD langsung berganti secara logis menampilkan elemen asli segelnya, yaitu Seal of Flame!"*

#### D. Saran Improvisasi:
- Presenter bisa menambahkan penjelasan alternatif: *"Selain lewat level up, deduksi logika juga bisa terjadi jika pemain menyabotase minion kurir di jalan. Esensi serpihan elemen yang tercecer akan dimasukkan sebagai fakta ke KB untuk menebak segel gerbang."*

---

### BAGIAN 4: Modul 09 — Decisions Under Uncertainty, MDP, & Bayesian Updating
* **Estimasi Waktu:** 05:00 – 07:45 (Durasi: ~165 detik)
* **Tujuan:** Menjelaskan dan mendemonstrasikan inti dari MDP, Persamaan Bellman, Value Iteration, dan perubahan kebijakan (*Policy Shift*) otomatis saat sensor bahaya aktif via aturan Bayes.

#### A. Panduan Visual (Apa yang Ditampilkan di Layar):
1. **05:00 - 05:40:** Buka **MDP Debug HUD** dengan menekan tombol **`M`** (atau klik tombol `[HUD [M]]` di pojok kiri bawah).
   - Tunjukkan card HUD yang kini tampil rapi dan ringkas di layar atas tanpa memotong teks.
   - Sorot baris status: **`Belief: P(Hazard) = 0.10 [Kondisi Normal / Aman]`** dan **`★ POLICY π*(Simpang) = PINTAS (Shortcut)`**.
   - Sorot tabel komputasi **Value Iteration ($k=3$)** yang menampilkan nilai $Q(\text{Pintas}) = 7.00$, $Q(\text{Raya}) = 6.00$, dan $V(\text{Simpang}) = 7.00$.
2. **05:40 - 06:20:** Tunjukkan minion kurir yang melintas.
   - Karena kondisi aman, minion secara konsisten memilih menyeberang lewat **Jembatan Tengah (Jalur Pintas)** karena utilitas ekspektasinya lebih tinggi (+7.00 vs +6.00).
3. **06:20 - 07:45:** Uji Skenario Bahaya (*Policy Shift Demo*):
   - Klik tombol **`[⚠ Force Warning (W=1)]`** di panel kontrol pojok kiri bawah (atau tunggu hingga jembatan tengah masuk fase *WARNING* secara otomatis).
   - Tunjukkan perubahan visual pada jembatan tengah: lantai batu retak dan memancarkan cahaya jingga berdenyut (*4-frame warning crack sheet*) serta suara peringatan `sfx_barrier_activate`.
   - Sorot HUD: Nilai Belief seketika diperbarui menjadi **`P(Hazard | W) = 0.50`**, dan Policy berganti menjadi **`★ POLICY π*(Simpang) = RAYA (Jalur Utama)`**.
   - Sorot tabel: Nilai $Q(\text{Pintas})$ anjlok dari $+7.00$ menjadi **$-5.00$**, sedangkan $Q(\text{Raya})$ tetap **$+6.00$**.
   - Tunjukkan minion yang sedang mendekat: Di atas kepalanya muncul balon reaksi **tanda seru `!` berwarna oranye**, lalu minion langsung membatalkan niat ke jembatan tengah dan berbelok ke kanan menuju jembatan benteng yang aman!

#### B. Keterkaitan Materi Modul:
- **Modul 09 (Decisions Under Uncertainty & MDP):**
  - **Tuple MDP $\langle S, A, P, R, \gamma \rangle$:**
    - State $s_1$ (Simpang), $s_2$ (Pintas), $s_3$ (Raya), $s_4$ (Goal $+10$), $s_5$ (Trap $-20$).
    - Living reward / step cost: $R(s') = -2.0$ (Slide 23) agar agen tidak looping.
    - Faktor diskon: $\gamma = 0.8$ (Slide 9 & 13).
  - **Prinsip Maximum Expected Utility (MEU):** $\pi^*(s) = \arg\max_a Q(s, a)$.
  - **Persamaan Bellman & Value Iteration:** Perhitungan berulang hingga tercapai konvergensi $\Delta V < 10^{-4}$.
  - **Aturan Bayes (Bayesian Updating - Slide 7–8):**
    $$P(W=1) = (0.90 \times 0.10) + (0.10 \times 0.90) = 0.18$$
    $$P(\text{Hazard} \mid W=1) = \frac{0.09}{0.18} = 0.50 \quad (50\%)$$
    Ketika risiko $f$ naik dari $0.10$ ke $0.50$, nilai ekspektasi $Q(s_1, \text{Pintas}) = 0.5(10) + 0.5(-20) = -5.00$, memicu perubahan kebijakan (*Policy Shifting*).

#### C. Saran Naskah Narasi:
> *"Sekarang kita sampai pada puncak implementasi Tahap 4, yaitu **Modul 09: Decisions Under Uncertainty dan Markov Decision Process (MDP)**.*  
>  
> *Saya buka antarmuka diagnostik **MDP Debug HUD** dengan menekan tombol `M`. Di sini kita bisa memantau cara berpikir agen secara matematis real-time.*  
>  
> *Perhatikan tabel Value Iteration ini: Pada kondisi normal tanpa sinyal bahaya, prior risiko bahaya sangat kecil, yaitu hanya 10 persen atau 0.10. Mengacu pada persamaan Bellman dengan reward sukses plus 10 dan diskon gamma 0.8, aksi `PINTAS` memiliki nilai Q sebesar **plus 7.00**, sedangkan aksi `RAYA` bernilai **plus 6.00**.*  
>  
> *Sesuai prinsip **Maximum Expected Utility (MEU)**, agen rasional pasti memilih utilitas tertinggi. Makanya, minion di layar ini memilih jalur jembatan tengah karena lebih cepat.*  
>  
> *Tapi, apa yang terjadi jika jembatan mulai retak dan mengeluarkan asap magma? Mari kita uji dengan menekan tombol **`Force Warning (W=1)`** di pojok kiri bawah.*  
>  
> *[Klik Force Warning - Efek Retakan Menyala]*  
>  
> *Perhatikan! Lantai jembatan sekarang berpijar oranye. Sensor minion menangkap bukti observasi W sama dengan 1. Melalui **Aturan Bayes (*Bayesian Updating*)**, keyakinan minion diperbarui: probabilitas bahaya melonjak drastis dari 0.10 menjadi **0.50 atau 50 persen**!*  
>  
> *Dampaknya ke persamaan Bellman luar biasa: nilai Q jalan pintas langsung anjlok dari plus 7 menjadi **minus 5.00**! Karena minus 5 jauh lebih buruk daripada jalan raya yang bernilai plus 6.00, secara otomatis terjadi **Policy Shifting**: kebijakan optimal berubah menjadi `RAYA`.*  
>  
> *Lihat minion kurir itu! Di atas kepalanya langsung muncul balon tanda seru `!` oranye, dan seketika itu juga dia berbelok ke kanan mengambil jalan memutar yang aman. Agen kita berhasil mengambil keputusan cerdas di bawah ketidakpastian!"*

#### D. Saran Improvisasi:
- Presenter dapat mendemonstrasikan tombol **`[Step Iter (k+1)]`** untuk memperlihatkan bagaimana angka-angka pada tabel $k=1, k=2, k=3$ berubah selangkah demi selangkah menuju titik konvergen, membuktikan bahwa kode Godot menjalankan algoritma iterasi yang sesungguhnya, bukan sekadar hardcode nilai statis.

---

### BAGIAN 5: Hazard Eruption & Efek Recoil Fisik Minion
* **Estimasi Waktu:** 07:45 – 08:45 (Durasi: ~60 detik)
* **Tujuan:** Menunjukkan apa yang terjadi jika minion terlambat menghindar atau nekat melintas saat fase letusan lahar berlangsung, membuktikan perbaikan bug fisik (*smooth knockback*, kristal terjatuh, dan status panik).

#### A. Panduan Visual (Apa yang Ditampilkan di Layar):
1. **07:45 - 08:15:** Tunggu atau posisikan minion melintas di jembatan tengah saat fase berganti ke **ERUPTION**.
   - Tunjukkan animasi tiang api dan semburan magma 6-frame (*vfx_flame_column_sheet.png*) yang membakar jembatan setinggi 64 piksel.
2. **08:15 - 08:45:** Sorot interaksi tabrakan lahar pada minion:
   - Minion terkena semburan api.
   - Kristal yang digendong minion seketika terlepas dan jatuh di atas lantai jembatan sebagai item `crystal_dropped.png` dengan partikel kilauan `item_sparkle.png`.
   - Minion tidak berteleportasi secara kaku, melainkan **terpental (*smooth knockback recoil*) sejauh 2 petak ke arah selatan**.
   - Di atas kepala minion muncul balon ekspresi **tengkorak `X` (*Skull Panic*)**, lalu minion berlari mundur dalam kondisi panik selama 2 detik sebelum merencanakan rute pemulihan baru.

#### B. Keterkaitan Materi Modul:
- **Terminal State Kegagalan (Failure State $s_5$):**
  Mengkonfirmasi transisi ke $s_5$ dengan penalti $R(s_5) = -20.0$. Kehilangan kristal merefleksikan kerugian utilitas, memvalidasi mengapa fungsi MEU memberi penalti berat pada aksi jalan pintas saat bahaya aktif.

#### C. Saran Naskah Narasi:
> *"Lalu, bagaimana jika ada minion yang terlambat menghindar dan nekat menyeberang saat lahar meletus? Mari kita saksikan fase **ERUPTION**.*  
>  
> *[Lahar Meletus - Tiang Api Muncul]*  
>  
> *Bisa kita lihat tiang api menyembur membakar jembatan pintas. Saat minion terkena lahar, sistem mendeteksi tabrakan hazard:*  
> *1. Kristal elemen yang dibawanya langsung terlepas dan jatuh ke lantai jembatan.*  
> *2. Minion tidak berteleportasi kaku, melainkan mengalami efek **knockback recoil** terpental dua petak ke selatan.*  
> *3. Di atas kepalanya muncul balon ekspresi tengkorak `X`, menandakan minion masuk ke mode Panic Retreat sebelum menyusun rencana baru.*  
>  
> *Kejadian ini membuktikan bahwa risiko penalti minus 20 pada formulasi MDP kita benar-benar memiliki konsekuensi nyata dalam permainan!"*

#### D. Saran Improvisasi:
- Presenter bisa menambahkan: *"Kristal yang terjatuh di jembatan ini juga bisa diambil atau disabotase oleh Player, menambah kedalaman interaksi antara pemain dan ekosistem AI."*

---

### BAGIAN 6: Kesimpulan & Penutup
* **Estimasi Waktu:** 08:45 – 09:30 (Durasi: ~45 detik)
* **Tujuan:** Merangkum seluruh keberhasilan implementasi Tahap 4 dan menutup presentasi secara profesional.

#### A. Panduan Visual (Apa yang Ditampilkan di Layar):
- Arahkan kamera player berdiri di tengah jembatan atau di depan benteng dengan zoom sinematik.
- Tampilkan slide penutup bertuliskan ucapan terima kasih dan nama tim.

#### B. Saran Naskah Narasi:
> *"Sebagai kesimpulan, pada Tugas Besar Tahap 4 ini, kami telah berhasil memadukan tiga cabang utama kecerdasan buatan ke dalam game Infernal Affairs:*  
> *1. **Modul 07:** Penalaran logika Forward Chaining untuk mengungkap rahasia dunia dan membangkitkan penjaga gerbang.*  
> *2. **Modul 08:** Perencanaan otonom berbasis STRIPS/PDDL yang menggerakkan rantai pasok minion secara mandiri.*  
> *3. **Modul 09:** Pengambilan keputusan berbasis MDP, Bellman Value Iteration, dan Bayesian Updating yang memungkinkan agen bertindak adaptif di bawah risiko dan ketidakpastian.*  
>  
> *Semua algoritma ini terbukti bekerja harmonis menghasilkan perilaku dunia game yang cerdas, hidup, dan dinamis.*  
>  
> *Sekian presentasi dan demonstrasi Tahap 4 dari Kelompok 10. Terima kasih banyak atas perhatian Bapak/Ibu dosen dan rekan-rekan sekalian. Sampai jumpa di pengembangan berikutnya!"*

---

## 💡 4. MATRIKS CHECKLIST REFERENSI MATERI KULIAH (07, 08, 09)

Gunakan tabel ini untuk memastikan tidak ada poin penting yang terlewat saat proses perekaman video berlangsung:

| Modul Perkuliahan | Topik & Konsep Teoretis | Bukti Nyata yang Ditampilkan di Video | Lokasi Skrip / Fitur |
| :--- | :--- | :--- | :--- |
| **Modul 07: Logic** | *Partially Observable* | Status Gerbang `[?] UNKNOWN` saat awal permainan | `LogicEngine.gd`, HUD |
| **Modul 07: Logic** | *Horn Clauses & KB* | Aturan `PlayerLevel_2 -> GuardAwakened -> SealRevealed` | `LogicEngine.gd` |
| **Modul 07: Logic** | *Forward Chaining* | Tekan `L` (Level Up) $\to$ Banner Awakening muncul & segel terungkap otomatis | `AwakeningBannerModal.gd` |
| **Modul 08: Planning** | *Classical Planning* | Minion menyusun rencana aksi goal-directed mandiri | `PlanSolver.gd` |
| **Modul 08: Planning** | *STRIPS Operators* | Siklus aksi `HARVEST` di 3 Altar $\to$ `MOVE` $\to$ `DELIVER` ke Guard/Boss | `PlanSolver.gd`, `Minion.gd` |
| **Modul 08: Planning** | *Closed World Assump.* | Status ketersediaan kristal dievaluasi berdasarkan fakta aktif di arena | `ResourceNode.gd` |
| **Modul 09: Uncertainty**| *MDP Tuple $\langle S, A, P, R, \gamma \rangle$* | State simpang, pintas, raya, reward $+10$, $-20$, living cost $-2$, $\gamma=0.8$ | `MDPSolver.gd`, HUD |
| **Modul 09: Uncertainty**| *Value Iteration* | Tabel nilai $Q(s, a)$ dan $V(s)$ ditampilkan live via tombol shortcut `M` | `MDPDebugHUD.gd` |
| **Modul 09: Uncertainty**| *Bayesian Updating* | Sinyal asap $W=1 \to P(\text{Hazard}\mid W)=0.50$ (naik dari $0.10$) | `MDPSolver.gd` |
| **Modul 09: Uncertainty**| *Policy Shifting & MEU* | Minion membatalkan jalan pintas, muncul emote `!`, dan belok ke rute aman | `Minion.gd`, `StochasticHazardManager.gd` |
| **Fitur Ergonomi Game**| *Dynamic Zoom & VFX* | Navigasi mouse wheel zoom $0.5\times - 2.0\times$, recoil terpental, emote `? ! X` | `Main.gd`, `Minion.gd` |

---

## 🎙️ 5. TIPS & SARAN IMPROVISASI UNTUK PRESENTER

1. **Gaya Bahasa Santai tapi Presisi Akademik:**
   - Jangan menghafal naskah kata per kata. Gunakan naskah di atas sebagai kerangka alur pikiran.
   - Tetap gunakan istilah teknis penting seperti *“Forward Chaining”*, *“STRIPS Operator”*, *“Maximum Expected Utility”*, *“Bayesian Updating”*, dan *“Policy Shift”* agar bobot akademiknya tetap kuat.
2. **Kombinasi Dual Peran (Jika Direkam Bersama Kelompok):**
   - **Presenter 1:** Memandu pengantar, menjelaskan latar belakang, dan membawakan bagian Modul 07 & 08.
   - **Presenter 2:** Memegang kendali keyboard/mouse, mendemokan tombol interaktif, dan membedah matematika Modul 09 di HUD.
3. **Penyelamatan Jika Terjadi Hal Tak Terduga Saat Rekaman:**
   - Jika minion sedang tidak melintas tepat saat menekan `Force Warning`: katakan santai, *“Sambil menunggu minion berikutnya datang dari arah Altar selatan, kita bisa perhatikan dulu perubahan angka pada tabel HUD ini...”*.
   - Jika lahar meletus lebih cepat: gunakan kesempatan tersebut untuk langsung menyorot efek animasi *flame column* dan batuan tebing.
4. **Kualitas Audio & Visual:**
   - Pastikan volume efek suara game (*SFX*) tidak menutupi suara mikrofon presenter.
   - Gunakan fitur zoom kamera di bagian awal untuk memberikan kesan profesional bahwa game dibangun dengan skala peta yang luas dan detail visual yang rapi.
