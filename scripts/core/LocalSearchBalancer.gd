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
const POTION_HEAL_MAX: int = 35

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

## Computes dynamic upper bounds based on player's stats/power so encounters scale smoothly.
static func get_domain_bounds(p_stats: Dictionary = {}, player_power: float = 0.0) -> Dictionary:
	var p_hp: int = p_stats.get("hp", 100)
	var p_atk: int = p_stats.get("attack", 12)
	var p_def: int = p_stats.get("defense", 5)

	var power_scale: float = 1.0
	if player_power > 0.0:
		power_scale = maxf(1.0, player_power / 180.0)

	return {
		"hp_min": HP_MIN,
		"hp_max": maxi(HP_MAX, int(maxf(float(p_hp * 1.6), HP_MAX * power_scale))),
		"atk_min": ATK_MIN,
		"atk_max": maxi(ATK_MAX, int(maxf(float(p_atk * 1.35), ATK_MAX * power_scale))),
		"heavy_atk_min": HEAVY_ATK_MIN,
		"heavy_atk_max": maxi(HEAVY_ATK_MAX, int(maxf(float(p_atk * 2.2), HEAVY_ATK_MAX * power_scale))),
		"def_min": DEF_MIN,
		"def_max": maxi(DEF_MAX, int(maxf(float(p_def * 1.25), DEF_MAX * power_scale))),
		"potion_count_min": POTION_COUNT_MIN,
		"potion_count_max": POTION_COUNT_MAX,
		"potion_heal_min": POTION_HEAL_MIN,
		"potion_heal_max": POTION_HEAL_MAX,
		"depth_min": DEPTH_MIN,
		"depth_max": DEPTH_MAX
	}

## Generates an adaptive base state vector S_0 for an enemy type scaled to player stats.
static func get_initial_state(enemy_type: String, p_stats: Dictionary = {}) -> Dictionary:
	var p_hp: int = p_stats.get("hp", 100)
	var p_atk: int = p_stats.get("attack", 12)
	var p_def: int = p_stats.get("defense", 5)

	match enemy_type.to_lower():
		"guard":
			return {
				"hp": maxi(110, int(p_hp * 1.05)),
				"atk": maxi(16, int(p_atk * 0.95)),
				"heavy_atk": maxi(28, int(p_atk * 1.6)),
				"def": maxi(6, int(p_def * 0.9)),
				"potion_count": 1,
				"potion_heal": 25,
				"minimax_depth": 2
			}
		"boss":
			return {
				"hp": maxi(180, int(p_hp * 1.25)),
				"atk": maxi(22, int(p_atk * 1.15)),
				"heavy_atk": maxi(38, int(p_atk * 1.9)),
				"def": maxi(9, int(p_def * 1.1)),
				"potion_count": 2,
				"potion_heal": 35,
				"minimax_depth": 3
			}
		_: # minion or default
			return {
				"hp": maxi(70, int(p_hp * 0.7)),
				"atk": maxi(10, int(p_atk * 0.75)),
				"heavy_atk": maxi(20, int(p_atk * 1.3)),
				"def": maxi(3, int(p_def * 0.6)),
				"potion_count": 0,
				"potion_heal": 20,
				"minimax_depth": 1
			}

## Clamps state parameters to their valid domain ranges (using optional dynamic bounds).
static func clamp_state(s: Dictionary, bounds: Dictionary = {}) -> Dictionary:
	var c: Dictionary = s.duplicate()
	var h_min: int = bounds.get("hp_min", HP_MIN)
	var h_max: int = bounds.get("hp_max", HP_MAX)
	var a_min: int = bounds.get("atk_min", ATK_MIN)
	var a_max: int = bounds.get("atk_max", ATK_MAX)
	var ha_min: int = bounds.get("heavy_atk_min", HEAVY_ATK_MIN)
	var ha_max: int = bounds.get("heavy_atk_max", HEAVY_ATK_MAX)
	var d_min: int = bounds.get("def_min", DEF_MIN)
	var d_max: int = bounds.get("def_max", DEF_MAX)
	var p_min: int = bounds.get("potion_count_min", POTION_COUNT_MIN)
	var p_max: int = bounds.get("potion_count_max", POTION_COUNT_MAX)
	var ph_min: int = bounds.get("potion_heal_min", POTION_HEAL_MIN)
	var ph_max: int = bounds.get("potion_heal_max", POTION_HEAL_MAX)
	var dep_min: int = bounds.get("depth_min", DEPTH_MIN)
	var dep_max: int = bounds.get("depth_max", DEPTH_MAX)

	c["hp"] = clampi(c["hp"], h_min, h_max)
	c["atk"] = clampi(c["atk"], a_min, a_max)
	c["heavy_atk"] = clampi(c["heavy_atk"], ha_min, ha_max)
	c["def"] = clampi(c["def"], d_min, d_max)
	c["potion_count"] = clampi(c["potion_count"], p_min, p_max)
	c["potion_heal"] = clampi(c["potion_heal"], ph_min, ph_max)
	c["minimax_depth"] = clampi(c["minimax_depth"], dep_min, dep_max)
	return c

## Generates all discrete 1-step neighbours for Steepest-Ascent Hill Climbing.
static func get_all_neighbours(current: Dictionary, bounds: Dictionary = {}) -> Array[Dictionary]:
	var neighbours: Array[Dictionary] = []
	var h_max: int = bounds.get("hp_max", HP_MAX)
	var a_max: int = bounds.get("atk_max", ATK_MAX)
	var hp_step: int = maxi(10, int(h_max * 0.04))
	var atk_step: int = maxi(2, int(a_max * 0.06))
	var heavy_step: int = maxi(3, int(a_max * 0.10))
	var def_step: int = maxi(1, int(bounds.get("def_max", DEF_MAX) * 0.05))

	var deltas := [
		{"key": "hp", "delta": hp_step, "desc": "HP +%d" % hp_step},
		{"key": "hp", "delta": -hp_step, "desc": "HP -%d" % hp_step},
		{"key": "atk", "delta": atk_step, "desc": "Atk +%d" % atk_step},
		{"key": "atk", "delta": -atk_step, "desc": "Atk -%d" % atk_step},
		{"key": "heavy_atk", "delta": heavy_step, "desc": "HeavyAtk +%d" % heavy_step},
		{"key": "heavy_atk", "delta": -heavy_step, "desc": "HeavyAtk -%d" % heavy_step},
		{"key": "def", "delta": def_step, "desc": "Def +%d" % def_step},
		{"key": "def", "delta": -def_step, "desc": "Def -%d" % def_step},
		{"key": "potion_count", "delta": 1, "desc": "Potion +1"},
		{"key": "potion_count", "delta": -1, "desc": "Potion -1"},
		{"key": "minimax_depth", "delta": 1, "desc": "Depth +1"},
		{"key": "minimax_depth", "delta": -1, "desc": "Depth -1"}
	]

	for d in deltas:
		var n: Dictionary = current.duplicate()
		n[d["key"]] += d["delta"]
		n = clamp_state(n, bounds)
		n["_action_desc"] = d["desc"]
		neighbours.append(n)

	return neighbours

## Generates a single random neighbour for Simulated Annealing.
static func get_random_neighbour(current: Dictionary, bounds: Dictionary = {}) -> Dictionary:
	var n: Dictionary = current.duplicate()
	var choice: int = randi() % 6
	var desc: String = ""

	var h_max: int = bounds.get("hp_max", HP_MAX)
	var a_max: int = bounds.get("atk_max", ATK_MAX)
	var hp_step: int = maxi(10, int(h_max * 0.04))
	var atk_step: int = maxi(2, int(a_max * 0.06))
	var heavy_step: int = maxi(3, int(a_max * 0.10))
	var def_step: int = maxi(1, int(bounds.get("def_max", DEF_MAX) * 0.05))

	match choice:
		0:
			var dh: int = hp_step if randf() < 0.5 else -hp_step
			n["hp"] += dh
			desc = "HP %+d" % dh
		1:
			var da: int = atk_step if randf() < 0.5 else -atk_step
			n["atk"] += da
			desc = "Atk %+d" % da
		2:
			var dha: int = heavy_step if randf() < 0.5 else -heavy_step
			n["heavy_atk"] += dha
			desc = "HeavyAtk %+d" % dha
		3:
			var dd: int = def_step if randf() < 0.5 else -def_step
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

	n = clamp_state(n, bounds)
	n["_action_desc"] = desc
	return n

# ---------------------------------------------------------------
# 1. HILL CLIMBING (STEEPEST ASCENT)
# ---------------------------------------------------------------
static func run_hill_climbing(initial_state: Dictionary, player_power: float, target_ratio: float, max_steps: int = 35, bounds: Dictionary = {}) -> Dictionary:
	var start_time: int = Time.get_ticks_usec()
	if bounds.is_empty():
		bounds = get_domain_bounds({}, player_power)
	var current: Dictionary = clamp_state(initial_state, bounds)
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
		var neighbours: Array[Dictionary] = get_all_neighbours(current, bounds)
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
static func run_simulated_annealing(initial_state: Dictionary, player_power: float, target_ratio: float, max_steps: int = MAX_ITERATIONS, bounds: Dictionary = {}) -> Dictionary:
	var start_time: int = Time.get_ticks_usec()
	if bounds.is_empty():
		bounds = get_domain_bounds({}, player_power)
	var current: Dictionary = clamp_state(initial_state, bounds)
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

		var neighbour: Dictionary = get_random_neighbour(current, bounds)
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

# ---------------------------------------------------------------
# 3. HILL CLIMBING WITH RANDOM RESTART
# ---------------------------------------------------------------
static func get_random_state(bounds: Dictionary = {}) -> Dictionary:
	var h_min: int = bounds.get("hp_min", HP_MIN)
	var h_max: int = bounds.get("hp_max", HP_MAX)
	var a_min: int = bounds.get("atk_min", ATK_MIN)
	var a_max: int = bounds.get("atk_max", ATK_MAX)
	var ha_min: int = bounds.get("heavy_atk_min", HEAVY_ATK_MIN)
	var ha_max: int = bounds.get("heavy_atk_max", HEAVY_ATK_MAX)
	var d_min: int = bounds.get("def_min", DEF_MIN)
	var d_max: int = bounds.get("def_max", DEF_MAX)

	return {
		"hp": (randi() % maxi(1, (h_max - h_min) / 10 + 1)) * 10 + h_min,
		"atk": (randi() % maxi(1, (a_max - a_min) / 2 + 1)) * 2 + a_min,
		"heavy_atk": (randi() % maxi(1, (ha_max - ha_min) / 3 + 1)) * 3 + ha_min,
		"def": (randi() % maxi(1, d_max - d_min + 1)) + d_min,
		"potion_count": randi() % 4,
		"potion_heal": 20 + (randi() % 4) * 5,
		"minimax_depth": 1 + randi() % 4
	}

static func run_hill_climbing_random_restart(initial_state: Dictionary, player_power: float, target_ratio: float, restarts: int = 3, max_steps_per_restart: int = 20, bounds: Dictionary = {}) -> Dictionary:
	var start_time: int = Time.get_ticks_usec()
	if bounds.is_empty():
		bounds = get_domain_bounds({}, player_power)
	var target_power: float = player_power * target_ratio

	var global_best_state: Dictionary = {}
	var global_best_fitness: float = -INF
	var combined_step_logs: Array[Dictionary] = []

	var current_seed: Dictionary = initial_state
	var total_step_counter: int = 0

	for r in range(restarts):
		var restart_run: Dictionary = run_hill_climbing(current_seed, player_power, target_ratio, max_steps_per_restart, bounds)
		var run_logs: Array = restart_run.get("step_logs", [])

		for entry in run_logs:
			var logged: Dictionary = entry.duplicate()
			logged["step"] = total_step_counter
			total_step_counter += 1
			logged["restart_idx"] = r + 1
			if logged.get("status") == "START":
				logged["action_desc"] = "Restart %d/%d (Seed: %d HP, %d Atk)" % [r + 1, restarts, current_seed.get("hp", 0), current_seed.get("atk", 0)]
			combined_step_logs.append(logged)

		var run_best_fitness: float = restart_run.get("best_fitness", -INF)
		if run_best_fitness > global_best_fitness:
			global_best_fitness = run_best_fitness
			global_best_state = restart_run.get("best_state", {}).duplicate()

		current_seed = get_random_state(bounds)

	var execution_time_ms: float = (Time.get_ticks_usec() - start_time) / 1000.0

	return {
		"algorithm": "Hill Climbing (Random Restart)",
		"initial_state": initial_state,
		"best_state": global_best_state,
		"best_fitness": global_best_fitness,
		"initial_fitness": evaluate_fitness(initial_state, player_power, target_ratio),
		"player_power": player_power,
		"target_power": target_power,
		"final_npc_power": calculate_npc_power(global_best_state),
		"step_logs": combined_step_logs,
		"total_steps": combined_step_logs.size() - 1,
		"restarts": restarts,
		"execution_time_ms": execution_time_ms
	}
