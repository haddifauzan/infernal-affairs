## BattleManager.gd
## Orchestrates turn-based battle: player input, NPC AI, state transitions.
class_name BattleManager
extends Node

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal battle_started(state: BattleState)
signal battle_ended(winner: String, final_state: BattleState)
signal action_performed(actor: String, action: int, result: Dictionary, new_state: BattleState)
signal turn_changed(whose_turn: String)
signal debug_updated(info: Dictionary)
signal npc_thinking(is_thinking: bool)

# -----------------------------------------------------------------------------
# STATE & SOLVER
# -----------------------------------------------------------------------------
var state: BattleState
var solver: MinimaxSolver

# -----------------------------------------------------------------------------
# AI SETTINGS (can be changed at runtime for experiments)
# -----------------------------------------------------------------------------
var ai_algorithm:    int = MinimaxSolver.Algorithm.ALPHABETA
var ai_eval_func:    int = MinimaxSolver.EvalFunc.HP_DIFF
var ai_action_order: int = MinimaxSolver.ActionOrder.DEFAULT
var ai_depth:        int = 3
var npc_think_delay: float = 1.3   # visual pause before NPC acts (seconds)

# -----------------------------------------------------------------------------
# INTERNAL
# -----------------------------------------------------------------------------
var is_active: bool = false
var _waiting_npc: bool = false
var _npc_timer:   float = 0.0
var _last_debug:  Dictionary = {}

func _ready() -> void:
	solver = MinimaxSolver.new()

# -----------------------------------------------------------------------------
# START / STOP
# -----------------------------------------------------------------------------
func start_battle(player_hp: int = BattleState.MAX_HP, npc_hp: int = BattleState.MAX_HP) -> void:
	state = BattleState.new()
	state.player_hp      = clampi(player_hp, 1, BattleState.MAX_HP)
	state.npc_hp         = clampi(npc_hp,    1, BattleState.MAX_HP)
	state.player_potions = BattleState.MAX_POTIONS
	state.npc_potions    = BattleState.MAX_POTIONS
	state.player_defending = false
	state.npc_defending    = false
	state.turn = BattleState.Turn.PLAYER

	is_active    = true
	_waiting_npc = false
	_npc_timer   = 0.0

	_apply_solver_settings()
	battle_started.emit(state)
	turn_changed.emit("player")

func start_battle_custom(config: Dictionary) -> void:
	state = BattleState.new()
	state.player_max_hp     = config.get("player_max_hp", BattleState.MAX_HP)
	state.player_hp         = config.get("player_hp", state.player_max_hp)
	state.player_potions    = config.get("player_potions", 1)
	state.player_atk_dmg    = config.get("player_atk", 20)
	state.player_heavy_dmg  = config.get("player_heavy_atk", 37)
	state.player_potion_heal= config.get("player_potion_heal", 30)

	state.npc_max_hp        = config.get("npc_max_hp", 100)
	state.npc_hp            = config.get("npc_hp", state.npc_max_hp)
	state.npc_potions       = config.get("npc_potions", 1)
	state.npc_atk_dmg       = config.get("npc_atk", 16)
	state.npc_heavy_dmg     = config.get("npc_heavy_atk", 28)
	state.npc_potion_heal   = config.get("npc_potion_heal", 25)

	state.enemy_type        = config.get("enemy_type", "guard")
	state.enemy_name        = config.get("enemy_name", "Hell Guard")

	# CSP-driven strategy, seals, and weapon passives
	state.gate_seal         = config.get("gate_seal", "")
	state.boss_weapon       = config.get("boss_weapon", "")
	state.enemy_strategy    = config.get("enemy_strategy", "")
	state.gate_seal_effect  = config.get("gate_seal_effect", "")
	state.boss_weapon_effect= config.get("boss_weapon_effect", "")

	ai_depth        = config.get("minimax_depth", 2)
	ai_eval_func    = config.get("ai_eval_func", MinimaxSolver.EvalFunc.HP_DIFF)
	ai_action_order = config.get("ai_action_order", MinimaxSolver.ActionOrder.DEFAULT)
	state.minimax_depth = ai_depth

	state.player_defending  = false
	state.npc_defending     = false
	state.turn = BattleState.Turn.PLAYER

	is_active    = true
	_waiting_npc = false
	_npc_timer   = 0.0

	_apply_solver_settings()
	battle_started.emit(state)
	turn_changed.emit("player")


func stop_battle() -> void:
	is_active    = false
	_waiting_npc = false

# -----------------------------------------------------------------------------
# PLAYER ACTION
# -----------------------------------------------------------------------------
func player_action(action: int) -> void:
	if not is_active: return
	if state.turn != BattleState.Turn.PLAYER: return
	if action not in solver.get_available_actions(state): return

	var prev := state.clone()
	state = solver.apply_action(state, action)

	var result := _build_result(prev, state, action, false)
	action_performed.emit("player", action, result, state)

	if state.is_terminal():
		_end_battle()
		return

	turn_changed.emit("npc")
	npc_thinking.emit(true)
	_waiting_npc = true
	_npc_timer   = npc_think_delay

# -----------------------------------------------------------------------------
# NPC TURN (deferred via timer for visual feel)
# -----------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not is_active or not _waiting_npc: return
	_npc_timer -= delta
	if _npc_timer <= 0.0:
		_waiting_npc = false
		_do_npc_turn()

func _do_npc_turn() -> void:
	_apply_solver_settings()

	var search_result := solver.best_move(state)
	var best_action: int = search_result.get("best_action", MinimaxSolver.Action.ATTACK)

	_last_debug = search_result
	debug_updated.emit(search_result)
	npc_thinking.emit(false)

	var prev := state.clone()
	state = solver.apply_action(state, best_action)

	var result := _build_result(prev, state, best_action, true)
	action_performed.emit("npc", best_action, result, state)

	if state.is_terminal():
		_end_battle()
		return

	turn_changed.emit("player")

# -----------------------------------------------------------------------------
# EXPERIMENT CONTROL
# -----------------------------------------------------------------------------
func set_ai_config(algo: int, eval: int, order: int, depth: int) -> void:
	ai_algorithm    = algo
	ai_eval_func    = eval
	ai_action_order = order
	ai_depth        = depth

func get_last_debug() -> Dictionary:
	return _last_debug

# -----------------------------------------------------------------------------
# INTERNALS
# -----------------------------------------------------------------------------
func _apply_solver_settings() -> void:
	solver.max_depth    = ai_depth
	solver.algorithm    = ai_algorithm
	solver.eval_func    = ai_eval_func
	solver.action_order = ai_action_order

func _end_battle() -> void:
	is_active = false
	battle_ended.emit(state.get_winner(), state)

func _build_result(before: BattleState, after: BattleState, action: int, is_npc: bool) -> Dictionary:
	var dmg_dealt: int
	var heal_amt:  int
	var was_blocked: bool

	if is_npc:
		dmg_dealt   = max(0, before.player_hp - after.player_hp)
		heal_amt    = max(0, after.npc_hp    - before.npc_hp)
		was_blocked = before.player_defending and \
					  action in [MinimaxSolver.Action.ATTACK, MinimaxSolver.Action.HEAVY_ATTACK]
	else:
		dmg_dealt   = max(0, before.npc_hp    - after.npc_hp)
		heal_amt    = max(0, after.player_hp - before.player_hp)
		was_blocked = before.npc_defending and \
					  action in [MinimaxSolver.Action.ATTACK, MinimaxSolver.Action.HEAVY_ATTACK]

	var lifesteal: bool = is_npc and heal_amt > 0 and action == MinimaxSolver.Action.ATTACK
	var burn_applied: bool = is_npc and after.player_burn_turns > before.player_burn_turns
	var burn_tick: bool = before.player_burn_turns > 0
	var seal_burn_tick: bool = before.enemy_type == "guard" and before.gate_seal == "Seal of Flame"
	var seal_block: bool = not is_npc and before.enemy_type == "guard" and before.gate_seal == "Seal of Blood" and action in [MinimaxSolver.Action.ATTACK, MinimaxSolver.Action.HEAVY_ATTACK]
	var armor_pierced: bool = is_npc and before.player_defending and before.boss_weapon == "Blood Trident" and action in [MinimaxSolver.Action.ATTACK, MinimaxSolver.Action.HEAVY_ATTACK]

	return {
		"action":         action,
		"action_name":    MinimaxSolver.action_name(action),
		"action_icon":    MinimaxSolver.action_icon(action),
		"damage_dealt":   dmg_dealt,
		"heal_amount":    heal_amt,
		"was_blocked":    was_blocked,
		"lifesteal":      lifesteal,
		"burn_applied":   burn_applied,
		"burn_tick":      burn_tick,
		"seal_burn_tick": seal_burn_tick,
		"seal_block":     seal_block,
		"armor_pierced":  armor_pierced
	}

