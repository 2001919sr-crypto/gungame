class_name Item
extends Area2D
## 道中に流れてくるアイテム。触れると取れる。種類と色は config.gd の ITEMS。

signal picked(item: Item)

const FONT := preload("res://assets/fonts/MPLUSRounded1c-Bold.ttf")

var kind := "coin"
var _taken := false
var _t := 0.0


func setup(k: String, pos: Vector2) -> void:
	kind = k
	position = pos


func _process(delta: float) -> void:
	_t += delta
	position.y += Config.SCROLL_SPEED * delta
	if position.y > Config.world_size(self).y + 40.0:
		queue_free()
	queue_redraw()


## プレイヤーが触れた時に呼ばれる
func pick() -> void:
	if _taken:
		return
	_taken = true
	picked.emit(self)
	queue_free()


func _draw() -> void:
	var def: Dictionary = Config.ITEMS[kind]
	var col: Color = def["color"]
	var outline := Color(0.12, 0.12, 0.16)
	var r := Config.ITEM_RADIUS
	var bob := sin(_t * 5.0) * 2.5
	match kind:
		"coin":
			draw_circle(Vector2(0, bob), r * 0.75, outline)
			draw_circle(Vector2(0, bob), r * 0.75 - 3.0, col)
			draw_circle(Vector2(0, bob), r * 0.4, col.darkened(0.2))
		"heart":
			_draw_heart(Vector2(0, bob), r, outline, col)
		_:
			# 横長のカプセルに「威力+1」などの文字
			var w := 84.0
			var h := 36.0
			_draw_capsule(Vector2(0, bob), w + 10.0, h + 10.0, Color(col, 0.25))
			_draw_capsule(Vector2(0, bob), w, h, outline)
			_draw_capsule(Vector2(0, bob), w - 6.0, h - 6.0, col)
			var text: String = def["label"]
			draw_string(FONT, Vector2(-w * 0.5, bob + 6.0), text, HORIZONTAL_ALIGNMENT_CENTER, w, 17, Color.WHITE)


func _draw_capsule(c: Vector2, w: float, h: float, col: Color) -> void:
	var r := h * 0.5
	draw_rect(Rect2(c.x - w * 0.5 + r, c.y - r, w - h, h), col)
	draw_circle(c + Vector2(-w * 0.5 + r, 0), r, col)
	draw_circle(c + Vector2(w * 0.5 - r, 0), r, col)

func _draw_heart(c: Vector2, r: float, outline: Color, col: Color) -> void:
	for pass_i in 2:
		var grow := 3.0 if pass_i == 0 else 0.0
		var cc := outline if pass_i == 0 else col
		var lobe := r * 0.45 + grow
		draw_circle(c + Vector2(-r * 0.38, -r * 0.2), lobe, cc)
		draw_circle(c + Vector2(r * 0.38, -r * 0.2), lobe, cc)
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(-r * 0.8 - grow, -r * 0.05),
			c + Vector2(r * 0.8 + grow, -r * 0.05),
			c + Vector2(0, r * 0.8 + grow),
		]), cc)
