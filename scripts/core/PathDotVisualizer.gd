class_name PathDotVisualizer
extends Node2D

# Visualisasi garis jejak AI sebagai titik-titik oranye menyala (• • • •)
# menggunakan gambar path_dot.png yang di-stamp berulang di sepanjang jalur

var dot_tex: Texture2D
var dot_spacing: float = 20.0  # jarak antar titik dalam pixel
var dot_scale: float = 0.18    # ukuran dot sedikit lebih besar agar keliatan jelas
var path_points: Array[Vector2] = []

# Pool sprite untuk performa (hindari create/destroy setiap frame)
var dot_pool: Array[Sprite2D] = []

func _ready() -> void:
	dot_tex = load("res://assets/sprites/ui/effects/path_dot.png")
	# Pre-spawn pool awal
	for i in range(200):
		var s = Sprite2D.new()
		s.texture = dot_tex
		s.scale = Vector2(dot_scale, dot_scale)
		s.visible = false
		s.modulate = Color(1.0, 0.65, 0.1, 0.92)  # Oranye menyala
		add_child(s)
		dot_pool.append(s)

func update_path(world_points: Array[Vector2]) -> void:
	path_points = world_points
	_redraw_dots()

func clear_path() -> void:
	path_points = []
	for s in dot_pool:
		s.visible = false

func _redraw_dots() -> void:
	# Sembunyikan semua dulu
	for s in dot_pool:
		s.visible = false

	if path_points.size() < 2:
		return

	# Bangun polyline dari titik-titik path lalu stamp dot di sepanjangnya
	var pool_idx = 0
	var total_dist = 0.0
	var next_dot_dist = dot_spacing / 2.0  # mulai sedikit lebih dekat dari titik awal

	for i in range(1, path_points.size()):
		var from = path_points[i - 1]
		var to   = path_points[i]
		var seg_len = from.distance_to(to)
		var dir = (to - from).normalized()

		while total_dist + seg_len >= next_dot_dist:
			var t = next_dot_dist - total_dist
			var dot_pos = from + dir * t

			if pool_idx < dot_pool.size():
				var sp = dot_pool[pool_idx]
				sp.position = dot_pos
				sp.visible = true
				# Efek fade alpha: titik-titik dekat demon transparan, makin ke player makin solid
				var progress = float(pool_idx) / float(max(1, path_points.size() * 3))
				sp.modulate.a = lerpf(0.3, 0.95, progress)
				pool_idx += 1

			next_dot_dist += dot_spacing

		total_dist += seg_len
