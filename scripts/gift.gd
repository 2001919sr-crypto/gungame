class_name Gift
extends Area2D
## ランの最初に落ちてくる箱。取ると「銃を選ぶ画面」が出る。
## 取り逃さないように、プレイヤーの列へゆっくり寄っていく。

signal picked

var _taken := false
var _t := 0.0


func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	position.y += Config.GIFT_FALL_SPEED * delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		position.x = lerpf(position.x, player.position.x, minf(delta * 2.5, 1.0))
	if position.y > get_viewport_rect().size.y + 40.0:
		position.y = -40.0   # もし取り逃しても、もう一度上から落ちてくる
	queue_redraw()


## プレイヤーが触れた時に呼ばれる
func pick() -> void:
	if _taken:
		return
	_taken = true
	picked.emit()
	queue_free()


func _draw() -> void:
	var r := Config.GIFT_RADIUS
	var bob := sin(_t * 6.0) * 3.0
	var outline := Color(0.12, 0.12, 0.16)
	# プレゼント箱: 赤い箱に黄色いリボン、ふわふわ光る
	draw_circle(Vector2(0, bob), r + 10.0, Color(1.0, 0.95, 0.5, 0.25 + 0.15 * sin(_t * 8.0)))
	draw_rect(Rect2(-r, -r + bob, r * 2.0, r * 2.0), outline)
	draw_rect(Rect2(-r + 3.0, -r + 3.0 + bob, r * 2.0 - 6.0, r * 2.0 - 6.0), Color(0.95, 0.3, 0.35))
	draw_rect(Rect2(-5.0, -r + 3.0 + bob, 10.0, r * 2.0 - 6.0), Color(1.0, 0.85, 0.2))
	draw_rect(Rect2(-r + 3.0, -5.0 + bob, r * 2.0 - 6.0, 10.0), Color(1.0, 0.85, 0.2))
