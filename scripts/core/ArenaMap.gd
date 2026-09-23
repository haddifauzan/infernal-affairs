class_name ArenaMap
extends Node2D

# Tekstur lingkungan
var ground_tex: Texture2D
var lava_pool_large_tex: Texture2D
var lava_pool_medium_tex: Texture2D

# Potongan sungai resmi dari lava_tileset.png yang sudah diekstrak & disempurnakan
var river_v_tex: Texture2D
var river_h_tex: Texture2D
var river_c_bl_tex: Texture2D
var river_c_br_tex: Texture2D

# Tekstur rintangan
var rock_large_tex: Texture2D
var rock_medium_tex: Texture2D
var rock_small_tex: Texture2D
var crystal_large_tex: Texture2D
var crystal_small_tex: Texture2D
var tree_large_tex: Texture2D
var tree_medium_tex: Texture2D
var tree_stump_tex: Texture2D
var shadow_tex: Texture2D

var grid_manager: GridManager
var tile_size: int = 32
var rng := RandomNumberGenerator.new()

var spawned_nodes: Array[Node2D] = []

func _ready() -> void:
	_load_textures()

func _load_textures() -> void:
	ground_tex           = load("res://assets/sprites/map/ground/ground_texture.png")
	lava_pool_large_tex  = load("res://assets/sprites/map/lava/lava_pool_large.png")
	lava_pool_medium_tex = load("res://assets/sprites/map/lava/lava_pool_medium.png")

	# Sungai vertikal & horizontal tanpa celah transparan
	river_v_tex          = load("res://assets/sprites/map/lava/extracted/river_v.png")
	river_h_tex          = load("res://assets/sprites/map/lava/extracted/river_h.png")

	# Sudut Bawah-Kiri (Menyambungkan Atas ke Kanan)
	river_c_bl_tex       = load("res://assets/sprites/map/lava/extracted/river_c_right_to_up.png")
	# Sudut Bawah-Kanan (Menyambungkan Kiri ke Atas)
	river_c_br_tex       = load("res://assets/sprites/map/lava/extracted/river_c_left_to_up.png")

	rock_large_tex       = load("res://assets/sprites/map/obstacles/rock_large.png")
	rock_medium_tex      = load("res://assets/sprites/map/obstacles/rock_medium.png")
	rock_small_tex       = load("res://assets/sprites/map/obstacles/rock_small.png")
	crystal_large_tex    = load("res://assets/sprites/map/obstacles/crystal_large.png")
	crystal_small_tex    = load("res://assets/sprites/map/obstacles/crystal_small.png")
	tree_large_tex       = load("res://assets/sprites/map/obstacles/tree_large.png")
	tree_medium_tex      = load("res://assets/sprites/map/obstacles/tree_medium.png")
	tree_stump_tex       = load("res://assets/sprites/map/obstacles/tree_stump.png")
	shadow_tex           = load("res://assets/sprites/map/obstacles/shadow_oval.png")

func build_map(gm: GridManager) -> void:
	grid_manager = gm
	tile_size = gm.tile_size
	rng.randomize()

	# Bersihkan objek lama
	for node in spawned_nodes:
		if is_instance_valid(node):
			node.queue_free()
	spawned_nodes.clear()

	# Gambar kanvas dasar
	queue_redraw()

	# Pasang pagar batu jembatan, kawah lahar, dan tebing gua
	_spawn_visual_elements()

func _draw() -> void:
	if not grid_manager or grid_manager.grid.is_empty():
		return

	var w = grid_manager.width
	var h = grid_manager.height
	var ts = float(tile_size)

	# 1. LANTAI UTAMA VULKANIK (Seamless Ground di Seluruh Peta & Jembatan)
	if ground_tex:
		var gw = ground_tex.get_width()
		var gh = ground_tex.get_height()
		for y in range(h):
			for x in range(w):
				var rx = x * ts
				var ry = y * ts
				var rect = Rect2(rx, ry, ts, ts)
				var src_x = int(fmod(rx, gw))
				var src_y = int(fmod(ry, gh))
				draw_texture_rect_region(ground_tex, rect, Rect2(src_x, src_y, ts, ts))
		# Lapisan ambient tint tipis agar tanah sedikit lebih redup (kontras latar belakang)
		draw_rect(Rect2(0, 0, w * ts, h * ts), Color(0.02, 0.01, 0.02, 0.26), true)
	else:
		draw_rect(Rect2(0, 0, w * ts, h * ts), Color("#1b1816"), true)

	# 2. GAMBAR SUNGAI LAVA RESMI DARI LAVA_TILESET.PNG
	# (Jembatan dibiarkan kosong agar ground_texture di bawahnya tampil utuh sebagai jembatan alami)

	# a. Sungai Barat (x=13..14):
	# - Atas ke Jembatan Barat 1 (y=1..5)
	_draw_vertical_river(13, 1, 5)
	# - Antara Jembatan Barat 1 dan 2 (y=8..12)
	_draw_vertical_river(13, 8, 12)
	# - Dari Jembatan Barat 2 ke Sudut Bawah (y=15..18)
	_draw_vertical_river(13, 15, 18)

	# b. Sudut Bawah-Kiri: Menikung dari Atas ke Kanan (Skala proporsional 97x82 px)
	if river_c_bl_tex:
		var corner_x = 13.0 * ts
		var corner_y = (19.0 + 2.0) * ts - 82.0
		draw_texture_rect(river_c_bl_tex, Rect2(corner_x, corner_y, 97.0, 82.0), false)

	# c. Sungai Bawah Horizontal (y=19..20):
	# - Dari Sudut Kiri ke Jembatan Selatan (x=16..20)
	_draw_horizontal_river(19, 16, 20)
	# - Dari Jembatan Selatan ke Sudut Kanan (x=23..28)
	_draw_horizontal_river(19, 23, 28)

	# d. Sudut Bawah-Kanan: Menikung dari Kiri ke Atas (Skala proporsional 97x82 px)
	if river_c_br_tex:
		var corner_x = (29.0 + 2.0) * ts - 97.0
		var corner_y = (19.0 + 2.0) * ts - 82.0
		draw_texture_rect(river_c_br_tex, Rect2(corner_x, corner_y, 97.0, 82.0), false)

	# e. Sungai Timur (x=29..30):
	# - Atas ke Jembatan Timur 1 (y=1..5)
	_draw_vertical_river(29, 1, 5)
	# - Antara Jembatan Timur 1 dan 2 (y=8..12)
	_draw_vertical_river(29, 8, 12)
	# - Dari Jembatan Timur 2 ke Sudut Bawah (y=15..18)
	_draw_vertical_river(29, 15, 18)

func _draw_vertical_river(col_x: int, start_y: int, end_y: int) -> void:
	if not river_v_tex:
		return
	var ts = float(tile_size)
	var rx = col_x * ts
	var channel_w = ts * 2.0 # 64 px
	var tex_w = river_v_tex.get_width()
	var tex_h = river_v_tex.get_height()

	var curr_y = start_y * ts
	var end_px = (end_y + 1) * ts

	while curr_y < end_px:
		var slice_h = min(tex_h, end_px - curr_y)
		var dest_rect = Rect2(rx, curr_y, channel_w, slice_h)
		var src_rect  = Rect2(0, 0, tex_w, slice_h)
		draw_texture_rect_region(river_v_tex, dest_rect, src_rect)
		curr_y += slice_h

func _draw_horizontal_river(row_y: int, start_x: int, end_x: int) -> void:
	if not river_h_tex:
		return
	var ts = float(tile_size)
	var ry = row_y * ts
	var channel_h = ts * 2.0 # 64 px
	var tex_w = river_h_tex.get_width()
	var tex_h = river_h_tex.get_height()

	var curr_x = start_x * ts
	var end_px = (end_x + 1) * ts

	while curr_x < end_px:
		var slice_w = min(tex_w, end_px - curr_x)
		var dest_rect = Rect2(curr_x, ry, slice_w, channel_h)
		var src_rect  = Rect2(0, 0, slice_w, tex_h)
		draw_texture_rect_region(river_h_tex, dest_rect, src_rect)
		curr_x += slice_w

func _spawn_visual_elements() -> void:
	if not grid_manager:
		return

	var w = grid_manager.width
	var h = grid_manager.height
	var ts = float(tile_size)

	# 1. JEMBATAN: BERJAJAR BATU KECIL (ROCK_SMALL) DI KEDUA SISINYA (TEPAT 3 BATU PER JAJAR)
	for b in grid_manager.bridges_info:
		var bx = b.x
		var by = b.y
		var bw = b.w
		var bh = b.h
		var orient = b.orientation

		if orient == "horizontal":
			# Jembatan horizontal menyeberangi sungai vertikal
			# 3 batu kecil per jajar di sisi ATAS (y = by) dan BAWAH (y = by + bh)
			var x_positions = [
				(bx + 0.22) * ts,
				(bx + 1.00) * ts,
				(bx + 1.78) * ts
			]
			for px in x_positions:
				# Pagar atas (menghadap lahar utara)
				_spawn_single_prop(rock_small_tex, Vector2(px, (by + 0.08) * ts), 0.32, by - 1, Color(1.25, 1.18, 1.10))
				# Pagar bawah (menghadap lahar selatan)
				_spawn_single_prop(rock_small_tex, Vector2(px, (by + bh - 0.08) * ts), 0.32, by + bh, Color(1.25, 1.18, 1.10))
		else:
			# Jembatan vertikal menyeberangi sungai horizontal (Jembatan Selatan)
			# 3 batu kecil per jajar di sisi KIRI dan KANAN jembatan
			var y_positions = [
				(by + 0.22) * ts,
				(by + 1.00) * ts,
				(by + 1.78) * ts
			]
			for py in y_positions:
				# Pagar kiri (menghadap lahar barat)
				_spawn_single_prop(rock_small_tex, Vector2((bx + 0.08) * ts, py), 0.32, by, Color(1.25, 1.18, 1.10))
				# Pagar kanan (menghadap lahar timur)
				_spawn_single_prop(rock_small_tex, Vector2((bx + bw - 0.08) * ts, py), 0.32, by, Color(1.25, 1.18, 1.10))

	# 2. PASANG 2 KAWAH LAVA BULAT ALAMI (2x2)
	for pc in grid_manager.pool_centers:
		if lava_pool_large_tex:
			var pool_sprite = Sprite2D.new()
			pool_sprite.texture = lava_pool_large_tex
			pool_sprite.position = Vector2((pc.x + 1) * ts, (pc.y + 1) * ts)
			pool_sprite.scale = Vector2(0.42, 0.42)
			pool_sprite.z_index = 0
			add_child(pool_sprite)
			spawned_nodes.append(pool_sprite)

	# 3. PASANG TEBING GUA BATAS PETA & RINTANGAN RERUNTUHAN
	for y in range(h):
		for x in range(w):
			var tile_type = grid_manager.grid[y][x]
			var is_border = (x == 0 or x == w - 1 or y == 0 or y == h - 1)

			if tile_type == GridManager.TileType.OBSTACLE:
				if is_border:
					var roll = rng.randf()
					var tex = rock_large_tex if roll < 0.55 else (tree_large_tex if roll < 0.8 else rock_medium_tex)
					var sc = rng.randf_range(0.60, 0.75)
					var mod_c = Color(1.24, 1.14, 1.05) if tex == tree_large_tex else Color(1.20, 1.12, 1.05)
					_spawn_single_prop(tex, Vector2((x + 0.5) * ts, (y + 0.4) * ts), sc, y, mod_c)
				else:
					# Jika petak ini adalah pohon mandiri, lewati (akan di-spawn khusus di bawah)
					if grid_manager.tree_positions.has(Vector2i(x, y)):
						continue

					var roll = rng.randf()
					if roll < 0.30:
						_spawn_single_prop(rock_large_tex, Vector2((x + 0.5) * ts, (y + 0.35) * ts), 0.52, y, Color(1.22, 1.14, 1.06))
					elif roll < 0.52:
						_spawn_single_prop(crystal_large_tex, Vector2((x + 0.5) * ts, (y + 0.30) * ts), 0.48, y, Color(1.20, 1.15, 1.15))
					elif roll < 0.70:
						_spawn_single_prop(rock_medium_tex, Vector2((x + 0.5) * ts, (y + 0.40) * ts), 0.42, y, Color(1.20, 1.12, 1.05))
					elif roll < 0.82:
						_spawn_single_prop(crystal_small_tex, Vector2((x + 0.5) * ts, (y + 0.45) * ts), 0.35, y, Color(1.25, 1.18, 1.18))
					elif roll < 0.92:
						_spawn_single_prop(tree_medium_tex, Vector2((x + 0.5) * ts, (y + 0.38) * ts), 0.46, y, Color(1.26, 1.14, 1.04))
					else:
						_spawn_single_prop(tree_stump_tex, Vector2((x + 0.5) * ts, (y + 0.45) * ts), 0.40, y, Color(1.22, 1.12, 1.04))

	# 4. PASANG RINTANGAN POHON NERAKA MANDIRI DI AREA KOSONG
	for tp in grid_manager.tree_positions:
		var roll = rng.randf()
		var tree_tex: Texture2D = tree_large_tex if roll < 0.6 else tree_medium_tex
		var tree_sc: float = 0.55 if roll < 0.6 else 0.48
		var y_off: float   = 0.30 if roll < 0.6 else 0.36
		_spawn_single_prop(tree_tex, Vector2((tp.x + 0.5) * ts, (tp.y + y_off) * ts), tree_sc, tp.y, Color(1.26, 1.14, 1.04))

func _spawn_single_prop(tex: Texture2D, pos: Vector2, sc: float, row_y: int, custom_modulate: Color = Color(1.18, 1.12, 1.06)) -> void:
	if not tex:
		return

	# 1. Bayangan dasar (Drop Shadow) agar rintangan terangkat dari lantai & kontrasnya tegas
	if shadow_tex:
		var shadow = Sprite2D.new()
		shadow.texture = shadow_tex
		# Posisi bayangan di dasar/kaki rintangan
		var shadow_y_offset = (tex.get_height() * 0.38) * sc
		shadow.position = Vector2(pos.x, pos.y + shadow_y_offset)
		# Skala bayangan proporsional terhadap ukuran prop
		var shadow_w_ratio = (tex.get_width() * sc) / float(shadow_tex.get_width())
		shadow.scale = Vector2(shadow_w_ratio * 0.85, shadow_w_ratio * 0.45)
		shadow.modulate = Color(1.0, 1.0, 1.0, 0.85)
		shadow.z_index = max(1, row_y) # Di atas lantai (0), di bawah prop
		add_child(shadow)
		spawned_nodes.append(shadow)

	# 2. Sprite rintangan utama dengan modulate kontras/kecerahan
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	spr.scale = Vector2(sc, sc)
	spr.modulate = custom_modulate
	spr.z_index = row_y + 1
	add_child(spr)
	spawned_nodes.append(spr)
