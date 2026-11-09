class_name ResourceNodeEntity
extends Node2D

## ResourceNodeEntity.gd
## Represents an Elemental Altar / Shard Node in the Wilderness (Tahap 4).
## Minions harvest elemental resources here to supply the Guard and Boss.

signal shard_harvested(node: ResourceNodeEntity, remaining: int)
signal node_replenished(node: ResourceNodeEntity)

@export var element_type: String = "Flame" # "Flame", "Shadow", "Blood"
@export var node_name: String = "Ignis Altar"
@export var grid_pos: Vector2i = Vector2i.ZERO
@export var max_shards: int = 3
@export var current_shards: int = 3

var grid_manager: GridManager = null

# Timers
var replenish_interval: float = 25.0
var replenish_timer: float = 0.0

# Visual Components
var crystal_sprite: Sprite2D = null
var aura_sprite: Sprite2D = null
var info_label: Label = null
var pulse_time: float = 0.0

func initialize(gm: GridManager, pos: Vector2i, elem: String, altar_name: String) -> void:
	grid_manager = gm
	grid_pos = pos
	element_type = elem
	node_name = altar_name
	current_shards = max_shards

	if grid_manager:
		position = grid_manager.grid_to_world(grid_pos)
	else:
		position = Vector2(grid_pos.x * 32 + 16, grid_pos.y * 32 + 16)

	_setup_visuals()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if not crystal_sprite:
		_setup_visuals()

func _setup_visuals() -> void:
	# Y-sorting
	z_index = int(position.y)

	var elem_color: Color = _get_element_color()

	# 1. Aura glow behind altar
	if not aura_sprite:
		aura_sprite = Sprite2D.new()
		aura_sprite.name = "AuraGlow"
		var aura_tex = load("res://assets/sprites/ui/effects/aura_demon.png")
		if aura_tex:
			aura_sprite.texture = aura_tex
		aura_sprite.scale = Vector2(0.35, 0.20)
		aura_sprite.position = Vector2(0, 8)
		aura_sprite.z_index = -1
		add_child(aura_sprite)
	aura_sprite.modulate = Color(elem_color.r, elem_color.g, elem_color.b, 0.45)

	# 2. Main Altar Structure (Tahap 4)
	if not crystal_sprite:
		crystal_sprite = Sprite2D.new()
		crystal_sprite.name = "CrystalSprite"
		add_child(crystal_sprite)

	var altar_tex: Texture2D = null
	match element_type.to_lower():
		"flame", "fire":
			altar_tex = load("res://assets/sprites/map/obstacles/altar_ignis.png")
		"shadow", "void", "dark":
			altar_tex = load("res://assets/sprites/map/obstacles/altar_abyssal.png")
		"blood", "sanguine", "earth":
			altar_tex = load("res://assets/sprites/map/obstacles/altar_sanguine.png")

	if altar_tex:
		crystal_sprite.texture = altar_tex
		crystal_sprite.scale = Vector2(0.20, 0.20)
		crystal_sprite.position = Vector2(0, -12)
		crystal_sprite.modulate = Color(1.0, 1.0, 1.0)
	else:
		var crystal_tex = load("res://assets/sprites/map/obstacles/crystal_large.png")
		if crystal_tex:
			crystal_sprite.texture = crystal_tex
		crystal_sprite.scale = Vector2(0.42, 0.42)
		crystal_sprite.position = Vector2(0, -10)
		crystal_sprite.modulate = elem_color

	# 3. Label Badge
	if not info_label:
		info_label = Label.new()
		info_label.name = "InfoLabel"
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.add_theme_font_size_override("font_size", 8)
		info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		info_label.add_theme_constant_override("shadow_offset_x", 1)
		info_label.add_theme_constant_override("shadow_offset_y", 1)
		info_label.position = Vector2(-60, -42)
		info_label.size = Vector2(120, 16)
		add_child(info_label)
	info_label.add_theme_color_override("font_color", elem_color)

	_update_label()

func _get_element_color() -> Color:
	match element_type.to_lower():
		"shadow", "dark", "void":
			return Color(0.75, 0.25, 1.0) # Purple
		"blood", "sanguine", "earth":
			return Color(0.95, 0.15, 0.25) # Crimson
		_:
			return Color(1.0, 0.50, 0.15) # Flame Orange

func _update_label() -> void:
	if is_instance_valid(info_label):
		if current_shards <= 0:
			info_label.text = "%s\n[⚠ 0/%d Kosong]" % [node_name, max_shards]
			info_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		else:
			info_label.text = "%s\n[✦ %d/%d Shards]" % [node_name, current_shards, max_shards]
			info_label.add_theme_color_override("font_color", _get_element_color())

func _process(delta: float) -> void:
	# Subtle floating & pulsing VFX
	pulse_time += delta * 2.5
	if is_instance_valid(crystal_sprite):
		crystal_sprite.position.y = -10.0 + sin(pulse_time) * 2.0
	if is_instance_valid(aura_sprite):
		var pulse_scale = 1.0 + sin(pulse_time * 1.5) * 0.08
		aura_sprite.scale = Vector2(0.35, 0.20) * pulse_scale

	# Replenishment timer if depleted
	if current_shards < max_shards:
		replenish_timer += delta
		if replenish_timer >= replenish_interval:
			replenish_timer = 0.0
			current_shards = mini(max_shards, current_shards + 1)
			_update_label()
			node_replenished.emit(self)

## Minion harvests 1 shard. Returns true if successful.
func harvest_shard() -> bool:
	if current_shards > 0:
		current_shards -= 1
		_update_label()
		shard_harvested.emit(self, current_shards)

		# Visual feedback: flash crystal
		if is_instance_valid(crystal_sprite):
			var tw = create_tween()
			tw.tween_property(crystal_sprite, "modulate:a", 0.3, 0.15)
			tw.tween_property(crystal_sprite, "modulate:a", 1.0, 0.25)

		return true
	return false

func has_resources() -> bool:
	return current_shards > 0

