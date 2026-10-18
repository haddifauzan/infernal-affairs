class_name CSPSolver
extends RefCounted

## CSPSolver.gd
## Constraint Satisfaction Problem (CSP) Solver for Infernal Affairs (Tubes AI Tahap 3).
## Implements formal <X, D, C> triplet modeling and Backtracking Search with:
## - Minimum Remaining Values (MRV) heuristic
## - Degree Heuristic (tie-breaker for MRV)
## - Least Constraining Value (LCV) ordering
## - AC-3 (Arc Consistency) constraint propagation

# --- Domain Constants ---
const GUARD_TYPES: Array[String] = ["Infernal Knight", "Abyssal Shaman", "Obsidian Gargoyle"]
const GATE_SEALS: Array[String] = ["Seal of Flame", "Seal of Shadow", "Seal of Blood"]
const GUARD_STRATEGIES: Array[String] = ["Aggressive", "Defensive", "Tactical"]
const BOSS_WEAPONS: Array[String] = ["Flame Scythe", "Cursed Blade", "Blood Trident"]
const BOSS_STRATEGIES: Array[String] = ["Aggressive", "Defensive", "Tactical"]
const GATE_REQS: Array[int] = [2, 3]
const CASTLE_POTIONS: Array[int] = [2, 3, 4]

# --- Element & Affinity Mappings ---
const GUARD_ELEMENTS: Dictionary = {
	"Infernal Knight": "Fire",
	"Abyssal Shaman": "Dark",
	"Obsidian Gargoyle": "Earth"
}

const WEAPON_ELEMENTS: Dictionary = {
	"Flame Scythe": "Fire",
	"Cursed Blade": "Dark",
	"Blood Trident": "Blood"
}

const SEAL_ELEMENTS: Dictionary = {
	"Seal of Flame": "Fire",
	"Seal of Shadow": "Dark",
	"Seal of Blood": "Blood"
}

# --- Mechanics Effects Descriptions ---
const SEAL_EFFECTS: Dictionary = {
	"Seal of Flame": "Medan Panas: Pemain terkena 3 damage api tak langsung per ronde.",
	"Seal of Shadow": "Hisap Jiwa: Serangan Penjaga menyerap 15% damage menjadi HP.",
	"Seal of Blood": "Kulit Iblis: Seluruh damage fisik yang diterima Penjaga berkurang flat 4 poin."
}

const WEAPON_EFFECTS: Dictionary = {
	"Flame Scythe": "Infernal Burn: Serangan Heavy Bos memberi efek Burn DoT 5 HP/ronde selama 2 ronde.",
	"Cursed Blade": "Soul Drain: Serangan Bos menyerap 20% damage menjadi penyembuhan HP Bos.",
	"Blood Trident": "Armor Pierce: Serangan Bos menembus pertahanan, aksi Defend pemain hanya efektif 20%."
}

# --- Minimax Enum Mapping Helpers ---
# EvalFunc { HP_DIFF = 0, AGGRESSIVE = 1, DEFENSIVE = 2, WEIGHTED = 3, HP_RATIO = 4 }
# ActionOrder { DEFAULT = 0, AGGRESSIVE = 1, DEFENSIVE = 2, RANDOM = 3 }
const STRATEGY_MINIMAX_CONFIG: Dictionary = {
	"Aggressive": {
		"eval_func": 1,        # EvalFunc.AGGRESSIVE
		"action_order": 1,     # ActionOrder.AGGRESSIVE
		"desc": "Prioritas Heavy Attack & memaksimalkan selisih HP lawan."
	},
	"Defensive": {
		"eval_func": 2,        # EvalFunc.DEFENSIVE
		"action_order": 2,     # ActionOrder.DEFENSIVE
		"desc": "Prioritas Defend/Potion & mempertahankan kelangsungan hidup diri."
	},
	"Tactical": {
		"eval_func": 3,        # EvalFunc.WEIGHTED
		"action_order": 0,     # ActionOrder.DEFAULT
		"desc": "Kalkulasi seimbang antara selisih HP, stok potion, dan status bertahan."
	}
}

# --- C1: Affinity (guard_type <-> gate_seal) ---
const GUARD_SEAL_AFFINITY: Dictionary = {
	"Infernal Knight": ["Seal of Flame", "Seal of Blood"],
	"Abyssal Shaman": ["Seal of Shadow", "Seal of Blood"],
	"Obsidian Gargoyle": ["Seal of Flame", "Seal of Shadow"]
}

# --- C2: Doctrine Compatibility (guard_type <-> guard_strategy) ---
const GUARD_STRATEGY_COMPAT: Dictionary = {
	"Infernal Knight": ["Aggressive", "Tactical"],
	"Abyssal Shaman": ["Tactical", "Defensive"],
	"Obsidian Gargoyle": ["Defensive", "Tactical"]
}

# --- C3: Elemental Resonance (gate_seal <-> boss_weapon) ---
const SEAL_WEAPON_RESONANCE: Dictionary = {
	"Seal of Flame": "Flame Scythe",
	"Seal of Shadow": "Cursed Blade",
	"Seal of Blood": "Blood Trident"
}

# --- Metrics recorded during search ---
var assignments_count: int = 0
var consistency_checks: int = 0
var backtracks_count: int = 0
var search_time_ms: float = 0.0

# Constraint graph adjacency for Degree Heuristic & AC-3
# Cyclic network: guard_type <-> gate_seal <-> boss_weapon <-> guard_type
# Branch network: guard_type <-> guard_strategy <-> boss_strategy
const NEIGHBORS: Dictionary = {
	"guard_type": ["gate_seal", "guard_strategy", "boss_weapon"],
	"gate_seal": ["guard_type", "boss_weapon"],
	"boss_weapon": ["gate_seal", "guard_type"],
	"guard_strategy": ["guard_type", "boss_strategy"],
	"boss_strategy": ["guard_strategy"],
	"gate_req": [],
	"castle_potions": []
}

## Initial domain definition for all 7 variables
func get_initial_domains() -> Dictionary:
	return {
		"guard_type": GUARD_TYPES.duplicate(),
		"gate_seal": GATE_SEALS.duplicate(),
		"guard_strategy": GUARD_STRATEGIES.duplicate(),
		"boss_weapon": BOSS_WEAPONS.duplicate(),
		"boss_strategy": BOSS_STRATEGIES.duplicate(),
		"gate_req": GATE_REQS.duplicate(),
		"castle_potions": CASTLE_POTIONS.duplicate()
	}

## Solves the CSP using Backtracking Search with MRV, Degree Heuristic, LCV, and AC-3.
## Returns a Dictionary containing the complete assignment and search metrics.
func solve(use_mrv: bool = true, use_lcv: bool = true, use_ac3: bool = true, randomize: bool = true, overrides: Dictionary = {}) -> Dictionary:
	var start_time: int = Time.get_ticks_usec()
	assignments_count = 0
	consistency_checks = 0
	backtracks_count = 0

	var domains: Dictionary = get_initial_domains()

	# Apply overrides if specified (e.g. {"guard_type": "Abyssal Shaman"})
	for key in overrides:
		if domains.has(key):
			domains[key] = [overrides[key]]

	# Randomize domain order for diverse playthroughs
	if randomize:
		if not overrides.has("guard_type"):
			domains["guard_type"] = [GUARD_TYPES.pick_random()]
		for k in domains:
			if not overrides.has(k):
				domains[k].shuffle()

	# 1. Unary constraint enforcement (Node Consistency)
	_apply_unary_constraints(domains)

	# 2. AC-3 Preprocessing
	if use_ac3:
		_ac3(domains)

	# 3. Backtracking Search
	var assignment: Dictionary = {}
	var success: bool = _backtrack(assignment, domains, use_mrv, use_lcv, use_ac3)

	search_time_ms = (Time.get_ticks_usec() - start_time) / 1000.0

	# Extract solved variables with fallbacks
	var guard_type: String = assignment.get("guard_type", "Infernal Knight")
	var gate_seal: String = assignment.get("gate_seal", "Seal of Flame")
	var guard_strategy: String = assignment.get("guard_strategy", "Aggressive")
	var boss_weapon: String = assignment.get("boss_weapon", "Blood Trident")
	var boss_strategy: String = assignment.get("boss_strategy", "Tactical")
	var gate_req: int = assignment.get("gate_req", 2)
	var castle_potions: int = assignment.get("castle_potions", 3)

	# Potion allocation from global constraint: Potion_Guard + Potion_Boss <= castle_potions
	var guard_potions: int = 1
	var boss_potions: int = maxi(1, castle_potions - guard_potions)

	var g_cfg: Dictionary = STRATEGY_MINIMAX_CONFIG.get(guard_strategy, STRATEGY_MINIMAX_CONFIG["Aggressive"])
	var b_cfg: Dictionary = STRATEGY_MINIMAX_CONFIG.get(boss_strategy, STRATEGY_MINIMAX_CONFIG["Tactical"])

	return {
		"success": success,
		"assignment": assignment,
		# Guard specs
		"guard_type": guard_type,
		"guard_element": GUARD_ELEMENTS.get(guard_type, "Fire"),
		"guard_strategy": guard_strategy,
		"guard_eval_func": g_cfg.get("eval_func", 1),
		"guard_action_order": g_cfg.get("action_order", 1),
		"guard_strategy_desc": g_cfg.get("desc", ""),
		# Gate Seal specs
		"gate_seal": gate_seal,
		"gate_seal_element": SEAL_ELEMENTS.get(gate_seal, "Fire"),
		"gate_seal_effect": SEAL_EFFECTS.get(gate_seal, ""),
		# Boss specs
		"boss_weapon": boss_weapon,
		"boss_element": WEAPON_ELEMENTS.get(boss_weapon, "Blood"),
		"boss_weapon_effect": WEAPON_EFFECTS.get(boss_weapon, ""),
		"boss_strategy": boss_strategy,
		"boss_eval_func": b_cfg.get("eval_func", 3),
		"boss_action_order": b_cfg.get("action_order", 0),
		"boss_strategy_desc": b_cfg.get("desc", ""),
		# Level & Logistics
		"gate_req": gate_req,
		"castle_potions": castle_potions,
		"guard_potions": guard_potions,
		"boss_potions": boss_potions,
		# Performance Metrics
		"assignments_count": assignments_count,
		"consistency_checks": consistency_checks,
		"backtracks_count": backtracks_count,
		"time_ms": search_time_ms,
		"used_mrv": use_mrv,
		"used_lcv": use_lcv,
		"used_ac3": use_ac3
	}

## Unary constraints: gate_req >= 2, boss_weapon != ""
func _apply_unary_constraints(domains: Dictionary) -> void:
	# gate_req >= 2
	var valid_gates: Array = []
	for req in domains["gate_req"]:
		consistency_checks += 1
		if req >= 2:
			valid_gates.append(req)
	domains["gate_req"] = valid_gates

	# boss_weapon != ""
	var valid_weapons: Array = []
	for w in domains["boss_weapon"]:
		consistency_checks += 1
		if str(w).length() > 0:
			valid_weapons.append(w)
	domains["boss_weapon"] = valid_weapons

## AC-3 (Arc Consistency) Algorithm
func _ac3(domains: Dictionary) -> bool:
	var queue: Array = []
	for xi in NEIGHBORS:
		for xj in NEIGHBORS[xi]:
			queue.append([xi, xj])

	while queue.size() > 0:
		var arc: Array = queue.pop_front()
		var xi: String = arc[0]
		var xj: String = arc[1]

		if _revise(domains, xi, xj):
			if domains[xi].size() == 0:
				return false # Domain wiped out, problem unsolvable
			for xk in NEIGHBORS[xi]:
				if xk != xj:
					queue.append([xk, xi])
	return true

## Revises the domain of xi to satisfy constraints with xj
func _revise(domains: Dictionary, xi: String, xj: String) -> bool:
	var revised: bool = false
	var values_to_remove: Array = []

	for x_val in domains[xi]:
		var has_support: bool = false
		for y_val in domains[xj]:
			consistency_checks += 1
			if _is_binary_consistent(xi, x_val, xj, y_val):
				has_support = true
				break
		if not has_support:
			values_to_remove.append(x_val)
			revised = true

	for val in values_to_remove:
		domains[xi].erase(val)

	return revised

## Binary constraint checks for all 5 relational rules:
## C1: Affinity (guard_type <-> gate_seal)
## C2: Doctrine Compatibility (guard_type <-> guard_strategy)
## C3: Resonance (gate_seal <-> boss_weapon)
## C4: Diversity (guard_strategy <-> boss_strategy)
## C5: Element Anti-Monopoly (guard_type <-> boss_weapon)
func _is_binary_consistent(var1: String, val1, var2: String, val2) -> bool:
	# C1: Affinity (guard_type <-> gate_seal)
	if var1 == "guard_type" and var2 == "gate_seal":
		return val2 in GUARD_SEAL_AFFINITY.get(val1, [])
	elif var1 == "gate_seal" and var2 == "guard_type":
		return val1 in GUARD_SEAL_AFFINITY.get(val2, [])

	# C2: Doctrine Compatibility (guard_type <-> guard_strategy)
	if var1 == "guard_type" and var2 == "guard_strategy":
		return val2 in GUARD_STRATEGY_COMPAT.get(val1, [])
	elif var1 == "guard_strategy" and var2 == "guard_type":
		return val1 in GUARD_STRATEGY_COMPAT.get(val2, [])

	# C3: Resonance (gate_seal <-> boss_weapon)
	if var1 == "gate_seal" and var2 == "boss_weapon":
		return SEAL_WEAPON_RESONANCE.get(val1, "") == str(val2)
	elif var1 == "boss_weapon" and var2 == "gate_seal":
		return SEAL_WEAPON_RESONANCE.get(val2, "") == str(val1)

	# C4: Strategy Diversity (guard_strategy <-> boss_strategy)
	if var1 == "guard_strategy" and var2 == "boss_strategy":
		return str(val1) != str(val2)
	elif var1 == "boss_strategy" and var2 == "guard_strategy":
		return str(val1) != str(val2)

	# C5: Element Anti-Monopoly (guard_type <-> boss_weapon)
	if var1 == "guard_type" and var2 == "boss_weapon":
		return GUARD_ELEMENTS.get(val1, "") != WEAPON_ELEMENTS.get(val2, "")
	elif var1 == "boss_weapon" and var2 == "guard_type":
		return WEAPON_ELEMENTS.get(val1, "") != GUARD_ELEMENTS.get(val2, "")

	return true

## Recursive Backtracking Search
func _backtrack(assignment: Dictionary, domains: Dictionary, use_mrv: bool, use_lcv: bool, use_ac3: bool) -> bool:
	# Complete assignment test (7 variables)
	if assignment.size() == 7:
		return _is_globally_consistent(assignment)

	var var_name: String = _select_unassigned_variable(assignment, domains, use_mrv)
	var ordered_values: Array = _order_domain_values(var_name, assignment, domains, use_lcv)

	for val in ordered_values:
		consistency_checks += 1
		if _is_consistent_with_assignment(var_name, val, assignment):
			assignment[var_name] = val
			assignments_count += 1

			# Forward checking / domain pruning for child search
			var new_domains: Dictionary = _clone_domains(domains)
			new_domains[var_name] = [val]

			var inferences_valid: bool = true
			if use_ac3:
				inferences_valid = _ac3(new_domains)

			if inferences_valid:
				var result: bool = _backtrack(assignment, new_domains, use_mrv, use_lcv, use_ac3)
				if result:
					return true

			# Backtrack
			assignment.erase(var_name)
			backtracks_count += 1

	return false

## MRV Heuristic with Degree Heuristic tie-breaker
func _select_unassigned_variable(assignment: Dictionary, domains: Dictionary, use_mrv: bool) -> String:
	var all_vars: Array[String] = [
		"guard_type", "gate_seal", "guard_strategy",
		"boss_weapon", "boss_strategy", "gate_req", "castle_potions"
	]
	var unassigned: Array[String] = []
	for v in all_vars:
		if not assignment.has(v):
			unassigned.append(v)

	if not use_mrv or unassigned.size() <= 1:
		return unassigned[0]

	# Find variable with Minimum Remaining Values
	var best_var: String = unassigned[0]
	var min_size: int = domains[best_var].size()

	for v in unassigned:
		var size: int = domains[v].size()
		if size < min_size:
			min_size = size
			best_var = v
		elif size == min_size:
			# Degree Heuristic tie-breaker: most constraints on remaining unassigned variables
			var deg_best: int = _count_unassigned_neighbors(best_var, assignment)
			var deg_v: int = _count_unassigned_neighbors(v, assignment)
			if deg_v > deg_best:
				best_var = v

	return best_var

func _count_unassigned_neighbors(var_name: String, assignment: Dictionary) -> int:
	var count: int = 0
	for n in NEIGHBORS.get(var_name, []):
		if not assignment.has(n):
			count += 1
	return count

## Least Constraining Value (LCV) Heuristic
func _order_domain_values(var_name: String, assignment: Dictionary, domains: Dictionary, use_lcv: bool) -> Array:
	var values: Array = domains[var_name].duplicate()
	if not use_lcv or values.size() <= 1:
		return values

	# Score each value by how many choices it eliminates for unassigned neighbors
	var scores: Array = []
	for val in values:
		var eliminated: int = 0
		for neighbor in NEIGHBORS.get(var_name, []):
			if not assignment.has(neighbor):
				for n_val in domains[neighbor]:
					consistency_checks += 1
					if not _is_binary_consistent(var_name, val, neighbor, n_val):
						eliminated += 1
		scores.append({"value": val, "eliminated": eliminated})

	# Sort ascending by eliminated choices (least constraining first)
	scores.sort_custom(func(a, b): return a["eliminated"] < b["eliminated"])

	var sorted_values: Array = []
	for entry in scores:
		sorted_values.append(entry["value"])
	return sorted_values

## Check consistency against current partial assignment
func _is_consistent_with_assignment(var_name: String, val, assignment: Dictionary) -> bool:
	for assigned_var in assignment:
		var assigned_val = assignment[assigned_var]
		if not _is_binary_consistent(var_name, val, assigned_var, assigned_val):
			return false
	return true

## Global Constraint: Potion_Guard + Potion_Boss <= castle_potions
func _is_globally_consistent(assignment: Dictionary) -> bool:
	var castle_potions: int = assignment.get("castle_potions", 0)
	var guard_potions: int = 1
	var boss_potions: int = maxi(1, castle_potions - guard_potions)
	return (guard_potions + boss_potions) <= castle_potions

func _clone_domains(domains: Dictionary) -> Dictionary:
	var clone: Dictionary = {}
	for key in domains:
		clone[key] = domains[key].duplicate()
	return clone
