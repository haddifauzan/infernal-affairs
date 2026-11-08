class_name LogicEngine
extends RefCounted

## LogicEngine.gd
## Knowledge-Based Logic & Inference Engine for Infernal Affairs Tahap 4.
## Manages Propositional Logic Knowledge Base (KB), Horn Clauses, Forward Chaining,
## and partial observability of the Gate Seal & Boss Weapon.

signal guard_awakened(dialog_text: String)
signal seal_revealed(seal_name: String, seal_effect: String)
signal deduction_updated(intel_text: String)

# --- Knowledge Base (KB) Data Structures ---
var known_facts: Dictionary = {}
var inference_rules: Array[Dictionary] = []

# --- World Truths (Actual ground truth from CSP) ---
var true_guard_type: String = "Infernal Knight"
var true_gate_seal: String = "Seal of Flame"
var true_boss_weapon: String = "Flame Scythe"

# --- Observable State ---
var is_guard_awakened: bool = false
var is_seal_revealed: bool = false
var deduced_element: String = ""
var deduction_log: Array[String] = []

func initialize(guard_t: String, seal_t: String, boss_w: String) -> void:
	true_guard_type = guard_t
	true_gate_seal = seal_t
	true_boss_weapon = boss_w

	known_facts.clear()
	inference_rules.clear()
	deduction_log.clear()
	is_guard_awakened = false
	is_seal_revealed = false
	deduced_element = ""

	_setup_knowledge_base()

func _setup_knowledge_base() -> void:
	# Initial Fact
	tell("GateSeal_Unknown")

	# Rule 1: Level 2 Milestone triggers Guard Awakening (User Specification)
	# IF PlayerLevel_2 THEN GuardAwakened
	add_horn_clause(["PlayerLevel_2"], "GuardAwakened")

	# Rule 2: Guard Awakening triggers Full Seal Reveal
	# IF GuardAwakened THEN SealRevealed
	add_horn_clause(["GuardAwakened"], "SealRevealed")

	# Rule 3: Eliminating all resource minions also triggers full reveal
	# IF AllMinionsDefeated THEN GuardAwakened
	add_horn_clause(["AllMinionsDefeated"], "GuardAwakened")

	# Rule 4: Residual essence deduction rules (Sabotaging Minions)
	add_horn_clause(["ResidualEssence_Flame"], "Deduced_Flame")
	add_horn_clause(["ResidualEssence_Shadow"], "Deduced_Shadow")
	add_horn_clause(["ResidualEssence_Blood"], "Deduced_Blood")

## Adds a Horn Clause rule: IF all preconditions in 'body' are TRUE, THEN 'head' is TRUE.
func add_horn_clause(body: Array[String], head: String) -> void:
	inference_rules.append({
		"body": body,
		"head": head
	})

## Asserts a new fact into the Knowledge Base (TELL).
## Automatically runs Forward Chaining to infer new facts.
func tell(fact: String) -> void:
	if not known_facts.has(fact):
		known_facts[fact] = true
		_forward_chain()

## Queries if a proposition is entailed by KB (ASK).
func ask(query: String) -> bool:
	return known_facts.get(query, false)

## Forward Chaining Inference Algorithm
func _forward_chain() -> void:
	var new_fact_inferred: bool = true

	while new_fact_inferred:
		new_fact_inferred = false

		for rule in inference_rules:
			var head: String = rule["head"]
			if known_facts.has(head):
				continue # Already proven

			var body: Array = rule["body"]
			var body_satisfied: bool = true

			for premise in body:
				if not known_facts.has(premise):
					body_satisfied = false
					break

			if body_satisfied:
				known_facts[head] = true
				new_fact_inferred = true
				_on_fact_derived(head)

## Callback when a high-level proposition is proven true
func _on_fact_derived(fact: String) -> void:
	match fact:
		"GuardAwakened":
			if not is_guard_awakened:
				is_guard_awakened = true
				var dialog := _generate_awakening_dialog()
				guard_awakened.emit(dialog)

		"SealRevealed":
			if not is_seal_revealed:
				is_seal_revealed = true
				known_facts.erase("GateSeal_Unknown")
				known_facts["GateSeal_Revealed"] = true
				var seal_eff := _get_seal_effect_desc(true_gate_seal)
				seal_revealed.emit(true_gate_seal, seal_eff)

		"Deduced_Flame":
			deduced_element = "Flame"
			var msg := "DEDUKSI LOGIKA: Esensi api terdeteksi dari minion! Kemungkinan besar Segel gerbang berelemen Api (Seal of Flame)."
			deduction_log.append(msg)
			deduction_updated.emit(msg)

		"Deduced_Shadow":
			deduced_element = "Shadow"
			var msg := "DEDUKSI LOGIKA: Esensi kegelapan terdeteksi! Kemungkinan besar Segel gerbang berelemen Bayangan (Seal of Shadow)."
			deduction_log.append(msg)
			deduction_updated.emit(msg)

		"Deduced_Blood":
			deduced_element = "Blood"
			var msg := "DEDUKSI LOGIKA: Esensi darah terdeteksi! Kemungkinan besar Segel gerbang berelemen Darah (Seal of Blood)."
			deduction_log.append(msg)
			deduction_updated.emit(msg)

## Generate dramatic Awakening monologue from the Guard
func _generate_awakening_dialog() -> String:
	var g_name := true_guard_type
	var s_name := true_gate_seal
	return "I HAVE AWAKENED! The ancient %s burns with infernal wrath. Turn back, mortal, or be consumed by the %s!" % [s_name.to_upper(), g_name.to_upper()]

func _get_seal_effect_desc(seal: String) -> String:
	match seal:
		"Seal of Flame":
			return "Medan Panas: Pemain terkena damage api DoT per ronde."
		"Seal of Shadow":
			return "Hisap Jiwa: Serangan Penjaga menyerap damage menjadi HP."
		"Seal of Blood":
			return "Kulit Iblis: Mengurangi seluruh damage fisik yang diterima."
		_:
			return "Kekuatan Segel Kuno Aktif."

## Updates player level in KB
func update_player_level(level: int) -> void:
	tell("PlayerLevel_%d" % level)
	if level >= 2:
		tell("PlayerLevel_2")
	if level >= 3:
		tell("PlayerLevel_3")

## Records minion defeat in KB
func record_minion_defeated(carried_element: String, remaining_count: int) -> void:
	if carried_element != "":
		tell("ResidualEssence_%s" % carried_element)

	if remaining_count <= 0:
		tell("AllMinionsDefeated")

