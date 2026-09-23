## BattleHUD.gd
## ──────────────────────────────────────────────────────────────────────────────
## Premium Battle HUD with:
## 1. Procedural Action & Waiting Animations (Tween + VFX + Floating Damage)
## 2. Dedicated Combat Stage Frame (Unobstructed duel view)
## 3. Modular External Debug Sidebar (Organized into structured sub-boxes)
## ──────────────────────────────────────────────────────────────────────────────
class_name BattleHUD
extends CanvasLayer

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS & ASSETS
# ─────────────────────────────────────────────────────────────────────────────
const TEX_PLAYER_PORTRAIT := "res://assets/sprites/characters/player/player_portrait.png"
const TEX_DEMON_BOSS      := "res://assets/sprites/characters/demon/demon_boss.png"
const TEX_AURA_PLAYER     := "res://assets/sprites/ui/effects/aura_player.png"
const TEX_AURA_DEMON      := "res://assets/sprites/ui/effects/aura_demon.png"
const TEX_ICON_SWORD      := "res://assets/sprites/ui/skills/icon_sword.png"
const TEX_ICON_SHIELD     := "res://assets/sprites/ui/skills/icon_shield.png"
const TEX_ICON_POTION     := "res://assets/sprites/ui/skills/icon_potion.png"

# ─────────────────────────────────────────────────────────────────────────────
# REFERENCES
# ─────────────────────────────────────────────────────────────────────────────
var _manager: BattleManager

# Main Layout
var _root_container: MarginContainer
var _main_layout:    HBoxContainer
var _combat_column:  VBoxContainer
var _debug_sidebar:  PanelContainer

# Header & HP Bars
var _player_hp_bar:   ProgressBar
var _npc_hp_bar:      ProgressBar
var _player_hp_label: Label
var _npc_hp_label:    Label
var _player_pot_label: Label
var _npc_pot_label:   Label
var _player_def_badge: PanelContainer
var _npc_def_badge:   PanelContainer

# Combat Stage Elements
var _combat_stage_panel: PanelContainer
var _combat_stage:       Control
var _player_node:        Control
var _player_sprite:      TextureRect
var _player_aura:        TextureRect
var _player_shield_fx:   TextureRect
var _player_turn_badge:  PanelContainer
var _player_badge_lbl:   Label

var _demon_node:         Control
var _demon_sprite:       TextureRect
var _demon_aura:         TextureRect
var _demon_shield_fx:    TextureRect
var _demon_turn_badge:   PanelContainer
var _demon_badge_lbl:    Label

var _vfx_layer:          Control

# Base Positions for Combatants
var _player_base_pos: Vector2 = Vector2(140, 180)
var _demon_base_pos:  Vector2 = Vector2(460, 180)
var _player_base_scale: Vector2 = Vector2(1.0, 1.0)
var _demon_base_scale:  Vector2 = Vector2(1.0, 1.0)

# Idle Animation State
var _idle_time: float = 0.0
var _is_busy_animating: bool = false
var _player_animating:  bool = false
var _demon_animating:   bool = false

# Status & Action Buttons
var _status_label:   Label
var _turn_label:     Label
var _btn_attack:     Button
var _btn_heavy:      Button
var _btn_defend:     Button
var _btn_potion:     Button
var _btn_toggle_dbg: Button
var _btn_toggle_exp: Button
var _btn_copy_exp:   Button
var _lbl_depth_val: Label

# Debug Sidebar Modular Sub-Boxes
var _debug_visible: bool = true
var _box_config:    PanelContainer
var _lbl_algo:      Label
var _lbl_eval:      Label
var _lbl_depth:     Label
var _lbl_order:     Label

var _box_perf:      PanelContainer
var _lbl_visited:   Label
var _lbl_pruned:    Label
var _lbl_efficiency: Label
var _lbl_max_depth: Label

var _box_actions:   PanelContainer
var _actions_vbox:  VBoxContainer

var _box_state:     PanelContainer
var _lbl_advantage: Label
var _lbl_threat:    Label

var _box_history:   PanelContainer
var _lbl_history:   RichTextLabel

# Experiment Panel
var _exp_panel:   PanelContainer
var _exp_vbox:    VBoxContainer
var _exp_log:     RichTextLabel
var _exp_visible: bool = false

# Action History
var _action_history: Array[String] = []

# ─────────────────────────────────────────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────────────────────────────────────────
func init(manager: BattleManager) -> void:
	_manager = manager
	_manager.battle_started.connect(_on_battle_started)
	_manager.battle_ended.connect(_on_battle_ended)
	_manager.action_performed.connect(_on_action_performed)
	_manager.turn_changed.connect(_on_turn_changed)
	_manager.debug_updated.connect(_on_debug_updated)
	_manager.npc_thinking.connect(_on_npc_thinking)
	_refresh_debug_config()

func _ready() -> void:
	layer = 10
	_build_ui()
	_update_positions()
	get_viewport().size_changed.connect(_update_positions)
	if is_instance_valid(_combat_stage) and not _combat_stage.resized.is_connected(_update_positions):
		_combat_stage.resized.connect(_update_positions)

# ─────────────────────────────────────────────────────────────────────────────
# UI BUILD
# ─────────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Full screen overlay
	_root_container = MarginContainer.new()
	_root_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_container.add_theme_constant_override("margin_left",   12)
	_root_container.add_theme_constant_override("margin_top",    10)
	_root_container.add_theme_constant_override("margin_right",  12)
	_root_container.add_theme_constant_override("margin_bottom", 10)

	var bg_overlay := StyleBoxFlat.new()
	bg_overlay.bg_color = Color(0.03, 0.03, 0.08, 0.94)
	_root_container.add_theme_stylebox_override("panel", bg_overlay)
	add_child(_root_container)

	_main_layout = HBoxContainer.new()
	_main_layout.add_theme_constant_override("separation", 14)
	_root_container.add_child(_main_layout)

	# 1. Left/Center Column: Combat Arena & Controls
	_combat_column = VBoxContainer.new()
	_combat_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combat_column.add_theme_constant_override("separation", 8)
	_main_layout.add_child(_combat_column)

	_build_header_and_hp()
	_build_combat_stage()
	_build_controls()
	_build_experiment_panel()

	# 2. Right Column: Dedicated Modular Debug Sidebar
	_build_debug_sidebar()

# ─────────────────────────────────────────────────────────────────────────────
# 1. HEADER & HP SECTION
# ─────────────────────────────────────────────────────────────────────────────
func _build_header_and_hp() -> void:
	var header_panel := PanelContainer.new()
	var h_style := StyleBoxFlat.new()
	h_style.bg_color = Color(0.07, 0.06, 0.14, 0.9)
	h_style.border_color = Color(0.35, 0.15, 0.65, 0.8)
	h_style.set_border_width_all(1)
	h_style.set_corner_radius_all(6)
	h_style.content_margin_left   = 12
	h_style.content_margin_right  = 12
	h_style.content_margin_top    = 6
	h_style.content_margin_bottom = 6
	header_panel.add_theme_stylebox_override("panel", h_style)
	_combat_column.add_child(header_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	header_panel.add_child(main_vbox)

	# Top Bar: Title & Toggle Debug Button
	var top_row := HBoxContainer.new()
	main_vbox.add_child(top_row)

	var title := Label.new()
	title.text = "⚔️  INFERNAL DUEL  •  TURN-BASED COMBAT"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)

	_btn_toggle_exp = Button.new()
	_btn_toggle_exp.text = "🧪 Benchmark Lab [P]"
	_btn_toggle_exp.add_theme_font_size_override("font_size", 10)
	_btn_toggle_exp.pressed.connect(_toggle_experiment_panel)
	top_row.add_child(_btn_toggle_exp)

	_btn_toggle_dbg = Button.new()
	_btn_toggle_dbg.text = "🔍 Debug Overlay [D]"
	_btn_toggle_dbg.add_theme_font_size_override("font_size", 10)
	_btn_toggle_dbg.pressed.connect(_toggle_debug_sidebar)
	top_row.add_child(_btn_toggle_dbg)

	# HP Row
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 16)
	main_vbox.add_child(hp_row)

	# Player Side
	var p_box := VBoxContainer.new()
	p_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(p_box)

	var p_hdr := HBoxContainer.new()
	p_box.add_child(p_hdr)
	var p_title := Label.new()
	p_title.text = "🛡️ PLAYER (Lost Soul Knight)"
	p_title.add_theme_font_size_override("font_size", 11)
	p_title.add_theme_color_override("font_color", Color(0.0, 0.95, 0.85))
	p_hdr.add_child(p_title)

	var p_spc := Control.new(); p_spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p_hdr.add_child(p_spc)
	_player_def_badge = _make_mini_badge("🛡️ DEFENDING", Color(0.1, 0.6, 1.0))
	_player_def_badge.visible = false
	p_hdr.add_child(_player_def_badge)

	_player_hp_bar = _make_hp_bar(Color(0.0, 0.85, 0.65))
	p_box.add_child(_player_hp_bar)

	var p_sub := HBoxContainer.new()
	p_box.add_child(p_sub)
	_player_hp_label = _make_small_label("HP: 100 / 100")
	_player_hp_label.add_theme_color_override("font_color", Color(0.0, 0.95, 0.85))
	p_sub.add_child(_player_hp_label)
	var p_sub_spc := Control.new(); p_sub_spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; p_sub.add_child(p_sub_spc)
	_player_pot_label = _make_small_label("💊 Potions: 3/3")
	p_sub.add_child(_player_pot_label)

	# VS Badge
	var vs_lbl := Label.new()
	vs_lbl.text = "VS"
	vs_lbl.add_theme_font_size_override("font_size", 14)
	vs_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
	vs_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_row.add_child(vs_lbl)

	# Demon Side
	var d_box := VBoxContainer.new()
	d_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(d_box)

	var d_hdr := HBoxContainer.new()
	d_box.add_child(d_hdr)
	_npc_def_badge = _make_mini_badge("🛡️ DEFENDING", Color(1.0, 0.3, 0.1))
	_npc_def_badge.visible = false
	d_hdr.add_child(_npc_def_badge)

	var d_spc := Control.new(); d_spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; d_hdr.add_child(d_spc)
	var d_title := Label.new()
	d_title.text = "DEMON BRUTE (Minimax AI) 👹"
	d_title.add_theme_font_size_override("font_size", 11)
	d_title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.15))
	d_hdr.add_child(d_title)

	_npc_hp_bar = _make_hp_bar(Color(0.95, 0.25, 0.15))
	d_box.add_child(_npc_hp_bar)

	var d_sub := HBoxContainer.new()
	d_box.add_child(d_sub)
	_npc_pot_label = _make_small_label("💊 Potions: 3/3")
	d_sub.add_child(_npc_pot_label)
	var d_sub_spc := Control.new(); d_sub_spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; d_sub.add_child(d_sub_spc)
	_npc_hp_label = _make_small_label("HP: 100 / 100")
	_npc_hp_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.25))
	d_sub.add_child(_npc_hp_label)

# ─────────────────────────────────────────────────────────────────────────────
# 2. COMBAT STAGE (UNOBSTRUCTED ACTION ARENA)
# ─────────────────────────────────────────────────────────────────────────────
func _build_combat_stage() -> void:
	_combat_stage_panel = PanelContainer.new()
	_combat_stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_combat_stage_panel.custom_minimum_size = Vector2(0, 310)

	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = Color(0.05, 0.04, 0.11, 0.98)
	stage_style.border_color = Color(0.5, 0.15, 0.85, 0.8)
	stage_style.set_border_width_all(2)
	stage_style.set_corner_radius_all(8)
	_combat_stage_panel.add_theme_stylebox_override("panel", stage_style)
	_combat_column.add_child(_combat_stage_panel)

	_combat_stage = Control.new()
	_combat_stage.clip_contents = true
	_combat_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combat_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_combat_stage.resized.connect(_update_positions)
	_combat_stage_panel.add_child(_combat_stage)

	# Arena Floor Line / Platform Indicator
	var floor_line := ColorRect.new()
	floor_line.name = "FloorGlow"
	floor_line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	floor_line.anchor_top = 1.0
	floor_line.offset_top = -65
	floor_line.offset_bottom = -63
	floor_line.color = Color(0.55, 0.2, 0.9, 0.45)
	_combat_stage.add_child(floor_line)

	# --- PLAYER COMBATANT NODE ---
	_player_node = Control.new()
	_player_node.name = "PlayerNode"
	_combat_stage.add_child(_player_node)

	_player_aura = _make_texture_rect(TEX_AURA_PLAYER, Vector2(130, 40))
	_player_aura.position = Vector2(-65, -15)
	_player_aura.modulate = Color(0.0, 0.9, 1.0, 0.6)
	_player_node.add_child(_player_aura)

	_player_sprite = _make_texture_rect(TEX_PLAYER_PORTRAIT, Vector2(150, 150))
	_player_sprite.position = Vector2(-75, -145)
	_player_sprite.pivot_offset = Vector2(75, 145)
	_player_node.add_child(_player_sprite)

	_player_shield_fx = _make_texture_rect(TEX_ICON_SHIELD, Vector2(48, 48))
	_player_shield_fx.position = Vector2(25, -100)
	_player_shield_fx.modulate = Color(0.2, 0.8, 1.0, 0.0)
	_player_node.add_child(_player_shield_fx)

	_player_turn_badge = _make_mini_badge("👉 YOUR TURN", Color(0.0, 0.95, 0.85))
	_player_turn_badge.position = Vector2(-55, -180)
	_player_node.add_child(_player_turn_badge)
	_player_badge_lbl = _player_turn_badge.get_child(0) as Label

	# --- DEMON COMBATANT NODE ---
	_demon_node = Control.new()
	_demon_node.name = "DemonNode"
	_combat_stage.add_child(_demon_node)

	_demon_aura = _make_texture_rect(TEX_AURA_DEMON, Vector2(140, 45))
	_demon_aura.position = Vector2(-70, -18)
	_demon_aura.modulate = Color(1.0, 0.3, 0.1, 0.6)
	_demon_node.add_child(_demon_aura)

	_demon_sprite = _make_texture_rect(TEX_DEMON_BOSS, Vector2(175, 175))
	_demon_sprite.position = Vector2(-88, -170)
	_demon_sprite.pivot_offset = Vector2(88, 170)
	_demon_sprite.flip_h = true  # Face left toward player
	_demon_node.add_child(_demon_sprite)

	_demon_shield_fx = _make_texture_rect(TEX_ICON_SHIELD, Vector2(48, 48))
	_demon_shield_fx.position = Vector2(-65, -110)
	_demon_shield_fx.modulate = Color(1.0, 0.4, 0.1, 0.0)
	_demon_node.add_child(_demon_shield_fx)

	_demon_turn_badge = _make_mini_badge("⏳ THINKING...", Color(1.0, 0.4, 0.1))
	_demon_turn_badge.position = Vector2(-60, -205)
	_demon_turn_badge.visible = false
	_demon_node.add_child(_demon_turn_badge)
	_demon_badge_lbl = _demon_turn_badge.get_child(0) as Label

	# VFX Layer for floating text & impact sparks
	_vfx_layer = Control.new()
	_vfx_layer.name = "VFXLayer"
	_vfx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combat_stage.add_child(_vfx_layer)

# ─────────────────────────────────────────────────────────────────────────────
# 3. COMBAT CONTROLS (BUTTONS & TIPS)
# ─────────────────────────────────────────────────────────────────────────────
func _build_controls() -> void:
	var ctrl_panel := PanelContainer.new()
	var c_style := StyleBoxFlat.new()
	c_style.bg_color = Color(0.06, 0.05, 0.12, 0.95)
	c_style.border_color = Color(0.3, 0.2, 0.5, 0.6)
	c_style.set_border_width_all(1)
	c_style.set_corner_radius_all(6)
	c_style.content_margin_left   = 10
	c_style.content_margin_right  = 10
	c_style.content_margin_top    = 6
	c_style.content_margin_bottom = 6
	ctrl_panel.add_theme_stylebox_override("panel", c_style)
	_combat_column.add_child(ctrl_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	ctrl_panel.add_child(vbox)

	# Turn and Status Tip
	var tip_row := HBoxContainer.new()
	vbox.add_child(tip_row)

	_turn_label = Label.new()
	_turn_label.text = "YOUR TURN — Select an action:"
	_turn_label.add_theme_font_size_override("font_size", 12)
	_turn_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	tip_row.add_child(_turn_label)

	var spc := Control.new(); spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tip_row.add_child(spc)

	_status_label = Label.new()
	_status_label.text = "💡 Tip: Defend reduces incoming damage by 50%!"
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	tip_row.add_child(_status_label)

	# Action Buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	_btn_attack = _make_action_button("⚔️ [1] Attack\n[20 DMG]",        Color(0.85, 0.25, 0.1))
	_btn_heavy  = _make_action_button("🔥 [2] Heavy\n[37 DMG, -10]",     Color(0.95, 0.15, 0.45))
	_btn_defend = _make_action_button("🛡️ [3] Defend\n[Block 50%]",      Color(0.1, 0.55, 0.95))
	_btn_potion = _make_action_button("💊 [4] Potion\n[+30 HP]",         Color(0.1, 0.85, 0.35))

	btn_row.add_child(_btn_attack)
	btn_row.add_child(_btn_heavy)
	btn_row.add_child(_btn_defend)
	btn_row.add_child(_btn_potion)

	_btn_attack.pressed.connect(func(): _execute_player_choice(MinimaxSolver.Action.ATTACK))
	_btn_heavy.pressed.connect( func(): _execute_player_choice(MinimaxSolver.Action.HEAVY_ATTACK))
	_btn_defend.pressed.connect(func(): _execute_player_choice(MinimaxSolver.Action.DEFEND))
	_btn_potion.pressed.connect(func(): _execute_player_choice(MinimaxSolver.Action.POTION))

	# Hotkey Helper Row
	var helper_lbl := Label.new()
	helper_lbl.text = "⌨️ Shortcuts: [1-4] Action  |  [D] Toggle NPC Debug  |  [P] AI Config & Benchmark"
	helper_lbl.add_theme_font_size_override("font_size", 9)
	helper_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	helper_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(helper_lbl)

# ─────────────────────────────────────────────────────────────────────────────
# 4. MODULAR DEBUG SIDEBAR (OUTSIDE COMBAT FRAME, MULTIPLE SUB-BOXES)
# ─────────────────────────────────────────────────────────────────────────────
func _build_debug_sidebar() -> void:
	_debug_sidebar = PanelContainer.new()
	_debug_sidebar.custom_minimum_size = Vector2(330, 0)

	var sb_style := StyleBoxFlat.new()
	sb_style.bg_color = Color(0.04, 0.03, 0.10, 0.96)
	sb_style.border_color = Color(0.4, 0.15, 0.75, 0.85)
	sb_style.set_border_width_all(2)
	sb_style.set_corner_radius_all(8)
	sb_style.content_margin_left   = 8
	sb_style.content_margin_right  = 8
	sb_style.content_margin_top    = 8
	sb_style.content_margin_bottom = 8
	_debug_sidebar.add_theme_stylebox_override("panel", sb_style)
	_main_layout.add_child(_debug_sidebar)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_debug_sidebar.add_child(vbox)

	# Sidebar Title Bar
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var sb_title := Label.new()
	sb_title.text = "🔍 NPC MINIMAX MONITOR"
	sb_title.add_theme_font_size_override("font_size", 11)
	sb_title.add_theme_color_override("font_color", Color(0.8, 0.55, 1.0))
	sb_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(sb_title)

	var btn_close := Button.new()
	btn_close.text = "✕"
	btn_close.add_theme_font_size_override("font_size", 9)
	btn_close.custom_minimum_size = Vector2(22, 20)
	btn_close.pressed.connect(_toggle_debug_sidebar)
	title_row.add_child(btn_close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var boxes_vbox := VBoxContainer.new()
	boxes_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boxes_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(boxes_vbox)

	# ── KOTAK 1: AI Engine & Configuration ──
	var cfg_data := _make_subbox("⚙️  AI Engine & Search Config", Color(0.3, 0.2, 0.6))
	_box_config = cfg_data["panel"] as PanelContainer
	var cfg_vbox := cfg_data["content"] as VBoxContainer
	boxes_vbox.add_child(_box_config)
	_lbl_algo  = _make_stat_row("Algorithm:", "Alpha-Beta Pruning", Color(0.0, 0.95, 0.85), cfg_vbox)
	_lbl_eval  = _make_stat_row("Evaluation:", "HP Difference (Optimal)", Color(1.0, 0.85, 0.3), cfg_vbox)
	_lbl_depth = _make_stat_row("Lookahead Depth:", "3 Plies (Balanced)", Color(0.9, 0.6, 1.0), cfg_vbox)
	_lbl_order = _make_stat_row("Action Ordering:", "Default Heuristic", Color(0.8, 0.8, 0.8), cfg_vbox)

	# ── KOTAK 2: Search Performance & Tree Stats ──
	var perf_data := _make_subbox("📊  Tree Search Performance", Color(0.15, 0.35, 0.65))
	_box_perf = perf_data["panel"] as PanelContainer
	var perf_vbox := perf_data["content"] as VBoxContainer
	boxes_vbox.add_child(_box_perf)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	perf_vbox.add_child(grid)

	_lbl_visited    = _make_metric_card("Nodes Visited", "0", Color(0.3, 0.85, 1.0), grid)
	_lbl_pruned     = _make_metric_card("Branches Pruned", "0", Color(1.0, 0.45, 0.3), grid)
	_lbl_efficiency = _make_metric_card("Prune Ratio", "0%", Color(0.2, 0.95, 0.5), grid)
	_lbl_max_depth  = _make_metric_card("Max Depth", "0", Color(1.0, 0.85, 0.2), grid)

	# ── KOTAK 3: Evaluated Actions & Decision Scores ──
	var act_data := _make_subbox("🎯  Candidate Action Utilities (NPC)", Color(0.65, 0.25, 0.15))
	_box_actions = act_data["panel"] as PanelContainer
	_actions_vbox = act_data["content"] as VBoxContainer
	boxes_vbox.add_child(_box_actions)
	_build_action_score_idle()

	# ── KOTAK 4: Combat State Assessment ──
	var st_data := _make_subbox("💡  Strategic State Assessment", Color(0.2, 0.45, 0.35))
	_box_state = st_data["panel"] as PanelContainer
	var st_vbox := st_data["content"] as VBoxContainer
	boxes_vbox.add_child(_box_state)
	_lbl_advantage = _make_stat_row("Advantage:", "Even Match (0 HP)", Color(0.8, 0.8, 0.8), st_vbox)
	_lbl_threat    = _make_stat_row("Threat Level:", "Moderate", Color(1.0, 0.8, 0.2), st_vbox)

	# ── KOTAK 5: Action History ──
	var hist_data := _make_subbox("📜  Recent Turns Log", Color(0.25, 0.25, 0.35))
	_box_history = hist_data["panel"] as PanelContainer
	var hist_vbox := hist_data["content"] as VBoxContainer
	boxes_vbox.add_child(_box_history)
	_lbl_history = RichTextLabel.new()
	_lbl_history.bbcode_enabled = true
	_lbl_history.fit_content = true
	_lbl_history.scroll_active = false
	_lbl_history.add_theme_font_size_override("normal_font_size", 9)
	_lbl_history.text = "[color=#666]Duel started. Awaiting actions…[/color]"
	hist_vbox.add_child(_lbl_history)

# ─────────────────────────────────────────────────────────────────────────────
# 5. EXPERIMENT PANEL (HEADLESS BENCHMARK & ALGO LAB)
# ─────────────────────────────────────────────────────────────────────────────
func _build_experiment_panel() -> void:
	_exp_panel = PanelContainer.new()
	_exp_panel.name = "ExpPanel"
	_exp_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_exp_panel.custom_minimum_size = Vector2(0, 310)

	var ep_style := StyleBoxFlat.new()
	ep_style.bg_color = Color(0.04, 0.03, 0.09, 0.98)
	ep_style.border_color = Color(0.9, 0.65, 0.1, 0.9)
	ep_style.set_border_width_all(2)
	ep_style.set_corner_radius_all(8)
	ep_style.content_margin_left   = 12
	ep_style.content_margin_right  = 12
	ep_style.content_margin_top    = 8
	ep_style.content_margin_bottom = 8
	_exp_panel.add_theme_stylebox_override("panel", ep_style)
	_exp_panel.visible = false
	_combat_column.add_child(_exp_panel)

	_exp_vbox = VBoxContainer.new()
	_exp_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_exp_vbox.add_theme_constant_override("separation", 6)
	_exp_panel.add_child(_exp_vbox)

	# Title Bar
	var hdr := HBoxContainer.new()
	_exp_vbox.add_child(hdr)

	var lab_title := Label.new()
	lab_title.text = "🧪  AI EXPERIMENT & BENCHMARK LAB"
	lab_title.add_theme_font_size_override("font_size", 12)
	lab_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	lab_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lab_title)

	_btn_copy_exp = Button.new()
	_btn_copy_exp.text = "📋 Copy to Clipboard"
	_btn_copy_exp.add_theme_font_size_override("font_size", 9)
	_btn_copy_exp.pressed.connect(_copy_exp_results)
	hdr.add_child(_btn_copy_exp)

	var close_btn := Button.new()
	close_btn.text = "✕ Back to Duel [P]"
	close_btn.add_theme_font_size_override("font_size", 9)
	close_btn.pressed.connect(_toggle_experiment_panel)
	hdr.add_child(close_btn)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.6, 0.5, 0.1, 0.5))
	_exp_vbox.add_child(sep)

	# Interactive AI Selection Rows
	_exp_vbox.add_child(_make_exp_row("Algorithm [1/2/3]:", ["Minimax", "Alpha-Beta", "Expectimax"],
		func(i: int): _manager.ai_algorithm = i; _refresh_debug_config()))
	_exp_vbox.add_child(_make_exp_row("Evaluation [Q..T]:", ["HP Diff", "Aggressive", "Defensive", "Weighted", "HP Ratio"],
		func(i: int): _manager.ai_eval_func = i; _refresh_debug_config()))
	_exp_vbox.add_child(_make_exp_row("Ordering [Z..V]:", ["Default", "Aggressive", "Defensive", "Random"],
		func(i: int): _manager.ai_action_order = i; _refresh_debug_config()))

	# Search Depth Selection Row
	var depth_row := HBoxContainer.new()
	depth_row.add_theme_constant_override("separation", 6)
	_exp_vbox.add_child(depth_row)

	var d_lbl := _make_small_label("Lookahead Depth [-/+]:")
	d_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	d_lbl.custom_minimum_size.x = 120
	depth_row.add_child(d_lbl)

	var btn_minus := Button.new()
	btn_minus.text = " - "
	btn_minus.custom_minimum_size = Vector2(28, 20)
	btn_minus.add_theme_font_size_override("font_size", 9)
	btn_minus.pressed.connect(func(): _change_ai_depth_by(-1))
	depth_row.add_child(btn_minus)

	var cur_depth: int = _manager.ai_depth if _manager != null else 3
	_lbl_depth_val = Label.new()
	_lbl_depth_val.text = "  %d Plies  " % cur_depth
	_lbl_depth_val.add_theme_font_size_override("font_size", 10)
	_lbl_depth_val.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	depth_row.add_child(_lbl_depth_val)

	var btn_plus := Button.new()
	btn_plus.text = " + "
	btn_plus.custom_minimum_size = Vector2(28, 20)
	btn_plus.add_theme_font_size_override("font_size", 9)
	btn_plus.pressed.connect(func(): _change_ai_depth_by(+1))
	depth_row.add_child(btn_plus)

	for d in [1, 2, 3, 4, 5, 6]:
		var d_val: int = d
		var d_btn := Button.new()
		d_btn.text = "d=%d" % d_val
		d_btn.custom_minimum_size = Vector2(38, 20)
		d_btn.add_theme_font_size_override("font_size", 8)
		d_btn.pressed.connect(func(): _set_ai_depth(d_val))
		depth_row.add_child(d_btn)

	var run_row := HBoxContainer.new()
	_exp_vbox.add_child(run_row)

	var run_btn := Button.new()
	run_btn.text = "⚡ Run Full Automated Benchmark (180 Headless Battles)"
	run_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_btn.add_theme_font_size_override("font_size", 10)
	run_btn.pressed.connect(_run_experiment)
	run_row.add_child(run_btn)

	# Scrollable Benchmark Log Box
	var log_box := PanelContainer.new()
	var lb_style := StyleBoxFlat.new()
	lb_style.bg_color = Color(0.02, 0.02, 0.06, 0.95)
	lb_style.border_color = Color(0.35, 0.3, 0.15, 0.6)
	lb_style.set_border_width_all(1)
	lb_style.set_corner_radius_all(4)
	lb_style.content_margin_left   = 8
	lb_style.content_margin_right  = 8
	lb_style.content_margin_top    = 6
	lb_style.content_margin_bottom = 6
	log_box.add_theme_stylebox_override("panel", lb_style)
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.custom_minimum_size = Vector2(0, 160)
	_exp_vbox.add_child(log_box)

	_exp_log = RichTextLabel.new()
	_exp_log.bbcode_enabled = true
	_exp_log.fit_content = false
	_exp_log.scroll_active = true
	_exp_log.scroll_following = false
	_exp_log.selection_enabled = true
	_exp_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_exp_log.add_theme_font_size_override("normal_font_size", 9)
	_exp_log.text = "[color=#ffcc00][b]Tekan tombol [⚡ Run Full Automated Benchmark] di atas.[/b][/color]\n[color=#888]Sistem akan menjalankan simulasi headless (Minimax vs Alpha-Beta, evaluasi fungsi, ordering, dan perbandingan depth).\nHasil pengujian dapat di-scroll dengan mouse wheel dan disalin langsung via [📋 Copy to Clipboard].[/color]"
	log_box.add_child(_exp_log)

# ─────────────────────────────────────────────────────────────────────────────
# PROCEDURAL ANIMATION LOOP (WAITING / BREATHING MODE)
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_idle_time += delta

	# 1. Player Idle Breathing (when not executing an action animation)
	if is_instance_valid(_player_sprite) and not _player_animating:
		var bob := sin(_idle_time * 3.2) * 3.5
		_player_sprite.position.y = -145.0 + bob
		var scale_y := 1.0 + sin(_idle_time * 3.2) * 0.02
		_player_sprite.scale = _player_base_scale * Vector2(1.0, scale_y)

	# 2. Demon Idle Breathing (slower, heavier demonic pulse)
	if is_instance_valid(_demon_sprite) and not _demon_animating:
		var bob_d := sin(_idle_time * 2.4 + 1.2) * 4.5
		_demon_sprite.position.y = -170.0 + bob_d
		var scale_yd := 1.0 + sin(_idle_time * 2.4 + 1.2) * 0.025
		_demon_sprite.scale = _demon_base_scale * Vector2(1.0, scale_yd)

	# 3. Ground Auras Pulse
	if is_instance_valid(_player_aura):
		var p_pulse: float = 0.5 + 0.25 * sin(_idle_time * 3.0)
		_player_aura.modulate.a = p_pulse
	if is_instance_valid(_demon_aura):
		var d_pulse: float = 0.5 + 0.25 * sin(_idle_time * 2.5 + 0.8)
		_demon_aura.modulate.a = d_pulse

	# 4. Turn Badge Arrow Bounce
	if is_instance_valid(_player_turn_badge) and _player_turn_badge.visible:
		var arrow_bob := sin(_idle_time * 5.0) * 4.0
		_player_turn_badge.position.y = -180.0 + arrow_bob
	if is_instance_valid(_demon_turn_badge) and _demon_turn_badge.visible:
		var demon_bob := sin(_idle_time * 4.0) * 4.0
		_demon_turn_badge.position.y = -205.0 + demon_bob

	# 5. Continuous position lock when not in dash attack animation
	if is_instance_valid(_player_node) and not _player_animating:
		_player_node.position = _player_base_pos
	if is_instance_valid(_demon_node) and not _demon_animating:
		_demon_node.position = _demon_base_pos

# ─────────────────────────────────────────────────────────────────────────────
# POSITION & RESPONSIVENESS
# ─────────────────────────────────────────────────────────────────────────────
func _update_positions() -> void:
	if not is_instance_valid(_combat_stage):
		return
	var w: float = _combat_stage.size.x
	var h: float = _combat_stage.size.y
	if w <= 0.0:
		w = 640.0
	if h <= 0.0:
		h = 310.0

	_player_base_pos = Vector2(w * 0.22, h * 0.78)
	_demon_base_pos  = Vector2(w * 0.78, h * 0.78)

	if is_instance_valid(_player_node) and not _player_animating:
		_player_node.position = _player_base_pos
	if is_instance_valid(_demon_node) and not _demon_animating:
		_demon_node.position = _demon_base_pos

# ─────────────────────────────────────────────────────────────────────────────
# ACTION ANIMATION DISPATCHER (OPSI B)
# ─────────────────────────────────────────────────────────────────────────────
func _execute_player_choice(action: int) -> void:
	if _is_busy_animating:
		return
	_set_buttons_enabled(false)
	_manager.player_action(action)

func _on_action_performed(actor: String, action: int, result: Dictionary, new_state: BattleState) -> void:
	_is_busy_animating = true
	_set_buttons_enabled(false)

	_update_action_history_log(actor, result)
	_play_combat_animation(actor, action, result, new_state)

func _play_combat_animation(actor: String, action: int, result: Dictionary, new_state: BattleState) -> void:
	var dmg: int         = result.get("damage_dealt", 0) as int
	var heal: int        = result.get("heal_amount", 0) as int
	var was_blocked: bool = result.get("was_blocked", false) as bool

	var is_player: bool = (actor == "player")
	var attacker_node   := _player_node if is_player else _demon_node
	var defender_node   := _demon_node if is_player else _player_node
	var attacker_sprite := _player_sprite if is_player else _demon_sprite
	var defender_sprite := _demon_sprite if is_player else _player_sprite
	var base_pos        := _player_base_pos if is_player else _demon_base_pos
	var target_dir      := 1.0 if is_player else -1.0

	if is_player:
		_player_animating = true
	else:
		_demon_animating = true

	match action:
		MinimaxSolver.Action.ATTACK:
			# Dash forward -> Hit impact -> Return
			var dash_target := base_pos + Vector2(target_dir * 170.0, 0.0)
			var tw := create_tween()
			tw.tween_property(attacker_node, "position", dash_target, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func():
				_trigger_hit_impact(defender_node, defender_sprite, dmg, was_blocked, false)
				_smooth_refresh_hp(new_state)
			)
			tw.tween_property(attacker_node, "position", base_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tw.finished.connect(func():
				_on_animation_finished(is_player, new_state)
			)

		MinimaxSolver.Action.HEAVY_ATTACK:
			# Windup backwards -> Fast heavy dash -> Stage shake -> Return
			var windup_pos := base_pos - Vector2(target_dir * 30.0, 0.0)
			var dash_target := base_pos + Vector2(target_dir * 200.0, 0.0)
			var tw := create_tween()
			# Windup
			tw.tween_property(attacker_node, "position", windup_pos, 0.12)
			tw.parallel().tween_property(attacker_sprite, "modulate", Color(2.5, 0.6, 0.2), 0.12)
			# Dash & Strike
			tw.tween_property(attacker_node, "position", dash_target, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			tw.tween_callback(func():
				attacker_sprite.modulate = Color(1.0, 1.0, 1.0)
				_shake_combat_stage(7.0, 0.25)
				_trigger_hit_impact(defender_node, defender_sprite, dmg, was_blocked, true)
				_smooth_refresh_hp(new_state)
			)
			tw.tween_property(attacker_node, "position", base_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tw.finished.connect(func():
				_on_animation_finished(is_player, new_state)
			)

		MinimaxSolver.Action.DEFEND:
			# Step back into defensive stance + barrier flash
			var brace_pos := base_pos - Vector2(target_dir * 20.0, 0.0)
			var shield_fx := _player_shield_fx if is_player else _demon_shield_fx
			var tw := create_tween()
			tw.tween_property(attacker_node, "position", brace_pos, 0.12)
			tw.parallel().tween_property(shield_fx, "modulate:a", 1.0, 0.15)
			tw.parallel().tween_property(shield_fx, "scale", Vector2(1.3, 1.3), 0.15)
			tw.tween_callback(func():
				_spawn_floating_text("🛡️ DEFENDING (Block 50%)", attacker_node.position + Vector2(0, -90), Color(0.2, 0.8, 1.0), false)
			)
			tw.tween_property(attacker_node, "position", base_pos, 0.18)
			tw.finished.connect(func():
				_refresh_defending_badges(new_state)
				_on_animation_finished(is_player, new_state)
			)

		MinimaxSolver.Action.POTION:
			# Hop upwards + green sparkle burst
			var jump_pos := base_pos - Vector2(0, 32.0)
			var tw := create_tween()
			tw.tween_property(attacker_node, "position", jump_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(attacker_node, "position", base_pos, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func():
				_spawn_floating_text("+%d HP 💊" % heal, attacker_node.position + Vector2(0, -110), Color(0.2, 1.0, 0.4), false)
				_smooth_refresh_hp(new_state)
			)
			tw.finished.connect(func():
				_on_animation_finished(is_player, new_state)
			)

func _trigger_hit_impact(def_node: Control, def_sprite: TextureRect, dmg: int, was_blocked: bool, is_crit: bool) -> void:
	if not is_instance_valid(def_node) or not is_instance_valid(def_sprite):
		return

	# Flash red/white
	def_sprite.modulate = Color(3.5, 0.4, 0.4) if is_crit else Color(2.5, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(def_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.22)

	# Flinch / Knockback shake
	var orig_pos := def_node.position
	var knock_dir := 1.0 if def_node == _demon_node else -1.0
	var knock_dist := 35.0 if is_crit else 18.0
	var tw_knock := create_tween()
	tw_knock.tween_property(def_node, "position", orig_pos + Vector2(knock_dir * knock_dist, 0.0), 0.08)
	tw_knock.tween_property(def_node, "position", orig_pos, 0.14)

	# Floating damage number
	var spawn_pos := def_node.position + Vector2(0.0, -100.0)
	if was_blocked:
		_spawn_floating_text("🛡️ BLOCKED! -%d HP" % dmg, spawn_pos, Color(0.3, 0.8, 1.0), false)
	elif is_crit:
		_spawn_floating_text("🔥 -%d CRIT!" % dmg, spawn_pos, Color(1.0, 0.3, 0.2), true)
	else:
		_spawn_floating_text("-%d HP" % dmg, spawn_pos, Color(1.0, 0.8, 0.2), false)

func _on_animation_finished(is_player: bool, new_state: BattleState) -> void:
	if is_player:
		_player_animating = false
	else:
		_demon_animating = false

	_is_busy_animating = false
	_refresh_state_data(new_state)

	# Check if turn is currently player's turn to re-enable inputs
	if _manager != null and _manager.is_active and _manager.state != null:
		if _manager.state.turn == BattleState.Turn.PLAYER:
			_set_buttons_enabled(true)
			_show_player_tip()

# ─────────────────────────────────────────────────────────────────────────────
# FLOATING COMBAT TEXT & SHAKE VFX
# ─────────────────────────────────────────────────────────────────────────────
func _spawn_floating_text(text: String, pos: Vector2, color: Color, is_crit: bool) -> void:
	if not is_instance_valid(_vfx_layer):
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14 if is_crit else 11)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = pos - Vector2(50, 10)
	lbl.z_index = 30
	_vfx_layer.add_child(lbl)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 48.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.75).set_delay(0.2)
	if is_crit:
		tw.tween_property(lbl, "scale", Vector2(1.25, 1.25), 0.2).set_trans(Tween.TRANS_BOUNCE)
	tw.finished.connect(lbl.queue_free)

func _shake_combat_stage(intensity: float = 6.0, duration: float = 0.22) -> void:
	if not is_instance_valid(_combat_stage):
		return
	var tw := create_tween()
	var steps: int = 5
	var step_time := duration / float(steps)
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(_combat_stage, "position", offset, step_time)
	tw.tween_property(_combat_stage, "position", Vector2.ZERO, step_time)

# ─────────────────────────────────────────────────────────────────────────────
# TURN & STATE SIGNALS
# ─────────────────────────────────────────────────────────────────────────────
func _on_turn_changed(whose_turn: String) -> void:
	if whose_turn == "player":
		_turn_label.text = "YOUR TURN — Select an action:"
		_turn_label.add_theme_color_override("font_color", Color(0.0, 0.95, 0.85))
		if is_instance_valid(_player_turn_badge): _player_turn_badge.visible = true
		if is_instance_valid(_demon_turn_badge):  _demon_turn_badge.visible  = false

		if not _is_busy_animating:
			_set_buttons_enabled(true)
			_show_player_tip()
	else:
		_turn_label.text = "⏳ Demon is evaluating game tree…"
		_turn_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15))
		if is_instance_valid(_player_turn_badge): _player_turn_badge.visible = false
		if is_instance_valid(_demon_turn_badge):
			_demon_turn_badge.visible = true
			_demon_badge_lbl.text = "⏳ THINKING..."
		_set_buttons_enabled(false)

func _on_npc_thinking(is_thinking: bool) -> void:
	if is_thinking and is_instance_valid(_demon_turn_badge):
		_demon_turn_badge.visible = true
		_demon_badge_lbl.text = "⏳ CALCULATING..."

func _on_battle_started(state: BattleState) -> void:
	_action_history.clear()
	_update_positions()
	_refresh_state_data(state)
	_turn_label.text = "YOUR TURN — Select an action:"
	_show_player_tip()
	_refresh_debug_config()
	_build_action_score_idle()

func _on_battle_ended(winner: String, final_state: BattleState) -> void:
	_refresh_state_data(final_state)
	_set_buttons_enabled(false)
	if is_instance_valid(_player_turn_badge): _player_turn_badge.visible = false
	if is_instance_valid(_demon_turn_badge):  _demon_turn_badge.visible  = false

	if winner == "player":
		_turn_label.text = "🏆 VICTORY! Demon brute was vanquished!"
		_turn_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
		_spawn_floating_text("🏆 VICTORY!", _player_base_pos + Vector2(0, -120), Color(0.2, 1.0, 0.5), true)
		if is_instance_valid(_demon_sprite):
			create_tween().tween_property(_demon_sprite, "modulate:a", 0.0, 1.0)
	else:
		_turn_label.text = "💀 DEFEATED! The Minimax demon prevailed."
		_turn_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
		_spawn_floating_text("💀 DEFEATED!", _player_base_pos + Vector2(0, -120), Color(1.0, 0.25, 0.2), true)
		if is_instance_valid(_player_sprite):
			create_tween().tween_property(_player_sprite, "modulate:a", 0.0, 1.0)

# ─────────────────────────────────────────────────────────────────────────────
# STATE REFRESH & SMOOTH HP TRANSITION
# ─────────────────────────────────────────────────────────────────────────────
func _smooth_refresh_hp(state: BattleState) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_player_hp_bar, "value", float(state.player_hp), 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_npc_hp_bar,    "value", float(state.npc_hp),    0.35).set_trans(Tween.TRANS_QUAD)

	_player_hp_label.text = "HP: %d / %d" % [state.player_hp, BattleState.MAX_HP]
	_npc_hp_label.text    = "HP: %d / %d" % [state.npc_hp,    BattleState.MAX_HP]
	_player_pot_label.text = "💊 Potions: %d/3" % state.player_potions
	_npc_pot_label.text    = "💊 Potions: %d/3" % state.npc_potions

	_refresh_defending_badges(state)

func _refresh_state_data(state: BattleState) -> void:
	_player_hp_bar.value  = state.player_hp
	_npc_hp_bar.value     = state.npc_hp
	_player_hp_label.text = "HP: %d / %d" % [state.player_hp, BattleState.MAX_HP]
	_npc_hp_label.text    = "HP: %d / %d" % [state.npc_hp,    BattleState.MAX_HP]
	_player_pot_label.text = "💊 Potions: %d/3" % state.player_potions
	_npc_pot_label.text    = "💊 Potions: %d/3" % state.npc_potions

	_refresh_defending_badges(state)
	_update_strategic_assessment(state)

func _refresh_defending_badges(state: BattleState) -> void:
	if is_instance_valid(_player_def_badge):
		_player_def_badge.visible = state.player_defending
	if is_instance_valid(_npc_def_badge):
		_npc_def_badge.visible = state.npc_defending
	if is_instance_valid(_player_shield_fx):
		_player_shield_fx.modulate.a = 0.8 if state.player_defending else 0.0
	if is_instance_valid(_demon_shield_fx):
		_demon_shield_fx.modulate.a = 0.8 if state.npc_defending else 0.0

func _show_player_tip() -> void:
	if _manager == null or _manager.state == null:
		return
	var s := _manager.state
	var tip := ""
	if s.player_hp <= 30 and s.player_potions > 0:
		tip = "💊 HP kritis! Gunakan Potion sekarang."
	elif s.npc_defending:
		tip = "🔥 Demon sedang Defend! Gunakan Heavy Attack untuk menembus block."
	elif s.player_hp < s.npc_hp - 20:
		tip = "🛡️ Tertinggal HP. Defend dapat menghemat HP dari Heavy Attack lawan."
	elif s.npc_hp <= 30:
		tip = "⚔️ Demon hampir tumbang! Lancarkan serangan terakhir!"
	else:
		tip = "⚔️ Serang terus. Manfaatkan saat Demon tidak dalam posisi Defend."
	_status_label.text = tip

# ─────────────────────────────────────────────────────────────────────────────
# DEBUG SIDEBAR UPDATER (MODULAR SUB-BOXES)
# ─────────────────────────────────────────────────────────────────────────────
func _toggle_debug_sidebar() -> void:
	_debug_visible = not _debug_visible
	_debug_sidebar.visible = _debug_visible
	_btn_toggle_dbg.text = "🔍 Debug Overlay [D]" if _debug_visible else "🔍 Show Debug [D]"
	await get_tree().process_frame
	await get_tree().process_frame
	_update_positions()

func _set_ai_depth(new_depth: int) -> void:
	if _manager == null:
		return
	_manager.ai_depth = clampi(new_depth, 1, 6)
	_refresh_debug_config()

func _change_ai_depth_by(diff: int) -> void:
	if _manager == null:
		return
	_set_ai_depth(_manager.ai_depth + diff)

func _refresh_debug_config() -> void:
	if _manager == null:
		return
	var algo_names  := ["Minimax", "Alpha-Beta Pruning", "Expectimax"]
	var eval_names  := ["HP Diff", "Aggressive", "Defensive", "Weighted", "HP Ratio"]
	var order_names := ["Default Heuristic", "Aggressive First", "Defensive First", "Randomized"]

	if is_instance_valid(_lbl_algo):
		_lbl_algo.text = algo_names[_manager.ai_algorithm]
	if is_instance_valid(_lbl_eval):
		_lbl_eval.text = eval_names[_manager.ai_eval_func]
	if is_instance_valid(_lbl_depth):
		_lbl_depth.text = "%d Plies" % _manager.ai_depth
	if is_instance_valid(_lbl_depth_val):
		_lbl_depth_val.text = "  %d Plies  " % _manager.ai_depth
	if is_instance_valid(_lbl_order):
		_lbl_order.text = order_names[_manager.ai_action_order]

func _on_debug_updated(info: Dictionary) -> void:
	_refresh_debug_config()

	var nv: int = info.get("nodes_visited", 0) as int
	var np: int = info.get("nodes_pruned", 0) as int
	var md: int = info.get("max_depth_reached", 0) as int
	var total_nodes: int = nv + np
	var prune_pct: float = (float(np) / float(max(1, total_nodes))) * 100.0

	if is_instance_valid(_lbl_visited):    _lbl_visited.text    = str(nv)
	if is_instance_valid(_lbl_pruned):     _lbl_pruned.text     = str(np)
	if is_instance_valid(_lbl_efficiency): _lbl_efficiency.text = "%.1f%%" % prune_pct
	if is_instance_valid(_lbl_max_depth):  _lbl_max_depth.text  = str(md)

	# Action scores
	var scores: Dictionary = info.get("action_scores", {})
	var best_name: String  = info.get("best_action_name", "") as String
	_render_action_scores_box(scores, best_name)

func _render_action_scores_box(scores: Dictionary, best_name: String) -> void:
	if not is_instance_valid(_actions_vbox):
		return
	for c in _actions_vbox.get_children():
		c.queue_free()

	if scores.is_empty():
		var lbl := Label.new()
		lbl.text = "Awaiting decision..."
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_actions_vbox.add_child(lbl)
		return

	var keys := scores.keys()
	keys.sort_custom(func(a, b): return float(scores[a]) > float(scores[b]))

	for k in keys:
		var score: float = float(scores[k])
		var is_best: bool = (str(k) == best_name)

		var card := PanelContainer.new()
		var card_style := StyleBoxFlat.new()
		if is_best:
			card_style.bg_color = Color(0.18, 0.12, 0.02, 0.95)
			card_style.border_color = Color(1.0, 0.8, 0.2, 0.9)
			card_style.set_border_width_all(1)
		else:
			card_style.bg_color = Color(0.08, 0.07, 0.14, 0.85)
			card_style.border_color = Color(0.25, 0.2, 0.4, 0.5)
			card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(4)
		card_style.content_margin_left   = 6
		card_style.content_margin_right  = 6
		card_style.content_margin_top    = 3
		card_style.content_margin_bottom = 3
		card.add_theme_stylebox_override("panel", card_style)
		_actions_vbox.add_child(card)

		var row := HBoxContainer.new()
		card.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = str(k)
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4) if is_best else Color(0.85, 0.85, 0.85))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var score_lbl := Label.new()
		score_lbl.text = "%+.1f" % score
		score_lbl.add_theme_font_size_override("font_size", 10)
		var score_color := Color(0.3, 1.0, 0.5) if score >= 0.0 else Color(1.0, 0.35, 0.35)
		score_lbl.add_theme_color_override("font_color", score_color)
		row.add_child(score_lbl)

		if is_best:
			var badge := Label.new()
			badge.text = " ★ BEST"
			badge.add_theme_font_size_override("font_size", 8)
			badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			row.add_child(badge)

func _build_action_score_idle() -> void:
	if not is_instance_valid(_actions_vbox):
		return
	for c in _actions_vbox.get_children():
		c.queue_free()
	var placeholder := Label.new()
	placeholder.text = "Scores will appear during Demon's turn…"
	placeholder.add_theme_font_size_override("font_size", 9)
	placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_actions_vbox.add_child(placeholder)

func _update_strategic_assessment(s: BattleState) -> void:
	if not is_instance_valid(_lbl_advantage) or not is_instance_valid(_lbl_threat):
		return
	var hp_diff: int = s.npc_hp - s.player_hp
	if hp_diff > 15:
		_lbl_advantage.text = "Demon (+%d HP Lead)" % hp_diff
		_lbl_advantage.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	elif hp_diff < -15:
		_lbl_advantage.text = "Player (+%d HP Lead)" % (-hp_diff)
		_lbl_advantage.add_theme_color_override("font_color", Color(0.0, 0.95, 0.85))
	else:
		_lbl_advantage.text = "Even Match (Δ%d HP)" % hp_diff
		_lbl_advantage.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4))

	if s.npc_hp <= 30:
		_lbl_threat.text = "Demon Lethal Danger!"
		_lbl_threat.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	elif s.player_hp <= 30:
		_lbl_threat.text = "Player Critical Risk!"
		_lbl_threat.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	else:
		_lbl_threat.text = "Stable"
		_lbl_threat.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _update_action_history_log(actor: String, result: Dictionary) -> void:
	var icon: String = result.get("action_icon", "")
	var name: String = result.get("action_name", "")
	var dmg: int     = result.get("damage_dealt", 0) as int
	var heal: int    = result.get("heal_amount", 0) as int
	var blocked: bool = result.get("was_blocked", false) as bool

	var entry := ""
	if actor == "player":
		entry += "[color=#00f5d4]Player[/color]: %s %s" % [icon, name]
	else:
		entry += "[color=#ff5533]Demon[/color]: %s %s" % [icon, name]

	if dmg > 0:
		entry += " [color=#ff4444]-%d HP[/color]" % dmg
		if blocked: entry += " [color=#66ccff](blocked)[/color]"
	if heal > 0:
		entry += " [color=#33ff88]+%d HP[/color]" % heal

	_action_history.push_front(entry)
	if _action_history.size() > 5:
		_action_history.pop_back()

	if is_instance_valid(_lbl_history):
		_lbl_history.text = "\n".join(_action_history)

# ─────────────────────────────────────────────────────────────────────────────
# EXPERIMENT RUNNER & CONTROLS
# ─────────────────────────────────────────────────────────────────────────────
func _toggle_experiment_panel() -> void:
	_exp_visible = not _exp_visible
	_exp_panel.visible = _exp_visible
	if is_instance_valid(_combat_stage_panel):
		_combat_stage_panel.visible = not _exp_visible
	if is_instance_valid(_btn_toggle_exp):
		_btn_toggle_exp.text = "⚔️ Back to Duel [P]" if _exp_visible else "🧪 Benchmark Lab [P]"
	call_deferred("_update_positions")

func _copy_exp_results() -> void:
	if is_instance_valid(_exp_log) and not _exp_log.text.is_empty():
		DisplayServer.clipboard_set(_exp_log.get_parsed_text())
		if is_instance_valid(_btn_copy_exp):
			_btn_copy_exp.text = "✅ Copied!"
			await get_tree().create_timer(1.8).timeout
			if is_instance_valid(_btn_copy_exp):
				_btn_copy_exp.text = "📋 Copy to Clipboard"

func _run_experiment() -> void:
	_exp_log.text = "[color=#ffcc00]⏳ Sedang menjalankan simulasi 180 pertarungan headless across all configs...\nHarap tunggu sebentar…[/color]"
	await get_tree().process_frame
	await get_tree().process_frame
	var runner := ExperimentRunner.new()
	var results := runner.run_comparison(_manager)
	_exp_log.text = results
	_exp_log.scroll_to_line(0)

# ─────────────────────────────────────────────────────────────────────────────
# INPUT SHORTCUTS
# ─────────────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_D:
			_toggle_debug_sidebar()
		KEY_P:
			_toggle_experiment_panel()
		KEY_1:
			if not _is_busy_animating and _manager != null and _manager.is_active and _manager.state.turn == BattleState.Turn.PLAYER:
				_execute_player_choice(MinimaxSolver.Action.ATTACK)
		KEY_2:
			if not _is_busy_animating and _manager != null and _manager.is_active and _manager.state.turn == BattleState.Turn.PLAYER:
				_execute_player_choice(MinimaxSolver.Action.HEAVY_ATTACK)
		KEY_3:
			if not _is_busy_animating and _manager != null and _manager.is_active and _manager.state.turn == BattleState.Turn.PLAYER:
				_execute_player_choice(MinimaxSolver.Action.DEFEND)
		KEY_4:
			if not _is_busy_animating and _manager != null and _manager.is_active and _manager.state.turn == BattleState.Turn.PLAYER:
				_execute_player_choice(MinimaxSolver.Action.POTION)
		KEY_MINUS:
			_change_ai_depth_by(-1)
		KEY_EQUAL:
			_change_ai_depth_by(+1)

# ─────────────────────────────────────────────────────────────────────────────
# WIDGET & FACTORY HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _make_subbox(title: String, border_color: Color) -> Dictionary:
	var box := PanelContainer.new()
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.06, 0.05, 0.12, 0.95)
	box_style.border_color = border_color
	box_style.set_border_width_all(1)
	box_style.set_corner_radius_all(6)
	box_style.content_margin_left   = 8
	box_style.content_margin_right  = 8
	box_style.content_margin_top    = 6
	box_style.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", box_style)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	box.add_child(vb)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", border_color.lightened(0.5))
	vb.add_child(title_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", border_color.darkened(0.2))
	vb.add_child(sep)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 3)
	vb.add_child(content)

	return { "panel": box, "content": content }

func _make_stat_row(label: String, val: String, val_color: Color, parent: Control) -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)

	var v := Label.new()
	v.text = val
	v.add_theme_font_size_override("font_size", 9)
	v.add_theme_color_override("font_color", val_color)
	row.add_child(v)
	return v

func _make_metric_card(title: String, val: String, color: Color, parent: Control) -> Label:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.07, 0.14, 0.9)
	card_style.border_color = color.darkened(0.4)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.content_margin_left   = 6
	card_style.content_margin_right  = 6
	card_style.content_margin_top    = 4
	card_style.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", card_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	card.add_child(vb)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 8)
	t.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	vb.add_child(t)

	var v := Label.new()
	v.text = val
	v.add_theme_font_size_override("font_size", 12)
	v.add_theme_color_override("font_color", color)
	vb.add_child(v)
	return v

func _make_hp_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = BattleState.MAX_HP
	bar.value     = BattleState.MAX_HP
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.08, 0.16)
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	return bar

func _make_action_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(105, 52)

	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.4)
	normal.border_color = color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)

	var hover := StyleBoxFlat.new()
	hover.bg_color = color.darkened(0.2)
	hover.border_color = color.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = color
	pressed.set_corner_radius_all(6)

	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.12, 0.12, 0.15)
	disabled.border_color = Color(0.25, 0.25, 0.3)
	disabled.set_border_width_all(1)
	disabled.set_corner_radius_all(6)

	btn.add_theme_stylebox_override("normal",   normal)
	btn.add_theme_stylebox_override("hover",    hover)
	btn.add_theme_stylebox_override("pressed",  pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_font_size_override("font_size", 10)
	return btn

func _make_mini_badge(text: String, color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	var b_style := StyleBoxFlat.new()
	b_style.bg_color = color.darkened(0.6)
	b_style.border_color = color
	b_style.set_border_width_all(1)
	b_style.set_corner_radius_all(3)
	b_style.content_margin_left   = 5
	b_style.content_margin_right  = 5
	b_style.content_margin_top    = 1
	b_style.content_margin_bottom = 1
	badge.add_theme_stylebox_override("panel", b_style)

	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color.lightened(0.3))
	badge.add_child(l)
	return badge

func _make_texture_rect(path: String, size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	var tex := load(path) as Texture2D
	if tex:
		tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = size
	tr.size = size
	return tr

func _make_small_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 9)
	return lbl

func _set_buttons_enabled(enabled: bool) -> void:
	if is_instance_valid(_btn_attack): _btn_attack.disabled = not enabled
	if is_instance_valid(_btn_heavy):  _btn_heavy.disabled  = not enabled
	if is_instance_valid(_btn_defend): _btn_defend.disabled = not enabled
	if is_instance_valid(_btn_potion):
		var has_potions: bool = (_manager != null and _manager.state != null and _manager.state.player_potions > 0)
		_btn_potion.disabled = not enabled or not has_potions

func _make_exp_row(label_text: String, options: Array, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := _make_small_label(label_text)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	lbl.custom_minimum_size.x = 120
	row.add_child(lbl)
	for i in range(options.size()):
		var idx: int = i
		var btn := Button.new()
		btn.text = str(options[i])
		btn.custom_minimum_size = Vector2(65, 20)
		btn.add_theme_font_size_override("font_size", 8)
		btn.pressed.connect(func(): callback.call(idx))
		row.add_child(btn)
	return row
