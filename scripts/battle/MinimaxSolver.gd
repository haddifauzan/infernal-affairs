## MinimaxSolver.gd
## ──────────────────────────────────────────────────────────────────────────────
## Implements three search algorithms on the BattleState game tree:
##
##   1. MINIMAX      — exhaustive adversarial search
##   2. ALPHABETA    — minimax + alpha-beta pruning (same decision, fewer nodes)
##   3. EXPECTIMAX   — probabilistic variant (heavy attack has a miss chance)
##
## Five evaluation functions allow NPC behaviour experiments.
## Four action orderings allow move-ordering experiments.
##
## All methods are PURE (no side effects on the input state).
## ──────────────────────────────────────────────────────────────────────────────
class_name MinimaxSolver
extends RefCounted

# ─────────────────────────────────────────────────────────────────────────────
# ENUMERATIONS  (exported so BattleManager can reference them by name)
# ─────────────────────────────────────────────────────────────────────────────
enum Algorithm   { MINIMAX = 0, ALPHABETA = 1, EXPECTIMAX = 2 }
enum EvalFunc    { HP_DIFF = 0, AGGRESSIVE = 1, DEFENSIVE = 2, WEIGHTED = 3, HP_RATIO = 4 }
enum ActionOrder { DEFAULT = 0, AGGRESSIVE = 1, DEFENSIVE = 2, RANDOM = 3 }

## Action IDs  (branching factor ≤ 4)
enum Action { ATTACK = 0, HEAVY_ATTACK = 1, DEFEND = 2, POTION = 3 }

# ─────────────────────────────────────────────────────────────────────────────
# DETERMINISTIC DAMAGE CONSTANTS (used by Minimax / Alpha-Beta)
# Heavy attack has probabilistic variant used only by Expectimax.
# ─────────────────────────────────────────────────────────────────────────────
const ATK_DMG:        int   = 20   ## Attack damage (deterministic midpoint)
const HEAVY_DMG:      int   = 37   ## Heavy attack damage (deterministic midpoint of 30-45)
const HEAVY_SELF_DMG: int   = 10   ## Heavy attack self-cost
const DEFEND_REDUCTION: float = 0.5 ## Block factor applied to attacker damage
const POTION_HEAL:    int   = 30   ## HP restored per potion
const HEAVY_HIT_PROB: float = 0.6  ## 60% hit in Expectimax (40% miss)

# ─────────────────────────────────────────────────────────────────────────────
# SOLVER SETTINGS  (configured by BattleManager per experiment)
# ─────────────────────────────────────────────────────────────────────────────
var max_depth:    int = 4
var algorithm:    int = Algorithm.ALPHABETA
var eval_func:    int = EvalFunc.HP_DIFF
var action_order: int = ActionOrder.DEFAULT

# ─────────────────────────────────────────────────────────────────────────────
# DEBUG COUNTERS (reset each best_move() call)
# ─────────────────────────────────────────────────────────────────────────────
var nodes_visited:  int = 0
var nodes_pruned:   int = 0
var max_depth_reached: int = 0

# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC ENTRY POINT
# Returns a Dictionary with all info the debug overlay needs:
#   best_action, action_scores, nodes_visited, nodes_pruned,
#   max_depth_reached, algorithm, eval_func, action_order, depth
# ─────────────────────────────────────────────────────────────────────────────
func best_move(state: BattleState) -> Dictionary:
	nodes_visited    = 0
	nodes_pruned     = 0
	max_depth_reached = 0

	var actions := get_available_actions(state)
	var ordered := _order_actions(actions)

	## Score every root action for debug display
	var action_scores: Dictionary = {}
	var best_action := ordered[0] if ordered.size() > 0 else Action.ATTACK
	var best_score  := -INF

	for act in ordered:
		var child := apply_action(state, act)
		var score: float
		match algorithm:
			Algorithm.MINIMAX:
				score = _minimax(child, max_depth - 1, false)
			Algorithm.ALPHABETA:
				score = _alphabeta(child, max_depth - 1, -INF, INF, false)
			Algorithm.EXPECTIMAX:
				score = _expectimax(child, max_depth - 1, false)
			_:
				score = _alphabeta(child, max_depth - 1, -INF, INF, false)

		action_scores[action_name(act)] = score
		if score > best_score:
			best_score  = score
			best_action = act

	return {
		"best_action":       best_action,
		"best_action_name":  action_name(best_action),
		"action_scores":     action_scores,
		"nodes_visited":     nodes_visited,
		"nodes_pruned":      nodes_pruned,
		"max_depth_reached": max_depth_reached,
		"algorithm":         _algo_name(),
		"eval_func":         _eval_name(),
		"action_order":      _order_name(),
		"depth":             max_depth,
	}

# ─────────────────────────────────────────────────────────────────────────────
# ALGORITHM 1: MINIMAX (exhaustive)
# ─────────────────────────────────────────────────────────────────────────────
func _minimax(state: BattleState, depth: int, is_maximising: bool) -> float:
	nodes_visited += 1
	max_depth_reached = max(max_depth_reached, max_depth - depth)

	if state.is_terminal():
		return float(state.terminal_utility())
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

# ─────────────────────────────────────────────────────────────────────────────
# ALGORITHM 2: ALPHA-BETA PRUNING
# ─────────────────────────────────────────────────────────────────────────────
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
				break   ## β cut-off
		return value
	else:
		var value := INF
		for act in actions:
			var child := apply_action(state, act)
			value = min(value, _alphabeta(child, depth - 1, alpha, beta, true))
			beta = min(beta, value)
			if beta <= alpha:
				nodes_pruned += 1
				break   ## α cut-off
		return value

# ─────────────────────────────────────────────────────────────────────────────
# ALGORITHM 3: EXPECTIMAX
# Chance node: HEAVY_ATTACK becomes probabilistic (hit 60% / miss 40%)
# All other actions remain deterministic for simplicity.
# ─────────────────────────────────────────────────────────────────────────────
func _expectimax(state: BattleState, depth: int, is_maximising: bool) -> float:
	nodes_visited += 1
	max_depth_reached = max(max_depth_reached, max_depth - depth)

	if state.is_terminal():
		return float(state.terminal_utility())
	if depth == 0:
		return _evaluate(state)

	var actions := _order_actions(get_available_actions(state))

	if is_maximising:
		## NPC is the max player — still picks the best deterministic action
		## (its own uncertainty is about the opponent, not itself)
		var best := -INF
		for act in actions:
			var child := apply_action(state, act)
			var val   := _expectimax(child, depth - 1, false)
			best = max(best, val)
		return best
	else:
		## Player turn — we model each action as a chance node where
		## HEAVY_ATTACK has probability outcomes
		var total := 0.0
		for act in actions:
			if act == Action.HEAVY_ATTACK:
				## Hit branch (60%)
				var hit_child  := _apply_heavy_attack_hit(state)
				var hit_val    := _expectimax(hit_child, depth - 1, true)
				## Miss branch (40%)
				var miss_child := _apply_heavy_attack_miss(state)
				var miss_val   := _expectimax(miss_child, depth - 1, true)
				total += HEAVY_HIT_PROB * hit_val + (1.0 - HEAVY_HIT_PROB) * miss_val
				nodes_visited += 1   ## extra node for miss branch
			else:
				var child := apply_action(state, act)
				total += _expectimax(child, depth - 1, true)
		return total / float(actions.size()) if actions.size() > 0 else 0.0

## Heavy attack HIT outcome (player attacks NPC)
func _apply_heavy_attack_hit(state: BattleState) -> BattleState:
	var s := state.clone()
	## It's player's turn — player uses heavy on NPC
	var dmg := HEAVY_DMG
	if s.npc_defending:
		dmg = int(dmg * DEFEND_REDUCTION)
	s.npc_hp     = max(0, s.npc_hp - dmg)
	s.player_hp  = max(0, s.player_hp - HEAVY_SELF_DMG)
	s.npc_defending    = false
	s.player_defending = false
	s.turn       = BattleState.Turn.NPC
	s.turn_count += 1
	return s

## Heavy attack MISS outcome (player loses self-HP but deals no damage)
func _apply_heavy_attack_miss(state: BattleState) -> BattleState:
	var s := state.clone()
	s.player_hp  = max(0, s.player_hp - HEAVY_SELF_DMG)
	s.npc_defending    = false
	s.player_defending = false
	s.turn       = BattleState.Turn.NPC
	s.turn_count += 1
	return s

# ─────────────────────────────────────────────────────────────────────────────
# ACTION LOGIC
# apply_action: returns a NEW BattleState (immutable-style)
# ─────────────────────────────────────────────────────────────────────────────
func apply_action(state: BattleState, action: int) -> BattleState:
	var s          := state.clone()
	var is_npc    := (s.turn == BattleState.Turn.NPC)

	## Which entity is acting / receiving?
	## Attacker = current turn, Defender = opponent
	var atk_hp: int      ## not directly used but helps clarity
	var def_hp: int
	var atk_defending: bool
	var def_defending: bool
	var atk_potions: int

	if is_npc:
		def_defending = s.player_defending
		atk_potions   = s.npc_potions
	else:
		def_defending = s.npc_defending
		atk_potions   = s.player_potions

	## Clear attacker's defending flag (buff expires this turn)
	if is_npc:
		s.npc_defending = false
	else:
		s.player_defending = false

	match action:
		Action.ATTACK:
			var dmg := ATK_DMG
			if def_defending:
				dmg = int(dmg * DEFEND_REDUCTION)
			if is_npc:
				s.player_hp = max(0, s.player_hp - dmg)
				s.player_defending = false
			else:
				s.npc_hp = max(0, s.npc_hp - dmg)
				s.npc_defending = false

		Action.HEAVY_ATTACK:
			var dmg := HEAVY_DMG
			if def_defending:
				## Defend does NOT fully block heavy (flavour rule: only 30% reduction)
				dmg = int(HEAVY_DMG * 0.7)
			if is_npc:
				s.player_hp = max(0, s.player_hp - dmg)
				s.npc_hp    = max(0, s.npc_hp    - HEAVY_SELF_DMG)
				s.player_defending = false
			else:
				s.npc_hp    = max(0, s.npc_hp    - dmg)
				s.player_hp = max(0, s.player_hp - HEAVY_SELF_DMG)
				s.npc_defending = false

		Action.DEFEND:
			if is_npc:
				s.npc_defending = true
			else:
				s.player_defending = true

		Action.POTION:
			if is_npc:
				s.npc_hp      = min(BattleState.MAX_HP, s.npc_hp + POTION_HEAL)
				s.npc_potions = max(0, s.npc_potions - 1)
			else:
				s.player_hp      = min(BattleState.MAX_HP, s.player_hp + POTION_HEAL)
				s.player_potions = max(0, s.player_potions - 1)

	## Advance turn
	s.turn = BattleState.Turn.PLAYER if is_npc else BattleState.Turn.NPC
	s.turn_count += 1
	return s

## Returns the list of valid actions for the current turn
func get_available_actions(state: BattleState) -> Array[int]:
	var acts: Array[int] = [Action.ATTACK, Action.HEAVY_ATTACK, Action.DEFEND]
	var potions := state.player_potions if state.turn == BattleState.Turn.PLAYER else state.npc_potions
	if potions > 0:
		acts.append(Action.POTION)
	return acts

# ─────────────────────────────────────────────────────────────────────────────
# EVALUATION FUNCTIONS  (heuristic for non-terminal states)
# From NPC (maximiser) perspective.
# ─────────────────────────────────────────────────────────────────────────────
func _evaluate(state: BattleState) -> float:
	match eval_func:
		EvalFunc.AGGRESSIVE:
			## Maximise damage dealt to player — pure aggression
			return float(BattleState.MAX_HP - state.player_hp)

		EvalFunc.DEFENSIVE:
			## Maximise own survival only
			return float(state.npc_hp)

		EvalFunc.WEIGHTED:
			## Balanced: HP diff + potion advantage + defending bonus
			var hp_adv    := 2.0 * float(state.npc_hp - state.player_hp)
			var pot_adv   := 10.0 * float(state.npc_potions) - 5.0 * float(state.player_potions)
			var def_bonus := 15.0 if state.npc_defending else 0.0
			return hp_adv + pot_adv + def_bonus

		EvalFunc.HP_RATIO:
			## Ratio-based: values HP lead multiplicatively
			return (float(state.npc_hp) / float(max(1, state.player_hp))) * 50.0

		_:  ## HP_DIFF (default)
			return float(state.npc_hp - state.player_hp)

# ─────────────────────────────────────────────────────────────────────────────
# ACTION ORDERING  (for alpha-beta move ordering efficiency)
# ─────────────────────────────────────────────────────────────────────────────
func _order_actions(actions: Array[int]) -> Array[int]:
	var result: Array[int] = actions.duplicate()
	match action_order:
		ActionOrder.AGGRESSIVE:
			## Heavy first — maximise early damage pressure
			result.sort_custom(func(a, b): return _order_aggressive(a, b))
		ActionOrder.DEFENSIVE:
			## Defend/Potion first — survivability priority
			result.sort_custom(func(a, b): return _order_defensive(a, b))
		ActionOrder.RANDOM:
			_shuffle(result)
		_:  ## DEFAULT: Attack, Heavy, Defend, Potion
			result.sort_custom(func(a, b): return a < b)
	return result

func _order_aggressive(a: int, b: int) -> bool:
	const prio := {Action.HEAVY_ATTACK: 0, Action.ATTACK: 1, Action.DEFEND: 2, Action.POTION: 3}
	return prio.get(a, 9) < prio.get(b, 9)

func _order_defensive(a: int, b: int) -> bool:
	const prio := {Action.DEFEND: 0, Action.POTION: 1, Action.ATTACK: 2, Action.HEAVY_ATTACK: 3}
	return prio.get(a, 9) < prio.get(b, 9)

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

# ─────────────────────────────────────────────────────────────────────────────
# DISPLAY HELPERS (static so BattleHUD can call without an instance)
# ─────────────────────────────────────────────────────────────────────────────
static func action_name(action: int) -> String:
	match action:
		Action.ATTACK:       return "Attack"
		Action.HEAVY_ATTACK: return "Heavy Atk"
		Action.DEFEND:       return "Defend"
		Action.POTION:       return "Potion"
		_:                   return "???"

static func action_icon(action: int) -> String:
	match action:
		Action.ATTACK:       return "⚔️"
		Action.HEAVY_ATTACK: return "🔥"
		Action.DEFEND:       return "🛡️"
		Action.POTION:       return "💊"
		_:                   return "❓"

func _algo_name() -> String:
	match algorithm:
		Algorithm.MINIMAX:    return "Minimax"
		Algorithm.ALPHABETA:  return "Alpha-Beta"
		Algorithm.EXPECTIMAX: return "Expectimax"
		_:                    return "???"

func _eval_name() -> String:
	match eval_func:
		EvalFunc.HP_DIFF:   return "HP Diff"
		EvalFunc.AGGRESSIVE:return "Aggressive"
		EvalFunc.DEFENSIVE: return "Defensive"
		EvalFunc.WEIGHTED:  return "Weighted"
		EvalFunc.HP_RATIO:  return "HP Ratio"
		_:                  return "???"

func _order_name() -> String:
	match action_order:
		ActionOrder.DEFAULT:    return "Default"
		ActionOrder.AGGRESSIVE: return "Aggressive"
		ActionOrder.DEFENSIVE:  return "Defensive"
		ActionOrder.RANDOM:     return "Random"
		_:                      return "???"
