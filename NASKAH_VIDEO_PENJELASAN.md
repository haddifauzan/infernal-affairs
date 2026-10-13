# 🎬 NASKAH VIDEO PRESENTASI & DEMONSTRASI TUBES TAHAP 2
## INFERNAL AFFAIRS: Adversarial Search (Turn-Based Combat)

* **Mata Kuliah:** Kecerdasan Buatan (Artificial Intelligence)
* **Topik:** Adversarial Search (Minimax, Alpha-Beta Pruning, Evaluation Functions, Move Ordering, Expectimax)
* **Estimasi Durasi Video:** 7 – 10 Menit
* **Format:** Pembagian dua kolom/seksi praktis antara **[Panduan Visual / Apa yang Ditampilkan di Layar]** dan **[Naskah Suara / Voice Over]**, lengkap dengan tips intonasi dan transisi.

---

## 📌 Ringkasan Alur Video (Storyboard Overview)
1. **Scene 1 (00:00 - 01:15):** Pembukaan, Identitas Tim, & Transisi Paradigma (Single-Agent ke Adversarial).
2. **Scene 2 (01:15 - 02:45):** Formulasi Formal Masalah Game (*Game as a Search Problem*).
3. **Scene 3 (02:45 - 04:30):** Algoritma Adversarial & Demonstrasi Live Debug Overlay (`[D]`).
4. **Scene 4 (04:30 - 08:30):** Pembuktian Saintifik di Laboratorium Eksperimen (`[P]` — 220 Pertarungan).
   - *Exp 1:* Minimax vs Alpha-Beta Pruning.
   - *Exp 2:* Perbandingan 5 Fungsi Evaluasi Heuristik.
   - *Exp 3:* Pengaruh Move Ordering terhadap Efisiensi Pruning.
   - *Exp 4:* Trade-off Kedalaman (*Depth* $d=1 \dots 6$).
   - *Exp 5:* Profil Karakteristik Perilaku AI.
   - *Exp 6:* Pengambilan Keputusan Probabilistik (Expectimax).
5. **Scene 5 (08:30 - 09:30):** Kesimpulan Akademik & Penutup.

---

## 🎞️ DETAIL SCENE-BY-SCENE

---

### SCENE 1: Pembukaan & Transisi Paradigma
* **Estimasi Waktu:** 00:00 – 01:15 (Durasi: ~75 detik)
* **Fokus Materi:** Orientasi proyek, pergeseran dari Single-Agent ke Multi-Agent Adversarial.

| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **00:00 - 00:20**<br>• Tampilkan Title Card / Slide Judul Proyek: *"Infernal Affairs: Adversarial Search Turn-Based Combat"*.<br>• Tampilkan Nama & NIM anggota kelompok.<br>• Rekaman layar game Godot saat karakter Player bergerak di dungeon lava. | *"Halo semuanya! Selamat datang di presentasi dan demonstrasi Tugas Besar Tahap 2 Mata Kuliah Kecerdasan Buatan.*<br><br>*Perkenalkan, kami dari Kelompok 10, yang beranggotakan Faridchi Trianda Safaraz, Haddi Fauzan Nurrosid, dan Farell Arrefa Zafhir.*<br><br>*Pada tahap kedua ini, kami memperluas dunia game Infernal Affairs dari yang sebelumnya berfokus pada pencarian rute rintangan jalan tunggal, kini bertransformasi menjadi game pertarungan taktis berbasis giliran atau Turn-Based Combat."* |
| **00:20 - 01:15**<br>• Gerakkan karakter Player mendekati musuh Demon Brute.<br>• Tunjukkan saat Player berada dalam jarak deteksi, layar bertransisi mulus masuk ke arena duel 1 lawan 1 (*Battle Mode*).<br>• Tampilkan UI duel: Bar HP Player, Bar HP Demon, slot Ramuan, dan 4 tombol aksi. | *"Jika pada Tahap 1 kita menggunakan asumsi Single-Agent dengan algoritma A-Star dan UCS di mana lingkungan bersifat pasif dan solusi berupa urutan jalur statis, maka pada Tahap 2 ini kita merelaksasi asumsi tersebut menjadi Multi-Agent Adversarial Search.*<br><br>*Di sini, musuh kita—yaitu Demon Brute—bukan sekadar NPC pasif, melainkan agen cerdas yang memiliki tujuan berlawanan: yaitu mengalahkan kita! Setiap kali Player berpapasan dengan Demon, game langsung bertransisi ke mode duel 1v1.*<br><br>*Kini, solusi bukan lagi urutan jalan, melainkan sebuah **strategi**—sebuah rencana aksi cerdas yang mengantisipasi setiap kemungkinan langkah yang diambil oleh lawan."* |

> 💡 **Tips Presenter:** Tekankan kata *"Strategi"* dan *"Mengantisipasi langkah lawan"*. Tunjukkan momen transisi kamera dari eksplorasi map ke arena duel dengan mulus.

---

### SCENE 2: Formulasi Formal Masalah Game (*Game as a Search Problem*)
* **Estimasi Waktu:** 01:15 – 02:45 (Durasi: ~90 detik)
* **Fokus Materi:** State, Actions ($b \le 4$), Transition Model, Terminal Test, Utility, & Heuristic Cutoff.

| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **01:15 - 01:50**<br>• Tampilkan diagram/slide formulasi game singkat di samping layar game.<br>• Sorot kursor ke Bar HP, ikon Potion, dan status giliran di HUD duel. | *"Sebelum masuk ke algoritma, kita formulasikan duel ini secara formal sebagai search problem.*<br><br>*Pertama, **State ($S$)** merepresentasikan kondisi permainan saat ini, yang terdiri dari: HP Player, HP Demon, sisa ramuan Potion, status bertahan atau Defend, dan giliran siapa saat ini.*<br><br>*Kedua, **Actions ($A$)**: Pada setiap giliran, agen memiliki ruang percabangan atau branching factor paling banyak 4 aksi:*<br>1. *`ATTACK`: Serangan normal sebesar 20 damage.*<br>2. *`HEAVY_ATTACK`: Serangan kritikal 37 damage dengan recoil 10 damage ke diri sendiri. Jika musuh sedang bertahan, serangan ini memiliki sifat partial pierce atau hanya tereduksi 30 persen.*<br>3. *`DEFEND`: Kuda-kuda bertahan yang memotong 50 persen damage serangan biasa berikutnya.*<br>4. *`POTION`: Ramuan pemulih 30 HP, yang hanya valid digunakan jika HP kurang dari 100 dan stok ramuan masih ada."* |
| **01:50 - 02:45**<br>• Tampilkan teks formula Utility dan Terminal Test di layar.<br>• Tunjukkan ilustrasi pohon pencarian dengan kedalaman terbatas (*Cutoff Depth*). | *"Ketiga, **Terminal Test & Utility**: Pertarungan berakhir jika HP Player mencapai 0 di mana Demon menang dengan nilai utilitas plus 10.000, atau sebaliknya jika HP Demon 0 maka nilainya minus 10.000. Jika putaran mencapai 40 turn, duel dinyatakan Draw atau seri dengan nilai 0.*<br><br>*Namun, karena total kemungkinan cabang pohon permainan sangat besar hingga mencapai ribuan status, kita tidak bisa mencari hingga daun terminal paling akhir.*<br><br>*Oleh karena itu, kami menerapkan **Heuristic Search with Early Stop**: pencarian kita batasi pada kedalaman tertentu, lalu status daunnya kita taksir menggunakan fungsi evaluasi heuristik, seperti selisih keunggulan HP, persediaan potion, dan pertahanan."* |

> 💡 **Tips Presenter:** Bicara dengan tempo teratur. Saat menyebutkan nilai damage aksi (20 DMG, 37 DMG, block 50%), sorot kursor mouse ke tombol skill di HUD.

---

### SCENE 3: Algoritma Adversarial & Demonstrasi Live Debug Overlay
* **Estimasi Waktu:** 02:45 – 04:30 (Durasi: ~105 detik)
* **Fokus Materi:** Minimax vs Alpha-Beta Pruning, Real-Time Debug Sidebar (`[D]`).

| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **02:45 - 03:30**<br>• Tampilkan diagram visual Minimax Tree (Node MAX Demon & Node MIN Player) dengan pemangkasan Alpha-Beta ($\alpha \ge \beta$).<br>• Kamera kembali ke gameplay duel Godot. | *"Otak dari agen Demon Brute digerakkan oleh algoritma **Minimax**.*<br><br>*Demon bertindak sebagai pemain **MAX** yang ingin memaksimalkan utilitas, sedangkan Player dianggap sebagai pemain **MIN** yang berusaha meminimalkan utilitas Demon dengan asumsi bermain optimal.*<br><br>*Agar pohon pencarian tidak terlalu lebar dan boros komputasi, kami menyematkan **Alpha-Beta Pruning**. Dengan melacak parameter Alpha—yaitu nilai terbaik yang dijamin untuk MAX, dan Beta—nilai terbaik untuk MIN, sistem akan langsung memangkas cabang anak begitu Alpha lebih besar atau sama dengan Beta. Cabang tersebut diabaikan karena terbukti secara matematis tidak akan pernah mempengaruhi keputusan akhir di akar."* |
| **03:30 - 04:30**<br>• Di dalam game, tekan tombol keyboard **`[D]`** untuk memunculkan **Modular Debug Sidebar** di sisi kanan.<br>• Sorot kursor ke panel: Kandidat Aksi & Skor Utilitas.<br>• Sorot metrik: *Nodes Visited*, *Branches Pruned*, dan *Prune Ratio*.<br>• Lakukan 1 kali aksi pemain (misal tekan `[1]` Attack), lalu tunjukkan AI merespons seketika dan log metriknya terupdate live. | *"Nah, untuk membuktikan transparansi cara berpikir agen AI secara real-time, kami membuat fitur **Debug Overlay** yang bisa dibuka kapan saja dengan menekan tombol `[D]`.*<br><br>*Mari kita perhatikan panel kanan ini:*<br>1. *Pada bagian **Candidate Action Utilities**, kita bisa melihat semua aksi yang sedang dipertimbangkan Demon beserta skor evaluasinya. Aksi dengan nilai tertinggi otomatis ditandai dengan badge `[BEST]`.*<br>2. *Pada bagian **Tree Search Performance**, kita dapat memantau berapa jumlah node yang dikunjungi, berapa cabang yang berhasil dipangkas oleh Alpha-Beta, serta persentase Prune Ratio-nya.*<br><br>*Hebatnya lagi, di sidebar ini kita bisa mengganti algoritma, kedalaman, hingga fungsi evaluasi secara live saat duel sedang berlangsung tanpa perlu merestart game!"* |

> 💡 **Tips Presenter:** Tunjukkan reaksi langsung AI saat tombol `[1]` ditekan. Perlihatkan teks log giliran dan bagaimana angka di Debug Sidebar langsung terhitung ulang dalam hitungan milidetik.

---

### SCENE 4: Laboratorium Eksperimen Saintifik (`[P]` — 220 Pertarungan)
* **Estimasi Waktu:** 04:30 – 08:30 (Durasi: ~240 detik / 4 menit)
* **Fokus Materi:** Pembahasan 6 Eksperimen Sesuai Ketentuan Tugas.

| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **04:30 - 05:00**<br>• Tekan tombol keyboard **`[P]`** di layar duel untuk memunculkan **Automated Benchmark Lab**.<br>• Tunjukkan jendela benchmark dan tombol eksekusi.<br>• Tampilkan log hasil benchmark yang rapi di layar. | *"Sekarang kita masuk ke bagian inti penelitian, yaitu **Laboratorium Eksperimen**.*<br><br>*Dengan menekan tombol `[P]`, game akan menjalankan modul **Headless Automated Battle Engine**. Sistem ini mengeksekusi total **220 pertarungan simulasi** tanpa campur tangan manusia.*<br><br>*Agar pengujian bersifat adil dan terkontrol secara saintifik (*controlled environment*), sisi Player digerakkan oleh bot baseline bertipe `GREEDY` yang selalu menyerang dan hanya minum potion saat kritis. Dengan begitu, setiap perbedaan hasil murni mencerminkan kualitas kecerdasan AI Demon."* |

#### Sub-Scene 4.1: Eksperimen 1 — Minimax vs Alpha-Beta Pruning
| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **05:00 - 05:40**<br>• Sorot tabel **Exp 1: Algorithm Comparison** di log benchmark.<br>• Tampilkan tabel perbandingan: Minimax (1.811 nodes) vs Alpha-Beta (752 nodes, 397 pruned). | *"Eksperimen pertama menguji efisiensi komputasi antara Standard Minimax melawan Alpha-Beta Pruning pada kedalaman 4.*<br><br>*Hasilnya sangat impresif:*<br>• *Minimax murni harus mengunjungi rata-rata **1.811 node** per pertarungan tanpa memangkas satu cabang pun.*<br>• *Sementara Alpha-Beta Pruning hanya membutuhkan **752 node**, karena berhasil memangkas rata-rata **397 cabang**.*<br><br>*Ini menghasilkan **58,5% penghematan komputasi**! Dan yang terpenting: kedua algoritma menghasilkan keputusan langkah dan win rate 100% yang identik secara optimal. Ini membuktikan bahwa Alpha-Beta memangkas cabang tanpa sedikit pun mengorbankan kualitas solusi."* |

#### Sub-Scene 4.2: Eksperimen 2 — Perbandingan Fungsi Evaluasi
| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **05:40 - 06:25**<br>• Sorot tabel **Exp 2: Eval Function Comparison**.<br>• Tampilkan 5 variasi fungsi evaluasi: HP_DIFF, AGGRESSIVE, DEFENSIVE, WEIGHTED, HP_RATIO. | *"Eksperimen kedua membandingkan lima jenis fungsi evaluasi heuristik:*<br>1. *`HP_DIFF` dan `WEIGHTED` mencatatkan performa terbaik dengan **Win Rate 100%**. Keduanya sangat adaptif, tahu kapan harus menekan lawan dan kapan harus menyembuhkan diri.*<br>2. *`HP_RATIO` meraih 90% Win Rate dan 10% seri.*<br>3. *Fungsi `AGGRESSIVE` hanya meraih 80% Win Rate. Karena ia hanya bernafsu mengurangi HP Player tanpa mempedulikan keselamatannya sendiri, AI sering melancarkan Heavy Attack dan justru mati terkena recoil-nya sendiri saat darahnya sekarat.*<br>4. *Sedangkan fungsi `DEFENSIVE` mencatat Win Rate terendah yaitu 60%, dan 30% berakhir seri karena AI terlalu sering bertahan hingga mencapai batas maksimal putaran."* |

#### Sub-Scene 4.3: Eksperimen 3 — Pengaruh Urutan Aksi (*Move Ordering*)
| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **06:25 - 07:05**<br>• Sorot tabel **Exp 3: Action Order Comparison**.<br>• Tampilkan urutan: DEFAULT (752 nodes) vs AGGRESSIVE (894 nodes) vs DEFENSIVE (1.028 nodes) vs RANDOM (1.280 nodes). | *"Eksperimen ketiga menguji prinsip penting dalam materi kuliah: **Urutan Evaluasi Anak itu Krusial**.*<br><br>*Pada Alpha-Beta, jika langkah terbaik diperiksa lebih awal, nilai batas Alpha akan langsung melompat naik dan memicu pemangkasan massal pada cabang-cabang berikutnya.*<br><br>*Data membuktikan:*<br>• *Urutan `DEFAULT` yang mendahulukan aksi serang hanya mengeksplorasi **752 node**.*<br>• *Urutan `DEFENSIVE` membengkak hingga **1.028 node**.*<br>• *Dan urutan `RANDOM` melonjak hingga **1.280 node**.*<br><br>*Keputusan akhirnya sama persis, tetapi urutan yang cerdas menghemat hingga 41% langkah komputasi!"* |

#### Sub-Scene 4.4: Eksperimen 4 — Trade-off Kedalaman (*Depth*)
| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **07:05 - 07:40**<br>• Sorot tabel **Exp 4: Depth Comparison ($d=1 \dots 6$)**.<br>• Tunjukkan grafik/tabel pertumbuhan eksponensial node dan waktu eksekusi. | *"Eksperimen keempat menguji kedalaman pencarian dari depth 1 sampai 6.*<br><br>*Pada depth 1, AI bersifat rabun dekat (*myopic*), hanya melihat 1 aksi ke depan dan hanya menang 70%.*<br><br>*Kemenangan optimal 100% tercapai mulai depth 3 dan 4. Perhatikan lonjakan bebannya: dari hanya 31 node di depth 1, melonjak menjadi 752 node di depth 4, hingga mencapai **3.820 node** di depth 6 dengan waktu 22 milidetik.*<br><br>*Kesimpulannya, **depth 4 adalah sweet-spot ideal** yang menawarkan kecerdasan maksimal dengan waktu komputasi yang sangat ringan untuk game real-time."* |

#### Sub-Scene 4.5 & 4.6: Eksperimen 5 & 6 — Profil Perilaku AI & Expectimax
| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **07:40 - 08:30**<br>• Sorot tabel **Exp 5: NPC Behaviour Profile** (persentase Attack, Heavy, Defend, Potion).<br>• Tampilkan cuplikan mode **Expectimax** di dropdown Debug HUD. | *"Pada Eksperimen kelima, kita melihat bagaimana fungsi evaluasi membentuk kepribadian AI:*<br>• *AI `AGGRESSIVE` melancarkan Heavy Attack sebanyak **63 persen** dari total aksinya.*<br>• *Sebaliknya, AI `DEFENSIVE` melipatgandakan penggunaan Defend hingga **42 persen**.*<br><br>*Terakhir, sebagai fitur pengayaan pada materi kuliah slide 25, kami juga mengimplementasikan **Expectimax Search**.*<br><br>*Pada mode ini, aksi Heavy Attack dimodelkan tidak deterministik dengan peluang akurasi 60% Hit dan 40% Miss. Layer musuh digantikan oleh node probabilitas Chance untuk menghitung nilai harapan matematis (*expected utility*), sehingga agen mampu beradaptasi di bawah ketidakpastian."* |

> 💡 **Tips Presenter:** Saat menjelaskan angka-angka penting (misal: *"58.5% penghematan"* atau *"63% Heavy Attack"*), gunakan pointer mouse atau zoom-in perlahan ke baris tabel tersebut agar audiens fokus.

---

### SCENE 5: Kesimpulan & Penutup
* **Estimasi Waktu:** 08:30 – 09:30 (Durasi: ~60 detik)
* **Fokus Materi:** Sintesis akademis, apresiasi, penutup resmi.

| Panduan Visual (On-Screen) | Naskah Suara (Voice Over) |
| :--- | :--- |
| **08:30 - 09:30**<br>• Tampilkan kembali layar duel game dengan gameplay yang seru dan dinamis.<br>• Tampilkan slide penutup berisi ringkasan poin-poin utama pembelajaran.<br>• Tampilkan kredit tim: Kelompok 10, Prodi, Fakultas, dan Kampus. | *"Dari seluruh proses pengembangan dan eksperimen ini, kami dapat menyimpulkan bahwa:*<br>1. *Penerapan **Adversarial Search** berhasil mengubah perilaku musuh dari sekadar script kondisional sederhana menjadi agen cerdas yang mampu memprediksi masa depan.*<br>2. ***Alpha-Beta Pruning** terbukti secara empiris memangkas lebih dari 58 persen cabang pencarian tanpa menurunkan keoptimalan keputusan.*<br>3. *Desain **Fungsi Evaluasi** dan **Urutan Aksi** adalah dua pilar terpenting dalam menentukan karakter serta efisiensi agen kecerdasan buatan.*<br><br>*Demikian presentasi laporan dan demonstrasi Tugas Besar Tahap 2 dari Kelompok 10. Terima kasih banyak atas perhatian Bapak/Ibu dosen serta rekan-rekan sekalian. Sampai jumpa di tahap berikutnya!"* |

---

## 📋 CHEAT SHEET PINTASAN TOMBOL SAAT REKAMAN
Agar proses perekaman video lancar tanpa canggung, gunakan keyboard shortcut berikut:
* **`[D]`**: Buka / Tutup sidebar **Debug Overlay** (Tunjukkan candidate score & prune ratio).
* **`[P]`**: Buka / Tutup jendela **Benchmark Lab** (Tunjukkan log 220 battle & tabel eksperimen).
* **`[1]`**: Attack biasa (20 DMG).
* **`[2]`**: Heavy Attack (37 DMG, -10 HP diri).
* **`[3]`**: Defend (Kuda-kuda bertahan).
* **`[4]`**: Potion (Minum obat +30 HP).
* **`[R]`**: Restart / Reset duel jika pertandingan selesai.

---
*Dokumen ini dibuat khusus sebagai panduan naskah rekaman presentasi video Tugas Besar Tahap 2 Infernal Affairs.*
