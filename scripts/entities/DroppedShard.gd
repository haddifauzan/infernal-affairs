class_name DroppedShardEntity
extends Node2D

## DroppedShardEntity.gd
## Represents an elemental crystal dropped on the overworld ground
## when a courier minion is intercepted by the player or scorched by magma fissures (Tahap 4).

signal collected(shard: DroppedShardEntity, element: String)

var grid_manager: GridManager = null
var grid_pos: Vector2i = Vector2i.ZERO
var element_type: String = "Flame"
var is_collected: bool = false

var sprite: Sprite2D
var shadow: Sprite2D
var float_time: float = 0.0

func initialize(gm: GridManager, pos: Vector2i, elem: String) -> void:
	grid_manager = gm
	grid_pos = pos
	element_type = elem
	z_index = 6

	if grid_manager:
		position = grid_manager.grid_to_world(grid_pos)
	else:
		position = Vector2(pos.x * 32 + 16, pos.y * 32 + 16)

	_setup_visuals()

func _setup_visuals() -> void:
	# Subtle ground shadow
	shadow = Sprite2D.new()
	shadow.name = "Shadow"
	var sh_tex = load("res://assets/sprites/map/obstacles/shadow_oval.png")
	if sh_tex:
		shadow.texture = sh_tex
		shadow.scale = Vector2(0.22, 0.12)
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.45)
		shadow.position = Vector2(0, 8)
		add_child(shadow)

	# Floating crystal sprite
	sprite = Sprite2D.new()
	sprite.name = "CrystalSprite"
	var shard_tex: Texture2D = null
	match element_type.to_lower():
		"shadow", "void":
			shard_tex = load("res://assets/sprites/map/obstacles/shard_shadow.png")
		"blood", "earth", "sanguine":
			shard_tex = load("res://assets/sprites/map/obstacles/shard_blood.png")
		_:
			shard_tex = load("res://assets/sprites/map/obstacles/shard_flame.png")

	if shard_tex:
		sprite.texture = shard_tex
		sprite.scale = Vector2(0.35, 0.35)
	else:
		# Fallback small crystal
		var fallback_tex = load("res://assets/sprites/map/obstacles/crystal_small.png")
		if fallback_tex:
			sprite.texture = fallback_tex
			sprite.scale = Vector2(0.4, 0.4)
			match element_type.to_lower():
				"shadow": sprite.modulate = Color(0.7, 0.2, 1.0)
				"blood":  sprite.modulate = Color(1.0, 0.2, 0.2)
				_:        sprite.modulate = Color(1.0, 0.6, 0.1)

	add_child(sprite)

func _process(delta: float) -> void:
	if is_collected:
		return
	float_time += delta * 4.0
	if sprite:
		sprite.position.y = -6.0 + sin(float_time) * 4.0
		sprite.rotation = sin(float_time * 0.5) * 0.12

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(0.6, 0.6), 0.2)
	tw.tween_property(sprite, "position:y", sprite.position.y - 20.0, 0.25)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)
	collected.emit(self, element_type)

