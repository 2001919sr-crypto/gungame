class_name UiKit
extends RefCounted
## 画面づくりの共通部品（大きな角丸ボタンなど）。タイトル・一時停止・リザルトで使う。


static func make_button(text: String, col: Color, on_press: Callable, min_size := Vector2(280, 72), font_size := 28) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(key, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
	var normal := StyleBoxFlat.new()
	normal.bg_color = col
	normal.border_color = Color(0.12, 0.12, 0.16)
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(18)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = col.lightened(0.15)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = col.darkened(0.3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", disabled)
	b.pressed.connect(on_press)
	return b


static func make_label(text: String, font_size: int, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	return l
