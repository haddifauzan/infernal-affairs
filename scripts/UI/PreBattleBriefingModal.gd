class_name PreBattleBriefingModal
extends CanvasLayer

## PreBattleBriefingModal.gd
## Modal tab peringatan intel combat & tips taktis yang muncul SEBELUM masuk ke duel.
## Modal ini TIDAK memiliki timer otomatis, melainkan menunggu pemain menekan [X] / [Enter]
## untuk melanjutkan ke battle atau [ESC] untuk batal / mundur.

signal continue_to_battle
signal cancelled

var enemy_type: String = "guard"
var enemy_name: String = "Hell Guard"
var enemy_element: String = "Fire"
var enemy_weapon: String = ""
var enemy_strategy: String = "Aggressive"
var enemy_strategy_desc: String = ""
var gate_seal: String = "Seal of Flame"
var gate_seal_effect: String = ""
var boss_weapon_effect: String = ""

var _root: MarginContainer
var _panel: PanelContainer

func _init() -> void:
	layer = 16

func setup_briefing(type: String, e_name: String, e_elem: String, e_wep: String, csp_extra: Dictionary = {}) -> void:
	enemy_type = type
	enemy_name = e_name
	enemy_element = e_elem
	enemy_weapon = e_wep
	enemy_strategy = csp_extra.get("strategy", "Aggressive")
	enemy_strategy_desc = csp_extra.get("strategy_desc", "")
	gate_seal = csp_extra.get("gate_seal", "Seal of Flame")
	gate_seal_effect = csp_extra.get("gate_seal_effect", "")
	boss_weapon_effect = csp_extra.get("boss_weapon_effect", "")

	# Guarantee fallback passive effect descriptions if not present
	if enemy_type == "guard" and gate_seal_effect.is_empty():
		var s_lower := gate_seal.to_lower()
		if "blood" in s_lower:
			gate_seal_effect = "Kulit Iblis: Seluruh damage fisik yang diterima Penjaga berkurang flat 4 poin."
		elif "shadow" in s_lower:
			gate_seal_effect = "Hisap Jiwa: Serangan Penjaga menyerap 15% damage menjadi HP."
		else:
			gate_seal_effect = "Medan Panas: Pemain terkena 3 damage api tak langsung per ronde."
	elif enemy_type == "boss" and boss_weapon_effect.is_empty():
		var w_lower := enemy_weapon.to_lower()
		if "trident" in w_lower or "blood" in w_lower:
			boss_weapon_effect = "Armor Pierce: Serangan Bos menembus pertahanan, aksi Defend pemain hanya efektif 20%."
		elif "scythe" in w_lower or "flame" in w_lower:
			boss_weapon_effect = "Infernal Burn: Serangan Heavy Bos memberi efek Burn DoT 5 HP/ronde selama 2 ronde."
		else:
			boss_weapon_effect = "Soul Drain: Serangan Bos menyerap 20% damage menjadi penyembuhan HP Bos."

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 1. Fullscreen dark backdrop
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.05, 0.88)
	add_child(backdrop)

	# 2. Centered Modal Container
	_root = MarginContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_theme_constant_override("margin_left", 60)
	_root.add_theme_constant_override("margin_right", 60)
	_root.add_theme_constant_override("margin_top", 25)
	_root.add_theme_constant_override("margin_bottom", 25)
	add_child(_root)

	_panel = PanelContainer.new()
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var border_color := Color(1.0, 0.55, 0.15, 0.95)
	if enemy_type == "boss":
		border_color = Color(1.0, 0.25, 0.25, 0.95)
	elif "shadow" in gate_seal.to_lower():
		border_color = Color(0.75, 0.3, 1.0, 0.95)
	elif "blood" in gate_seal.to_lower():
		border_color = Color(1.0, 0.2, 0.3, 0.95)

	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.05, 0.04, 0.09, 0.97)
	p_style.border_color = border_color
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(10)
	p_style.content_margin_left   = 20
	p_style.content_margin_right  = 20
	p_style.content_margin_top    = 16
	p_style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", p_style)
	_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(vbox)

	# --- HEADER ---
	var h_box := HBoxContainer.new()
	vbox.add_child(h_box)

	var title_lbl := Label.new()
	title_lbl.text = "⚠️ PERINGATAN COMBAT: INTEL & STRATEGI LAWAN"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_box.add_child(title_lbl)

	var csp_badge := Label.new()
	csp_badge.text = "[ CSP ENCOUNTER BRIEFING ]"
	csp_badge.add_theme_font_size_override("font_size", 10)
	csp_badge.add_theme_color_override("font_color", Color(0.2, 1.0, 0.7))
	h_box.add_child(csp_badge)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# --- ROW 1: ENEMY PROFILE & PASIF ---
	var profile_box := HBoxContainer.new()
	profile_box.add_theme_constant_override("separation", 16)
	vbox.add_child(profile_box)

	# Portrait VBox
	var port_vbox := VBoxContainer.new()
	port_vbox.add_theme_constant_override("separation", 6)
	profile_box.add_child(port_vbox)

	var portrait_rect := TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(90, 90)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.texture = _get_enemy_portrait()
	port_vbox.add_child(portrait_rect)

	var icon_seal_rect := TextureRect.new()
	icon_seal_rect.custom_minimum_size = Vector2(40, 40)
	icon_seal_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_seal_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if enemy_type == "guard":
		icon_seal_rect.texture = _get_seal_icon(gate_seal)
	else:
		icon_seal_rect.texture = _get_weapon_icon("boss", enemy_weapon)
	icon_seal_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	port_vbox.add_child(icon_seal_rect)

	# Details VBox
	var details_vbox := VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_vbox.add_theme_constant_override("separation", 4)
	profile_box.add_child(details_vbox)

	var enemy_h := Label.new()
	enemy_h.text = enemy_name.to_upper()
	enemy_h.add_theme_font_size_override("font_size", 13)
	enemy_h.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2) if enemy_type == "guard" else Color(1.0, 0.25, 0.25))
	details_vbox.add_child(enemy_h)

	var strat_row := Label.new()
	strat_row.text = "• Doktrin Strategi AI : %s (%s)" % [enemy_strategy, enemy_strategy_desc if enemy_strategy_desc.length() > 0 else "Minimax AI Optimization"]
	strat_row.add_theme_font_size_override("font_size", 10)
	strat_row.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	details_vbox.add_child(strat_row)

	var item_row := Label.new()
	if enemy_type == "guard":
		item_row.text = "• Beban Segel Gerbang: %s (Elemen: %s)" % [gate_seal, enemy_element]
	else:
		item_row.text = "• Senjata Bos Tahta   : %s (Elemen: %s)" % [enemy_weapon, enemy_element]
	item_row.add_theme_font_size_override("font_size", 10)
	item_row.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	details_vbox.add_child(item_row)

	var passive_box := PanelContainer.new()
	var pass_style := StyleBoxFlat.new()
	pass_style.bg_color = Color(0.12, 0.04, 0.06, 0.9)
	pass_style.border_color = Color(0.9, 0.25, 0.25, 0.8)
	pass_style.set_border_width_all(1)
	pass_style.set_corner_radius_all(4)
	pass_style.content_margin_left   = 8
	pass_style.content_margin_right  = 8
	pass_style.content_margin_top    = 4
	pass_style.content_margin_bottom = 4
	passive_box.add_theme_stylebox_override("panel", pass_style)
	details_vbox.add_child(passive_box)

	var passive_lbl := Label.new()
	var pass_text := gate_seal_effect if enemy_type == "guard" else boss_weapon_effect
	if pass_text.is_empty():
		pass_text = "Pertahanan dasar infernal aktif."
	passive_lbl.text = "⚠️ EFEK PASIF: %s" % pass_text
	passive_lbl.add_theme_font_size_override("font_size", 10)
	passive_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	passive_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_box.add_child(passive_lbl)

	# --- ROW 2: 💡 TIPS TAKTIS UNTUK PEMAIN ---
	var tips_panel := PanelContainer.new()
	tips_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tip_style := StyleBoxFlat.new()
	tip_style.bg_color = Color(0.04, 0.09, 0.08, 0.95)
	tip_style.border_color = Color(0.2, 0.9, 0.65, 0.9)
	tip_style.set_border_width_all(1)
	tip_style.set_corner_radius_all(6)
	tip_style.content_margin_left   = 12
	tip_style.content_margin_right  = 12
	tip_style.content_margin_top    = 8
	tip_style.content_margin_bottom = 8
	tips_panel.add_theme_stylebox_override("panel", tip_style)
	vbox.add_child(tips_panel)

	var tips_vbox := VBoxContainer.new()
	tips_vbox.add_theme_constant_override("separation", 4)
	tips_panel.add_child(tips_vbox)

	var tip_h := Label.new()
	tip_h.text = "💡 PANDUAN & REKOMENDASI TAKTIK PEMAIN:"
	tip_h.add_theme_font_size_override("font_size", 11)
	tip_h.add_theme_color_override("font_color", Color(0.2, 1.0, 0.75))
	tips_vbox.add_child(tip_h)

	var tip_body := RichTextLabel.new()
	tip_body.bbcode_enabled = true
	tip_body.text = _generate_player_tips_bbcode()
	tip_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tip_body.scroll_active = true
	tip_body.add_theme_font_size_override("normal_font_size", 10)
	tip_body.add_theme_font_size_override("bold_font_size", 11)
	tips_vbox.add_child(tip_body)

	# --- ROW 3: BOTTOM ACTIONS ---
	var bot_box := HBoxContainer.new()
	bot_box.add_theme_constant_override("separation", 14)
	vbox.add_child(bot_box)

	var btn_cancel := Button.new()
	btn_cancel.text = " 🏃 Mundur / Batal [ESC] "
	btn_cancel.add_theme_font_size_override("font_size", 11)
	btn_cancel.custom_minimum_size = Vector2(170, 34)
	var cancel_style := StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.35, 0.12, 0.12, 0.95)
	cancel_style.border_color = Color(0.85, 0.3, 0.3, 0.95)
	cancel_style.set_border_width_all(1)
	cancel_style.set_corner_radius_all(6)
	btn_cancel.add_theme_stylebox_override("normal", cancel_style)
	btn_cancel.pressed.connect(_on_cancel)
	bot_box.add_child(btn_cancel)

	var hint_lbl := Label.new()
	hint_lbl.text = "Tekan [X] atau [ENTER] untuk Duel  |  [ESC] untuk Batal"
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_box.add_child(hint_lbl)

	var btn_continue := Button.new()
	btn_continue.text = " ⚔ Lanjut ke Battle [X / Enter] "
	btn_continue.add_theme_font_size_override("font_size", 12)
	btn_continue.custom_minimum_size = Vector2(230, 34)
	var cont_style := StyleBoxFlat.new()
	cont_style.bg_color = Color(0.10, 0.55, 0.35, 0.95)
	cont_style.border_color = Color(0.3, 1.0, 0.65, 0.95)
	cont_style.set_border_width_all(2)
	cont_style.set_corner_radius_all(6)
	btn_continue.add_theme_stylebox_override("normal", cont_style)
	btn_continue.pressed.connect(_on_continue)
	bot_box.add_child(btn_continue)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_X, KEY_ENTER, KEY_SPACE:
			_on_continue()
		KEY_ESCAPE:
			_on_cancel()

func _on_continue() -> void:
	continue_to_battle.emit()
	queue_free()

func _on_cancel() -> void:
	cancelled.emit()
	queue_free()

func _get_enemy_portrait() -> Texture2D:
	var path: String = ""
	if enemy_type == "guard":
		var elower := enemy_name.to_lower()
		if "shaman" in elower:
			path = "res://assets/sprites/characters/guard/guard_shaman_portrait.png"
		elif "gargoyle" in elower:
			path = "res://assets/sprites/characters/guard/guard_gargoyle_portrait.png"
		else:
			path = "res://assets/sprites/characters/guard/guard_knight_portrait.png"
	else:
		path = "res://assets/sprites/characters/demon/demon_boss.png"

	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _get_seal_icon(seal_name: String) -> Texture2D:
	const PATH := "res://assets/sprites/map/obstacles/seals_gate_sheet.png"
	if not ResourceLoader.exists(PATH):
		return null
	var sheet: Texture2D = load(PATH) as Texture2D
	if not sheet:
		return null
	var col := 0
	var s_lower := seal_name.to_lower()
	if "shadow" in s_lower or "void" in s_lower:
		col = 1
	elif "blood" in s_lower:
		col = 2
	else:
		col = 0
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var w := sheet.get_width() / 3.0
	var h := float(sheet.get_height())
	atlas.region = Rect2(col * w, 0, w, h)
	return atlas

func _get_weapon_icon(wep_type: String, weapon_name: String) -> Texture2D:
	var path := "res://assets/sprites/characters/demon/weapons_boss_sheet.png" if wep_type == "boss" else "res://assets/sprites/characters/guard/weapons_guard_sheet.png"
	if not ResourceLoader.exists(path):
		return null
	var sheet: Texture2D = load(path) as Texture2D
	if not sheet:
		return null
	var col := 0
	var w_lower := weapon_name.to_lower()
	if "cursed" in w_lower or "shadow" in w_lower or "staff" in w_lower or "void" in w_lower:
		col = 1
	elif "trident" in w_lower or "blood" in w_lower or "mace" in w_lower or "chaos" in w_lower:
		col = 2
	else:
		col = 0
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var w := sheet.get_width() / 3.0
	var h := float(sheet.get_height())
	atlas.region = Rect2(col * w, 0, w, h)
	return atlas

func _get_passive_explanation_bbcode() -> String:
	var is_boss := enemy_type == "boss"
	var text := ""

	if is_boss:
		var wep_lower := enemy_weapon.to_lower()
		if "trident" in wep_lower or "blood" in wep_lower or "pierce" in boss_weapon_effect.to_lower():
			text += "[b][color=#ff4d6d]🩸 PENJELASAN SENJATA BOS: BLOOD TRIDENT (PENEMBUS PERISAI / ARMOR PIERCE)[/color][/b]\n"
			text += "• [b][color=#ffb3c1]Apa yang dilakukan senjata ini?[/color][/b] Trisula Darah memiliki efek [b]True Armor Pierce[/b] mutlak. Ketika kamu memilih aksi [b][Defend][/b], perisaimu hanya efektif 10-20% ([color=#ff4d6d]artinya 80% s/d 90% damage tusukan Trisula TETAP MENEMBUS PERISAI[/color] dan langsung memotong HP pemain)!\n"
			text += "• [b][color=#ffb3c1]Dampak di Pertempuran:[/color][/b] Aksi [Defend] TIDAK AKAN melindungimu dari tusukan maut Blood Trident. Menangkis hanya membuang 1 giliran berharga secara sia-sia.\n"
			text += "• [b][color=#ffb3c1]Solusi Taktis Pemain:[/color][/b] JANGAN gunakan [Defend]! Lebih baik bertukar pukulan agresif dengan [b][Heavy Attack][/b], dan selalu jaga HP di atas 45% dengan segera meminum [b][Potion][/b] sebelum darahmu kritis terkena tusukan maut.\n"
		elif "scythe" in wep_lower or "flame" in wep_lower or "burn" in boss_weapon_effect.to_lower():
			text += "[b][color=#ff9e00]🔥 PENJELASAN SENJATA BOS: FLAME SCYTHE (INFERNAL BURN DoT)[/color][/b]\n"
			text += "• [b][color=#ffd166]Apa yang dilakukan senjata ini?[/color][/b] Sabit Api Neraka membakar tubuh pemain. Setiap kali Bos berhasil melancarkan [b][Heavy Attack][/b], kamu akan terkena status [color=#ff9e00]Infernal Burn sebesar -5 HP per turn selama 2 ronde berturut-turut[/color]!\n"
			text += "• [b][color=#ffd166]Dampak di Pertempuran:[/b][/color] Kena tebasan sabit berat berarti kamu tidak hanya menerima damage benturan masif (~20-25 HP), tapi juga tambahan -10 HP dari kobaran luka bakar infernal di 2 ronde berikutnya.\n"
			text += "• [b][color=#ffd166]Solusi Taktis Pemain:[/color][/b] Selalu pasang [b][Defend][/b] saat Bos bersiap mengayunkan Heavy Attack untuk memotong 50% damage benturan awal sabit, dan segera pulihkan HP dengan [b][Potion][/b] bila terbakar.\n"
		else:
			# Cursed Blade / Shadow Staff
			text += "[b][color=#c77dff]🔮 PENJELASAN SENJATA BOS: CURSED BLADE (ABYSSAL SOUL DRAIN / 20% LIFESTEAL)[/color][/b]\n"
			text += "• [b][color=#e0aaff]Apa yang dilakukan senjata ini?[/color][/b] Pedang Terkutuk Penguasa Neraka mengisap energi kehidupan pemain. Setiap kali serangan Bos melukaimu, ia [color=#c77dff]menyerap 20% dari damage yang dihasilkan langsung menjadi penyembuhan HP Bos[/color]!\n"
			text += "• [b][color=#e0aaff]Dampak di Pertempuran:[/b][/color] Darah Bos yang sangat tebal akan terus terisi kembali jika kamu terus terkena tebasan pedang tanpa perlindungan, membatalkan progres damage yang sudah kamu buat.\n"
			text += "• [b][color=#e0aaff]Solusi Taktis Pemain:[/color][/b] Pasang [b][Defend][/b] saat Bos melancarkan serangan agar damage masuk berkurang drastis (sehingga HP yang diserap Bos pun sangat kecil), lalu hempaskan [b][Heavy Attack][/b] saat giliranmu untuk melampaui kemampuan regenerasinya!\n"
	else:
		var seal_lower := gate_seal.to_lower()
		if "blood" in seal_lower or "ward" in gate_seal_effect.to_lower() or "kulit" in gate_seal_effect.to_lower():
			text += "[b][color=#ff4d6d]🩸 PENJELASAN PASIF: SEAL OF BLOOD (KULIT IBLIS / PERISAI DARAH FLAT -4 DMG)[/color][/b]\n"
			text += "• [b][color=#ffb3c1]Apa yang dilakukan segel ini?[/color][/b] Segel Darah mengeraskan fisik Penjaga dengan perlindungan iblis (Kulit Iblis). Setiap kali kamu menyerang ([Attack] atau [Heavy Attack]), [color=#ff4d6d]seluruh damage fisik yang masuk langsung dipotong flat 4 poin[/color] ([i]damage = max(1, damage - 4)[/i])!\n"
			text += "• [b][color=#ffb3c1]Dampak di Pertempuran:[/color][/b] Serangan biasa [Attack] dengan damage rendah (misal 8) akan terpangkas separuh menjadi hanya 4 damage! Spam serangan biasa membuat Penjaga tampak sangat kebal dan alot.\n"
			text += "• [b][color=#ffb3c1]Solusi Taktis Pemain:[/color][/b] JANGAN buang stamina dengan spam [Attack] biasa! Andalkan [b][Heavy Attack][/b] (damage dasar ~20) agar damage bersih yang tembus tetap tinggi (~16 damage), dan manfaatkan jeda saat musuh Defend untuk memulihkan diri dengan [b][Potion][/b].\n"
		elif "flame" in seal_lower or "panas" in gate_seal_effect.to_lower() or "burn" in gate_seal_effect.to_lower():
			text += "[b][color=#ff9e00]🔥 PENJELASAN PASIF: SEAL OF FLAME (MEDAN BARA NERAKA / SCORCHED GROUND)[/color][/b]\n"
			text += "• [b][color=#ffd166]Apa yang dilakukan segel ini?[/color][/b] Segel Api memanaskan lantai arena pertarungan menjadi lautan bara. Di setiap akhir ronde, pemain secara otomatis [color=#ff9e00]terkena 3 damage api tak langsung (Scorched Ground)[/color] tanpa mempedulikan posisi Defend!\n"
			text += "• [b][color=#ffd166]Dampak di Pertempuran:[/color][/b] Pertarungan yang berlarut-larut (banyak stalling/menunggu) akan merugikanmu karena HP pemain terus bocor terbakar bara di setiap pergantian giliran.\n"
			text += "• [b][color=#ffd166]Solusi Taktis Pemain:[/color][/b] Mainkan tempo cepat (Blitzkrieg)! Tumbangkan Penjaga secepat mungkin dengan kombo agresif sebelum akumulasi damage bara menghabiskan nyawamu, dan siapkan [b][Potion][/b] bila HP mulai menipis.\n"
		else:
			# Seal of Shadow
			text += "[b][color=#c77dff]🔮 PENJELASAN PASIF: SEAL OF SHADOW (HISAP JIWA / SOUL DRAIN 15%)[/color][/b]\n"
			text += "• [b][color=#e0aaff]Apa yang dilakukan segel ini?[/color][/b] Segel Bayangan menyelubungi Penjaga dengan aura kegelapan. Setiap kali serangannya melukai pemain, ia [color=#c77dff]menyerap 15% dari total damage untuk menyembuhkan HP Penjaga[/color]!\n"
			text += "• [b][color=#e0aaff]Dampak di Pertempuran:[/color][/b] Membiarkan Penjaga leluasa melancarkan serangan berat membuat HP-nya terus terisi kembali dan duel menjadi semakin sulit diselesaikan.\n"
			text += "• [b][color=#e0aaff]Solusi Taktis Pemain:[/color][/b] Pasang [b][Defend][/b] saat musuh bersiap menyerang untuk memperkecil damage masuk (yang secara otomatis memangkas serapan HP lawan), lalu balas dengan [b][Heavy Attack][/b] saat ada celah!\n"

	return text

func _generate_player_tips_bbcode() -> String:
	var strat := enemy_strategy.to_lower()
	var bb := ""

	if enemy_type == "guard":
		bb += "[b][color=#ffaa00]PENJAGA GERBANG[/color][/b] bertipe [color=#00f5d4]%s[/color], bergerak dengan doktrin AI [color=#ffcc00]%s[/color], dan memikul [color=#ff77aa]%s[/color].\n\n" % [
			enemy_name, enemy_strategy, gate_seal
		]
	else:
		bb += "[b][color=#ff4444]PENGUASA TAHTA NERAKA[/color][/b] bertipe [color=#00f5d4]Demon Lord[/color], bergerak dengan doktrin AI [color=#ffcc00]%s[/color], dan menggenggam [color=#ff77aa]%s[/color].\n\n" % [
			enemy_strategy, enemy_weapon
		]

	# 1. Penjelasan Mekanik Pasif Lengkap
	bb += _get_passive_explanation_bbcode()
	bb += "\n"

	# 2. Cara Meng-counter Doktrin AI Lawan
	bb += "[b][color=#00f5d4]🧠 CARA MENG-COUNTER DOKTRIN STRATEGI LAWAN (%s):[/color][/b]\n" % enemy_strategy.to_upper()
	if "aggressive" in strat:
		bb += "• [color=#ffd166]Prioritas Serangan Berat:[/color] Lawan Agresif selalu memprioritaskan pukulan Heavy Attack. Pasang [b][Defend][/b] (kecuali bila musuh memakai Blood Trident) saat musuh bersiap menyerang, lalu balas dengan [b][Heavy Attack][/b] saat musuh jeda kelelahan!\n"
	elif "defensive" in strat:
		bb += "• [color=#ffd166]Eksploitasi Sikap Menangkis:[/color] Musuh sering menangkis & meminum potion. Jangan boros pukulan berat saat lawan sedang Defend; manfaatkan momen pertahanan lawan untuk meminum Potion atau menyusun ritme serangan!\n"
	elif "tactical" in strat:
		bb += "• [color=#ffd166]Kalkulasi Minimax Mendalam:[/color] AI menghitung 3-4 giliran ke depan untuk menghukum blunder pemain. Hindari pola yang monoton dan selalu jaga HP di atas 40% dengan Potion sebelum terkena pukulan telak!\n"
	else:
		bb += "• [color=#ffd166]Ritme Serangan Bebas:[/color] Manfaatkan saat lawan tidak dalam posisi Defend untuk melancarkan serangan terkuatmu!\n"

	return bb
