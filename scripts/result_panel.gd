extends Control
## リザルト画面（倒れた後に出る）。スコア（進んだ距離）・時間・コイン・倒した数・取ったアイテムなど。
## 押し間違いを防ぐため、出てから少しの間はボタンを押せない。

signal retry_pressed
signal title_pressed

const BUTTON_DELAY := 0.8

var _box: VBoxContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.08, 0.12, 0.82)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_CENTER)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	hide()


## r: game.gd が作る結果のまとめ
func open(r: Dictionary) -> void:
	for c in _box.get_children():
		c.queue_free()
	_buttons.clear()
	_box.add_child(UiKit.make_label("GAME OVER", 40))
	_box.add_child(UiKit.make_label("スコア", 18, Color(1, 1, 1, 0.7)))
	_box.add_child(UiKit.make_label("%s m" % SaveData.format_distance(r["distance"]), 52, Color(1.0, 0.85, 0.3)))
	if r["new_record"]:
		_box.add_child(UiKit.make_label("★ 自己ベスト更新! ★", 24, Color(1.0, 0.6, 0.3)))
	else:
		_box.add_child(UiKit.make_label("自己ベスト  %s m" % SaveData.format_distance(SaveData.best_distance), 18, Color(1, 1, 1, 0.7)))
	_box.add_child(_spacer(8))
	var rows := [
		["到達", r["reach"]],
		["時間", r["time_text"]],
		["コイン", str(r["coins"])],
		["倒した敵", str(r["kills"])],
		["倒したボス", "中ボス %d / 大ボス %d" % [r["mid_kills"], r["big_kills"]]],
	]
	for row in rows:
		_box.add_child(_row(row[0], row[1]))
	_box.add_child(_spacer(6))
	_box.add_child(UiKit.make_label("取ったアイテム", 18, Color(1, 1, 1, 0.7)))
	var items: Dictionary = r["items"]
	var parts := []
	for label in items:
		parts.append("%s ×%d" % [label, items[label]])
	var item_label := UiKit.make_label("なし" if parts.is_empty() else _wrap(parts, 3), 18)
	_box.add_child(item_label)
	var rewards: Array = r["rewards"]
	if not rewards.is_empty():
		_box.add_child(_spacer(4))
		_box.add_child(UiKit.make_label("ボスのご褒美", 18, Color(1, 1, 1, 0.7)))
		_box.add_child(UiKit.make_label(_wrap(rewards, 3), 18, Color(1.0, 0.85, 0.3)))
	_box.add_child(_spacer(14))
	var retry := UiKit.make_button("もう一度", Color(1.0, 0.55, 0.15), func() -> void: retry_pressed.emit())
	var title := UiKit.make_button("タイトルへ", Color(0.55, 0.55, 0.6), func() -> void: title_pressed.emit(), Vector2(280, 60), 24)
	for b in [retry, title]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.disabled = true
		_buttons.append(b)
		_box.add_child(b)
	show()
	await get_tree().create_timer(BUTTON_DELAY, true).timeout
	for b in _buttons:
		if is_instance_valid(b):
			b.disabled = false


## 「到達　2 周目 中ボス 1」のような左右 2 列の行
func _row(key: String, value: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var k := UiKit.make_label(key, 20, Color(1, 1, 1, 0.75))
	k.custom_minimum_size = Vector2(140, 0)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var v := UiKit.make_label(value, 22)
	v.custom_minimum_size = Vector2(250, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h.add_theme_constant_override("separation", 18)
	h.add_child(k)
	h.add_child(v)
	return h


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## 「威力+1 ×5」などを 1 行 per_line 個ずつに並べる
func _wrap(parts: Array, per_line: int) -> String:
	var lines := []
	for i in range(0, parts.size(), per_line):
		lines.append("   ".join(parts.slice(i, i + per_line)))
	return "\n".join(lines)
