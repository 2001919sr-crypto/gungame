class_name Enemy
extends Area2D
## 敵。種類（walker / tank / shooter）ごとの数値は config.gd の ENEMIES。
## 下へ進み、弾が当たると体力が減る。0 になると died を出して消える。

signal died(enemy: Enemy)

const ENEMY_BULLET_SCENE := preload("res://scenes/enemy_bullet.tscn")

var type_id := "walker"
var def: Dictionary = {}
var hp := 1
var max_hp := 1
var radius := 22.0
var contact_damage := 20
var dead := false
var bullet_container: Node = null   # 敵の弾を入れる場所（spawner が渡す）

var _flash := 0.0          # 被弾時に白く光る残り時間
var _state := "enter"      # shooter 用: enter → aim → wait → leave
var _timer := 0.0


## hp_mult: 周回で強くなった倍率（中ボスごとに ×1.2、大ボスごとに ×1.5）
func setup(id: String, pos: Vector2, hp_mult: float = 1.0) -> void:
	type_id = id
	def = Config.ENEMIES[id]
	hp = maxi(int(round(def["hp"] * hp_mult)), 1)
	max_hp = hp
	radius = def["radius"]
	contact_damage = def["contact_damage"]
	position = pos


func _ready() -> void:
	# 形は 1 体ごとに作る（共有すると全員の大きさが変わってしまう）
	var shape := CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape
	add_to_group("enemies")


func _process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(_flash - delta, 0.0)
	if type_id == "shooter":
		_shooter_move(delta)
	else:
		position.y += def["speed"] * delta
	if position.y > get_viewport_rect().size.y + radius + 20.0:
		queue_free()   # 下まで抜けた敵は消すだけ（倒した数には入らない）
	queue_redraw()


func _shooter_move(delta: float) -> void:
	match _state:
		"enter":
			position.y += def["speed"] * delta
			if position.y >= def["stop_y"]:
				_state = "aim"
				_timer = 0.0
		"aim":
			_timer += delta
			if _timer >= def["shoot_delay"]:
				_shoot()
				_state = "wait"
				_timer = 0.0
		"wait":
			_timer += delta
			if _timer >= def["after_shot_wait"]:
				_state = "leave"
		"leave":
			position.y += def["speed"] * delta


func _shoot() -> void:
	if bullet_container == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var dir := Vector2.DOWN
	if player:
		dir = (player.global_position - global_position).normalized()
	var b := ENEMY_BULLET_SCENE.instantiate()
	b.setup(global_position + dir * (radius + 6.0), dir * def["bullet_speed"], def["bullet_damage"])
	bullet_container.add_child(b)


func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	_flash = 0.07
	if hp <= 0:
		dead = true
		died.emit(self)
		queue_free()


## プレイヤーにぶつかった時。倒した数には入れずに消える
func crash() -> void:
	if dead:
		return
	dead = true
	queue_free()


func _draw() -> void:
	var body: Color = def.get("color", Color.WHITE)
	if _flash > 0.0:
		body = Color.WHITE
	var outline := Color(0.12, 0.12, 0.16)
	var r := radius
	match type_id:
		"tank":
			# 四角いブロックのおもちゃ
			draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), outline)
			draw_rect(Rect2(-r + 4.0, -r + 4.0, r * 2.0 - 8.0, r * 2.0 - 8.0), body)
			draw_rect(Rect2(-r * 0.5, r * 0.15, r, r * 0.35), outline)
		"shooter":
			# 丸い本体に大きな目。狙っている間は目が赤く光る（予告）
			draw_circle(Vector2.ZERO, r, outline)
			draw_circle(Vector2.ZERO, r - 3.0, body)
			var eye := Color(1.0, 0.2, 0.2) if _state == "aim" else Color.WHITE
			draw_circle(Vector2(0.0, 4.0), r * 0.42, outline)
			draw_circle(Vector2(0.0, 4.0), r * 0.32, eye)
		_:
			# ロボットの頭: 角丸っぽい四角に 2 つの目
			draw_rect(Rect2(-r, -r * 0.85, r * 2.0, r * 1.7), outline)
			draw_rect(Rect2(-r + 3.0, -r * 0.85 + 3.0, r * 2.0 - 6.0, r * 1.7 - 6.0), body)
			draw_circle(Vector2(-r * 0.4, 0.0), 4.0, outline)
			draw_circle(Vector2(r * 0.4, 0.0), 4.0, outline)
	# 体力バー（減っている時だけ）
	if hp < max_hp:
		var w := r * 2.0
		var y := -r - 12.0
		draw_rect(Rect2(-w * 0.5, y, w, 6.0), outline)
		draw_rect(Rect2(-w * 0.5 + 1.0, y + 1.0, (w - 2.0) * float(hp) / float(max_hp), 4.0), Color(0.95, 0.3, 0.3))
