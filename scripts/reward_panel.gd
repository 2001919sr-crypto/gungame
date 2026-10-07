extends Control
## 3 択画面（本家の「賞を選んでください」に相当）。銃選びとボスのご褒美の両方で使う。
## ゲームを一時停止した状態で出し、カードを押すと chosen を出して閉じる。
## カード 1 枚 = {id, name, desc, color, badge（大きな文字）} か {id, gun（銃の定義）}

signal chosen(id: String)

const CARD_SIZE := Vector2(156, 300)

var _cards: HBoxContainer
var _title: Label
var _note: Label


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

	_title = UiKit.make_label("", 32)
	box.add_child(_title)

	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 12)
	box.add_child(_cards)

	_note = UiKit.make_label("", 16, Color(1, 1, 1, 0.8))
	box.add_child(_note)

	hide()


## 銃を選ぶ画面（ランの最初）
func open_guns(ids: Array) -> void:
	var cards := []
	for id in ids:
		var def: Dictionary = Config.GUNS[id]
		cards.append({"id": id, "name": def["name"], "desc": def["desc"], "gun": def})
	open("銃を選んでください", "※ ゲーム中は交換できません", cards)


## cards の順にカードを並べて表示する
func open(title: String, note: String, cards: Array) -> void:
	_title.text = title
	_note.text = note
	for c in _cards.get_children():
		c.queue_free()
	for card in cards:
		_cards.add_child(_make_card(card))
	show()


func _make_card(card: Dictionary) -> Button:
	var id: String = card["id"]
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

	var icon: Control
	if card.has("gun"):
		var gun_icon := GunIcon.new()
		gun_icon.def = card["gun"]
		icon = gun_icon
	else:
		var badge := BadgeIcon.new()
		badge.text = card["badge"]
		badge.color = card["color"]
		icon = badge
	icon.custom_minimum_size = Vector2(0, 110)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)

	var name_label := Label.new()
	name_label.text = card["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_label)

	var desc := Label.new()
	desc.text = card["desc"]
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
			# 銃身と持ち手（スナイパーは細長い銃身とスコープ）
			if def.get("long_barrel", false):
				draw_rect(Rect2(x - 8, c.y - 52, 16, 68), outline)
				draw_rect(Rect2(x - 5, c.y - 49, 10, 62), col)
				draw_rect(Rect2(x + 8, c.y - 22, 14, 22), outline)
				draw_circle(Vector2(x + 15, c.y - 26), 7.0, outline)
			else:
				draw_rect(Rect2(x - 12, c.y - 40, 24, 56), outline)
				draw_rect(Rect2(x - 9, c.y - 37, 18, 50), col)
			draw_rect(Rect2(x - 4, c.y + 16, 22, 28), outline)
			draw_rect(Rect2(x - 1, c.y + 19, 16, 22), col.darkened(0.25))
		# ショットガンは扇の線
		if def.get("spread_deg", 0.0) > 0.0:
			for a in [-15.0, 0.0, 15.0]:
				var d := Vector2.UP.rotated(deg_to_rad(a))
				draw_line(c + Vector2(0, -44) + d * 6, c + Vector2(0, -44) + d * 18, outline, 3.0)


## ご褒美カードの絵: 色つきの丸に「+10」「×2」などの大きな文字
class BadgeIcon:
	extends Control
	const FONT := preload("res://assets/fonts/MPLUSRounded1c-Bold.ttf")
	var text := ""
	var color := Color.WHITE

	func _draw() -> void:
		var c := size * 0.5
		var outline := Color(0.12, 0.12, 0.16)
		draw_circle(c, 50.0, outline)
		draw_circle(c, 45.0, color)
		draw_circle(c + Vector2(-16, -18), 9.0, Color(1, 1, 1, 0.5))
		var fs := 40 if text.length() <= 2 else 34
		var p := Vector2(0.0, c.y + fs * 0.36)
		draw_string_outline(FONT, p, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 8, outline)
		draw_string(FONT, p, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color.WHITE)
