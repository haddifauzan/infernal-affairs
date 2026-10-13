# Catatan Penjelasan Logika & Algoritma - Infernal Affairs

Dokumen ini berisi rangkuman pembahasan materi dan logika algoritma pada project ini. Setiap sesi tanya-jawab baru akan ditambahkan di bagian bawah dokumen ini.

---

## 1. Algoritma A* (A-Star) & Fungsi Heuristik

### 1.1 Lokasi File
- Kode sumber algoritma: [`scripts/core/AStar.gd`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/core/AStar.gd)
- Struktur data antrian prioritas: [`scripts/core/MinHeap.gd`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/core/MinHeap.gd)
- Pengelola grid & tetangga: [`scripts/core/GridManager.gd`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/core/GridManager.gd)

---

### 1.2 Konsep Fungsi Heuristik

Di `AStar.gd` (baris 4-5):
```gdscript
func heuristic(a: Vector2i, b: Vector2i) -> float:
	return abs(a.x - b.x) + abs(a.y - b.y)
```

- **Jenis Heuristik:** **Manhattan Distance** ($L_1$ Distance / Taxicab Distance).
- **Rumus Matematis:**
  $$\Large h(n) = |x_n - x_{\text{goal}}| + |y_n - y_{\text{goal}}|$$

#### Kenapa Menggunakan Manhattan Distance?
1. **Grid 4-Arah:** Karakter hanya bergerak orthogonal (Atas, Bawah, Kiri, Kanan) tanpa pergerakan diagonal.
2. **Admissible (Layak):** Nilai estimasi $h(n)$ tidak pernah melebihi jarak/biaya sebenarnya menuju target ($h(n) \le h^*(n)$).
3. **Consistent (Monoton):** Untuk setiap langkah dari node $n$ ke tetangga $n'$, berlaku $h(n) \le c(n, n') + h(n')$. Sifat ini menjamin bahwa saat sebuah node diambil dari antrian, jalur terbaik menuju node tersebut sudah final.

---

### 1.3 Rumus Utama Evaluasi A*

Setiap node yang dipertimbangkan di dalam Priority Queue ([`MinHeap.gd`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/core/MinHeap.gd)) dinilai menggunakan fungsi evaluasi:

$$\Large f(n) = g(n) + h(n)$$

Keterangan:
- **$g(n)$ (Actual Cost):** Total biaya riil yang dihabiskan dari titik awal (`start`) menuju node $n$.
  - Diperoleh dari akumulasi bobot petak yang dilewati (`cost_so_far`).
- **$h(n)$ (Heuristic Cost):** Perkiraan sisa jarak/biaya dari node $n$ ke titik tujuan (`goal`).
- **$f(n)$ (Priority / Total Estimated Cost):** Total perkiraan biaya dari titik awal ke tujuan jika melewati node $n$. Node dengan nilai $f(n)$ terkecil akan selalu diproses lebih dulu.

---

### 1.4 Bedah Kode GDScript

```gdscript
func search(grid_manager: GridManager, start: Vector2i, goal: Vector2i) -> Dictionary:
	var start_time = Time.get_ticks_usec()
	var frontier = MinHeap.new()
	frontier.push(start, 0.0) # Titik awal dimasukkan dengan priority 0
	
	var came_from: Dictionary = {}      # Menyimpan hubungan jalur: came_from[anak] = induk
	var cost_so_far: Dictionary = {}    # Menyimpan g(n) terendah tiap titik
	cost_so_far[start] = 0.0
	
	var explored: Array[Vector2i] = []  # Catatan node yang sudah diekspansi (untuk visualizer)
	var nodes_expanded: int = 0

	while not frontier.is_empty():
		var current = frontier.pop()    # Ambil node dengan f(n) terendah
		nodes_expanded += 1
		if not explored.has(current):
			explored.append(current)
			
		if current == goal:             # Goal tercapai!
			break
			
		# Eksplorasi tetangga
		for neighbor in grid_manager.get_neighbors(current):
			# Hitung g(neighbor) baru
			var new_cost = cost_so_far[current] + neighbor.cost
			
			# Jika tetangga belum pernah dikunjungi, ATAU ketemu rute yang lebih murah
			if not cost_so_far.has(neighbor.pos) or new_cost < cost_so_far[neighbor.pos]:
				cost_so_far[neighbor.pos] = new_cost
				
				# f(n) = g(n) + h(n)
				var priority = new_cost + heuristic(neighbor.pos, goal)
				
				frontier.push(neighbor.pos, priority)
				came_from[neighbor.pos] = current # Tandai asal langkah untuk rekonstruksi path

	var execution_time_ms = (Time.get_ticks_usec() - start_time) / 1000.0
	var path = _reconstruct_path(start, goal, came_from)
	var total_cost = cost_so_far.get(goal, INF)
	
	return {
		"path": path,
		"cost": total_cost,
		"explored": explored,
		"nodes_expanded": nodes_expanded,
		"execution_time_ms": execution_time_ms
	}
```

#### Rekonstruksi Jalur (`_reconstruct_path`)
Melacak kembali koordinat dari `goal` mundur ke `start` melalui dictionary `came_from`, lalu membalikkan urutannya (`path.reverse()`):
```gdscript
func _reconstruct_path(start: Vector2i, goal: Vector2i, came_from: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var curr = goal
	if not came_from.has(curr) and curr != start:
		return [] # Tidak ada jalan menuju goal
	while curr != start:
		path.append(curr)
		curr = came_from[curr]
	path.append(start)
	path.reverse()
	return path
```

---

### 1.5 Contoh Simulasi Perhitungan Angka

**Kondisi Awal:**
- Titik Start $S = (1, 1)$
- Titik Goal $G = (4, 3)$
- Node saat ini $C = (2, 2)$ dengan nilai $g(C) = 2.0$
- Agen mengecek tetangga di sebelah kanan: $N = (3, 2)$
- Bobot jalan ke $N$: `neighbor.cost = 1.0` (tanah normal)

**Langkah Perhitungan:**
1. **Hitung $g(N)$:**
   $$g(N) = g(C) + \text{cost}(C \to N) = 2.0 + 1.0 = 3.0$$

2. **Hitung $h(N)$ (Manhattan Distance ke Goal):**
   $$h(N) = |x_N - x_G| + |y_N - y_G| = |3 - 4| + |2 - 3| = |-1| + |-1| = 1 + 1 = 2.0$$

3. **Hitung $f(N)$ (Priority untuk MinHeap):**
   $$f(N) = g(N) + h(N) = 3.0 + 2.0 = 5.0$$

4. Node $N(3, 2)$ dimasukkan ke dalam antrian `frontier` dengan prioritas **$5.0$**.

---

## 2. Adversarial Search (Minimax, Alpha-Beta Pruning, & Expectimax)

### 2.1 Lokasi File
- Algoritma & Solver: [`scripts/battle/MinimaxSolver.gd`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/MinimaxSolver.gd)
- Model State Pertarungan: [`scripts/battle/BattleState.gd`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/BattleState.gd)
- Orkestrator Turn & Battle: [`scripts/battle/BattleManager.gd`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/BattleManager.gd)

---

### 2.2 Formulasi Game State & Aturan Pertarungan

Game ini dimodelkan sebagai **Turn-Based 2-Player Zero-Sum Game**:
- **MAX Player:** NPC (AI). Tujuannya memaksimalkan skor evaluasi (menang).
- **MIN Player:** Player (manusia atau lawan). Tujuannya meminimalkan skor NPC (mengalahkan NPC).

#### State Space $s \in S$:
$$s = \langle HP_{\text{player}}, HP_{\text{npc}}, Pot_{\text{player}}, Pot_{\text{npc}}, Def_{\text{player}}, Def_{\text{npc}}, Turn, TurnCount \rangle$$

#### Aksi ($A(s)$) dengan Branching Factor $b \le 4$:
1. **`ATTACK`**: 
   - Damage dasar $= 20$.
   - Jika lawan sedang `DEFEND`, damage $= 20 \times 0.5 = 10$.
2. **`HEAVY_ATTACK`**:
   - Damage kritikal $= 37$ (menembus pertahanan lawan).
   - Recoil self-damage $= 10\text{ HP}$ pada penyerang.
3. **`DEFEND`**:
   - Mengurangi damage serangan biasa berikutnya sebesar $50\%$.
4. **`POTION`**:
   - Memulihkan $+30\text{ HP}$ (maksimal $100$). Hanya valid jika stok ramuan $> 0$.

---

### 2.3 Algoritma Minimax Standar

Minimax mengeksplorasi seluruh pohon permainan hingga kedalaman tertentu (`max_depth`).

#### Rumus Matematis:
$$\text{Minimax}(s, d) = 
\begin{cases} 
\text{Utility}(s) & \text{jika } s \text{ terminal} \\
\text{Eval}(s) & \text{jika } d = 0 \\
\max_{a \in A(s)} \text{Minimax}(\text{Result}(s, a), d-1) & \text{jika giliran MAX (NPC)} \\
\min_{a \in A(s)} \text{Minimax}(\text{Result}(s, a), d-1) & \text{jika giliran MIN (Player)}
\end{cases}$$

#### Kode Implementasi ([`MinimaxSolver.gd:L106-131`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/MinimaxSolver.gd#L106-L131)):
```gdscript
func _minimax(state: BattleState, depth: int, is_maximising: bool) -> float:
	nodes_visited += 1
	max_depth_reached = max(max_depth_reached, max_depth - depth)

	if state.is_terminal():
		return float(state.terminal_utility()) # Win: +1000, Lose: -1000, Draw: 0
	if depth == 0:
		return _evaluate(state)

	var actions := _order_actions(get_available_actions(state))

	if is_maximising:
		var best := -INF
		for act in actions:
			var child := apply_action(state, act)
			var val   := _minimax(child, depth - 1, false)
			best = max(best, val)
		return best
	else:
		var best := INF
		for act in actions:
			var child := apply_action(state, act)
			var val   := _minimax(child, depth - 1, true)
			best = min(best, val)
		return best
```

---

### 2.4 Algoritma Alpha-Beta Pruning

Alpha-Beta Pruning menghasilkan **keputusan yang sama persis dengan Minimax**, namun memangkas cabang (*pruning*) yang tidak mungkin dipilih oleh pemain rasional, sehingga menghemat jumlah node yang diperiksa secara dramatis.

#### Dua Parameter Batas:
- **$\alpha$ (Alpha):** Nilai terbaik (tertinggi) yang dijamin diperoleh oleh pemain **MAX** di sepanjang jalur saat ini. Nilai awal $= -\infty$.
- **$\beta$ (Beta):** Nilai terbaik (terendah) yang dijamin diperoleh oleh pemain **MIN** di sepanjang jalur saat ini. Nilai awal $= +\infty$.

#### Syarat Pemangkasan (Cut-off):
Jika di suatu titik $\beta \le \alpha$, maka cabang tersebut langsung dihentikan (`break`) karena salah satu pihak sudah punya pilihan yang lebih menguntungkan di cabang lain.
- **$\beta$-cut (pada MAX node):** Ketika nilai anak $\ge \beta$, pemain MIN di atasnya tidak akan pernah membiarkan kondisi ini terjadi.
- **$\alpha$-cut (pada MIN node):** Ketika nilai anak $\le \alpha$, pemain MAX di atasnya tidak akan pernah memilih rute ini.

#### Kode Implementasi ([`MinimaxSolver.gd:L135-165`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/MinimaxSolver.gd#L135-L165)):
```gdscript
func _alphabeta(state: BattleState, depth: int, alpha: float, beta: float, is_maximising: bool) -> float:
	nodes_visited += 1
	max_depth_reached = max(max_depth_reached, max_depth - depth)

	if state.is_terminal():
		return float(state.terminal_utility())
	if depth == 0:
		return _evaluate(state)

	var actions := _order_actions(get_available_actions(state))

	if is_maximising:
		var value := -INF
		for act in actions:
			var child := apply_action(state, act)
			value = max(value, _alphabeta(child, depth - 1, alpha, beta, false))
			alpha = max(alpha, value)
			if beta <= alpha:
				nodes_pruned += 1
				break   ## β cut-off (cabang sisa tidak diperiksa)
		return value
	else:
		var value := INF
		for act in actions:
			var child := apply_action(state, act)
			value = min(value, _alphabeta(child, depth - 1, alpha, beta, true))
			beta = min(beta, value)
			if beta <= alpha:
				nodes_pruned += 1
				break   ## α cut-off (cabang sisa tidak diperiksa)
		return value
```

---

### 2.5 Move Ordering (Urutan Aksi) & Pengaruhnya pada Pruning

Efisiensi Alpha-Beta Pruning sangat bergantung pada urutan eksplorasi cabang:
- **Kasus Terburuk (Worst Case):** Jika aksi dieksplorasi dari yang paling jelek ke paling bagus, tidak ada cabang yang terpotong. Kompleksitas tetap $O(b^d)$.
- **Kasus Terbaik (Best Case / Optimal Ordering):** Jika langkah terbaik selalu dieksplorasi pertama, kompleksitas turun menjadi $O(b^{d/2})$ atau secara efektif mampu mencari hingga kedalaman **$2 \times$ lipat** dengan jumlah node yang sama.

Di project ini disediakan opsi pengurutan aksi ([`MinimaxSolver.gd:L349-370`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/MinimaxSolver.gd#L349-L370)):
- **AGGRESSIVE:** Mengutamakan `HEAVY_ATTACK` $\to$ `ATTACK` $\to$ `DEFEND` $\to$ `POTION`.
- **DEFENSIVE:** Mengutamakan `DEFEND` $\to$ `POTION` $\to$ `ATTACK` $\to$ `HEAVY_ATTACK`.
- **DEFAULT:** Berdasarkan ID enum berurutan.

---

### 2.6 Fungsi Evaluasi Heuristik (Evaluation Functions)

Ketika batas kedalaman tercapai (`depth == 0`), nilai non-terminal ditentukan oleh fungsi evaluasi dari sudut pandang NPC ([`MinimaxSolver.gd:L322-345`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/MinimaxSolver.gd#L322-L345)):

1. **HP Difference (Default):**
   $$\text{Eval}(s) = HP_{\text{npc}} - HP_{\text{player}}$$
   Sederhana dan seimbang. Menilai selisih keunggulan sisa darah.

2. **Aggressive:**
   $$\text{Eval}(s) = 100 - HP_{\text{player}}$$
   Hanya peduli seberapa banyak damage yang berhasil ditimpakan ke Player, mengabaikan keselamatan diri sendiri.

3. **Defensive:**
   $$\text{Eval}(s) = HP_{\text{npc}}$$
   Hanya peduli mempertahankan sisa HP diri sendiri, cenderung sering bertahan atau minum potion.

4. **Weighted Evaluation:**
   $$\text{Eval}(s) = 2 \cdot (HP_{\text{npc}} - HP_{\text{player}}) + (10 \cdot Pot_{\text{npc}} - 5 \cdot Pot_{\text{player}}) + (15 \text{ jika } Def_{\text{npc}} \text{ aktif})$$
   Memberi bobot strategis ekstra pada keunggulan stok potion dan perlindungan pertahanan aktif.

5. **HP Ratio:**
   $$\text{Eval}(s) = \left(\frac{HP_{\text{npc}}}{\max(1, HP_{\text{player}})}\right) \times 50$$
   Menilai rasio keunggulan secara proporsional/multiplikatif.

---

### 2.7 Varian Expectimax (Ketidakpastian / Probabilistik)

Selain Minimax dan Alpha-Beta yang bersifat deterministik, project ini juga menyertakan **Expectimax** ([`MinimaxSolver.gd:L172-210`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/MinimaxSolver.gd#L172-L210)).

- **Konsep:** Pada giliran Player saat menggunakan `HEAVY_ATTACK`, ada faktor peluang (chance node):
  - **Peluang Berhasil (*Hit*):** $60\%$ ($P = 0.6$) $\to$ Menghasilkan damage $37$.
  - **Peluang Meleset (*Miss*):** $40\%$ ($P = 0.4$) $\to$ Player tetap terkena recoil $10\text{ HP}$, namun damage ke NPC $= 0$.
- **Rumus Expected Value pada Chance Node:**
  $$\text{Value}_{\text{chance}} = 0.6 \times V(\text{child}_{\text{hit}}) + 0.4 \times V(\text{child}_{\text{miss}})$$
- **Catatan Penting:** Alpha-Beta Pruning **tidak bisa langsung diterapkan secara naif pada Expectimax** tanpa bound probabilitas khusus, karena nilai chance node membutuhkan rata-rata tertimbang semua cabang kemungkinan.

---

## 3. Analisis Strategi & Settingan Mengalahkan NPC (AI)

Untuk mengalahkan NPC dengan mudah, kita bisa mengeksploitasi **kelemahan fungsi heuristik AI**, memanfaatkan **asimetri mekanik game**, atau **mengatur parameter settingan (solver configuration)**.

---

### 3.1 Settingan Solver Terbaik (Membuat AI Menjadi Paling Lemah / Mudah Dikalahkan)

Jika Anda ingin NPC mudah dikalahkan melalui konfigurasi panel eksperimen/HUD:

| Parameter | Settingan Paling Lemah (Mudah Dikalahkan) | Alasan Analitis |
| :--- | :--- | :--- |
| **Algorithm** | **Expectimax** atau **Minimax (Depth Rendah)** | Pada Expectimax, NPC berasumsi Player punya risiko meleset $40\%$ pada Heavy Attack, sehingga perhitungannya sering terlalu optimis/kurang berhati-hati. |
| **Max Depth** | **1 atau 2** (*Shallow Horizon*) | Depth 1–2 membuat AI menderita fenomena *Horizon Effect*. AI hanya melihat 1 giliran ke depan dan **buta** terhadap combo serangan balasan Player di giliran ke-3 atau ke-4. |
| **Eval Function** | **AGGRESSIVE** | AI tipe agresif murni hanya mengejar damage ke Player ($100 - HP_{\text{player}}$) tanpa peduli $HP$-nya sendiri. AI ini akan **terus melancarkan `HEAVY_ATTACK`** hingga $HP$-nya sendiri terkuras habis akibat *recoil self-damage* ($10\text{ HP}$ per serangan). |
| **Action Ordering** | **RANDOM** | Memperlambat pencarian dan membuat evaluasi pohon kurang optimal jika dipotong waktu. |

> **Catatan Ujian/Laporan:**  
> Sebaliknya, jika ingin **NPC Terkuat (AI Sempurna / God Mode)**:  
> Gunakan **Alpha-Beta**, **Depth 6–8**, **EvalFunc: WEIGHTED** (menghitung HP + stok Potion + status Defend), dan **ActionOrder: AGGRESSIVE/DEFAULT**.

---

### 3.2 Strategi Bermain Terbaik (Game Mechanics & Exploitation)

Berdasarkan rumus damage pada [`apply_action()`](file:///d:/Tugas/KULIAH/SEMESTER%203/Kecerdasan%20Buatan/Tugas/tubes/infernal-affairs/scripts/battle/MinimaxSolver.gd#L240-L305):

#### 1. Eksploitasi AI "Aggressive" (Trik Recoil Damage)
- **Kelemahan AI:** `HEAVY_ATTACK` memberikan damage 37 tapi memotong 10 HP diri sendiri.
- **Taktik Kita:** Pasang **`DEFEND`** setiap kali darah AI masih banyak atau ketika AI diprediksi akan menyerang berat.
  - Saat kita `DEFEND`, damage `HEAVY_ATTACK` berkurang $30\%$ (dari $37 \to 25$).
  - Tapi AI **tetap menderita recoil $10\text{ HP}$ penuh**.
  - Tukar pukulan ini sangat merugikan AI dalam jangka panjang.

#### 2. Eksploitasi AI "Defensive" (Trik Potion & Heavy Penetration)
- **Kelemahan AI:** AI defensif sangat berfokus menaikkan $HP_{\text{npc}}$. Begitu darahnya berkurang sedikit, ia buru-buru menghabiskan ramuan (`POTION`) atau terus memasang kuda-kuda (`DEFEND`).
- **Taktik Kita:**
  - Jangan pakai `ATTACK` biasa (karena terpotong $50\%$ menjadi $10$ DMG).
  - Gunakan **`HEAVY_ATTACK`** karena serangan ini menembus pertahanan lawan dan memberi $25$–$37$ DMG.
  - Begitu stok 3 botol ramuan AI habis, AI tidak lagi memiliki opsi bertahan yang kuat.

#### 3. Manajemen Potion Efisien
- `POTION` memulihkan **$+30\text{ HP}$**.
- **Aturan Emas:** Jangan minum potion saat $HP > 70$ (agar tidak ada efek *overheal* yang terbuang).
- Minumlah saat $HP \in [30, 60]$. Minum ketika $HP < 25$ sangat berisiko mati instan terkena `HEAVY_ATTACK` ($37$ DMG).

#### 4. Formula Kill-Zone (Finishing Move)
- Jika $HP_{\text{npc}} \le 20$: Cukup gunakan **`ATTACK` biasa** (tanpa recoil, pasti menang jika NPC tidak bertahan).
- Jika $HP_{\text{npc}} \le 37$ dan NPC **tidak** sedang *Defending*: Langsung luncurkan **`HEAVY_ATTACK`** untuk *instant execution* (Game Over seketika).


