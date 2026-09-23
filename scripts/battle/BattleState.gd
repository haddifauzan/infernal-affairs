## BattleState.gd
## ──────────────────────────────────────────────────────────────────────────────
## Formal definition of the battle search problem:
##
##   State   S = (player_hp, npc_hp, player_potions, npc_potions,
##                player_defending, npc_defending, turn, turn_count)
##
##   Actions A = { ATTACK, HEAVY_ATTACK, DEFEND, POTION }   (branching ≤ 4)
##
##   Terminal Test:
##       player_hp ≤ 0  → NPC wins
##       npc_hp    ≤ 0  → Player wins
##       turn_count ≥ MAX_TURNS → Draw
##
##   Utility  U(S, NPC):
##       +WIN_SCORE if NPC wins, -WIN_SCORE if Player wins, 0 if draw
##
## This file is a pure data class — no Godot node dependencies.
## ──────────────────────────────────────────────────────────────────────────────
class_name BattleState
extends RefCounted

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
const MAX_HP:        int = 100
const MAX_POTIONS:   int = 3
const MAX_TURNS:     int = 40     ## Safety ceiling — prevents infinite trees
const WIN_SCORE:     int = 10000  ## Terminal utility magnitude

## Turn identifiers
enum Turn { PLAYER = 0, NPC = 1 }

# ─────────────────────────────────────────────────────────────────────────────
# STATE FIELDS
# ─────────────────────────────────────────────────────────────────────────────
var player_hp:        int  = MAX_HP
var npc_hp:           int  = MAX_HP
var player_potions:   int  = MAX_POTIONS
var npc_potions:      int  = MAX_POTIONS
var player_defending: bool = false   ## One-turn buff; cleared at start of attacker's next turn
var npc_defending:    bool = false
var turn:             int  = Turn.PLAYER
var turn_count:       int  = 0

# ─────────────────────────────────────────────────────────────────────────────
# TERMINAL TEST
# ─────────────────────────────────────────────────────────────────────────────
func is_terminal() -> bool:
	return player_hp <= 0 or npc_hp <= 0 or turn_count >= MAX_TURNS

## Returns "player", "npc", or "draw" — call only when is_terminal() == true
func get_winner() -> String:
	if player_hp <= 0 and npc_hp <= 0:
		return "draw"
	if player_hp <= 0:
		return "npc"
	if npc_hp <= 0:
		return "player"
	return "draw"  # turn_count exhausted

# ─────────────────────────────────────────────────────────────────────────────
# UTILITY  (from NPC/maximiser perspective)
# ─────────────────────────────────────────────────────────────────────────────
func terminal_utility() -> int:
	var winner := get_winner()
	match winner:
		"npc":    return  WIN_SCORE
		"player": return -WIN_SCORE
		_:        return  0

# ─────────────────────────────────────────────────────────────────────────────
# CLONE  (immutable-style tree search)
# ─────────────────────────────────────────────────────────────────────────────
func clone() -> BattleState:
	var s          := BattleState.new()
	s.player_hp        = player_hp
	s.npc_hp           = npc_hp
	s.player_potions   = player_potions
	s.npc_potions      = npc_potions
	s.player_defending = player_defending
	s.npc_defending    = npc_defending
	s.turn             = turn
	s.turn_count       = turn_count
	return s

# ─────────────────────────────────────────────────────────────────────────────
# DISPLAY HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func state_string() -> String:
	return "P=%d(%d💊) D=%d(%d💊) t=%d/%d" % [
		player_hp, player_potions, npc_hp, npc_potions, turn_count, MAX_TURNS
	]
