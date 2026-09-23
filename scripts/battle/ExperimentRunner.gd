## ExperimentRunner.gd
## ──────────────────────────────────────────────────────────────────────────────
## Headless auto-battle engine for AI experiments.
##
## Runs simulated battles with no player input — both sides controlled by AI.
## The "player" side uses a fixed reactive strategy (configurable) so results
## reflect NPC behaviour changes, not human skill variance.
##
## Experiments:
##   1. Minimax vs Alpha-Beta — same depth, compare node counts & win rates
##   2. Eval function comparison — HP_DIFF vs Aggressive vs Defensive vs Weighted vs HP_Ratio
##   3. Action order comparison — DEFAULT vs AGGRESSIVE vs DEFENSIVE vs RANDOM
##   4. Depth comparison — depth 1..6
##   5. NPC behaviour characterisation
##   (Expectimax included as Algorithm option in experiments 1/2)
## ──────────────────────────────────────────────────────────────────────────────
class_name ExperimentRunner
extends RefCounted

## How the simulated "player" picks actions in headless mode
enum PlayerStrategy {
	RANDOM,      ## Picks a uniformly random valid action
	GREEDY,      ## Always attacks (maximise damage)
	DEFENSIVE,   ## Defends when < 50% HP, else attacks
	MINIMAX_2,   ## Runs a depth-2 minimax from the player's perspective
}

const BATTLES_PER_CONFIG: int = 10
const MAX_BATTLE_TURNS:   int = BattleState.MAX_TURNS

# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC ENTRY: run_comparison
# Returns a BBCode string summary for display in BattleHUD._exp_log
# ─────────────────────────────────────────────────────────────────────────────
func run_comparison(manager: BattleManager) -> String:
	var out := ""
	out += "[color=#ffcc00][b]═══ EXPERIMENT RESULTS ═══[/b][/color]\n"
	out += "[color=#888]Player strategy: GREEDY  |  %d battles/config[/color]\n\n" % BATTLES_PER_CONFIG

	out += _exp1_algo_comparison()
	out += _exp2_eval_comparison()
	out += _exp3_order_comparison()
	out += _exp4_depth_comparison()
	out += _exp5_behaviour_summary()
	return out

# ─────────────────────────────────────────────────────────────────────────────
# EXPERIMENT 1: Minimax vs Alpha-Beta vs Expectimax
# Same config, compare node counts and decisions
# ─────────────────────────────────────────────────────────────────────────────
func _exp1_algo_comparison() -> String:
	var out := "[color=#aa88ff][b]Exp 1: Algorithm Comparison (depth=4, HP_DIFF)[/b][/color]\n"
	out += "%-12s %-8s %-8s %-8s %-8s\n" % ["Algorithm", "W%", "Nodes", "Pruned", "Depth"]
	out += "[color=#444]" + "─".repeat(50) + "[/color]\n"

	var configs := [
		[MinimaxSolver.Algorithm.MINIMAX,    "Minimax"],
		[MinimaxSolver.Algorithm.ALPHABETA,  "Alpha-Beta"],
		[MinimaxSolver.Algorithm.EXPECTIMAX, "Expectimax"],
	]
	for cfg in configs:
		var r := _run_battles(cfg[0], MinimaxSolver.EvalFunc.HP_DIFF, MinimaxSolver.ActionOrder.DEFAULT, 4)
		var win_pct: int = (r.npc_wins as int) * 100 / BATTLES_PER_CONFIG
		var color: String = "[color=#44ff88]" if win_pct >= 50 else "[color=#ff4444]"
		out += "%-12s %s%d%%[/color]     %-8d %-8d %-8d\n" % [
			cfg[1], color, win_pct, r.avg_nodes as int, r.avg_pruned as int, r.avg_depth as int
		]
	out += "\n"
	return out

# ─────────────────────────────────────────────────────────────────────────────
# EXPERIMENT 2: Eval Function Comparison
# ─────────────────────────────────────────────────────────────────────────────
func _exp2_eval_comparison() -> String:
	var out := "[color=#aa88ff][b]Exp 2: Eval Function Comparison (Alpha-Beta, depth=4)[/b][/color]\n"
	out += "%-12s %-8s %-8s %-8s\n" % ["Eval", "W%", "D%", "L%"]
	out += "[color=#444]" + "─".repeat(45) + "[/color]\n"

	var evals := [
		[MinimaxSolver.EvalFunc.HP_DIFF,    "HP Diff"],
		[MinimaxSolver.EvalFunc.AGGRESSIVE, "Aggressive"],
		[MinimaxSolver.EvalFunc.DEFENSIVE,  "Defensive"],
		[MinimaxSolver.EvalFunc.WEIGHTED,   "Weighted"],
		[MinimaxSolver.EvalFunc.HP_RATIO,   "HP Ratio"],
	]
	for cfg in evals:
		var r := _run_battles(MinimaxSolver.Algorithm.ALPHABETA, cfg[0], MinimaxSolver.ActionOrder.DEFAULT, 4)
		var wp: int = (r.npc_wins   as int) * 100 / BATTLES_PER_CONFIG
		var dp: int = (r.draws      as int) * 100 / BATTLES_PER_CONFIG
		var lp: int = (r.npc_losses as int) * 100 / BATTLES_PER_CONFIG
		out += "%-12s %-8d %-8d %-8d\n" % [cfg[1], wp, dp, lp]
	out += "\n"
	return out

# ─────────────────────────────────────────────────────────────────────────────
# EXPERIMENT 3: Action Order Comparison
# ─────────────────────────────────────────────────────────────────────────────
func _exp3_order_comparison() -> String:
	var out := "[color=#aa88ff][b]Exp 3: Action Order Comparison (Alpha-Beta, depth=4, HP_DIFF)[/b][/color]\n"
	out += "%-12s %-8s %-8s %-8s\n" % ["Order", "W%", "Nodes", "Pruned"]
	out += "[color=#444]" + "─".repeat(45) + "[/color]\n"

	var orders := [
		[MinimaxSolver.ActionOrder.DEFAULT,    "Default"],
		[MinimaxSolver.ActionOrder.AGGRESSIVE, "Aggressive"],
		[MinimaxSolver.ActionOrder.DEFENSIVE,  "Defensive"],
		[MinimaxSolver.ActionOrder.RANDOM,     "Random"],
	]
	for cfg in orders:
		var r := _run_battles(MinimaxSolver.Algorithm.ALPHABETA, MinimaxSolver.EvalFunc.HP_DIFF, cfg[0], 4)
		var wp: int = (r.npc_wins as int) * 100 / BATTLES_PER_CONFIG
		out += "%-12s %-8d %-8d %-8d\n" % [cfg[1], wp, r.avg_nodes as int, r.avg_pruned as int]
	out += "\n"
	return out

# ─────────────────────────────────────────────────────────────────────────────
# EXPERIMENT 4: Depth Comparison
# ─────────────────────────────────────────────────────────────────────────────
func _exp4_depth_comparison() -> String:
	var out := "[color=#aa88ff][b]Exp 4: Depth Comparison (Alpha-Beta, HP_DIFF)[/b][/color]\n"
	out += "%-8s %-8s %-10s %-10s\n" % ["Depth", "W%", "Nodes", "Pruned"]
	out += "[color=#444]" + "─".repeat(42) + "[/color]\n"

	for d in range(1, 7):
		var r := _run_battles(MinimaxSolver.Algorithm.ALPHABETA, MinimaxSolver.EvalFunc.HP_DIFF, MinimaxSolver.ActionOrder.DEFAULT, d)
		var wp: int = (r.npc_wins as int) * 100 / BATTLES_PER_CONFIG
		out += "%-8d %-8d %-10d %-10d\n" % [d, wp, r.avg_nodes as int, r.avg_pruned as int]
	out += "\n"
	return out

# ─────────────────────────────────────────────────────────────────────────────
# EXPERIMENT 5: NPC Behaviour Profile
# Shows what actions the NPC prefers under different eval functions
# ─────────────────────────────────────────────────────────────────────────────
func _exp5_behaviour_summary() -> String:
	var out := "[color=#aa88ff][b]Exp 5: NPC Behaviour Profile (action frequencies)[/b][/color]\n"
	out += "%-12s %-8s %-8s %-8s %-8s\n" % ["Eval", "Atk%", "Heavy%", "Def%", "Pot%"]
	out += "[color=#444]" + "─".repeat(50) + "[/color]\n"

	var evals := [
		[MinimaxSolver.EvalFunc.HP_DIFF,    "HP Diff"],
		[MinimaxSolver.EvalFunc.AGGRESSIVE, "Aggressive"],
		[MinimaxSolver.EvalFunc.DEFENSIVE,  "Defensive"],
		[MinimaxSolver.EvalFunc.WEIGHTED,   "Weighted"],
	]
	for cfg in evals:
		var r := _run_battles(MinimaxSolver.Algorithm.ALPHABETA, cfg[0], MinimaxSolver.ActionOrder.DEFAULT, 4)
		var total: int = max(1, r.total_npc_actions as int)
		var a: int = (r.npc_action_counts as Dictionary).get(MinimaxSolver.Action.ATTACK,       0) * 100 / total
		var h: int = (r.npc_action_counts as Dictionary).get(MinimaxSolver.Action.HEAVY_ATTACK, 0) * 100 / total
		var d: int = (r.npc_action_counts as Dictionary).get(MinimaxSolver.Action.DEFEND,       0) * 100 / total
		var p: int = (r.npc_action_counts as Dictionary).get(MinimaxSolver.Action.POTION,       0) * 100 / total
		out += "%-12s %-8d %-8d %-8d %-8d\n" % [cfg[1], a, h, d, p]
	out += "\n"
	return out

# ─────────────────────────────────────────────────────────────────────────────
# CORE SIMULATION
# Runs BATTLES_PER_CONFIG headless battles with given config.
# Returns aggregate statistics.
# ─────────────────────────────────────────────────────────────────────────────
func _run_battles(algo: int, eval: int, order: int, depth: int) -> Dictionary:
	var solver := MinimaxSolver.new()
	solver.algorithm    = algo
	solver.eval_func    = eval
	solver.action_order = order
	solver.max_depth    = depth

	var npc_wins   := 0
	var npc_losses := 0
	var draws      := 0
	var total_nodes   := 0
	var total_pruned  := 0
	var total_depth   := 0
	var npc_action_counts: Dictionary = {}
	var total_npc_actions := 0

	for _battle in range(BATTLES_PER_CONFIG):
		var state := BattleState.new()
		state.player_hp      = BattleState.MAX_HP
		state.npc_hp         = BattleState.MAX_HP
		state.player_potions = BattleState.MAX_POTIONS
		state.npc_potions    = BattleState.MAX_POTIONS
		state.turn           = BattleState.Turn.PLAYER

		var turn_nodes  := 0
		var turn_pruned := 0
		var turn_depth  := 0
		var turn_count  := 0

		while not state.is_terminal():
			if state.turn == BattleState.Turn.PLAYER:
				## Simulated player: GREEDY (always attacks or uses potion at low HP)
				var action := _greedy_player_action(state)
				state = solver.apply_action(state, action)
			else:
				## NPC: full Minimax
				var result := solver.best_move(state)
				var npc_action := result.get("best_action", MinimaxSolver.Action.ATTACK) as int
				turn_nodes  += result.get("nodes_visited", 0) as int
				turn_pruned += result.get("nodes_pruned",  0) as int
				turn_depth  = max(turn_depth, result.get("max_depth_reached", 0) as int)

				## Track action frequency for behaviour profiling
				npc_action_counts[npc_action] = npc_action_counts.get(npc_action, 0) + 1
				total_npc_actions += 1

				state = solver.apply_action(state, npc_action)

			turn_count += 1

		## Battle outcome
		match state.get_winner():
			"npc":    npc_wins   += 1
			"player": npc_losses += 1
			_:        draws      += 1

		total_nodes  += turn_nodes
		total_pruned += turn_pruned
		total_depth  = max(total_depth, turn_depth)

	return {
		"npc_wins":          npc_wins,
		"npc_losses":        npc_losses,
		"draws":             draws,
		"avg_nodes":         total_nodes  / BATTLES_PER_CONFIG,
		"avg_pruned":        total_pruned / BATTLES_PER_CONFIG,
		"avg_depth":         total_depth,
		"npc_action_counts": npc_action_counts,
		"total_npc_actions": total_npc_actions,
	}

# ─────────────────────────────────────────────────────────────────────────────
# PLAYER SIMULATION STRATEGIES
# ─────────────────────────────────────────────────────────────────────────────

## GREEDY: use potion if HP critical, else always attack
func _greedy_player_action(state: BattleState) -> int:
	if state.player_hp < 30 and state.player_potions > 0:
		return MinimaxSolver.Action.POTION
	return MinimaxSolver.Action.ATTACK

## RANDOM: uniformly random from available actions
func _random_player_action(state: BattleState) -> int:
	var acts: Array[int] = [MinimaxSolver.Action.ATTACK, MinimaxSolver.Action.HEAVY_ATTACK, MinimaxSolver.Action.DEFEND]
	if state.player_potions > 0:
		acts.append(MinimaxSolver.Action.POTION)
	return acts[randi() % acts.size()]
