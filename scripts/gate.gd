class_name GatePair
extends Node2D
## 左右 2 枚のゲート。プレイヤーの高さまで流れてきた時、プレイヤーがいる側の効果が決まる。
## 必ずどちらか一方を通る（2 択）。当たり判定は使わず「高さ」と「左右どちら側か」で判断する。

signal passed(kind: String, side: int)   # side: -1 = 左 / +1 = 右

const FONT := preload("res://assets/fonts/MPLUSRounded1c-Bold.ttf")
const GOOD_COLOR := Color(0.3, 0.75, 0.45)
const BAD_COLOR := Color(0.92, 0.32, 0.32)

var left_kind := "count_up"
var right_kind := "pierce"
var _done := false
var _side := 0
var _fade := 0.0


func setup(l: String, r: String, y: float) -> void:
	left_kind = l
	right_kind = r
	position = Vector2(0.0, y)


func _process(delta: float) -> void:
	position.y += Config.SCROLL_SPEED * delta
	if not _done:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player and player.alive and position.y >= player.position.y:
			_done = true
			_side = -1 if player.position.x < Config.SCREEN_W * 0.5 else 1
			passed.emit(left_kind if _side < 0 else right_kind, _side)
	else:
		_fade += delta
		if _fade >= 0.35:
			queue_free()
	if position.y > Config.world_size(self).y + 100.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var half := Config.SCREEN_W * 0.5
	var h := Config.GATE_HEIGHT
	for side in [-1, 1]:
		var kind: String = left_kind if side < 0 else right_kind
		var def: Dictionary = Config.GATES[kind]
		var col: Color = GOOD_COLOR if def["good"] else BAD_COLOR
		var x0 := 6.0 if side < 0 else half + 3.0
		var rect := Rect2(x0, -h * 0.5, half - 9.0, h)
		var alpha := 0.82
		if _done:
			if side == _side:
				col = col.lightened(0.5)
				alpha = 1.0 - _fade / 0.35
			else:
				alpha = 0.82 * (1.0 - _fade / 0.2)
		alpha = clampf(alpha, 0.0, 1.0)
		draw_rect(rect, Color(0.12, 0.12, 0.16, alpha))
		draw_rect(rect.grow(-4.0), Color(col, alpha))
		var text: String = def["label"]
		var lines := text.split("\n")
		var y := -8.0 * float(lines.size() - 1) + 9.0
		for line in lines:
			draw_string(FONT, Vector2(x0, y), line, HORIZONTAL_ALIGNMENT_CENTER, half - 9.0, 24, Color(1, 1, 1, alpha))
			y += 26.0
