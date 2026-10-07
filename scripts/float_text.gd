class_name FloatText
extends Node2D
## ふわっと浮かんで消える文字（「威力+1」「撃破!」など）。

const FONT := preload("res://assets/fonts/MPLUSRounded1c-Bold.ttf")
var life := 0.9
var text := ""
var color := Color.WHITE
var font_size := 22
var _t := 0.0


static func spawn(parent: Node, pos: Vector2, txt: String, col: Color, size: int = 22, life_sec: float = 0.9) -> void:
	var f := FloatText.new()
	f.life = life_sec
	f.text = txt
	f.color = col
	f.font_size = size
	f.position = pos
	parent.add_child(f)


func _process(delta: float) -> void:
	_t += delta
	position.y -= 50.0 * delta
	modulate.a = clampf((life - _t) / 0.4, 0.0, 1.0)
	if _t >= life:
		queue_free()


func _draw() -> void:
	# 改行で複数行にできる
	var y := 0.0
	for line in text.split("\n"):
		var p := Vector2(-260, y)
		draw_string_outline(FONT, p, line, HORIZONTAL_ALIGNMENT_CENTER, 520, font_size, 6, Color(0.12, 0.12, 0.16))
		draw_string(FONT, p, line, HORIZONTAL_ALIGNMENT_CENTER, 520, font_size, color)
		y += font_size * 1.25
