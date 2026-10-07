class_name Enemy
extends Area2D
## 敵。種類（walker / tank / shooter）ごとの数値は config.gd の ENEMIES。
## 列（180px）いっぱいの四角。下へ進み、弾が当たると体力が減る。0 になると died を出して消える。
## 実際に削った体力はプレイヤーに知らせる（吸収で回復するため）。

signal died(enemy: Enemy)

const ENEMY_BULLET_SCENE := preload("res://scenes/enemy_bullet.tscn")

var type_id := "walker"
var def: Dictionary = {}
var hp := 1
var max_hp := 1
var half := Vector2(75, 32)   # 当たり判定の四角の半分の大きさ
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
	half = def["size"] * 0.5
	contact_damage = def["contact_damage"]
	position = pos


func _ready() -> void:
	# 形は 1 体ごとに作る（共有すると全員の大きさが変わってしまう）
	var shape := RectangleShape2D.new()
	shape.size = half * 2.0
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
	if position.y > get_viewport_rect().size.y + half.y + 20.0:
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
	b.setup(global_position + dir * (half.y + 6.0), dir * def["bullet_speed"], def["bullet_damage"])
	bullet_container.add_child(b)


func take_damage(amount: int) -> void:
	if dead:
		return
	# とどめの一撃で余った分は数えない（吸収で体力が増えすぎないように）
	var dealt := mini(amount, hp)
	hp -= amount
	_flash = 0.07
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.absorb(dealt)
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
	var w := half.x
	var h := half.y
	match type_id:
		"tank":
			# 四角いブロックのおもちゃ。キャタピラ付き
			draw_rect(Rect2(-w, -h, w * 2.0, h * 2.0), outline)
			draw_rect(Rect2(-w + 5.0, -h + 5.0, w * 2.0 - 10.0, h * 2.0 - 10.0), body)
			draw_rect(Rect2(-w + 5.0, h - 26.0, w * 2.0 - 10.0, 21.0), body.darkened(0.3))
			for i in 6:
				draw_circle(Vector2(-w + 20.0 + i * (w * 2.0 - 40.0) / 5.0, h - 15.0), 6.0, outline)
			draw_rect(Rect2(-w * 0.4, -h * 0.35, w * 0.8, h * 0.4), outline)
		"shooter":
			# 横長の砲台。狙っている間は目が赤く光る（予告）
			draw_rect(Rect2(-w, -h, w * 2.0, h * 2.0), outline)
			draw_rect(Rect2(-w + 4.0, -h + 4.0, w * 2.0 - 8.0, h * 2.0 - 8.0), body)
			var eye := Color(1.0, 0.2, 0.2) if _state == "aim" else Color.WHITE
			draw_circle(Vector2(0.0, 0.0), h * 0.55, outline)
			draw_circle(Vector2(0.0, 0.0), h * 0.42, eye)
			draw_rect(Rect2(-6.0, h - 4.0, 12.0, 14.0), outline)
		_:
			# ロボットの頭: 横長の四角に 2 つの目
			draw_rect(Rect2(-w, -h, w * 2.0, h * 2.0), outline)
			draw_rect(Rect2(-w + 4.0, -h + 4.0, w * 2.0 - 8.0, h * 2.0 - 8.0), body)
			draw_circle(Vector2(-w * 0.35, -2.0), 8.0, outline)
			draw_circle(Vector2(w * 0.35, -2.0), 8.0, outline)
			draw_rect(Rect2(-w * 0.2, h * 0.35, w * 0.4, 6.0), outline)
	# 体力バー（減っている時だけ）
	if hp < max_hp:
		var bw := w * 1.6
		var y := -h - 12.0
		draw_rect(Rect2(-bw * 0.5, y, bw, 7.0), outline)
		draw_rect(Rect2(-bw * 0.5 + 1.0, y + 1.0, (bw - 2.0) * float(hp) / float(max_hp), 5.0), Color(0.95, 0.3, 0.3))
