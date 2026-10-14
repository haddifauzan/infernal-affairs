class_name LocalSearchBalancer
extends RefCounted

## LocalSearchBalancer.gd
## Dynamic Difficulty Balancer using Local Search (Hill Climbing & Simulated Annealing).
## Formulated for Infernal Affairs (Tubes AI Tahap 3) to optimize NPC combat configurations
## right before battle so that encounters remain balanced, engaging, and fair.

# --- Domain Bounds for State Vector S ---
const HP_MIN: int = 60
const HP_MAX: int = 250

const ATK_MIN: int = 8
const ATK_MAX: int = 30

const HEAVY_ATK_MIN: int = 16
const HEAVY_ATK_MAX: int = 50

const DEF_MIN: int = 2
const DEF_MAX: int = 12

const POTION_COUNT_MIN: int = 0
const POTION_COUNT_MAX: int = 3

const POTION_HEAL_MIN: int = 20
const POTION_HEAL_MAX: int = 45

const DEPTH_MIN: int = 1
const DEPTH_MAX: int = 4

# --- Target Ratios (PLAN.md Section 3.3) ---
const RATIO_GUARD: float = 1.05
const RATIO_BOSS: float = 1.25

# --- Simulated Annealing Hyperparameters ---
const SA_INITIAL_TEMP: float = 100.0
const SA_COOLING_RATE: float = 0.95
const SA_MIN_TEMP: float = 0.05
const MAX_ITERATIONS: int = 50

## Calculates theoretical Combat Power for the Player based on live stats.
static func calculate_player_power(hp: int, atk: int, def: int, potions: int) -> float:
	return float(hp) + (float(atk) * 2.5) + (float(def) * 3.0) + (float(potions) * 20.0)

## Calculates theoretical Combat Power for the NPC given state vector S.
static func calculate_npc_power(state: Dictionary) -> float:
	var hp: float = float(state.get("hp", 100))
	var atk: float = float(state.get("atk", 14))
	var heavy_atk: float = float(state.get("heavy_atk", 28))
	var def: float = float(state.get("def", 5))
	var pot_count: float = float(state.get("potion_count", 1))
	var pot_heal: float = float(state.get("potion_heal", 30))
	var depth: float = float(state.get("minimax_depth", 2))

	return hp + (atk * 2.2) + (heavy_atk * 1.2) + (def * 3.0) + (pot_count * pot_heal * 0.7) + (depth * 15.0)

## Objective/Fitness Function f(S) - Semakin mendekati 0 semakin sempurna.
static func evaluate_fitness(state: Dictionary, player_power: float, target_ratio: float) -> float:
	var npc_power: float = calculate_npc_power(state)
	var target_power: float = player_power * target_ratio
	return -absf(npc_power - target_power)

## Generates a default base state vector S_0 for an enemy type.
static func get_initial_state(enemy_type: String) -> Dictionary:
	match enemy_type.to_lower():
		"guard":
			return {
				"hp": 110,
				"atk": 16,
				"heavy_atk": 28,
				"def": 6,
				"potion_count": 1,
				"potion_heal": 25,
				"minimax_depth": 2
			}
		"boss":
			return {
				"hp": 180,
				"atk": 22,
				"heavy_atk": 38,
				"def": 9,
				"potion_count": 2,
				"potion_heal": 35,
				"minimax_depth": 3
			}
		_: # minion or default
			return {
				"hp": 70,
				"atk": 10,
				"heavy_atk": 20,
				"def": 3,
				"potion_count": 0,
				"potion_heal": 20,
				"minimax_depth": 1
			}

## Clamps state parameters to their valid domain ranges.
static func clamp_state(s: Dictionary) -> Dictionary:
	var c := s.duplicate()
	c["hp"] = clampi(c["hp"], HP_MIN, HP_MAX)
	c["atk"] = clampi(c["atk"], ATK_MIN, ATK_MAX)
	c["heavy_atk"] = clampi(c["heavy_atk"], HEAVY_ATK_MIN, HEAVY_ATK_MAX)
	c["def"] = clampi(c["def"], DEF_MIN, DEF_MAX)
	c["potion_count"] = clampi(c["potion_count"], POTION_COUNT_MIN, POTION_COUNT_MAX)
	c["potion_heal"] = clampi(c["potion_heal"], POTION_HEAL_MIN, POTION_HEAL_MAX)
	c["minimax_depth"] = clampi(c["minimax_depth"], DEPTH_MIN, DEPTH_MAX)
	return c

## Generates all discrete 1-step neighbours for Steepest-Ascent Hill Climbing.
static func get_all_neighbours(current: Dictionary) -> Array[Dictionary]:
	var neighbours: Array[Dictionary] = []
	var deltas := [
		{"key": "hp", "delta": 10, "desc": "HP +10"},
		{"key": "hp", "delta": -10, "desc": "HP -10"},
		{"key": "atk", "delta": 2, "desc": "Atk +2"},
		{"key": "atk", "delta": -2, "desc": "Atk -2"},
		{"key": "heavy_atk", "delta": 3, "desc": "HeavyAtk +3"},
		{"key": "heavy_atk", "delta": -3, "desc": "HeavyAtk -3"},
		{"key": "def", "delta": 1, "desc": "Def +1"},
		{"key": "def", "delta": -1, "desc": "Def -1"},
		{"key": "potion_count", "delta": 1, "desc": "Potion +1"},
		{"key": "potion_count", "delta": -1, "desc": "Potion -1"},
		{"key": "minimax_depth", "delta": 1, "desc": "Depth +1"},
		{"key": "minimax_depth", "delta": -1, "desc": "Depth -1"}
	]

	for d in deltas:
		var n := current.duplicate()
		n[d["key"]] += d["delta"]
		n = clamp_state(n)
		n["_action_desc"] = d["desc"]
		neighbours.append(n)

	return neighbours

## Generates a single random neighbour for Simulated Annealing.
static func get_random_neighbour(current: Dictionary) -> Dictionary:
	var n := current.duplicate()
	var choice: int = randi() % 6
	var desc: String = ""

	match choice:
		0:
			var dh: int = 10 if randf() < 0.5 else -10
			n["hp"] += dh
			desc = "HP %+d" % dh
		1:
			var da: int = 2 if randf() < 0.5 else -2
			n["atk"] += da
			desc = "Atk %+d" % da
		2:
			var dha: int = 3 if randf() < 0.5 else -3
			n["heavy_atk"] += dha
			desc = "HeavyAtk %+d" % dha
		3:
			var dd: int = 1 if randf() < 0.5 else -1
			n["def"] += dd
			desc = "Def %+d" % dd
		4:
			var dp: int = 1 if randf() < 0.5 else -1
			n["potion_count"] += dp
			desc = "Potion %+d" % dp
		5:
			var ddep: int = 1 if randf() < 0.5 else -1
			n["minimax_depth"] += ddep
			desc = "Depth %+d" % ddep

	n = clamp_state(n)
	n["_action_desc"] = desc
	return n

# ---------------------------------------------------------------
# 1. HILL CLIMBING (STEEPEST ASCENT)
# ---------------------------------------------------------------
static func run_hill_climbing(initial_state: Dictionary, player_power: float, target_ratio: float, max_steps: int = 35) -> Dictionary:
	var start_time: int = Time.get_ticks_usec()
	var current: Dictionary = clamp_state(initial_state)
	var current_fitness: float = evaluate_fitness(current, player_power, target_ratio)
	var target_power: float = player_power * target_ratio

	var step_logs: Array[Dictionary] = []
	step_logs.append({
		"step": 0,
		"action_desc": "Initial State",
		"score": current_fitness,
		"delta": 0.0,
		"status": "START",
		"temp": 0.0,
		"prob": 1.0,
		"state": current.duplicate(),
		"npc_power": calculate_npc_power(current),
		"target_power": target_power
	})

	var step: int = 1
	var stuck: bool = false

	while step <= max_steps:
		var neighbours: Array[Dictionary] = get_all_neighbours(current)
		var best_neighbour: Dictionary = {}
		var best_fitness: float = -INF
		var best_desc: String = ""

		for n in neighbours:
			var f: float = evaluate_fitness(n, player_power, target_ratio)
			if f > best_fitness:
				best_fitness = f
				best_neighbour = n
				best_desc = n.get("_action_desc", "Step")

		var delta: float = best_fitness - current_fitness

		if delta > 0.001:
			current = best_neighbour
			current_fitness = best_fitness
			step_logs.append({
				"step": step,
				"action_desc": best_desc,
				"score": current_fitness,
				"delta": delta,
				"status": "ACCEPTED",
				"temp": 0.0,
				"prob": 1.0,
				"state": current.duplicate(),
				"npc_power": calculate_npc_power(current),
				"target_power": target_power
			})
			step += 1
		else:
			# Stuck at local maximum / plateau
			stuck = true
			step_logs.append({
				"step": step,
				"action_desc": "No better neighbour",
				"score": current_fitness,
				"delta": 0.0,
				"status": "STUCK AT LOCAL MAXIMUM",
				"temp": 0.0,
				"prob": 0.0,
				"state": current.duplicate(),
				"npc_power": calculate_npc_power(current),
				"target_power": target_power
			})
			break

	var execution_time_ms: float = (Time.get_ticks_usec() - start_time) / 1000.0

	return {
		"algorithm": "Hill Climbing",
		"initial_state": initial_state,
		"best_state": current,
		"best_fitness": current_fitness,
		"initial_fitness": evaluate_fitness(initial_state, player_power, target_ratio),
		"player_power": player_power,
		"target_power": target_power,
		"final_npc_power": calculate_npc_power(current),
		"step_logs": step_logs,
		"total_steps": step_logs.size() - 1,
		"stuck": stuck,
		"execution_time_ms": execution_time_ms
	}

# ---------------------------------------------------------------
# 2. SIMULATED ANNEALING (SA)
# ---------------------------------------------------------------
static func run_simulated_annealing(initial_state: Dictionary, player_power: float, target_ratio: float, max_steps: int = MAX_ITERATIONS) -> Dictionary:
	var start_time: int = Time.get_ticks_usec()
	var current: Dictionary = clamp_state(initial_state)
	var current_fitness: float = evaluate_fitness(current, player_power, target_ratio)
	var target_power: float = player_power * target_ratio

	var best_state: Dictionary = current.duplicate()
	var best_fitness: float = current_fitness

	var temp: float = SA_INITIAL_TEMP
	var step_logs: Array[Dictionary] = []

	step_logs.append({
		"step": 0,
		"action_desc": "Initial State",
		"score": current_fitness,
		"delta": 0.0,
		"status": "START",
		"temp": temp,
		"prob": 1.0,
		"state": current.duplicate(),
		"npc_power": calculate_npc_power(current),
		"target_power": target_power
	})

	for step in range(1, max_steps + 1):
		if temp < SA_MIN_TEMP:
			break

		var neighbour: Dictionary = get_random_neighbour(current)
		var n_fitness: float = evaluate_fitness(neighbour, player_power, target_ratio)
		var delta_e: float = n_fitness - current_fitness
		var action_desc: String = neighbour.get("_action_desc", "Perturb")

		var accept: bool = false
		var prob: float = 1.0
		var status_str: String = ""

		if delta_e > 0.0:
			accept = true
			prob = 1.0
			status_str = "ACCEPTED"
		else:
			# Downhill probability: P = e^(delta_E / T)
			prob = exp(delta_e / temp)
			if randf() < prob:
				accept = true
				status_str = "DOWNHILL ACCEPTED (P=%.2f, T=%.1f)" % [prob, temp]
			else:
				status_str = "REJECTED (P=%.2f, T=%.1f)" % [prob, temp]

		if accept:
			current = neighbour
			current_fitness = n_fitness
			if current_fitness > best_fitness:
				best_fitness = current_fitness
				best_state = current.duplicate()

		step_logs.append({
			"step": step,
			"action_desc": action_desc,
			"score": current_fitness,
			"delta": delta_e,
			"status": status_str,
			"temp": temp,
			"prob": prob,
			"state": current.duplicate(),
			"npc_power": calculate_npc_power(current),
			"target_power": target_power
		})

		# Cooling schedule: T = T * 0.95
		temp *= SA_COOLING_RATE

	var execution_time_ms: float = (Time.get_ticks_usec() - start_time) / 1000.0

	return {
		"algorithm": "Simulated Annealing",
		"initial_state": initial_state,
		"best_state": best_state,
		"best_fitness": best_fitness,
		"initial_fitness": evaluate_fitness(initial_state, player_power, target_ratio),
		"player_power": player_power,
		"target_power": target_power,
		"final_npc_power": calculate_npc_power(best_state),
		"step_logs": step_logs,
		"total_steps": step_logs.size() - 1,
		"final_temp": temp,
		"execution_time_ms": execution_time_ms
	}
