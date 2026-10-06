extends Control
## 「銃を選んでください」の 3 択画面（本家の「賞を選んでください」に相当）。
## ゲームを一時停止した状態で出し、カードを押すと chosen を出して閉じる。
## 後でボス撃破後の強化選びにも使い回せるよう、カードの中身は外から渡す形にしている。

signal chosen(id: String)

const CARD_SIZE := Vector2(156, 300)

var _cards: HBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # 一時停止中でも押せるように
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.08, 0.12, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(box)

	var title := Label.new()
	title.text = "銃を選んでください"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(title)

	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 12)
	box.add_child(_cards)

	var note := Label.new()
	note.text = "※ ゲーム中は交換できません"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	box.add_child(note)

	hide()


## ids の順にカードを並べて表示する
func open(ids: Array) -> void:
	for c in _cards.get_children():
		c.queue_free()
	for id in ids:
		_cards.add_child(_make_card(id))
	show()


func _make_card(id: String) -> Button:
	var def: Dictionary = Config.GUNS[id]
	var btn := Button.new()
	btn.custom_minimum_size = CARD_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.98, 0.93, 0.8)
	normal.border_color = Color(0.12, 0.12, 0.16)
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(16)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.97, 0.88)
	hover.border_color = Color(1.0, 0.55, 0.15)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.pressed.connect(func() -> void: _choose(id))

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 14
	v.offset_bottom = -10
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(v)

	var icon := GunIcon.new()
	icon.def = def
	icon.custom_minimum_size = Vector2(0, 110)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)

	var name_label := Label.new()
	name_label.text = def["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_label)

	var desc := Label.new()
	desc.text = def["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.38))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(desc)
	return btn


func _choose(id: String) -> void:
	hide()
	chosen.emit(id)


## カードの上の銃の絵（仮。図形で描く。デザインは後で差し替え）
class GunIcon:
	extends Control
	var def: Dictionary = {}

	func _draw() -> void:
		var c := size * 0.5
		var outline := Color(0.12, 0.12, 0.16)
		var barrels: Array = def.get("barrels", [0.0])
		var colors: Array = def.get("colors", [Color.WHITE])
		var gap := 46.0
		for i in barrels.size():
			var x := c.x + (float(i) - float(barrels.size() - 1) * 0.5) * gap
			var col: Color = colors[i % colors.size()]
			# 銃身と持ち手
			draw_rect(Rect2(x - 12, c.y - 40, 24, 56), outline)
			draw_rect(Rect2(x - 9, c.y - 37, 18, 50), col)
			draw_rect(Rect2(x - 4, c.y + 16, 22, 28), outline)
			draw_rect(Rect2(x - 1, c.y + 19, 16, 22), col.darkened(0.25))
		# ショットガンは扇の線
		if def.get("spread_deg", 0.0) > 0.0:
			for a in [-15.0, 0.0, 15.0]:
				var d := Vector2.UP.rotated(deg_to_rad(a))
				draw_line(c + Vector2(0, -44) + d * 6, c + Vector2(0, -44) + d * 18, outline, 3.0)
