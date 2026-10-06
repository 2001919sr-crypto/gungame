class_name Bullet
extends Area2D
## 弾。まっすぐ飛び、画面外か射程の限界で消える。
## 敵に当たるとダメージを与えて消える。貫通（pierce）が残っていれば突き抜ける。跳弾は Step 3。

var velocity := Vector2.ZERO
var damage := 10
var pierce := 0
var bounce := 0
var range_px := 0.0
var color := Color.WHITE
var _traveled := 0.0
var _spent := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func setup(wpn: WeaponState, start_pos: Vector2, angle_deg: float) -> void:
	position = start_pos
	velocity = Vector2.UP.rotated(deg_to_rad(angle_deg)) * wpn.bullet_speed
	damage = wpn.damage
	pierce = wpn.pierce
	bounce = wpn.bounce
	range_px = wpn.range_px
	color = wpn.color
	scale = Vector2.ONE * wpn.size


func _on_area_entered(area: Area2D) -> void:
	if _spent:
		return
	if area is Enemy and not area.dead:
		area.take_damage(damage)
		if pierce > 0:
			pierce -= 1
		else:
			_spent = true
			queue_free()


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
