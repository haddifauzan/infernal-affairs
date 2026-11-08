class_name AwakeningBannerModal
extends CanvasLayer

## AwakeningBannerModal.gd
## Dramatic popup dialog triggered when Player reaches Level 2 and the Guard awakens (Tahap 4).

signal closed

var dialog_message: String = ""
var seal_name: String = ""

var _panel: PanelContainer

func setup(msg: String, s_name: String) -> void:
	dialog_message = msg
	seal_name = s_name

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_build_ui()

func _build_ui() -> void:
	# Fullscreen dark overlay
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.01, 0.02, 0.75)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(520, 220)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.03, 0.06, 0.98)
	style.border_color = Color(1.0, 0.45, 0.15)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left   = 24
	style.content_margin_right  = 24
	style.content_margin_top    = 18
	style.content_margin_bottom = 18
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	var header_lbl := Label.new()
	header_lbl.text = "⚔️ KEBANGKITAN PENJAGA GERBANG (GUARD AWAKENED) ⚔️"
	header_lbl.add_theme_font_size_override("font_size", 13)
	header_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header_lbl)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var quote_lbl := Label.new()
	quote_lbl.text = "\"%s\"" % dialog_message
	quote_lbl.add_theme_font_size_override("font_size", 11)
	quote_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.25))
	quote_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(quote_lbl)

	var info_lbl := Label.new()
	info_lbl.text = "✦ IDENTITAS SEGEL GERBANG TERUNGKAP: %s ✦\nBasis Pengetahuan (KB) Logika telah mengonfirmasi kelemahan & karakteristik musuh." % seal_name.to_upper()
	info_lbl.add_theme_font_size_override("font_size", 9)
	info_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_lbl)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "[ Lanjutkan Petualangan (Enter / Space) ]"
	dismiss_btn.custom_minimum_size = Vector2(260, 32)
	dismiss_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dismiss_btn.pressed.connect(_close)
	vbox.add_child(dismiss_btn)

	# Appear animation
	_panel.scale = Vector2(0.85, 0.85)
	_panel.pivot_offset = _panel.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			_close()

func _close() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		closed.emit()
		queue_free()
	)

