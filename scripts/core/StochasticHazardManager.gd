class_name StochasticHazardManager
extends Node2D

## StochasticHazardManager.gd
## Manages semi-stochastic magma fissure obstacles, visual telegraphing phases,
## player damage/slow effects, courier minion crystal loss, and Bayesian sensor signals.
## Milestone 2 of Infernal Affairs Tahap 4.

signal hazard_phase_changed(new_phase: int)
signal hazard_warning_started(fissure_tiles: Array[Vector2i])
signal hazard_erupted(fissure_tiles: Array[Vector2i])
signal hazard_dormant(fissure_tiles: Array[Vector2i])
signal minion_hazard_scorched(minion: Node2D, tile: Vector2i)
signal player_hazard_damaged(damage: int, tile: Vector2i)

enum HazardPhase {
	DORMANT = 0,    # Safe dark volcanic basalt (3.0 - 5.0s)
	WARNING = 1,    # Glowing orange cracks & sulfur smoke (1.5 - 2.0s) - Sensor W = true
	ERUPTION = 2    # Blazing magma and flame eruption (1.5 - 2.0s) - Lethal hazard
}

# --- Fissure Grid Coordinates: Central Shortcut Bridge over Lava River (y = 30..33, x = 24..27) ---
var fissure_tiles: Array[Vector2i] = [
	Vector2i(24, 30), Vector2i(25, 30), Vector2i(26, 30), Vector2i(27, 30),
	Vector2i(24, 31), Vector2i(25, 31), Vector2i(26, 31), Vector2i(27, 31),
	Vector2i(24, 32), Vector2i(25, 32), Vector2i(26, 32), Vector2i(27, 32),
	Vector2i(24, 33), Vector2i(25, 33), Vector2i(26, 33), Vector2i(27, 33)
]

# --- Timing Configurations ---
@export var dormant_min_time: float = 3.5
@export var dormant_max_time: float = 5.0
@export var warning_time: float = 1.8
@export var eruption_time: float = 1.6

var current_phase: int = HazardPhase.DORMANT
var phase_timer: float = 0.0
var target_phase_duration: float = 4.0
var force_warning_active: bool = false
var force_eruption_active: bool = false

# References
var grid_manager: GridManager = null
var player: Node2D = null
var active_minions: Array = []

# Player damage rate limiter
var player_damage_cooldown: float = 0.0
const PLAYER_LAVA_DAMAGE: int = 12

# Textures
var tex_dormant: Texture2D
var tex_warning: Texture2D
var tex_eruption: Texture2D
var tex_warning_sheet: Texture2D
var tex_eruption_sheet: Texture2D
var pulse_time: float = 0.0

# Sound effects
var sfx_warning_player: AudioStreamPlayer
var sfx_eruption_player: AudioStreamPlayer

func _ready() -> void:
	z_index = 5
	_load_hazard_textures()
	_setup_audio_players()
	_reset_to_dormant()

func _load_hazard_textures() -> void:
	tex_dormant = load("res://assets/sprites/map/hazards/fissure_dormant.png")
	tex_warning = load("res://assets/sprites/map/hazards/fissure_warning.png")
	tex_eruption = load("res://assets/sprites/map/hazards/fissure_eruption.png")
	tex_warning_sheet = load("res://assets/sprites/map/hazards/vfx_warning_crack_sheet.png")
	tex_eruption_sheet = load("res://assets/sprites/map/hazards/vfx_flame_column_sheet.png")

func _setup_audio_players() -> void:
	sfx_warning_player = AudioStreamPlayer.new()
	sfx_warning_player.name = "SFXWarning"
	var warn_stream = load("res://assets/audio/sfx_barrier_activate.wav")
	if warn_stream:
		sfx_warning_player.stream = warn_stream
	sfx_warning_player.volume_db = -6.0
	add_child(sfx_warning_player)

	sfx_eruption_player = AudioStreamPlayer.new()
	sfx_eruption_player.name = "SFXEruption"
	var erupt_stream = load("res://assets/audio/sfx_earth_slam.wav")
	if not erupt_stream:
		erupt_stream = load("res://assets/audio/sfx_void_burst.wav")
	if erupt_stream:
		sfx_eruption_player.stream = erupt_stream
	sfx_eruption_player.volume_db = -2.0
	add_child(sfx_eruption_player)

func initialize(gm: GridManager, p: Node2D) -> void:
	grid_manager = gm
	player = p
	_populate_all_bridge_fissures()
	_setup_world_signposts()
	queue_redraw()

func _populate_all_bridge_fissures() -> void:
	fissure_tiles.clear()
	# Only the Central Shortcut Bridge (x=24..27, y=30..33) contains stochastic eruption fissures!
	# The West and East Safe Viaduct Bridges are 100% free of magma hazards.
	if grid_manager and grid_manager.bridges_info.size() > 0:
		for b in grid_manager.bridges_info:
			var bname: String = str(b.get("name", ""))
			if "Shortcut" in bname or b.x == 24:
				# Place fissures on the central bridge rows (y = 30..33)
				for dy in range(1, b.h - 1):
					for dx in range(b.w):
						fissure_tiles.append(Vector2i(b.x + dx, b.y + dy))
	else:
		# Fallback to central shortcut bridge coordinates
		for y in range(30, 34):
			for x in range(24, 28):
				fissure_tiles.append(Vector2i(x, y))

func _setup_world_signposts() -> void:
	if not grid_manager:
		return
	var ts: float = float(grid_manager.tile_size)

	# 1. Jembatan Tengah (Jalur Pintas Berbahaya - Letupan Magma Stokastik) at (25.5, 28.2)
	_create_signpost("⚡ JALUR PINTAS BERBAHAYA (Jembatan Magma Stokastik) ⚡", Vector2((GridManager.CENTER_X + 0.5) * ts, 28.2 * ts), Color(1.0, 0.45, 0.15))

	# 2. Jembatan Sayap Barat (Jalur Utama Aman) at (8.0, 28.2)
	_create_signpost("🛡 JALUR UTAMA BARAT (Viaduct Batu Aman) 🛡", Vector2(8.0 * ts, 28.2 * ts), Color(0.3, 1.0, 0.7))

	# 3. Jembatan Sayap Timur (Jalur Utama Aman) at (44.0, 28.2)
	_create_signpost("🛡 JALUR UTAMA TIMUR (Viaduct Batu Aman) 🛡", Vector2(44.0 * ts, 28.2 * ts), Color(0.3, 1.0, 0.7))

	# 4. Simpang Lembah (Titik Keputusan MDP s1) at (25.5, 41.5)
	_create_signpost("⮁ SIMPANG LEMBAH (Titik Keputusan MDP s1) ⮁", Vector2((GridManager.CENTER_X + 0.5) * ts, 41.5 * ts), Color(1.0, 0.9, 0.3))

	# 5. Sacred Well Sanctuary (Kuil Tiga Altar Elemen) at (25.5, 52.5)
	_create_signpost("✨ SACRED WELL SANCTUARY (Area Altar Elemen s0) ✨", Vector2((GridManager.CENTER_X + 0.5) * ts, 52.5 * ts), Color(1.0, 0.55, 0.8))

func _create_signpost(text: String, world_pos: Vector2, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(world_pos.x - 120.0, world_pos.y)
	label.size = Vector2(240.0, 16.0)
	label.z_index = 6
	add_child(label)

func register_minion(minion: Node2D) -> void:
	if not active_minions.has(minion):
		active_minions.append(minion)

func unregister_minion(minion: Node2D) -> void:
	active_minions.erase(minion)

func _process(delta: float) -> void:
	pulse_time += delta
	if player_damage_cooldown > 0.0:
		player_damage_cooldown -= delta

	# Process phase transition
	if not force_warning_active and not force_eruption_active:
		phase_timer += delta
		if phase_timer >= target_phase_duration:
			phase_timer = 0.0
			_advance_phase()
	elif force_eruption_active and current_phase != HazardPhase.ERUPTION:
		_set_phase(HazardPhase.ERUPTION)
	elif force_warning_active and current_phase != HazardPhase.WARNING:
		_set_phase(HazardPhase.WARNING)

	# Redraw animated hazard visuals
	queue_redraw()

	# Check hazards collision in overworld
	_check_collisions(delta)

func _advance_phase() -> void:
	match current_phase:
		HazardPhase.DORMANT:
			_set_phase(HazardPhase.WARNING)
		HazardPhase.WARNING:
			_set_phase(HazardPhase.ERUPTION)
		HazardPhase.ERUPTION:
			_set_phase(HazardPhase.DORMANT)

func _set_phase(new_phase: int) -> void:
	current_phase = new_phase
	phase_timer = 0.0

	match current_phase:
		HazardPhase.DORMANT:
			target_phase_duration = randf_range(dormant_min_time, dormant_max_time)
			hazard_dormant.emit(fissure_tiles)
		HazardPhase.WARNING:
			target_phase_duration = warning_time
			if sfx_warning_player and sfx_warning_player.stream:
				sfx_warning_player.play()
			hazard_warning_started.emit(fissure_tiles)
		HazardPhase.ERUPTION:
			target_phase_duration = eruption_time
			if sfx_eruption_player and sfx_eruption_player.stream:
				sfx_eruption_player.play()
			hazard_erupted.emit(fissure_tiles)

	hazard_phase_changed.emit(current_phase)

func _reset_to_dormant() -> void:
	_set_phase(HazardPhase.DORMANT)

## Evaluates whether sensor signal W is active for minion Bayes update:
## Triggered if fissures are warning/erupting OR if player is bluffing at chokepoint.
func is_hazard_signal_active(minion_pos: Vector2i = Vector2i.ZERO) -> bool:
	if force_warning_active or force_eruption_active:
		return true

	# Physical magma warning or eruption in progress
	if current_phase == HazardPhase.WARNING or current_phase == HazardPhase.ERUPTION:
		return true

	# Check Player Bluffing presence near the chokepoint
	if is_player_bluffing():
		return true

	return false

## Player Bluffing: Standing on or directly guarding the Central Shortcut Bridge
func is_player_bluffing() -> bool:
	if not is_instance_valid(player) or not ("grid_pos" in player):
		return false
	var p_pos: Vector2i = player.grid_pos
	# On or near the Central Shortcut Bridge (x: 23..28, y: 28..35)
	return (p_pos.x >= 23 and p_pos.x <= 28 and p_pos.y >= 28 and p_pos.y <= 35)

func _check_collisions(_delta: float) -> void:
	if current_phase != HazardPhase.ERUPTION:
		return

	# 1. Player check
	if is_instance_valid(player) and ("grid_pos" in player):
		var p_pos: Vector2i = player.grid_pos
		if fissure_tiles.has(p_pos) and player_damage_cooldown <= 0.0:
			player_damage_cooldown = 0.8
			_apply_player_lava_damage(p_pos)

	# 2. Minion courier check
	for m in active_minions:
		if is_instance_valid(m) and ("grid_pos" in m) and not m.is_defeated:
			var m_pos: Vector2i = m.grid_pos
			if fissure_tiles.has(m_pos):
				_apply_minion_scorched(m, m_pos)

func _apply_player_lava_damage(tile: Vector2i) -> void:
	if not is_instance_valid(player):
		return

	# Apply damage
	if "current_hp" in player:
		player.current_hp = max(1, player.current_hp - PLAYER_LAVA_DAMAGE)
	if player.has_method("take_damage"):
		player.take_damage(PLAYER_LAVA_DAMAGE)

	# Slow effect
	if "move_speed" in player:
		var orig_speed = player.move_speed
		player.move_speed = orig_speed * 0.5
		var t = get_tree().create_timer(1.0)
		t.timeout.connect(func(): if is_instance_valid(player) and "move_speed" in player: player.move_speed = orig_speed)

	# Play hurt sound
	if sfx_eruption_player:
		sfx_eruption_player.play()

	player_hazard_damaged.emit(PLAYER_LAVA_DAMAGE, tile)

func _apply_minion_scorched(minion: Node2D, tile: Vector2i) -> void:
	if minion.has_method("on_hazard_scorched"):
		minion.on_hazard_scorched()
	minion_hazard_scorched.emit(minion, tile)

func _draw() -> void:
	if not grid_manager:
		return

	var ts: float = float(grid_manager.tile_size)

	# 1. Base tile rendering for all bridge tiles
	for tile in fissure_tiles:
		var world_x: float = tile.x * ts
		var world_y: float = tile.y * ts
		var rect = Rect2(world_x, world_y, ts, ts)

		match current_phase:
			HazardPhase.DORMANT:
				if tex_dormant:
					# Subtle dormant basalt fissures over stone pavers
					draw_texture_rect(tex_dormant, rect, false, Color(1.0, 1.0, 1.0, 0.45))
				else:
					draw_rect(rect, Color(0.15, 0.12, 0.15, 0.45))

			HazardPhase.WARNING:
				if tex_warning_sheet:
					# 4 frames warning animation (32x32 per frame)
					var frame_idx = int(fmod(pulse_time * 6.0 + (tile.x + tile.y), 4.0))
					var src_rect = Rect2(frame_idx * 32.0, 0.0, 32.0, 32.0)
					var glow: float = 0.85 + sin(pulse_time * 8.0) * 0.15
					draw_texture_rect_region(tex_warning_sheet, rect, src_rect, Color(1.0, 1.0, 1.0, glow))
				elif tex_warning:
					# Pulsing hot warning glow fallback
					var glow: float = 0.85 + sin(pulse_time * 8.0) * 0.15
					draw_texture_rect(tex_warning, rect, false, Color(1.0, 1.0, 1.0, glow))
				else:
					var warn_color = Color(1.0, 0.5, 0.1, 0.7 + sin(pulse_time * 6.0) * 0.3)
					draw_rect(rect, warn_color)

			HazardPhase.ERUPTION:
				if tex_eruption_sheet:
					# 6 frames vertical flame geyser animation (32x64 per frame)
					var frame_idx = int(fmod(pulse_time * 12.0 + (tile.x * 2 + tile.y), 6.0))
					var src_rect = Rect2(frame_idx * 32.0, 0.0, 32.0, 64.0)
					var erupt_rect = Rect2(world_x, world_y - 32.0, ts, ts + 32.0)
					var flicker = Color(1.0, 0.95 + sin(pulse_time * 20.0 + tile.x) * 0.05, 0.85 + cos(pulse_time * 16.0) * 0.15)
					draw_texture_rect_region(tex_eruption_sheet, erupt_rect, src_rect, flicker)
				elif tex_eruption:
					# Taller fiery erupting column extending above the bridge tile fallback
					var erupt_rect = Rect2(world_x, world_y - 14.0, ts, ts + 14.0)
					var flicker = Color(1.0, 0.9 + sin(pulse_time * 16.0 + tile.x * 0.5) * 0.1, 0.8 + cos(pulse_time * 14.0 + tile.y) * 0.2)
					draw_texture_rect(tex_eruption, erupt_rect, false, flicker)
				else:
					draw_rect(rect, Color(1.0, 0.2, 0.0, 0.95))

	# 2. Continuous Bridge Fiery Aura & Inferno Effects across the Central Shortcut Bridge
	# NOTE: The outer roads and side bridges are safe zones and do not glow with magma hazard.
	var shortcut_bx: float = 24.0 * ts
	var shortcut_by: float = 29.0 * ts
	var shortcut_bw: float = 4.0 * ts
	var shortcut_bh: float = 6.0 * ts
	if grid_manager and grid_manager.bridges_info.size() > 0:
		for b in grid_manager.bridges_info:
			var bname: String = str(b.get("name", ""))
			if "Shortcut" in bname or b.x == 24:
				shortcut_bx = float(b.x) * ts
				shortcut_by = float(b.y) * ts
				shortcut_bw = float(b.w) * ts
				shortcut_bh = float(b.h) * ts
				break

	if current_phase == HazardPhase.WARNING:
		# Ambient orange heat shimmer confined strictly to the Central Shortcut Bridge
		var warn_glow = 0.22 + sin(pulse_time * 7.0) * 0.08
		draw_rect(Rect2(shortcut_bx, shortcut_by, shortcut_bw, shortcut_bh), Color(1.0, 0.45, 0.05, warn_glow), true)
	elif current_phase == HazardPhase.ERUPTION:
		# Blazing fiery sea of inferno confined strictly to the Central Shortcut Bridge
		var erupt_glow = 0.38 + sin(pulse_time * 18.0) * 0.10
		draw_rect(Rect2(shortcut_bx, shortcut_by - 6.0, shortcut_bw, shortcut_bh + 6.0), Color(1.0, 0.25, 0.0, erupt_glow), true)
		# Roaring bright golden core along the central bridge axis
		var core_flicker = 0.50 + cos(pulse_time * 22.0) * 0.15
		draw_rect(Rect2(shortcut_bx + 0.5 * ts, shortcut_by, shortcut_bw - 1.0 * ts, shortcut_bh), Color(1.0, 0.85, 0.25, core_flicker), true)

