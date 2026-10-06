class_name Player
extends Node2D
## プレイヤー。左右に動き、持っている銃を自動で撃つ。
## 銃は「弾のパラメータの組」（WeaponState）の一覧。二丁拳銃なら 2 つ入る。
## 敵や敵の弾に当たると体力が減り、少しの間だけ無敵になる。

signal hp_changed(hp: int, max_hp: int)
signal died

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

var gun_id := ""   # 最初は銃なし。最初のアイテムで決まり、その後は変えられない
var weapons: Array[WeaponState] = []
var bullet_container: Node = null   # 弾を入れる場所（game.gd が渡す）
var max_hp: int = Config.PLAYER_MAX_HP
var hp: int = Config.PLAYER_MAX_HP
var alive := true
var _invincible := 0.0


func _ready() -> void:
	add_to_group("player")
	var shape := CircleShape2D.new()
	shape.radius = Config.PLAYER_HIT_RADIUS
	$Hurtbox/CollisionShape2D.shape = shape
	$Hurtbox.area_entered.connect(_on_hurtbox_area_entered)


## 銃を決める（ランの最初に 1 回だけ呼ばれる）
func set_gun(id: String) -> void:
	gun_id = id
	weapons.clear()
	var def: Dictionary = Config.GUNS[id]
	for i in def["barrels"].size():
		weapons.append(WeaponState.from_gun(def, i))
	queue_redraw()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not alive:
		return
	if area is Enemy:
		if area.dead:
			return
		var dmg: int = area.contact_damage
		area.crash()   # ぶつかった敵は壊れる
		take_damage(dmg)
	elif area is EnemyBullet:
		var dmg: int = area.damage
		area.queue_free()
		take_damage(dmg)
	elif area.has_method("pick"):
		area.pick()   # アイテム


func take_damage(amount: int) -> void:
	if not alive or _invincible > 0.0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		alive = false
		modulate.a = 1.0
		$Hurtbox.set_deferred("monitoring", false)
		queue_redraw()
		died.emit()
	else:
		_invincible = Config.PLAYER_INVINCIBLE_TIME


func _process(delta: float) -> void:
	if not alive:
		return
	if _invincible > 0.0:
		_invincible -= delta
		# 無敵の間は点滅させる
		modulate.a = 0.35 if fmod(_invincible, 0.16) < 0.08 else 1.0
		if _invincible <= 0.0:
			modulate.a = 1.0
	_move(delta)
	_auto_fire(delta)


func _move(delta: float) -> void:
	var dir := GameInput.get_move_dir()
	var view := Config.world_size(self)
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
	var body := Color(1.0, 0.55, 0.15) if alive else Color(0.55, 0.55, 0.55)
	draw_circle(Vector2.ZERO, 24.0, Color(0.12, 0.12, 0.16))
	draw_circle(Vector2.ZERO, 20.0, body)
	draw_circle(Vector2(-6.0, -4.0), 4.0, Color(1.0, 1.0, 1.0, 0.8))
	for wpn in weapons:
		var r := Rect2(wpn.offset_x - 6.0, -44.0, 12.0, 26.0)
		draw_rect(r, Color(0.12, 0.12, 0.16))
		draw_rect(r.grow(-2.5), wpn.color)
