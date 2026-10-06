class_name EnemyBullet
extends Area2D
## 敵の弾。撃ち落とせない（設計の決定）。避けるしかない。

var velocity := Vector2.ZERO
var damage := 15


func setup(pos: Vector2, vel: Vector2, dmg: int) -> void:
	position = pos
	velocity = vel
	damage = dmg


func _physics_process(delta: float) -> void:
	position += velocity * delta
	var view := get_viewport_rect().size
	var m := 30.0
	if position.y < -m or position.y > view.y + m or position.x < -m or position.x > view.x + m:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(0.12, 0.12, 0.16))
	draw_circle(Vector2.ZERO, 6.5, Color(0.95, 0.25, 0.3))
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color(1, 1, 1, 0.8))
