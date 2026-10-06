extends Node2D
## 流れる背景。横線が下に流れて「前に進んでいる」感じを出す。
## 真ん中の薄い縦線は、左右タップの境目の目印。

const GAP := 90.0
var _offset := 0.0


func _process(delta: float) -> void:
	_offset = fmod(_offset + Config.SCROLL_SPEED * delta, GAP)
	queue_redraw()


func _draw() -> void:
	var view := Config.world_size(self)
	# 画面が横に広い時の左右の余白は少し暗く塗る
	draw_rect(Rect2(-2000.0, 0.0, 4000.0 + view.x, view.y), Color(0.85, 0.83, 0.78))
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.96, 0.94, 0.88))
	var y := _offset - GAP
	while y < view.y:
		draw_line(Vector2(0.0, y), Vector2(view.x, y), Color(0.3, 0.3, 0.4, 0.10), 3.0)
		y += GAP
	draw_line(Vector2(view.x * 0.5, 0.0), Vector2(view.x * 0.5, view.y), Color(0.3, 0.3, 0.4, 0.12), 2.0)
