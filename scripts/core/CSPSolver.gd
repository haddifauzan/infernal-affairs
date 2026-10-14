class_name CSPSolver
extends RefCounted

## CSPSolver.gd
## Constraint Satisfaction Problem (CSP) Solver for Infernal Affairs (Tubes AI Tahap 3).
## Implements formal <X, D, C> triplet modeling and Backtracking Search with:
## - Minimum Remaining Values (MRV) heuristic
## - Degree Heuristic (tie-breaker for MRV)
## - Least Constraining Value (LCV) ordering
## - AC-3 (Arc Consistency) constraint propagation

const GUARD_TYPES: Array[String] = ["Hell Knight", "Fire Shaman", "Gargoyle"]
const BOSS_WEAPONS: Array[String] = ["Flame Sword", "Cursed Scythe", "Dark Trident"]
const GATE_REQS: Array[int] = [2, 3]
const CASTLE_POTIONS: Array[int] = [2, 3, 4]

# Elemental mapping for diversity constraint: Element(Guard) != Element(BossWeapon)
const GUARD_ELEMENTS: Dictionary = {
	"Hell Knight": "Fire",
	"Fire Shaman": "Fire",
	"Gargoyle": "Dark"
}

const WEAPON_ELEMENTS: Dictionary = {
	"Flame Sword": "Fire",
	"Cursed Scythe": "Dark",
	"Dark Trident": "Water"
}

# Metrics recorded during search
var assignments_count: int = 0
var consistency_checks: int = 0
var backtracks_count: int = 0
var search_time_ms: float = 0.0

# Constraint graph adjacency for Degree Heuristic & AC-3
# guard_type and boss_weapon share a binary constraint (diversity)
# castle_potions affects global potion allocation
const NEIGHBORS: Dictionary = {
	"guard_type": ["boss_weapon"],
	"boss_weapon": ["guard_type"],
	"gate_req": [],
	"castle_potions": []
}

## Initial domain definition
func get_initial_domains() -> Dictionary:
	return {
		"guard_type": GUARD_TYPES.duplicate(),
		"boss_weapon": BOSS_WEAPONS.duplicate(),
		"gate_req": GATE_REQS.duplicate(),
		"castle_potions": CASTLE_POTIONS.duplicate()
	}

## Solves the CSP using Backtracking Search with MRV, Degree Heuristic, LCV, and AC-3.
## Returns a Dictionary containing the solution and search metrics.
func solve(use_mrv: bool = true, use_lcv: bool = true, use_ac3: bool = true) -> Dictionary:
	var start_time: int = Time.get_ticks_usec()
	assignments_count = 0
	consistency_checks = 0
	backtracks_count = 0

	var domains: Dictionary = get_initial_domains()

	# 1. Unary constraint enforcement (Node Consistency)
	_apply_unary_constraints(domains)

	# 2. AC-3 Preprocessing
	if use_ac3:
		_ac3(domains)

	# 3. Backtracking Search
	var assignment: Dictionary = {}
	var success: bool = _backtrack(assignment, domains, use_mrv, use_lcv, use_ac3)

	search_time_ms = (Time.get_ticks_usec() - start_time) / 1000.0

	var guard_type: String = assignment.get("guard_type", "Hell Knight")
	var boss_weapon: String = assignment.get("boss_weapon", "Cursed Scythe")
	var gate_req: int = assignment.get("gate_req", 2)
	var castle_potions: int = assignment.get("castle_potions", 3)

	# Allocate potions based on global constraint: Potion_Guard + Potion_Boss <= castle_potions
	var guard_potions: int = 1
	var boss_potions: int = maxi(1, castle_potions - guard_potions)

	return {
		"success": success,
		"assignment": assignment,
		"guard_type": guard_type,
		"guard_element": GUARD_ELEMENTS.get(guard_type, "Fire"),
		"boss_weapon": boss_weapon,
		"boss_element": WEAPON_ELEMENTS.get(boss_weapon, "Dark"),
		"gate_req": gate_req,
		"castle_potions": castle_potions,
		"guard_potions": guard_potions,
		"boss_potions": boss_potions,
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
	# Initialize queue with all directed arcs between constrained variables
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

## Binary constraint check: Element(guard) != Element(boss_weapon)
func _is_binary_consistent(var1: String, val1, var2: String, val2) -> bool:
	if (var1 == "guard_type" and var2 == "boss_weapon"):
		return GUARD_ELEMENTS.get(val1, "") != WEAPON_ELEMENTS.get(val2, "")
	elif (var1 == "boss_weapon" and var2 == "guard_type"):
		return WEAPON_ELEMENTS.get(val1, "") != GUARD_ELEMENTS.get(val2, "")
	return true

## Recursive Backtracking Search
func _backtrack(assignment: Dictionary, domains: Dictionary, use_mrv: bool, use_lcv: bool, use_ac3: bool) -> bool:
	# Complete assignment test
	if assignment.size() == 4:
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
	var unassigned: Array[String] = []
	for v in ["guard_type", "boss_weapon", "gate_req", "castle_potions"]:
		if not assignment.has(v):
			unassigned.append(v)

	if not use_mrv:
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
