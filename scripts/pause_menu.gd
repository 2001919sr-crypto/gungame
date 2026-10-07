extends Control
## 一時停止メニュー。再開 / 倍速 / リトライ / タイトルへ。
## ゲームを一時停止した状態で出す。倍速は Engine.time_scale を変えるだけ（敵も弾もゲートも一緒に速くなる）。
## 倍速は Step 5 のショップでコインによる解放制にする予定。今は誰でも使える。

signal resume_pressed
signal retry_pressed
signal quit_pressed
signal speed_changed(speed: float)

var _speed_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # 一時停止中でも押せるように
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.08, 0.12, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	var title := Label.new()
	title.text = "一時停止"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(title)

	box.add_child(_make_button("再開", Color(0.3, 0.75, 0.45), func() -> void: resume_pressed.emit()))
	_speed_button = _make_button("", Color(0.3, 0.6, 1.0), _cycle_speed)
	box.add_child(_speed_button)
	box.add_child(_make_button("リトライ", Color(1.0, 0.55, 0.15), func() -> void: retry_pressed.emit()))
	box.add_child(_make_button("タイトルへ", Color(0.55, 0.55, 0.6), func() -> void: quit_pressed.emit()))
	_update_speed_label()
	hide()


func open() -> void:
	_update_speed_label()
	show()


func _make_button(text: String, col: Color, on_press: Callable) -> Button:
	return UiKit.make_button(text, col, on_press)


func _cycle_speed() -> void:
	var steps: Array = Config.SPEED_STEPS
	var i := steps.find(Engine.time_scale)
	var next: float = steps[(i + 1) % steps.size()] if i >= 0 else steps[0]
	Engine.time_scale = next
	_update_speed_label()
	speed_changed.emit(next)


func _update_speed_label() -> void:
	_speed_button.text = "倍速  ×%s" % _speed_text(Engine.time_scale)


static func _speed_text(s: float) -> String:
	return str(int(s)) if is_equal_approx(s, roundf(s)) else "%.1f" % s
