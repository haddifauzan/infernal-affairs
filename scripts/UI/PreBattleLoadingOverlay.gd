class_name PreBattleLoadingOverlay
extends CanvasLayer

## PreBattleLoadingOverlay.gd
## Live Debug Overlay for the Pre-Battle Loading Transition (Tubes AI Tahap 3).
## Visualizes the Local Search Dynamic Balancer (Simulated Annealing vs Hill Climbing)
## optimizing NPC combat loadout in real-time before entering turn-based battle.

signal proceed_to_battle(config: Dictionary)
signal cancelled()

# Configuration data
var enemy_type: String = "guard"
var enemy_name: String = "Hell Guard"
var enemy_weapon: String = ""
var enemy_element: String = ""
var player_stats: Dictionary = {}
var target_ratio: float = LocalSearchBalancer.RATIO_GUARD
var current_algo: String = "sa" # "sa" (Simulated Annealing) or "hc" (Hill Climbing)

# Balancer results & animation state
var balancer_result: Dictionary = {}
var step_logs: Array[Dictionary] = []
var current_step_idx: int = 0
var is_animating: bool = false
var step_timer: float = 0.0
const STEP_INTERVAL: float = 0.045

# Audio
var sfx_tick: AudioStream
var audio_player: AudioStreamPlayer

# UI Nodes
var _root: MarginContainer
var _title_label: Label
var _enemy_subtitle_label: Label
var _algo_btn: Button
var _proceed_btn: Button
var _cancel_btn: Button

# Player & NPC Power Cards
var _lbl_player_power: Label
var _lbl_target_power: Label
var _lbl_npc_power: Label
var _lbl_fitness_score: Label

# Visualizer Elements
var _progress_bar: ProgressBar
var _step_counter_label: Label
var _log_box: RichTextLabel
var _stat_grid: GridContainer

# Comparison Labels
var _lbl_hp_comp: Label
var _lbl_atk_comp: Label
var _lbl_heavy_comp: Label
var _lbl_def_comp: Label
var _lbl_pot_comp: Label
var _lbl_depth_comp: Label

func _init() -> void:
	layer = 15

func _ready() -> void:
	sfx_tick = load("res://assets/audio/sfx_balancer_tick.wav")
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "TickAudio"
	audio_player.volume_db = -12.0
	add_child(audio_player)

	_build_ui()
	_run_optimization()

## Setup encounter context before adding to tree
func setup_encounter(type: String, name: String, element: String, weapon: String, p_stats: Dictionary) -> void:
	enemy_type = type
	enemy_name = name
	enemy_element = element
	enemy_weapon = weapon
	player_stats = p_stats
	target_ratio = LocalSearchBalancer.RATIO_BOSS if enemy_type == "boss" else LocalSearchBalancer.RATIO_GUARD

func _build_ui() -> void:
	# Full screen root
	_root = MarginContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_theme_constant_override("margin_left", 30)
	_root.add_theme_constant_override("margin_right", 30)
	_root.add_theme_constant_override("margin_top", 20)
	_root.add_theme_constant_override("margin_bottom", 20)
	add_child(_root)

	# Background styling with translucent dark neon obsidian
	var bg_panel := Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.04, 0.03, 0.07, 0.96)
	bg_style.border_color = Color(0.9, 0.35, 0.1, 0.85)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(10)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	_root.add_child(bg_panel)

	# Main layout
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	_root.add_child(main_vbox)

	# --- 1. HEADER BAR ---
	var header_box := HBoxContainer.new()
	header_box.add_theme_constant_override("separation", 12)
	main_vbox.add_child(header_box)

	var icon_chip := TextureRect.new()
	var chip_tex = load("res://assets/sprites/ui/skills/icon_algorithm_chip.png")
	if chip_tex:
		icon_chip.texture = chip_tex
		icon_chip.custom_minimum_size = Vector2(36, 36)
		icon_chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_box.add_child(icon_chip)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(title_vbox)

	_title_label = Label.new()
	_title_label.text = "ENCOUNTER OPTIMIZATION SYSTEM  |  LOCAL SEARCH DYNAMIC BALANCER"
	_title_label.add_theme_font_size_override("font_size", 15)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15))
	title_vbox.add_child(_title_label)

	_enemy_subtitle_label = Label.new()
	var elem_info: String = " (%s)" % enemy_element if enemy_element.length() > 0 else ""
	var wep_info: String = " [Senjata: %s]" % enemy_weapon if enemy_weapon.length() > 0 else ""
	_enemy_subtitle_label.text = "Target: %s%s%s   |   Target Power Ratio: %.2fx" % [enemy_name, elem_info, wep_info, target_ratio]
	_enemy_subtitle_label.add_theme_font_size_override("font_size", 12)
	_enemy_subtitle_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	title_vbox.add_child(_enemy_subtitle_label)

	_algo_btn = Button.new()
	_algo_btn.text = "Algoritma: Simulated Annealing (Demo)"
	_algo_btn.add_theme_font_size_override("font_size", 11)
	_algo_btn.custom_minimum_size = Vector2(230, 32)
	_algo_btn.pressed.connect(_toggle_algorithm)
	header_box.add_child(_algo_btn)

	var sep1 := HSeparator.new()
	main_vbox.add_child(sep1)

	# --- 2. TOP METRICS CARDS (Player vs Target vs Enemy) ---
	var metrics_row := HBoxContainer.new()
	metrics_row.add_theme_constant_override("separation", 10)
	main_vbox.add_child(metrics_row)

	# Card A: Player Status
	var p_card := _make_info_card("1. KONDISI NYATA PLAYER", Color(0.0, 0.9, 0.8))
	metrics_row.add_child(p_card)
	var p_vbox: VBoxContainer = p_card.get_node("VBox")

	var p_hp: int = player_stats.get("hp", 100)
	var p_pot: int = player_stats.get("potions", 1)
	var p_atk: int = player_stats.get("attack", 12)
	var p_def: int = player_stats.get("defense", 5)
	var p_lvl: int = player_stats.get("level", 1)
	var p_power: float = LocalSearchBalancer.calculate_player_power(p_hp, p_atk, p_def, p_pot)

	var p_info := Label.new()
	p_info.text = "Level: %d  |  HP: %d  |  Potions: %d\nAtk: %d  |  Def: %d" % [p_lvl, p_hp, p_pot, p_atk, p_def]
	p_info.add_theme_font_size_override("font_size", 11)
	p_vbox.add_child(p_info)

	_lbl_player_power = Label.new()
	_lbl_player_power.text = "Player Power: %.1f" % p_power
	_lbl_player_power.add_theme_font_size_override("font_size", 12)
	_lbl_player_power.add_theme_color_override("font_color", Color(0.2, 1.0, 0.8))
	p_vbox.add_child(_lbl_player_power)

	# Card B: Target Difficulty Ratio
	var t_card := _make_info_card("2. FORMULA KESEIMBANGAN f(S)", Color(1.0, 0.8, 0.2))
	metrics_row.add_child(t_card)
	var t_vbox: VBoxContainer = t_card.get_node("VBox")

	_lbl_target_power = Label.new()
	var t_power: float = p_power * target_ratio
	_lbl_target_power.text = "Target NPC Power: %.1f\n(Player Power x %.2f)" % [t_power, target_ratio]
	_lbl_target_power.add_theme_font_size_override("font_size", 11)
	_lbl_target_power.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	t_vbox.add_child(_lbl_target_power)

	_lbl_fitness_score = Label.new()
	_lbl_fitness_score.text = "Fitness: -100.0 (Calculating...)"
	_lbl_fitness_score.add_theme_font_size_override("font_size", 12)
	_lbl_fitness_score.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	t_vbox.add_child(_lbl_fitness_score)

	# Card C: NPC Current Balanced Power
	var e_card := _make_info_card("3. POWER NPC HASIL OPTIMASI", Color(0.9, 0.3, 0.2))
	metrics_row.add_child(e_card)
	var e_vbox: VBoxContainer = e_card.get_node("VBox")

	_lbl_npc_power = Label.new()
	_lbl_npc_power.text = "NPC Power: 0.0"
	_lbl_npc_power.add_theme_font_size_override("font_size", 12)
	_lbl_npc_power.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	e_vbox.add_child(_lbl_npc_power)

	var formula_lbl := Label.new()
	formula_lbl.text = "HP + 2.2*Atk + 1.2*Heavy\n+ 3*Def + 0.7*PotHeal + 15*Depth"
	formula_lbl.add_theme_font_size_override("font_size", 10)
	formula_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	e_vbox.add_child(formula_lbl)

	# --- 3. MIDDLE SECTION: LIVE LOG & STAT COMPARISON ---
	var mid_row := HBoxContainer.new()
	mid_row.add_theme_constant_override("separation", 12)
	mid_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(mid_row)

	# Left Column: Live Step Search Log
	var log_panel := PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_style := StyleBoxFlat.new()
	log_style.bg_color = Color(0.02, 0.02, 0.05, 0.9)
	log_style.border_color = Color(0.4, 0.2, 0.6, 0.8)
	log_style.set_border_width_all(1)
	log_style.set_corner_radius_all(6)
	log_style.set_content_margin_all(8)
	log_panel.add_theme_stylebox_override("panel", log_style)
	mid_row.add_child(log_panel)

	var log_vbox := VBoxContainer.new()
	log_vbox.add_theme_constant_override("separation", 4)
	log_panel.add_child(log_vbox)

	var log_hdr := HBoxContainer.new()
	log_vbox.add_child(log_hdr)

	var log_title := Label.new()
	log_title.text = "LIVE SEARCH STEP LOG (Iterasi Perturbasi Lokal)"
	log_title.add_theme_font_size_override("font_size", 12)
	log_title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	log_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_hdr.add_child(log_title)

	_step_counter_label = Label.new()
	_step_counter_label.text = "Step: 0/50"
	_step_counter_label.add_theme_font_size_override("font_size", 11)
	_step_counter_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	log_hdr.add_child(_step_counter_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 8)
	_progress_bar.show_percentage = false
	var pb_style := StyleBoxFlat.new()
	pb_style.bg_color = Color(0.1, 0.8, 0.5, 0.9)
	pb_style.set_corner_radius_all(4)
	_progress_bar.add_theme_stylebox_override("fill", pb_style)
	log_vbox.add_child(_progress_bar)

	_log_box = RichTextLabel.new()
	_log_box.bbcode_enabled = true
	_log_box.scroll_following = true
	_log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_box.add_theme_font_size_override("normal_font_size", 11)
	log_vbox.add_child(_log_box)

	# Right Column: Initial vs Optimized Stat Comparison Card
	var comp_panel := PanelContainer.new()
	comp_panel.custom_minimum_size = Vector2(310, 0)
	var comp_style := StyleBoxFlat.new()
	comp_style.bg_color = Color(0.06, 0.04, 0.10, 0.9)
	comp_style.border_color = Color(0.7, 0.3, 0.8, 0.8)
	comp_style.set_border_width_all(1)
	comp_style.set_corner_radius_all(6)
	comp_style.set_content_margin_all(10)
	comp_panel.add_theme_stylebox_override("panel", comp_style)
	mid_row.add_child(comp_panel)

	var comp_vbox := VBoxContainer.new()
	comp_vbox.add_theme_constant_override("separation", 6)
	comp_panel.add_child(comp_vbox)

	var comp_title := Label.new()
	comp_title.text = "KONFIGURASI AKHIR MUSUH"
	comp_title.add_theme_font_size_override("font_size", 12)
	comp_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.8))
	comp_vbox.add_child(comp_title)

	var comp_sub := Label.new()
	comp_sub.text = "Awal (S_0)  ->  Optimal (S*)"
	comp_sub.add_theme_font_size_override("font_size", 10)
	comp_sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	comp_vbox.add_child(comp_sub)

	var comp_sep := HSeparator.new()
	comp_vbox.add_child(comp_sep)

	_stat_grid = GridContainer.new()
	_stat_grid.columns = 2
	_stat_grid.add_theme_constant_override("h_separation", 8)
	_stat_grid.add_theme_constant_override("v_separation", 6)
	comp_vbox.add_child(_stat_grid)

	_lbl_hp_comp = _add_stat_row(_stat_grid, "HP Target:")
	_lbl_atk_comp = _add_stat_row(_stat_grid, "Attack Damage:")
	_lbl_heavy_comp = _add_stat_row(_stat_grid, "Heavy Attack:")
	_lbl_def_comp = _add_stat_row(_stat_grid, "Defense Stat:")
	_lbl_pot_comp = _add_stat_row(_stat_grid, "Potion Count/Heal:")
	_lbl_depth_comp = _add_stat_row(_stat_grid, "Minimax Depth:")

	var note_lbl := Label.new()
	note_lbl.text = "[OK] Menjamin win-rate ~55%\n[OK] Durasi pertempuran 5-7 turn\n[OK] Dinamis sesuai level & HP player"
	note_lbl.add_theme_font_size_override("font_size", 10)
	note_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.6))
	comp_vbox.add_child(note_lbl)

	# --- 4. BOTTOM ACTION CONTROLS ---
	var bot_box := HBoxContainer.new()
	bot_box.add_theme_constant_override("separation", 12)
	main_vbox.add_child(bot_box)

	_cancel_btn = Button.new()
	_cancel_btn.text = " [Mundur / Batal]"
	_cancel_btn.add_theme_font_size_override("font_size", 12)
	_cancel_btn.custom_minimum_size = Vector2(140, 36)
	_cancel_btn.pressed.connect(_on_cancel_pressed)
	bot_box.add_child(_cancel_btn)

	var spc := Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_box.add_child(spc)

	_proceed_btn = Button.new()
	_proceed_btn.text = " Mulai Duel (Masuk Arena Turn-Based) "
	_proceed_btn.add_theme_font_size_override("font_size", 13)
	_proceed_btn.custom_minimum_size = Vector2(280, 38)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.9, 0.35, 0.1, 0.9)
	btn_style.set_corner_radius_all(6)
	btn_style.set_content_margin_all(8)
	_proceed_btn.add_theme_stylebox_override("normal", btn_style)
	_proceed_btn.pressed.connect(_on_proceed_pressed)
	bot_box.add_child(_proceed_btn)

func _make_info_card(title_text: String, border_col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.04, 0.09, 0.85)
	s.border_color = border_col
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", s)

	var vb := VBoxContainer.new()
	vb.name = "VBox"
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)

	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", 11)
	t.add_theme_color_override("font_color", border_col)
	vb.add_child(t)
	return p

func _add_stat_row(parent: Control, label_text: String) -> Label:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	parent.add_child(lbl)

	var val_lbl := Label.new()
	val_lbl.text = "--"
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	parent.add_child(val_lbl)
	return val_lbl

# ---------------------------------------------------------------
# RUN LOCAL SEARCH OPTIMIZATION & REAL-TIME ANIMATION
# ---------------------------------------------------------------
func _run_optimization() -> void:
	var p_hp: int = player_stats.get("hp", 100)
	var p_pot: int = player_stats.get("potions", 1)
	var p_atk: int = player_stats.get("attack", 12)
	var p_def: int = player_stats.get("defense", 5)
	var player_power: float = LocalSearchBalancer.calculate_player_power(p_hp, p_atk, p_def, p_pot)

	var bounds: Dictionary = LocalSearchBalancer.get_domain_bounds(player_stats, player_power)
	var s0: Dictionary = LocalSearchBalancer.get_initial_state(enemy_type, player_stats)

	if current_algo == "sa":
		_algo_btn.text = "Algoritma: Simulated Annealing (Klik to Swap)"
		_algo_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6))
		balancer_result = LocalSearchBalancer.run_simulated_annealing(s0, player_power, target_ratio, 50, bounds)
	elif current_algo == "hc":
		_algo_btn.text = "Algoritma: Steepest-Ascent Hill Climbing (Klik to Swap)"
		_algo_btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		balancer_result = LocalSearchBalancer.run_hill_climbing(s0, player_power, target_ratio, 35, bounds)
	else: # "rr"
		_algo_btn.text = "Algoritma: Hill Climbing + Random Restart (Klik to Swap)"
		_algo_btn.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
		balancer_result = LocalSearchBalancer.run_hill_climbing_random_restart(s0, player_power, target_ratio, 3, 20, bounds)

	step_logs = balancer_result.get("step_logs", [])
	current_step_idx = 0
	_log_box.text = ""
	_progress_bar.max_value = float(maxi(1, step_logs.size() - 1))
	_progress_bar.value = 0.0

	_lbl_target_power.text = "Target NPC Power: %.1f\n(Player Power x %.2f)" % [
		balancer_result.get("target_power", 0.0), target_ratio
	]

	# Start stepping animation
	is_animating = true
	step_timer = 0.0

func _process(delta: float) -> void:
	if not is_animating:
		return

	step_timer += delta
	if step_timer >= STEP_INTERVAL:
		step_timer = 0.0
		_step_forward()

func _step_forward() -> void:
	if current_step_idx >= step_logs.size():
		is_animating = false
		_display_final_results()
		return

	var entry: Dictionary = step_logs[current_step_idx]
	current_step_idx += 1

	_progress_bar.value = float(current_step_idx)
	_step_counter_label.text = "Step: %d/%d" % [current_step_idx, step_logs.size() - 1]

	# Build rich BBCode log line
	var color_tag := "white"
	var status: String = entry.get("status", "")
	if status.begins_with("ACCEPTED"):
		color_tag = "#00f5d4"
	elif status.begins_with("DOWNHILL"):
		color_tag = "#ffbe0b"
	elif status.begins_with("REJECTED"):
		color_tag = "#ff4d6d"
	elif status.begins_with("STUCK"):
		color_tag = "#ff0055"

	var log_line: String = "[color=#888][Step %02d][/color] %s -> Score: [color=%s]%.1f[/color] -> [b][color=%s]%s[/color][/b]\n" % [
		entry.get("step", 0),
		entry.get("action_desc", ""),
		color_tag,
		entry.get("score", 0.0),
		color_tag,
		status
	]
	_log_box.append_text(log_line)

	_lbl_npc_power.text = "NPC Power: %.1f" % entry.get("npc_power", 0.0)
	_lbl_fitness_score.text = "Fitness f(S): %.2f" % entry.get("score", 0.0)
	_lbl_fitness_score.add_theme_color_override("font_color", Color(color_tag))

	# Play SFX tick on steps
	if audio_player and sfx_tick and (current_step_idx % 2 == 0):
		audio_player.stream = sfx_tick
		audio_player.play()

	# Real-time update of best values
	var st: Dictionary = entry.get("state", {})
	_update_comparison_labels(balancer_result.get("initial_state", {}), st)

func _display_final_results() -> void:
	var init_s: Dictionary = balancer_result.get("initial_state", {})
	var best_s: Dictionary = balancer_result.get("best_state", {})
	_update_comparison_labels(init_s, best_s)

	_lbl_fitness_score.text = "Final Fitness: %.2f (SELESAI)" % balancer_result.get("best_fitness", 0.0)
	_lbl_fitness_score.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	_lbl_npc_power.text = "NPC Power: %.1f (Optimal)" % balancer_result.get("final_npc_power", 0.0)

	var summary_msg := "\n[color=#00f5d4][b][OK] OPTIMASI SELESAI (%s):[/b][/color] Total %d langkah dalam %.2f ms. Keseimbangan pertempuran tercapai!\n" % [
		balancer_result.get("algorithm", ""),
		balancer_result.get("total_steps", 0),
		balancer_result.get("execution_time_ms", 0.0)
	]
	_log_box.append_text(summary_msg)

func _update_comparison_labels(init_s: Dictionary, curr_s: Dictionary) -> void:
	if _lbl_hp_comp:
		_lbl_hp_comp.text = "%d  ->  %d HP" % [init_s.get("hp", 0), curr_s.get("hp", 0)]
	if _lbl_atk_comp:
		_lbl_atk_comp.text = "%d  ->  %d DMG" % [init_s.get("atk", 0), curr_s.get("atk", 0)]
	if _lbl_heavy_comp:
		_lbl_heavy_comp.text = "%d  ->  %d DMG" % [init_s.get("heavy_atk", 0), curr_s.get("heavy_atk", 0)]
	if _lbl_def_comp:
		_lbl_def_comp.text = "%d  ->  %d DEF" % [init_s.get("def", 0), curr_s.get("def", 0)]
	if _lbl_pot_comp:
		_lbl_pot_comp.text = "%d pot  ->  %d pot (+%d)" % [
			init_s.get("potion_count", 0), curr_s.get("potion_count", 0), curr_s.get("potion_heal", 25)
		]
	if _lbl_depth_comp:
		_lbl_depth_comp.text = "Depth %d  ->  Depth %d" % [
			init_s.get("minimax_depth", 2), curr_s.get("minimax_depth", 2)
		]

func _toggle_algorithm() -> void:
	if current_algo == "sa":
		current_algo = "hc"
	elif current_algo == "hc":
		current_algo = "rr"
	else:
		current_algo = "sa"
	_run_optimization()

func _on_proceed_pressed() -> void:
	# Ensure final state is used
	var best_s: Dictionary = balancer_result.get("best_state", {})
	if best_s.is_empty():
		best_s = LocalSearchBalancer.get_initial_state(enemy_type, player_stats)

	var config := {
		"enemy_type": enemy_type,
		"enemy_name": enemy_name,
		"enemy_element": enemy_element,
		"enemy_weapon": enemy_weapon,
		"npc_hp": best_s.get("hp", 100),
		"npc_max_hp": best_s.get("hp", 100),
		"npc_atk": best_s.get("atk", 16),
		"npc_heavy_atk": best_s.get("heavy_atk", 28),
		"npc_def": best_s.get("def", 5),
		"npc_potions": best_s.get("potion_count", 1),
		"npc_potion_heal": best_s.get("potion_heal", 25),
		"minimax_depth": best_s.get("minimax_depth", 2),
		"player_hp": player_stats.get("hp", 100),
		"player_max_hp": player_stats.get("max_hp", 100),
		"player_potions": player_stats.get("potions", 1),
		"player_atk": player_stats.get("attack", 12),
		"player_heavy_atk": int(player_stats.get("attack", 12) * 1.8),
		"player_potion_heal": 30
	}

	proceed_to_battle.emit(config)
	queue_free()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()
