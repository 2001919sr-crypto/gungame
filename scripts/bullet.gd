class_name Bullet
extends Area2D
## 弾。まっすぐ飛び、画面外か射程の限界で消える。
## 当たり判定は Step 2 で敵側とつなぐ。貫通・跳弾は Step 3。

var velocity := Vector2.ZERO
var damage := 10
var pierce := 0
var bounce := 0
var range_px := 0.0
var color := Color.WHITE
var _traveled := 0.0


func setup(wpn: WeaponState, start_pos: Vector2, angle_deg: float) -> void:
	position = start_pos
	velocity = Vector2.UP.rotated(deg_to_rad(angle_deg)) * wpn.bullet_speed
	damage = wpn.damage
	pierce = wpn.pierce
	bounce = wpn.bounce
	range_px = wpn.range_px
	color = wpn.color
	scale = Vector2.ONE * wpn.size


func _physics_process(delta: float) -> void:
	var step := velocity * delta
	position += step
	_traveled += step.length()
	if range_px > 0.0 and _traveled >= range_px:
		queue_free()
		return
	var view := get_viewport_rect().size
	var m := 40.0
	if position.y < -m or position.y > view.y + m or position.x < -m or position.x > view.x + m:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color(0.12, 0.12, 0.16))
	draw_circle(Vector2.ZERO, 5.0, color)
