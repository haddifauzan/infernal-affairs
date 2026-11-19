class_name MDPSolver
extends RefCounted

## MDPSolver.gd
## Markov Decision Process (MDP) & Bayesian Decision Engine for Infernal Affairs Tahap 4.
## Based on Bellman Equations, Value Iteration, Maximum Expected Utility (MEU),
## and Bayesian Belief Updating under Uncertainty.

# --- State Space (S) ---
enum State {
	ALTAR = 0,            # s0: Crystal harvest origin
	SIMPANG_LEMBAH = 1,   # s1: Bifurcation point (decision state)
	JALUR_PINTAS = 2,     # s2: Shortcut corridor (hazard-prone chokepoint)
	JALUR_UTAMA = 3,      # s3: Main winding road (safe, longer)
	POS_PENJAGA = 4,      # s4: Goal terminal state (delivery success)
	MAGMA_TRAP = 5        # s5: Failure terminal state (scorched / intercepted)
}

# --- Action Space (A) ---
enum Action {
	PINTAS = 0,    # a_Pintas: Venture into shortcut corridor
	RAYA = 1,      # a_Raya: Take the long safe detour
	WAIT = 2,      # a_Wait: Pause at safe tile until danger clears
	BALIK = 3      # a_Balik: Retreat to Altar / previous safe node
}

# Human-readable labels
const STATE_NAMES: Dictionary = {
	State.ALTAR: "Altar",
	State.SIMPANG_LEMBAH: "Simpang Lembah",
	State.JALUR_PINTAS: "Jalur Pintas",
	State.JALUR_UTAMA: "Jalur Utama",
	State.POS_PENJAGA: "Pos Penjaga",
	State.MAGMA_TRAP: "Magma Trap"
}

const ACTION_NAMES: Dictionary = {
	Action.PINTAS: "Pintas (Shortcut)",
	Action.RAYA: "Raya (Main Road)",
	Action.WAIT: "Wait (Tunggu)",
	Action.BALIK: "Balik (Mundur)"
}

# --- MDP Parameters (Mengacu Slide Kuliah 09) ---
const DISCOUNT_GAMMA: float = 0.8
const REWARD_GOAL: float = 10.0
const REWARD_FAIL: float = -20.0
const LIVING_COST: float = -2.0

# --- Bayesian Belief Parameters ---
const PRIOR_HAZARD: float = 0.10
const PRIOR_SAFE: float = 0.90
const SENSOR_P_W_GIVEN_HAZARD: float = 0.90   # P(W | Hazard) - True positive
const SENSOR_P_W_GIVEN_SAFE: float = 0.10     # P(W | Safe)   - False alarm

## Bayesian Updating: P(Hazard | W)
## Calculates updated belief based on sensor evidence W (smoke / player presence).
static func update_bayesian_belief(warning_detected: bool) -> float:
	if not warning_detected:
		# P(Hazard | no W)
		var p_no_w_given_haz = 1.0 - SENSOR_P_W_GIVEN_HAZARD   # 0.10
		var p_no_w_given_safe = 1.0 - SENSOR_P_W_GIVEN_SAFE    # 0.90
		var p_no_w = (p_no_w_given_haz * PRIOR_HAZARD) + (p_no_w_given_safe * PRIOR_SAFE)
		return (p_no_w_given_haz * PRIOR_HAZARD) / p_no_w     # ~ 0.012
	else:
		# P(Hazard | W) = (P(W | Hazard) * P(Hazard)) / P(W)
		var p_w = (SENSOR_P_W_GIVEN_HAZARD * PRIOR_HAZARD) + (SENSOR_P_W_GIVEN_SAFE * PRIOR_SAFE)
		# 0.90 * 0.10 + 0.10 * 0.90 = 0.09 + 0.09 = 0.18
		var posterior = (SENSOR_P_W_GIVEN_HAZARD * PRIOR_HAZARD) / p_w
		# 0.09 / 0.18 = 0.50
		return posterior

## Evaluates transition model P(s' | s, a) with parameter hazard_prob (f)
## Returns Array of dictionaries: [{"next_state": State, "prob": float, "reward": float}]
static func get_transitions(s: int, a: int, f: float) -> Array[Dictionary]:
	var trans: Array[Dictionary] = []

	# Terminal states have no transitions
	if s == State.POS_PENJAGA or s == State.MAGMA_TRAP:
		return trans

	match s:
		State.ALTAR:
			# Moving towards Simpang Lembah
			trans.append({"next_state": State.SIMPANG_LEMBAH, "prob": 1.0, "reward": LIVING_COST})

		State.SIMPANG_LEMBAH:
			match a:
				Action.PINTAS:
					# High risk shortcut
					trans.append({"next_state": State.POS_PENJAGA, "prob": 1.0 - f, "reward": REWARD_GOAL})
					trans.append({"next_state": State.MAGMA_TRAP, "prob": f, "reward": REWARD_FAIL})
				Action.RAYA:
					# Safe long detour to Jalur Utama
					trans.append({"next_state": State.JALUR_UTAMA, "prob": 1.0, "reward": LIVING_COST})
				Action.WAIT:
					# Stay at Simpang waiting for safe window
					trans.append({"next_state": State.SIMPANG_LEMBAH, "prob": 1.0, "reward": LIVING_COST})
				Action.BALIK:
					# Retreat to Altar
					trans.append({"next_state": State.ALTAR, "prob": 1.0, "reward": LIVING_COST})

		State.JALUR_PINTAS:
			# In the chokepoint corridor
			match a:
				Action.PINTAS:
					trans.append({"next_state": State.POS_PENJAGA, "prob": 1.0 - f, "reward": REWARD_GOAL})
					trans.append({"next_state": State.MAGMA_TRAP, "prob": f, "reward": REWARD_FAIL})
				Action.WAIT:
					# Holding ground in corridor before fissure
					trans.append({"next_state": State.JALUR_PINTAS, "prob": 1.0, "reward": LIVING_COST * 0.5})
				Action.BALIK:
					trans.append({"next_state": State.SIMPANG_LEMBAH, "prob": 1.0, "reward": LIVING_COST})
				_:
					trans.append({"next_state": State.POS_PENJAGA, "prob": 1.0 - f, "reward": REWARD_GOAL})
					trans.append({"next_state": State.MAGMA_TRAP, "prob": f, "reward": REWARD_FAIL})

		State.JALUR_UTAMA:
			# Advancing from Jalur Utama to Pos Penjaga
			trans.append({"next_state": State.POS_PENJAGA, "prob": 1.0, "reward": REWARD_GOAL})

	return trans

## Computes Expected Utility Q(s, a) using Bellman Operator:
## Q(s, a) = sum_{s'} P(s' | s, a) * [ R(s') + gamma * V(s') ]
static func compute_q_value(s: int, a: int, f: float, V: Dictionary) -> float:
	var trans = get_transitions(s, a, f)
	if trans.is_empty():
		return 0.0

	var q: float = 0.0
	for t in trans:
		var s_prime: int = int(t["next_state"])
		var p: float = float(t["prob"])
		var r: float = float(t["reward"])
		var v_next: float = float(V.get(s_prime, 0.0))
		# If next state is terminal, V(s_prime) is 0
		if s_prime == State.POS_PENJAGA or s_prime == State.MAGMA_TRAP:
			v_next = 0.0
		q += p * (r + DISCOUNT_GAMMA * v_next)

	return q

## Solves MDP using Value Iteration up to convergence or max_iterations.
## Returns comprehensive result dictionary with V, Q, policy, and iteration history.
static func solve_value_iteration(hazard_prob: float, max_iterations: int = 50, epsilon: float = 0.001) -> Dictionary:
	var states = [State.ALTAR, State.SIMPANG_LEMBAH, State.JALUR_PINTAS, State.JALUR_UTAMA, State.POS_PENJAGA, State.MAGMA_TRAP]
	var actions = [Action.PINTAS, Action.RAYA, Action.WAIT, Action.BALIK]

	# Initial V values (k = 0)
	var V: Dictionary = {}
	for s in states:
		V[s] = 0.0

	var Q: Dictionary = {}
	var policy: Dictionary = {}
	var history: Array[Dictionary] = []

	# Initial snapshot at k = 0
	history.append({
		"k": 0,
		"V": V.duplicate(),
		"Q": {},
		"policy": {}
	})

	for k in range(1, max_iterations + 1):
		var next_V: Dictionary = {}
		var step_Q: Dictionary = {}
		var step_policy: Dictionary = {}
		var max_delta: float = 0.0

		for s in states:
			if s == State.POS_PENJAGA or s == State.MAGMA_TRAP:
				next_V[s] = 0.0
				continue

			step_Q[s] = {}
			var best_q: float = -999999.0
			var best_action: int = Action.RAYA

			# Evaluate valid actions for state s
			var available_actions: Array[int] = []
			if s == State.SIMPANG_LEMBAH:
				available_actions = [Action.PINTAS, Action.RAYA, Action.WAIT, Action.BALIK]
			elif s == State.JALUR_PINTAS:
				available_actions = [Action.PINTAS, Action.WAIT, Action.BALIK]
			elif s == State.JALUR_UTAMA:
				available_actions = [Action.RAYA]
			else:
				available_actions = [Action.RAYA]

			for a in available_actions:
				var q_val = compute_q_value(s, a, hazard_prob, V)
				step_Q[s][a] = q_val
				if q_val > best_q:
					best_q = q_val
					best_action = a

			next_V[s] = best_q
			step_policy[s] = best_action
			var delta = abs(next_V[s] - V[s])
			if delta > max_delta:
				max_delta = delta

		V = next_V
		Q = step_Q
		policy = step_policy

		history.append({
			"k": k,
			"V": V.duplicate(),
			"Q": Q.duplicate(true),
			"policy": policy.duplicate()
		})

		if max_delta < epsilon:
			break

	return {
		"hazard_prob": hazard_prob,
		"V": V,
		"Q": Q,
		"policy": policy,
		"iterations": history.size() - 1,
		"history": history
	}

## Direct query for optimal action at state s given current belief
static func get_optimal_action(current_state: int, hazard_prob: float) -> int:
	var solution = solve_value_iteration(hazard_prob)
	var pol: Dictionary = solution.get("policy", {})
	return int(pol.get(current_state, Action.RAYA))

