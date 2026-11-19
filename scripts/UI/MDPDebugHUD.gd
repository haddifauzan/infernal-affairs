class_name MDPDebugHUD
extends PanelContainer

## MDPDebugHUD.gd
## Interactive Transparency & Visualization HUD for Decisions Under Uncertainty & MDP.
## Displays real-time Value Iteration tables, Bayesian Belief state,
## and allows manual test-triggering for academic presentations (Tahap 4).

signal force_warning_toggled(active: bool)
signal step_iteration_requested()
signal reset_simulation_requested()

var mdp_solver: MDPSolver = MDPSolver.new()
var hazard_manager: StochasticHazardManager = null

# UI Elements
var title_label: Label
var belief_label: Label
var status_badge: Label
var table_v_label: RichTextLabel
var formula_label: RichTextLabel

var btn_toggle_warning: Button
var btn_step_iter: Button
var btn_reset: Button
var btn_close: Button

# State tracking
var current_f: float = 0.10
var is_force_warning: bool = false
var current_step_k: int = 3
var last_solution: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(460, 360)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_styles()
	_build_ui_tree()
	update_mdp_display(0.10, false)

func _setup_styles() -> void:
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.12, 0.94)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(1.0, 0.55, 0.15, 0.85)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.content_margin_left = 14
	style_box.content_margin_top = 10
	style_box.content_margin_right = 14
	style_box.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style_box)

func _build_ui_tree() -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# --- Header Row ---
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	title_label = Label.new()
	title_label.text = "✦ TAHAP 4: MDP & BAYESIAN DECISION ✦"
	title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_label)

	btn_close = Button.new()
	btn_close.text = " [X] "
	btn_close.flat = true
	btn_close.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	btn_close.pressed.connect(func(): visible = false)
	header_hbox.add_child(btn_close)

	# --- Belief Banner & Status Badge ---
	var belief_box = PanelContainer.new()
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.12, 0.14, 0.20, 0.9)
	b_style.corner_radius_top_left = 6
	b_style.corner_radius_top_right = 6
	b_style.corner_radius_bottom_left = 6
	b_style.corner_radius_bottom_right = 6
	b_style.content_margin_left = 8
	b_style.content_margin_top = 6
	b_style.content_margin_right = 8
	b_style.content_margin_bottom = 6
	belief_box.add_theme_stylebox_override("panel", b_style)
	vbox.add_child(belief_box)

	var b_vbox = VBoxContainer.new()
	b_vbox.add_theme_constant_override("separation", 4)
	belief_box.add_child(b_vbox)

	belief_label = Label.new()
	belief_label.text = "Belief: P(Hazard) = 0.10 | Prior Normal"
	belief_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	belief_label.add_theme_font_size_override("font_size", 12)
	b_vbox.add_child(belief_label)

	status_badge = Label.new()
	status_badge.text = "★ POLICY π*(Simpang) = PINTAS (Shortcut)"
	status_badge.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	status_badge.add_theme_font_size_override("font_size", 12)
	b_vbox.add_child(status_badge)

	# --- Live Table Display (RichTextLabel) ---
	table_v_label = RichTextLabel.new()
	table_v_label.bbcode_enabled = true
	table_v_label.custom_minimum_size = Vector2(430, 140)
	table_v_label.scroll_active = false
	table_v_label.add_theme_font_size_override("normal_font_size", 11)
	vbox.add_child(table_v_label)

	# --- Theoretical Formula Footer ---
	formula_label = RichTextLabel.new()
	formula_label.bbcode_enabled = true
	formula_label.custom_minimum_size = Vector2(430, 42)
	formula_label.scroll_active = false
	formula_label.add_theme_font_size_override("normal_font_size", 10)
	formula_label.text = "[color=#aaaaaa]Bellman: Q(s, a) = Σ P(s'|s, a) [R(s') + γ V(s')] | γ = 0.8, R_step = -2\nBayes: P(H|W) = [P(W|H)·P(H)] / P(W) = 0.09 / 0.18 = 0.50[/color]"
	vbox.add_child(formula_label)

	# --- Button Controls Row ---
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_hbox)

	btn_toggle_warning = Button.new()
	btn_toggle_warning.text = "⚠ Force Warning (W=1)"
	btn_toggle_warning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_toggle_warning.pressed.connect(_on_toggle_warning_pressed)
	btn_hbox.add_child(btn_toggle_warning)

	btn_step_iter = Button.new()
	btn_step_iter.text = "Step Iter (k+1)"
	btn_step_iter.pressed.connect(_on_step_iteration_pressed)
	btn_hbox.add_child(btn_step_iter)

	btn_reset = Button.new()
	btn_reset.text = "Reset Normal"
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_hbox.add_child(btn_reset)

func update_mdp_display(hazard_prob: float, warning_active: bool) -> void:
	current_f = hazard_prob
	last_solution = MDPSolver.solve_value_iteration(current_f, 15)

	# Update Belief Label
	if warning_active or hazard_prob >= 0.40:
		belief_label.text = "Belief: P(Hazard | W) = %.2f [⚠ ALERT: SENSOR AKTIF!]" % current_f
		belief_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))

		status_badge.text = "★ POLICY π*(Simpang) = JALUR UTAMA (Safe Detour!)"
		status_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		belief_label.text = "Belief: P(Hazard) = %.2f [Kondisi Normal / Aman]" % current_f
		belief_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))

		status_badge.text = "★ POLICY π*(Simpang) = PINTAS (Shortcut)"
		status_badge.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

	_render_table()

func _render_table() -> void:
	var history = last_solution.get("history", [])
	var max_k = history.size() - 1
	var show_k = clamp(current_step_k, 0, max_k)

	var snap = history[show_k]
	var V: Dictionary = snap.get("V", {})
	var Q: Dictionary = snap.get("Q", {})

	var q_simpang: Dictionary = Q.get(MDPSolver.State.SIMPANG_LEMBAH, {})
	var q_pintas = q_simpang.get(MDPSolver.Action.PINTAS, 0.0)
	var q_raya = q_simpang.get(MDPSolver.Action.RAYA, 0.0)
	var q_balik = q_simpang.get(MDPSolver.Action.BALIK, 0.0)

	var v_altar = V.get(MDPSolver.State.ALTAR, 0.0)
	var v_simpang = V.get(MDPSolver.State.SIMPANG_LEMBAH, 0.0)
	var v_raya = V.get(MDPSolver.State.JALUR_UTAMA, 0.0)

	var best_act = "PINTAS" if q_pintas >= q_raya else "RAYA"
	var col_pintas = "#55ff55" if q_pintas >= q_raya else "#ff5555"
	var col_raya = "#55ff55" if q_raya > q_pintas else "#cccccc"

	var text = "[b]Tabel Komputasi Value Iteration (Iterasi k = %d):[/b]\n" % show_k
	text += "------------------------------------------------------------\n"
	text += "[color=#eedd88]State[/color]               | [color=#eedd88]Q(s, Pintas)[/color] | [color=#eedd88]Q(s, Raya)[/color] | [color=#eedd88]V(s) Optimal[/color]\n"
	text += "------------------------------------------------------------\n"
	text += "Altar (s0)         |   —         |   —        | %6.2f\n" % v_altar
	text += "Simpang (s1)       | [color=%s]%6.2f[/color]     | [color=%s]%6.2f[/color]   | [color=#ffee44]%6.2f (%s)[/color]\n" % [
		col_pintas, q_pintas, col_raya, q_raya, v_simpang, best_act
	]
	text += "Jalur Utama (s3)   |   —         |   —        | %6.2f\n" % v_raya
	text += "Pos Penjaga (Goal) | Terminal (+10)           |  10.00\n"
	text += "Magma Trap (Fail)  | Terminal (-20)           | -20.00\n"
	text += "------------------------------------------------------------"

	table_v_label.text = text

func _on_toggle_warning_pressed() -> void:
	is_force_warning = not is_force_warning
	btn_toggle_warning.text = "✓ Clear Warning (W=0)" if is_force_warning else "⚠ Force Warning (W=1)"
	force_warning_toggled.emit(is_force_warning)

func _on_step_iteration_pressed() -> void:
	var history = last_solution.get("history", [])
	if history.is_empty():
		return
	current_step_k = (current_step_k + 1) % history.size()
	_render_table()
	step_iteration_requested.emit()

func _on_reset_pressed() -> void:
	is_force_warning = false
	btn_toggle_warning.text = "⚠ Force Warning (W=1)"
	current_step_k = 3
	update_mdp_display(0.10, false)
	reset_simulation_requested.emit()

