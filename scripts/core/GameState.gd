class_name GameStateManager
extends Node

## Singleton autoload for centralized player progression state.
## Tracks level, experience, health, inventory, and quest flags.

signal level_changed(new_level: int)
signal exp_changed(new_exp: int)
signal hp_changed(new_hp: int)
signal key_obtained
signal gate_unlocked
signal player_died

# --- Player Stats ---
var level: int = 1
var exp: int = 0
var hp: int = 100
var max_hp: int = 100
var potions: int = 1
var attack: int = 12
var defense: int = 5

# --- Progression Flags & CSP Requirements ---
var has_castle_key: bool = false
var gate_is_open: bool = false
var boss_defeated: bool = false
var guard_defeated: bool = false
var gate_req_level: int = 2

# --- Constants ---
const EXP_PER_LEVEL: int = 100
const MAX_LEVEL: int = 3
const MINION_EXP_REWARD: int = 50
const MINION_POTION_DROP_CHANCE: float = 0.35

# --- Level-Up Stat Bonuses ---
const LEVEL_BONUSES: Dictionary = {
	2: {"max_hp": 130, "attack": 18, "defense": 8},
	3: {"max_hp": 160, "attack": 24, "defense": 12}
}

func _ready() -> void:
	reset_state()

func reset_state() -> void:
	level = 1
	exp = 0
	hp = 100
	max_hp = 100
	potions = 1
	attack = 12
	defense = 5
	has_castle_key = false
	gate_is_open = false
	boss_defeated = false
	guard_defeated = false

## Award EXP from defeating a minion. Returns true if leveled up.
func award_minion_exp() -> bool:
	var leveled_up := false

	# Award EXP
	exp += MINION_EXP_REWARD
	exp_changed.emit(exp)

	# Random potion drop
	if randf() < MINION_POTION_DROP_CHANCE:
		potions += 1

	# Check level up
	if exp >= EXP_PER_LEVEL and level < MAX_LEVEL:
		_level_up()
		leveled_up = true

	return leveled_up

## Level up from defeating the guard. Grants castle key.
func award_guard_victory() -> void:
	guard_defeated = true
	has_castle_key = true
	key_obtained.emit()

	if level < MAX_LEVEL:
		_level_up()

	# Open the gate
	gate_is_open = true
	gate_unlocked.emit()

## Mark the boss as defeated (victory condition).
func award_boss_victory() -> void:
	boss_defeated = true

## Check if player meets the minimum level to challenge the guard.
func can_challenge_guard() -> bool:
	return level >= gate_req_level

## Check if player can enter the castle (gate must be open).
func can_enter_castle() -> bool:
	return gate_is_open and has_castle_key

## Heal the player using a potion. Returns true if successful.
func use_potion() -> bool:
	if potions <= 0:
		return false
	potions -= 1
	hp = mini(hp + 30, max_hp)
	hp_changed.emit(hp)
	return true

## Take damage. Returns true if player died.
func take_damage(amount: int) -> bool:
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp)
	if hp <= 0:
		player_died.emit()
		return true
	return false

func _level_up() -> void:
	level += 1
	exp = 0
	exp_changed.emit(exp)

	# Apply stat bonuses
	if LEVEL_BONUSES.has(level):
		var bonus: Dictionary = LEVEL_BONUSES[level]
		max_hp = bonus.get("max_hp", max_hp)
		attack = bonus.get("attack", attack)
		defense = bonus.get("defense", defense)

	# Full heal on level up
	hp = max_hp
	hp_changed.emit(hp)
	level_changed.emit(level)

## Get a summary dictionary for debug HUD display.
func get_status_summary() -> Dictionary:
	return {
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"exp": exp,
		"exp_needed": EXP_PER_LEVEL,
		"potions": potions,
		"attack": attack,
		"defense": defense,
		"has_key": has_castle_key,
		"gate_open": gate_is_open,
		"guard_defeated": guard_defeated,
		"boss_defeated": boss_defeated
	}
