class_name Bullet
extends Area2D
## 弾。まっすぐ飛び、射程（range_px）の距離まで進むと消える。
## 画面の外でも飛び続けるので、射程が長ければ画面の上の外にいる敵にも当たる。
## 敵に当たると: 貫通が残っていれば突き抜ける → 跳弾が残っていれば近くの敵へ跳ねる → どちらもなければ消える

var velocity := Vector2.ZERO
var damage := 10
var pierce := 0
var bounce := 0
var range_px := 560.0
var color := Color.WHITE
var _traveled := 0.0
var _spent := false
var _last_hit: Enemy = null


func _ready() -> void:
	area_entered.connect(_on_area_entered)


## dmg と size_mult は「あふれた弾を威力に変えた」後の値（player.gd が計算する）
func setup(wpn: WeaponState, start_pos: Vector2, angle_deg: float, dmg: int, size_mult: float = 1.0) -> void:
	position = start_pos
	velocity = Vector2.UP.rotated(deg_to_rad(angle_deg)) * wpn.bullet_speed
	damage = dmg
	pierce = wpn.pierce
	bounce = wpn.bounce
	range_px = wpn.range_px
	color = wpn.color
	scale = Vector2.ONE * wpn.size * size_mult


func _on_area_entered(area: Area2D) -> void:
	if _spent:
		return
	if not (area is Enemy) or area.dead or area == _last_hit:
		return
	area.take_damage(damage)
	_last_hit = area
	if pierce > 0:
		pierce -= 1
	elif bounce > 0:
		bounce -= 1
		var target := _nearest_enemy(area)
		if target:
			velocity = (target.global_position - global_position).normalized() * velocity.length()
			_traveled = maxf(_traveled - Config.BOUNCE_RANGE_BONUS, 0.0)
		else:
			_finish()
	else:
		_finish()


func _nearest_enemy(exclude: Enemy) -> Enemy:
	var best: Enemy = null
	var best_d := Config.BOUNCE_SEARCH_RADIUS
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == exclude or e.dead:
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _finish() -> void:
	_spent = true
	queue_free()


func _physics_process(delta: float) -> void:
	var step := velocity * delta
	position += step
	_traveled += step.length()
	if _traveled >= range_px:
		queue_free()
		return
	# 射程の終わりが近づくと薄くなる（どこまで届くかが目で分かる）
	var left := range_px - _traveled
	modulate.a = clampf(left / 120.0, 0.25, 1.0)
	# 念のための安全柵（横に飛び出した弾など）
	var view := Config.world_size(self)
	if position.x < -60.0 or position.x > view.x + 60.0 or position.y > view.y + 60.0 \
			or position.y < -Config.SPAWN_AHEAD - 200.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color(0.12, 0.12, 0.16))
	draw_circle(Vector2.ZERO, 5.0, color)
