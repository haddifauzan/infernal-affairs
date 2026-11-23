# 🎬 PANDUAN & NASKAH VIDEO PENJELASAN: TAHAP 4 INFERNAL AFFAIRS
### Integrasi Modul 07 (*Logic*), Modul 08 (*Planning*), & Modul 09 (*Decisions Under Uncertainty*)

> **Mata Kuliah:** Kecerdasan Buatan (*Artificial Intelligence*) — Semester 3  
> **Kelompok 10:**  
> - Faridchi Trianda Safaraz (2506827)  
> - Haddi Fauzan Nurrosid (2507609)  
> - Farell Arrefa Zafhir (2508734)  
>  
> **Estimasi Total Durasi:** ± 6 – 7 Menit (Memenuhi batas minimal 5 menit)  
> **Gaya Bahasa:** Semi-formal, santai, luwes, komunikatif, namun tetap akurat secara akademis.

---

## 🎯 1. Ringkasan Tujuan Video
Video ini dirancang untuk mendemonstrasikan secara langsung (*live in-game demo*) implementasi kecerdasan buatan pada **Tahap 4**, dengan tujuan utama:
1. **Membuktikan integrasi 3 modul kurikulum AI:**
   - **Modul 07 (Logic):** Penalaran *Propositional Logic*, *Knowledge Base*, *Forward Chaining*, dan *Partial Observability* pada event *Guard Awakening* & *Gate Seal Reveal*.
   - **Modul 08 (Planning):** Perencanaan aksi terstruktur (*Classical Planning / STRIPS*) pada minion logistik untuk memanen dan menyuplai kristal dari 3 Altar ke Benteng.
   - **Modul 09 (Decisions Under Uncertainty):** Pengambilan keputusan di lingkungan stokastik menggunakan formulasi **Markov Decision Process (MDP)**, **Bellman Value Iteration**, serta **Bayesian Belief Updating** saat sensor bahaya mendeteksi letusan lahar.
2. **Menampilkan visualisasi interaktif & perbaikan gameplay:**
   - Menunjukkan *Policy Shift* waktu-nyata melalui *MDP Debug HUD*.
   - Memperlihatkan fitur baru *Dynamic Camera Zoom*, balon reaksi *Emote AI*, serta mekanisme terpental (*knockback recoil*) saat terkena bahaya lahar.
3. **Mempermudah presenter:** Memberikan panduan aksi tangan di keyboard/mouse yang sinkron dengan kalimat narasi yang dibacakan.

---

## 📊 2. Tabel Alur Demo Video (Storyboard Overview)

| Urutan | Segmen | Visual / Demo yang Ditampilkan | Poin Penjelasan | Kaitan dengan Modul PDF | Estimasi Durasi |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **1** | **Pembukaan & Orientasi Lingkungan** | • Layar awal game di overworld.<br>• Gunakan **Mouse Wheel Zoom-Out (0.6x)** untuk memperlihatkan panorama peta $52 \times 56$: Benteng Utara, Sungai Lahar dengan 3 Jembatan, dan 3 Altar Selatan.<br>• Zoom-in kembali ke Player. | • Salam & perkenalan Kelompok 10.<br>• Latar belakang Tahap 4: Transisi dari dunia deterministik ke dunia stokastik.<br>• Topografi peta pemisah lahar dan sistem 3 jembatan. | **Pengantar Umum & Transisi Paradigma** (Slide 09 hlm. 1–3) | **± 50 Detik**<br>(00:00 – 00:50) |
| **2** | **Modul 08: Automated Planning (STRIPS Minion)** | • Arahkan kamera ke wilayah selatan.<br>• Tunjukkan minion bergerak menuju salah satu Altar (*Ignis/Sanguine/Abyssal*).<br>• Minion memanen kristal elemen (`shards_spinning_sheet.png`), kristal terpasang di tas minion, lalu minion berbalik arah mengangkut suplai ke utara. | • Konsep agen perencana (*Autonomous Planning Agents*).<br>• Formulasi STRIPS: Operator `HARVEST`, `MOVE`, `DELIVER`.<br>• Asumsi dunia tertutup (*Closed World Assumption*) dan sekuens aksi *goal-directed*. | **Modul 08:** *Automated Planning* (Slide 08 hlm. 3–15, PDDL Operators) | **± 70 Detik**<br>(00:50 – 02:00) |
| **3** | **Modul 09: Keputusan di Bawah Ketidakpastian & MDP** | • Tekan tombol **`[M]`** untuk membuka **MDP Debug HUD**.<br>• Tunjukkan minion mendekati Simpang Lembah.<br>• Perlihatkan jembatan tengah aman (*Dormant*).<br>• Tunjukkan tabel di HUD: $Q(\text{Pintas}) = +7.00 > Q(\text{Raya}) = +6.00$.<br>• Minion memilih jembatan tengah sambil memunculkan balon emote `?`. | • Formulasi Tuple MDP $\langle S, A, P, R, \gamma \rangle$.<br>• Komputasi *Bellman Equation* & *Value Iteration* ($k=3$ konvergen).<br>• Prinsip *Maximum Expected Utility (MEU)*: Jalur pintas lebih menguntungkan saat kondisi tenang. | **Modul 09:** *Decisions Under Uncertainty* (Slide 09 hlm. 4–6, 14–21) | **± 60 Detik**<br>(02:00 – 03:00) |
| **4** | **Modul 09: Bayesian Updating & Live Policy Shift** | • Klik tombol **`[⚠ Warn (W=1)]`** di pojok kiri bawah.<br>• Jembatan tengah retak berpijar jingga (`vfx_warning_crack_sheet.png`) dan berasap.<br>• Tunjukkan HUD: $P(\text{Hazard})$ naik dari $0.10 \to 0.50$, $Q(\text{Pintas})$ anjlok ke $-5.00$.<br>• Minion memunculkan balon reaksi `!`, berbelok ke jembatan kanan (Jalur Utama Benteng). | • Aturan Bayes (*Bayesian Updating*): $P(\text{Hazard} \mid W=1)$.<br>• Likelihood sensor asap retakan ($0.90$).<br>• Konsep *Update Belief & Redo Decision*.<br>• Pembuktian *Policy Shift* secara live tanpa perlu reload game. | **Modul 09:** *Bayesian Updating* (Slide 09 hlm. 7–8, Update Belief) | **± 75 Detik**<br>(03:00 – 04:15) |
| **5** | **Hazard Eruption, Fisika Recoil, & Emote AI** | • Biarkan fase memasuki *ERUPTION* (semburan tiang api 6-frame).<br>• Gerakkan player atau biarkan minion tersengat lahar.<br>• Kristal terlepas ke tanah (`crystal_dropped.png`), minion terpental 2 petak ke selatan, memunculkan balon tengkorak `X`, dan lari mundur panik. | • Penanganan bahaya lingkungan dinamis (*Fissure Hazard FSM*).<br>• Evaluasi state kegagalan ($s_5$ Magma Trap, Reward $-20$).<br>• Eliminasi glitch teleportasi kaku menjadi *smooth knockback recoil*. | **Modul 09:** *Reward Penalties & Recovery Behavior* | **± 55 Detik**<br>(04:15 – 05:10) |
| **6** | **Modul 07: Logic & Guard Awakening Event** | • Gerakkan player ke depan gerbang benteng di utara.<br>• Tunjukkan status segel: `[?] UNKNOWN` (*Partially Observable*).<br>• Tekan tombol **`[L]`** untuk naik ke **Level 2**.<br>• Banner dramatis modal muncul: *"I HAVE AWAKENED!"*.<br>• Status gerbang terungkap (*Seal of Blood/Flame/Shadow Revealed*). | • Penalaran logika proposisional (*Propositional Logic*).<br>• Mesin *Forward Chaining* berbasis *Horn Clauses*:<br>  $\text{Level\_2} \implies \text{GuardAwakened} \implies \text{SealRevealed}$.<br>• Pengungkapan bertahap pada lingkungan teramati sebagian. | **Modul 07:** *Logic & Knowledge Representation* (Slide 07 hlm. 4–18) | **± 70 Detik**<br>(05:10 – 06:20) |
| **7** | **Validasi Numerik, Kesimpulan, & Penutup** | • Tampilkan kembali tabel ringkasan nilai di HUD pojok kiri.<br>• Klik tombol **`[Reset Normal]`** dan tunjukkan sistem kembali ke kondisi awal secara mulus.<br>• Karakter player berjalan santai di gerbang benteng. | • Validasi numerik: Galat teori vs runtime engine adalah $0.00\%$ (identik sempurna).<br>• Kesimpulan integrasi 3 modul.<br>• Ucapan terima kasih dan penutup. | **Rangkuman Evaluasi Akademik** | **± 40 Detik**<br>(06:20 – 07:00) |

---

## 🎙️ 3. Panduan Naskah Narasi & Saran Improvisasi Per Segmen

---

### SEGMEN 1: Pembukaan & Orientasi Lingkungan (00:00 – 00:50)

#### 🎮 Aksi di Layar:
1. Rekam game yang baru dijalankan di overworld.
2. Gunakan roda mouse (*scroll down*) untuk melakukan **Zoom-Out kamera** sehingga seluruh topografi peta terlihat luas: area benteng di utara, sungai lahar besar di tengah, dan 3 altar di selatan.
3. Gerakkan mouse mengitari 3 jembatan penghubung, lalu scroll-up zoom kembali ke karakter pemain.

#### 🗣️ Naskah Narasi Utama:
> *"Halo semuanya! Selamat datang di video demonstrasi Tugas Besar Tahap 4 Mata Kuliah Kecerdasan Buatan.*  
>  
> *Kami dari Kelompok 10, yang beranggotakan Faridchi Trianda Safaraz, Haddi Fauzan Nurrosid, dan Farell Arrefa Zafhir.*  
>  
> *Pada Tahap 4 ini, game Infernal Affairs mengalami lompatan besar. Jika pada tahap sebelumnya agen beroperasi di lingkungan deterministik yang serba pasti, kini game memasuki lingkungan stokastik yang penuh ketidakpastian. Di layar, teman-teman bisa melihat peta baru berukuran 52 kali 56 petak. Wilayah selatan tempat sumber daya dipisahkan oleh Sungai Lahar Besar dari benteng penjaga di utara, yang hanya dihubungkan oleh tiga buah jembatan strategis."*

#### 💡 Saran Improvisasi / Alternatif Kalimat:
* *Gaya lebih santai:* *"Halo guys! Kali ini kita bakal demoin hasil pengerjaan Tahap 4 game Infernal Affairs. Di tahap ini, AI kita buat jauh lebih realistis karena dunia game-nya sekarang punya risiko dan ketidakpastian, bukan cuma jalan lurus yang pasti aman."*
* *Saat zoom-out:* *"Bisa dilihat lewat fitur zoom kamera ini, map kita sekarang luas banget. Ada sungai lahar besar di tengah yang jadi rintangan utama buat agen-agen minion kita."*

---

### SEGMEN 2: Modul 08 — Automated Planning (STRIPS Supply Chain) (00:50 – 02:00)

#### 🎮 Aksi di Layar:
1. Geser kamera ke wilayah selatan tempat 3 Altar (*Ignis* di kiri bawah, *Sanguine* di tengah bawah, *Abyssal* di kanan bawah).
2. Tunjukkan minion yang berjalan mendekati Altar.
3. Sorot efek visual partikel kristal berputar (`shards_spinning_sheet.png`).
4. Perlihatkan saat minion mengambil kristal, kristal menempel di tas minion, dan minion mulai berjalan mengarah ke utara.

#### 🗣️ Naskah Narasi Utama:
> *"Bagian pertama mengacu pada **Modul 08: Automated Planning**.*  
>  
> *Di sini, minion tidak lagi berpatroli acak atau mengikuti rute kaku, melainkan bertindak sebagai **Autonomous Planning Agents**. Dengan asumsi dunia tertutup (*Closed World Assumption*), minion menyusun sekuens aksi berbasis formulasi klasik **STRIPS**.*  
>  
> *Ada tiga operator utama yang dijalankan minion:*  
> *Pertama, aksi `MOVE` menuju Altar terdekat.*  
> *Kedua, aksi `HARVEST`, yaitu mengambil serpihan kristal elemen jika tangannya kosong.*  
> *Dan ketiga, aksi `DELIVER`, yaitu mengangkut dan menyetor kristal tersebut ke Penjaga Benteng.*  
>  
> *Rantai pasokan ini berjalan otomatis dari tiga altar elemen di selatan menuju pos penjaga di utara."*

#### 💡 Saran Improvisasi / Alternatif Kalimat:
* *Gaya praktis:* *"Sesuai materi Modul 8 tentang STRIPS dan PDDL, minion di sini punya 'goal' atau tujuan. Kalau belum bawa kristal, dia generate plan buat jalan ke altar lalu panen. Begitu kristal ada di tangan, plan-nya otomatis berubah jadi mengantarkan suplai ke benteng penjaga."*
* *Menekankan visual:* *"Perhatikan serpihan kristal yang berputar di atas altar ini—minion bakal datang, ambil kristal itu, lalu membawanya menyeberangi sungai."*

---

### SEGMEN 3: Modul 09 — Keputusan di Bawah Ketidakpastian & MDP (02:00 – 03:00)

#### 🎮 Aksi di Layar:
1. Tekan tombol **`[M]`** pada keyboard untuk membuka kartu **Tahap 4 MDP & Bayesian HUD** di layar kanan atas.
2. Kamera mengikuti minion yang sedang membawa kristal mendekati titik persimpangan (*Simpang Lembah*).
3. Arahkan kursor mouse ke jembatan tengah yang sedang dalam kondisi tenang (*Dormant* / batu vulkanik gelap).
4. Sorot tabel HUD: tunjukkan baris $s_1$ (Simpang), nilai $Q(\text{Pintas}) = 7.00$, dan $Q(\text{Raya}) = 6.00$.
5. Tunjukkan minion memunculkan balon reaksi tanda tanya `?` di atas kepalanya lalu melangkah masuk ke jembatan tengah (*Jalur Pintas*).

#### 🗣️ Naskah Narasi Utama:
> *"Nah, pertanyaan besarnya: ketika minion sampai di persimpangan jalan, rute jembatan mana yang akan dia pilih? Inilah penerapan materi **Modul 09: Decisions Under Uncertainty**.*  
>  
> *Masalah ini kami modelkan secara formal sebagai **Markov Decision Process (MDP)** dengan tuple lima elemen: State, Action, Transition Probability, Reward, dan Discount Factor gamma sebesar 0,8.*  
>  
> *Mari kita buka panel debug dengan menekan tombol M. Di sini ditampilkan tabel hasil perhitungan **Bellman Value Iteration**.*  
> *Reward sukses mengantar kristal adalah plus 10, sedangkan risiko terbakar lahar adalah minus 20, dengan biaya langkah minus 2.*  
>  
> *Pada kondisi normal saat lahar tidak aktif, peluang bahaya hanya 10 persen. Berdasarkan prinsip **Maximum Expected Utility (MEU)**, nilai Q jalur pintas adalah 7,00, lebih tinggi dari jalur utama yang bernilai 6,00. Oleh karena itu, minion secara cerdas memilih jembatan tengah karena lebih cepat sampai!"*

#### 💡 Saran Improvisasi / Alternatif Kalimat:
* *Gaya santai:* *"Kalian bisa lihat di tabel MDP HUD ini. Selama kondisi jembatan aman, minion bakal milih jalan pintas di tengah. Kenapa? Karena utilitas ekspektasinya 7, lebih gede dari jalan raya yang cuma bernilai 6. Agen ini rasional, dia pengen reward tercepat!"*
* *Sorot balon emote:* *"Lihat ada balon tanda tanya di atas kepala minion—itu tandanya minion lagi mengevaluasi nilai Q sebelum menentukan langkah."*

---

### SEGMEN 4: Modul 09 — Bayesian Updating & Live Policy Shift (03:00 – 04:15)

#### 🎮 Aksi di Layar:
1. Arahkan kursor mouse ke panel kontrol di **pojok kiri bawah** dan klik tombol **`[⚠ Warn (W=1)]`** (atau `Force Warning`).
2. Tunjukkan lantai jembatan tengah seketika berubah: muncul retakan bercahaya jingga (`vfx_warning_crack_sheet.png`) dan kepulan asap belerang.
3. Sorot baris Belief di MDP HUD: nilai $P(\text{Hazard})$ melonjak dari $0.10$ menjadi **$0.50$ (50%)**.
4. Tunjukkan nilai pada tabel: $Q(\text{Pintas})$ langsung anjlok dari $+7.00$ menjadi **$-5.00$**, sementara $Q(\text{Raya})$ tetap **$+6.00$**.
5. Kamera menyorot minion berikutnya yang tiba di persimpangan: minion memunculkan balon tanda seru `!` berwarna oranye, membatalkan langkah ke jembatan tengah, dan **berbelok ke kanan** menuju Jalur Utama (*Jembatan Batu Besar*).

#### 🗣️ Naskah Narasi Utama:
> *"Sekarang mari kita uji bagaimana kecerdasan agen saat lingkungan berubah. Saya akan memicu sinyal peringatan bahaya dengan menekan tombol **Warn W=1** di kiri bawah.*  
>  
> *Perhatikan! Lantai jembatan tengah mulai retak dan mengeluarkan asap. Sensor agen mendeteksi sinyal W ini. Sesuai materi Slide 7 dan 8, agen menerapkan **Bayesian Belief Updating**.*  
>  
> *Dengan akurasi sensor 90 persen, probabilitas posterior bahaya dihitung ulang: P Hazard given W melonjak dari 10 persen menjadi 50 persen!*  
>  
> *Dampaknya sangat luar biasa terhadap nilai utilitas: nilai Q jalan pintas langsung anjlok menjadi minus 5,00, kalah jauh dari jalur utama yang bernilai plus 6,00.*  
> *Perhatikan minion di layar: begitu muncul tanda seru oranye di kepalanya, terjadi **Policy Shift** seketika! Minion langsung putar haluan ke jembatan kanan yang aman. Tidak ada satu pun minion yang terjebak!"*

#### 💡 Saran Improvisasi / Alternatif Kalimat:
* *Gaya interaktif:* *"Ini bagian paling keren dari sistem kita. Begitu sensor W aktif karena ada asap retakan, rumus Bayes langsung bekerja. Keyakinan bahaya naik jadi 50%, bikin nilai jalan pintas anjlok ke minus 5. Hasilnya? Minion kaget dengan emot tanda seru, dan langsung beralih ke jalan raya memutar. Agen berhasil update belief dan redo decision!"*
* *Menekankan ke dosen/penguji:* *"Ini membuktikan bahwa agen kita bukan sekadar hardcoded if-else, melainkan benar-benar menghitung ulang probabilitas Bayes dan persamaan Bellman secara real-time."*

---

### SEGMEN 5: Hazard Eruption, Fisika Recoil, & Emote AI (04:15 – 05:10)

#### 🎮 Aksi di Layar:
1. Tunggu 1–2 detik hingga jembatan tengah memasuki fase **ERUPTION** (semburan tiang api vertikal 6-frame yang menyala tinggi).
2. Gerakkan karakter pemain melintasi jembatan lahar untuk menunjukkan bahwa pemain terkena damage dan efek slow.
3. Biarkan minion yang telanjur melintas terkena semburan tiang lahar.
4. Tunjukkan efeknya:
   - Kristal terlepas dan jatuh ke tanah (`crystal_dropped.png`).
   - Minion tidak diteleportasi secara aneh, melainkan **terpental halus 2 petak ke selatan** (*recoil*).
   - Di atas kepala minion muncul balon ekspresi tengkorak `X` (*Skull of Panic*).
   - Minion berlari mundur panik selama 2 detik sebelum merencanakan rute baru.

#### 🗣️ Naskah Narasi Utama:
> *"Lalu, bagaimana jika ada entitas yang nekat melintas saat fase **Eruption** terjadi?*  
>  
> *Bisa kita lihat, semburan pilar api setinggi 64 piksel menyala membakar jembatan. Ini merepresentasikan state terminal kegagalan $s_5$ dengan penalti ekstrem minus 20.*  
>  
> *Jika minion tersengat lahar, kristal yang dibawanya akan terlepas dan jatuh ke tanah. Kami juga telah memperbaiki bug terdahulu: minion tidak lagi terteleportasi secara kaku, melainkan terpental secara realistis sejauh dua petak ke arah selatan.*  
>  
> *Minion memunculkan balon reaksi tengkorak X, masuk ke status panik, dan mundur menjauhi zona mematikan tersebut. Ini membuktikan integrasi mekanika bahaya lingkungan dengan respon fisik agen berjalan sangat mulus."*

#### 💡 Saran Improvisasi / Alternatif Kalimat:
* *Gaya santai:* *"Nah, kalau nekat nerobos pas semburan api lagi meledak, minion bakal kena sengatan lahar. Kristalnya langsung tumpah ke tanah, minionnya terpental mundur ke belakang dua petak sambil panik dengan emot tengkorak. Jadi ga ada lagi glitch teleport tiba-tiba kayak versi sebelumnya."*
* *Catatan interaksi pemain:* *"Pemain juga bisa memanfaatkan momen ini buat 'membegal' kristal yang jatuh di jembatan!"*

---

### SEGMEN 6: Modul 07 — Logic & Guard Awakening Event (05:10 – 06:20)

#### 🎮 Aksi di Layar:
1. Jalankan karakter pemain menyeberang ke wilayah utara dan dekati gerbang benteng tempat Penjaga (*Guard*) berdiri.
2. Arahkan kursor mouse ke status segel gerbang di HUD/atas pintu: tunjukkan teks bertuliskan **`[?] UNKNOWN`**.
3. Jelaskan bahwa informasi ini tersembunyi (*Partially Observable*).
4. Tekan tombol keyboard **`[L]`** (Debug Level Up) agar level pemain naik menjadi **Level 2**.
5. Seketika, banner modal hitam dramatis muncul di layar: *"I HAVE AWAKENED! ..."*.
6. Tunjukkan bahwa status segel gerbang langsung terbuka dan terungkap secara jelas (misalnya menjadi: *Seal of Blood* / *Seal of Flame*).

#### 🗣️ Naskah Narasi Utama:
> *"Sekarang kita beralih ke pilar ketiga, yaitu **Modul 07: Logic & Representasi Pengetahuan**.*  
>  
> *Di awal permainan, dunia bersifat teramati sebagian atau **Partially Observable**. Pemain tidak mengetahui jenis segel apa yang mengunci gerbang benteng—di layar statusnya bertanda tanya `[?] UNKNOWN`.*  
>  
> *Sistem ini kami bangun menggunakan **Knowledge Base (KB)** berbasis logika proposisional dan aturan klausa Horn (*Horn Clauses*), yang dievaluasi dengan algoritma **Forward Chaining**.*  
>  
> *Perhatikan: ketika karakter pemain mencapai Level 2—saya tekan tombol L—premis `PlayerLevel_2` terpenuhi. Mesin inferensi secara otomatis mendeduksikan fakta baru: `GuardAwakened`, yang kemudian memicu konklusi berikutnya: `SealRevealed`!*  
>  
> *Penjaga gerbang terbangun dengan dialog monolog dramatis, dan segel gerbang akhirnya terungkap ke layar. Selain lewat level, deduksi logis ini juga bisa terpicu jika pemain menyabotase minion pembawa elemen di alam liar."*

#### 💡 Saran Improvisasi / Alternatif Kalimat:
* *Gaya to the point:* *"Di Modul 7 materinya tentang Logika Proposisi dan Forward Chaining. Gerbang ini awalnya misterius, segelnya masih tanda tanya. Tapi begitu player naik ke Level 2, aturan IF PlayerLevel_2 THEN GuardAwakened langsung aktif. Penjaga bangun, ngasih dialog, dan rahasia segel gerbang langsung kebuka di HUD!"*
* *Koneksi ke gameplay:* *"Dengan tahu jenis segelnya, pemain bisa menyiapkan strategi sebelum menantang penjaga ke pertarungan duel turn-based di tahap berikutnya."*

---

### SEGMEN 7: Validasi Numerik, Kesimpulan, & Penutup (06:20 – 07:00)

#### 🎮 Aksi di Layar:
1. Tekan tombol **`[Reset Normal]`** di pojok kiri bawah untuk mengembalikan simulasi ke kondisi awal yang tenang.
2. Gerakkan kamera atau lakukan zoom-in pada karakter pemain yang berdiri gagah di depan gerbang benteng.
3. Tampilkan slide / closing card nama anggota kelompok dan judul proyek.

#### 🗣️ Naskah Narasi Utama:
> *"Sebagai penutup, seluruh hasil simulasi yang kita lihat tadi bukan sekadar efek visual, melainkan hasil perhitungan matematis yang presisi. Nilai iterasi Bellman pada HUD engine Godot terbukti memiliki selisih galat nol koma nol persen jika dibandingkan dengan perhitungan manual di atas kertas.*  
>  
> *Secara keseluruhan, Tahap 4 berhasil menyatukan tiga pilar penting AI:*  
> *Modul 07 mengungkap pengetahuan dunia,*  
> *Modul 08 merencanakan tugas logistik minion, dan*  
> *Modul 09 memandu keputusan agen di tengah ketidakpastian lahar.*  
>  
> *Sekian demonstrasi dari Kelompok 10. Terima kasih atas perhatiannya, dan sampai jumpa!"*

#### 💡 Saran Improvisasi / Alternatif Kalimat:
* *Gaya santai:* *"Jadi kesimpulannya, integrasi Modul 7, 8, dan 9 di game Infernal Affairs ini berjalan 100% mulus dan akurat secara matematis. Minion-nya pintar, dunianya dinamis, dan sistem logikanya jalan sempurna.*  
*Terima kasih banyak udah nyimak video demo ini, semoga bermanfaat! Dadah!"*

---

## 🛠️ 4. Catatan Teknis & Panduan Bagi Penguji / Pendemo Game

Agar rekaman video berjalan lancar tanpa kendala teknis, perhatikan panduan operasional berikut:

### A. Daftar Tombol Pintas (*Hotkeys & Controls*)

| Tombol Keyboard / Mouse | Fungsi & Reaksi In-Game | Kapan Harus Ditekan Saat Video |
| :--- | :--- | :--- |
| **`W / A / S / D`** atau Panah | Menggerakkan karakter Player | Digunakan saat eksplorasi awal dan mendekati jembatan / gerbang. |
| **Mouse Wheel Up / Down** | **Dynamic Zoom In / Zoom Out** (0.5x s.d. 2.0x) | Di awal video (Segmen 1) untuk memperlihatkan panorama seluruh peta. |
| **`+` / `-` / `0`** | Zoom Keyboard & Reset Zoom (1.0x) | Alternatif jika tidak menggunakan mouse. |
| **`M`** | Membuka / Menutup **MDP Debug HUD** | Di awal Segmen 3 untuk memperlihatkan tabel nilai $Q$ dan $V(s)$. |
| **Klik Tombol `[⚠ Warn]`** | Memicu sinyal peringatan bahaya ($W = 1$) | Di Segmen 4 untuk memicu asap jembatan dan demonstrasi *Policy Shift*. |
| **Klik Tombol `[Reset]`** | Mengembalikan jembatan ke fase aman ($W = 0$) | Di Segmen 7 saat mereset simulasi. |
| **`L`** atau **`C`** | **Debug Level Up** (Naik Level Instan) | Di Segmen 6 untuk memicu event *Guard Awakening* saat mencapai Level 2. |
| **`TAB`** | Toggle Pathfinding (**A\*** $\leftrightarrow$ **UCS**) | Opsional jika ingin menunjukkan bahwa pathfinding fisik tetap aktif. |
| **`R`** | Restart Game | Jika ingin mengulang demonstrasi dari awal. |

---

### B. Tips Eksekusi Demonstrasi yang Menarik:
1. **Posisi Kamera:** Saat minion mendekati jembatan lahar, gunakan tingkat zoom normal (1.0x atau 1.1x) agar balon reaksi emote (`!`, `?`, `X`) dan kepulan asap retakan terlihat jelas dan tajam.
2. **Timing Penekanan Tombol `[⚠ Warn]`:** Tekan tombol peringatan tepat saat minion sedang berjalan di antara Altar dan Simpang Lembah (belum menyeberang). Hal ini membuat penonton melihat secara dramatis momen ketika minion berbelok haluan (*Policy Shift*) ke jembatan kanan.
3. **Ergonomi UI:** Tombol kontrol MDP sengaja diletakkan di **pojok kiri bawah** pada kartu status player agar saat kursor mouse mengeklik tombol tersebut, pandangan ke jembatan di tengah layar dan kartu HUD di kanan atas tidak terhalangi sama sekali.
4. **Hal yang Perlu Dihindari:**
   - Jangan menabrak minion musuh di awal game jika tidak bermaksud bertarung, agar tidak mendadak masuk ke arena duel turn-based (Tahap 2).
   - Jangan menekan tombol `L` sebelum masuk ke Segmen 6, agar momen *Guard Awakening* tetap menjadi kejutan di segmen logika.
