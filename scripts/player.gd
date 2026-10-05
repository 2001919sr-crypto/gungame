class_name Player
extends Node2D
## プレイヤー。左右に動き、持っている銃を自動で撃つ。
## 銃は「弾のパラメータの組」（WeaponState）の一覧。二丁拳銃なら 2 つ入る。

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

var gun_id := "handgun"
var weapons: Array[WeaponState] = []
var bullet_container: Node = null   # 弾を入れる場所（game.gd が渡す）


func _ready() -> void:
	set_gun(gun_id)


## 銃を持ち替える（タイトル画面ができるまでは 1/2/3 キーで切り替え）
func set_gun(id: String) -> void:
	gun_id = id
	weapons.clear()
	var def: Dictionary = Config.GUNS[id]
	for i in def["barrels"].size():
		weapons.append(WeaponState.from_gun(def, i))
	queue_redraw()


func _process(delta: float) -> void:
	_move(delta)
	_auto_fire(delta)


func _move(delta: float) -> void:
	var dir := GameInput.get_move_dir()
	var view := get_viewport_rect().size
	position.x += dir * Config.PLAYER_SPEED * delta
	position.x = clampf(position.x, Config.PLAYER_HALF_W, view.x - Config.PLAYER_HALF_W)
	position.y = view.y - Config.PLAYER_BOTTOM_MARGIN


func _auto_fire(delta: float) -> void:
	for wpn in weapons:
		wpn.cooldown -= delta
		if wpn.cooldown <= 0.0:
			wpn.cooldown += 1.0 / wpn.fire_rate
			_fire(wpn)


func _fire(wpn: WeaponState) -> void:
	if bullet_container == null:
		return
	if bullet_container.get_child_count() >= Config.MAX_BULLETS:
		return
	var n := wpn.count
	for i in n:
		var angle_deg := 0.0
		var x_off := 0.0
		if wpn.spread_deg > 0.0 and n > 1:
			# 扇状: -spread/2 〜 +spread/2 に均等に並べる
			angle_deg = -wpn.spread_deg * 0.5 + wpn.spread_deg * float(i) / float(n - 1)
		else:
			# 平行: 中心をそろえて横に並べる
			x_off = (float(i) - float(n - 1) * 0.5) * Config.BULLET_SPACING
		var bullet := BULLET_SCENE.instantiate()
		var start := position + Vector2(wpn.offset_x + x_off, Config.MUZZLE_Y)
		bullet.setup(wpn, start, angle_deg)
		bullet_container.add_child(bullet)


func _draw() -> void:
	# おもちゃ風: 丸い本体と、銃ごとの銃口。絵は後で差し替える
	draw_circle(Vector2.ZERO, 24.0, Color(0.12, 0.12, 0.16))
	draw_circle(Vector2.ZERO, 20.0, Color(1.0, 0.55, 0.15))
	draw_circle(Vector2(-6.0, -4.0), 4.0, Color(1.0, 1.0, 1.0, 0.8))
	for wpn in weapons:
		var r := Rect2(wpn.offset_x - 6.0, -44.0, 12.0, 26.0)
		draw_rect(r, Color(0.12, 0.12, 0.16))
		draw_rect(r.grow(-2.5), wpn.color)
