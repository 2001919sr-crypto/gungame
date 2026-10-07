class_name Boss
extends Enemy
## 中ボスと大ボス。数値は config.gd の BOSSES。
## 敵（Enemy）の仲間として作っているので、弾の当たり方・跳弾・貫通はふつうの敵と同じ仕組みで動く。
## 中ボス: 列から列へ動き、止まるとプレイヤーへ 3 発ずつ狙い撃ち（撃つ前に目が赤く光る）
## 大ボス: 第 1 段階は左右に揺れながら扇形にばらまく。体力 50% 以下で赤くなり、ゆっくり迫ってくる

signal enraged                # 大ボスが第 2 段階になった
signal crushed(pos: Vector2)  # 大ボスがプレイヤーの所まで迫った

const FONT := preload("res://assets/fonts/MPLUSRounded1c-Bold.ttf")

var kind := "mid"
var phase := 1
var half := Vector2(65, 42)
var _mode := "enter"        # enter（降りてくる）→ fight
var _t := 0.0
var _shot_cd := 1.2
var _burst_left := 0
var _burst_cd := 0.0
var _target_x := Config.SCREEN_W * 0.5
var _move_wait := 0.0


func setup_boss(k: String, hp_mult: float) -> void:
	kind = k
	type_id = "boss_" + k
	def = Config.BOSSES[k]
	hp = maxi(int(round(def["hp"] * hp_mult)), 1)
	max_hp = hp
	half = def["size"] * 0.5
	radius = half.x
	contact_damage = def["contact_damage"]
	position = Vector2(Config.SCREEN_W * 0.5, -half.y - 20.0)


func _ready() -> void:
	# ボスは横長なので四角の当たり判定。設定は enemy.tscn と同じ（敵のレイヤー）
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	var shape := RectangleShape2D.new()
	shape.size = def["size"]
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	add_to_group("enemies")


func _process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(_flash - delta, 0.0)
	_t += delta
	var player := get_tree().get_first_node_in_group("player") as Player
	var hover := _hover_y(player)
	if _mode == "enter":
		position.y += Config.BOSS_ENTER_SPEED * delta
		if position.y >= hover:
			_mode = "fight"
	elif kind == "big" and phase == 2:
		_charge(delta, player, hover)
	else:
		position.y = move_toward(position.y, hover, 80.0 * delta)
	if _mode == "fight":
		if kind == "mid":
			_mid_move(delta)
		else:
			position.x = Config.SCREEN_W * 0.5 + sin(_t * def["sway_speed"]) * def["sway"]
		_attack(delta, player)
	queue_redraw()


## 居座る高さ。射程が短い銃でも届くよう、プレイヤーの射程に合わせて下がってくる
func _hover_y(player: Player) -> float:
	var y: float = def["hover_y"]
	if player and player.weapons.size() > 0:
		var reach := player.position.y + Config.MUZZLE_Y - player.max_range()
		y = maxf(y, reach + 50.0 - half.y)
	return minf(y, Config.BOSS_MAX_Y)


## 大ボスの第 2 段階: ゆっくり下に迫る。プレイヤーの所まで来たら大ダメージを与えて上に戻る
func _charge(delta: float, player: Player, hover: float) -> void:
	position.y += def["charge_speed"] * delta
	if player and position.y + half.y >= player.position.y - 40.0:
		player.take_damage(def["crush_damage"])
		crushed.emit(player.position)
		position.y = hover


## 中ボス: 列（左・中央・右）から列へ動く。撃っている間は止まる
func _mid_move(delta: float) -> void:
	if _burst_left > 0 or _shot_cd < def["aim_time"]:
		return
	if absf(position.x - _target_x) > 1.0:
		position.x = move_toward(position.x, _target_x, def["move_speed"] * delta)
		return
	_move_wait -= delta
	if _move_wait <= 0.0:
		var lanes: Array = Config.LANES.duplicate()
		lanes.shuffle()
		for lane in lanes:
			var x: float = Config.SCREEN_W * lane
			if absf(x - position.x) > 1.0:
				_target_x = x
				break
		_move_wait = 0.6


func _attack(delta: float, player: Player) -> void:
	if _burst_left > 0:
		_burst_cd -= delta
		if _burst_cd <= 0.0:
			_burst_cd = def["burst_gap"]
			_burst_left -= 1
			_shoot_at(player)
		return
	_shot_cd -= delta
	if _shot_cd > 0.0:
		return
	if kind == "mid":
		_shot_cd = def["fire_interval"]
		_burst_left = def["burst"]
		_burst_cd = 0.0
	else:
		var rage := phase == 2
		_shot_cd = def["rage_fire_interval"] if rage else def["fire_interval"]
		_shoot_fan(def["rage_fan"] if rage else def["fan"])


func _shoot_at(player: Player) -> void:
	var dir := Vector2.DOWN
	if player:
		dir = (player.global_position - global_position).normalized()
	_spawn_bullet(dir)


## 真下を中心に扇形にばらまく
func _shoot_fan(n: int) -> void:
	var spread: float = def["fan_deg"]
	for i in n:
		var a := -spread * 0.5 + spread * float(i) / float(maxi(n - 1, 1))
		_spawn_bullet(Vector2.DOWN.rotated(deg_to_rad(a)))


func _spawn_bullet(dir: Vector2) -> void:
	if bullet_container == null:
		return
	var b := ENEMY_BULLET_SCENE.instantiate()
	b.setup(global_position + Vector2(0.0, half.y * 0.6) + dir * 10.0, dir * def["bullet_speed"], def["bullet_damage"])
	bullet_container.add_child(b)


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	if not dead and kind == "big" and phase == 1 and hp * 2 <= max_hp:
		phase = 2
		enraged.emit()


## ボスはぶつかっても壊れない（プレイヤーだけダメージを受ける）
func crash() -> void:
	pass


func _draw() -> void:
	var outline := Color(0.12, 0.12, 0.16)
	var body: Color = def["color"]
	if kind == "big" and phase == 2:
		body = def["rage_color"]
	if _flash > 0.0:
		body = Color.WHITE
	var w := half.x
	var h := half.y
	# 腕
	draw_rect(Rect2(-w - 14.0, -h * 0.3, 18.0, h * 1.0), outline)
	draw_rect(Rect2(w - 4.0, -h * 0.3, 18.0, h * 1.0), outline)
	draw_rect(Rect2(-w - 11.0, -h * 0.3 + 3.0, 12.0, h * 1.0 - 6.0), body.darkened(0.2))
	draw_rect(Rect2(w - 1.0, -h * 0.3 + 3.0, 12.0, h * 1.0 - 6.0), body.darkened(0.2))
	# 体
	draw_rect(Rect2(-w, -h, w * 2.0, h * 2.0), outline)
	draw_rect(Rect2(-w + 4.0, -h + 4.0, w * 2.0 - 8.0, h * 2.0 - 8.0), body)
	# 目: 撃つ直前（中ボス）と怒っている時（大ボス）は赤く光る
	var aiming: bool = kind == "mid" and (_burst_left > 0 or (_mode == "fight" and _shot_cd < def["aim_time"]))
	var eye := Color(1.0, 0.2, 0.2) if aiming or phase == 2 else Color.WHITE
	var ex := w * 0.42
	for sx in [-1.0, 1.0]:
		draw_circle(Vector2(ex * sx, -h * 0.15), h * 0.28, outline)
		draw_circle(Vector2(ex * sx, -h * 0.15), h * 0.2, eye)
	# 口
	draw_rect(Rect2(-w * 0.45, h * 0.35, w * 0.9, h * 0.25), outline)
	if kind == "mid":
		# アンテナ
		draw_line(Vector2(0.0, -h), Vector2(0.0, -h - 16.0), outline, 4.0)
		draw_circle(Vector2(0.0, -h - 18.0), 6.0, Color(1.0, 0.85, 0.2))
	else:
		# 角（つの）
		for sx in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.55 * sx, -h), Vector2(w * 0.85 * sx, -h), Vector2(w * 0.8 * sx, -h - 26.0)]), outline)
	# 名前と体力バー（いつも出す）
	var bw := w * 2.0
	var by := -h - 40.0
	draw_string_outline(FONT, Vector2(-bw * 0.5, by - 6.0), def["name"], HORIZONTAL_ALIGNMENT_CENTER, bw, 18, 5, outline)
	draw_string(FONT, Vector2(-bw * 0.5, by - 6.0), def["name"], HORIZONTAL_ALIGNMENT_CENTER, bw, 18, Color.WHITE)
	draw_rect(Rect2(-bw * 0.5, by, bw, 10.0), outline)
	draw_rect(Rect2(-bw * 0.5 + 2.0, by + 2.0, (bw - 4.0) * float(maxi(hp, 0)) / float(max_hp), 6.0), Color(0.95, 0.3, 0.3))
