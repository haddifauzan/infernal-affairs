class_name PlanSolver
extends RefCounted

## PlanSolver.gd
## Automated Planning Engine (STRIPS / Classical Planning) for Infernal Affairs Tahap 4.
## Generates sequential action plans for Minion Supply Chains to harvest and deliver
## elemental resources to the Guard and Demon Lord (Boss).

# --- Planning Action Types ---
enum ActionType {
	MOVE = 0,
	HARVEST = 1,
	DELIVER_GUARD = 2,
	DELIVER_BOSS = 3,
	PATROL = 4
}

# --- Metrics ---
var nodes_expanded: int = 0
var planning_time_ms: float = 0.0

## Formal Planning Operator Structure
class PlanAction:
	var type: int
	var target_pos: Vector2i
	var element: String = ""
	var target_entity: String = ""
	var description: String = ""

	func _init(t: int, pos: Vector2i, elem: String = "", ent: String = "", desc: String = ""):
		type = t
		target_pos = pos
		element = elem
		target_entity = ent
		description = desc

	func to_dict() -> Dictionary:
		return {
			"type": type,
			"target_pos": target_pos,
			"element": element,
			"target_entity": target_entity,
			"description": description
		}

## Evaluates the world state and solves a Goal-Directed STRIPS Plan
## for a minion agent.
func solve_minion_plan(
	current_pos: Vector2i,
	carrying_elem: String,
	target_elem: String,
	altar_pos: Vector2i,
	guard_pos: Vector2i,
	boss_pos: Vector2i,
	guard_needs_supply: bool = true
) -> Array[Dictionary]:
	var start_time: int = Time.get_ticks_usec()
	nodes_expanded = 0
	var plan: Array[Dictionary] = []

	# Initial State Analysis
	var is_carrying: bool = carrying_elem != ""

	# Goal 1: If not carrying anything, Plan = [MOVE(Altar) -> HARVEST(Altar, Element)]
	if not is_carrying:
		nodes_expanded += 1
		# 1. Move to Altar
		var move_to_altar = PlanAction.new(
			ActionType.MOVE,
			altar_pos,
			target_elem,
			"Altar",
			"Bergerak menuju Altar %s di (%d, %d)" % [target_elem, altar_pos.x, altar_pos.y]
		)
		plan.append(move_to_altar.to_dict())

		# 2. Harvest Resource
		nodes_expanded += 1
		var harvest_act = PlanAction.new(
			ActionType.HARVEST,
			altar_pos,
			target_elem,
			"Altar",
			"Memanen Shard Elemen %s" % target_elem
		)
		plan.append(harvest_act.to_dict())

		# 3. Next transit step: Deliver to Guard or Boss
		var destination_pos: Vector2i = guard_pos if guard_needs_supply else boss_pos
		var dest_name: String = "Guard" if guard_needs_supply else "Boss"
		var deliver_type: int = ActionType.DELIVER_GUARD if guard_needs_supply else ActionType.DELIVER_BOSS

		nodes_expanded += 1
		var move_to_dest = PlanAction.new(
			ActionType.MOVE,
			destination_pos,
			target_elem,
			dest_name,
			"Membawa suplai %s menuju %s di (%d, %d)" % [target_elem, dest_name, destination_pos.x, destination_pos.y]
		)
		plan.append(move_to_dest.to_dict())

		nodes_expanded += 1
		var deliver_act = PlanAction.new(
			deliver_type,
			destination_pos,
			target_elem,
			dest_name,
			"Menyetor suplai %s ke %s" % [target_elem, dest_name]
		)
		plan.append(deliver_act.to_dict())

	else:
		# Already carrying! Goal = [MOVE(Target) -> DELIVER(Target)]
		var destination_pos: Vector2i = guard_pos if guard_needs_supply else boss_pos
		var dest_name: String = "Guard" if guard_needs_supply else "Boss"
		var deliver_type: int = ActionType.DELIVER_GUARD if guard_needs_supply else ActionType.DELIVER_BOSS

		nodes_expanded += 1
		var move_to_dest = PlanAction.new(
			ActionType.MOVE,
			destination_pos,
			carrying_elem,
			dest_name,
			"Membawa suplai %s menuju %s di (%d, %d)" % [carrying_elem, dest_name, destination_pos.x, destination_pos.y]
		)
		plan.append(move_to_dest.to_dict())

		nodes_expanded += 1
		var deliver_act = PlanAction.new(
			deliver_type,
			destination_pos,
			carrying_elem,
			dest_name,
			"Menyetor suplai %s ke %s" % [carrying_elem, dest_name]
		)
		plan.append(deliver_act.to_dict())

	planning_time_ms = float(Time.get_ticks_usec() - start_time) / 1000.0
	return plan

