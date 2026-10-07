class_name Boss
extends Enemy
## 中ボスと大ボス。数値は config.gd の BOSSES。横幅いっぱいなので避けられない。着かれる前に倒しきる。
## 敵（Enemy）の仲間として作っているので、弾の当たり方・貫通・吸収はふつうの敵と同じ仕組みで動く。
## 中ボス: 雑魚と同じ速さで画面の上の外から降りてくる。弾は撃たない
## 大ボス: 第 1 段階は上に居座り扇形にばらまく。体力 50% 以下で赤くなり、速く降りてくる
## プレイヤーの所まで来たら escaped を出して消える（倒したことにはならない）

signal enraged                 # 大ボスが第 2 段階になった
signal escaped(damage: int)    # 着かれた。damage はプレイヤーが受けたダメージ

const FONT := preload("res://assets/fonts/MPLUSRounded1c-Bold.ttf")

var kind := "mid"
var phase := 1
var _mode := "enter"        # 大ボス: enter（降りてくる）→ fight
var _shot_cd := 1.2


func setup_boss(k: String, hp_mult: float) -> void:
	kind = k
	type_id = "boss_" + k
	def = Config.BOSSES[k]
	hp = maxi(int(round(def["hp"] * hp_mult)), 1)
	max_hp = hp
	half = def["size"] * 0.5
	contact_damage = def["contact_damage"]
	# 中ボスは雑魚と同じく画面の上の外で生まれる（射程が長いと見える前から削れる）
	var start_y := -Config.SPAWN_AHEAD if k == "mid" else -half.y - 20.0
	position = Vector2(Config.SCREEN_W * 0.5, start_y)


func _ready() -> void:
	# 設定は enemy.tscn と同じ（敵のレイヤー）。四角の当たり判定は自分で作る
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	var shape := RectangleShape2D.new()
	shape.size = half * 2.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	add_to_group("enemies")


func _process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(_flash - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as Player
	if kind == "mid":
		position.y += def["speed"] * delta
	elif phase == 2:
		position.y += def["charge_speed"] * delta
	else:
		_big_phase1(delta, player)
	if player and position.y + half.y >= player.position.y - 40.0:
		_reach_player(player)
		return
	queue_redraw()


func _big_phase1(delta: float, player: Player) -> void:
	var hover := _hover_y(player)
	if _mode == "enter":
		position.y += Config.BOSS_ENTER_SPEED * delta
		if position.y >= hover:
			_mode = "fight"
		return
	position.y = move_toward(position.y, hover, 80.0 * delta)
	_shot_cd -= delta
	if _shot_cd <= 0.0:
		_shot_cd = def["fire_interval"]
		_shoot_fan(def["fan"])


## 大ボスが居座る高さ。射程が短い銃でも届くよう、プレイヤーの射程に合わせて下がってくる
func _hover_y(player: Player) -> float:
	var y: float = def["hover_y"]
	if player and player.weapons.size() > 0:
		var reach := player.position.y + Config.MUZZLE_Y - player.max_range()
		y = maxf(y, reach + 50.0 - half.y)
	return minf(y, Config.BOSS_MAX_Y)


## 着かれた: ボスの残り体力に応じた大ダメージ（無敵時間も無視）。ボスは消える
func _reach_player(player: Player) -> void:
	var dmg := maxi(int(round(hp * Config.CRUSH_DAMAGE_RATE)), 1)
	dead = true
	player.take_damage(dmg, true)
	escaped.emit(dmg)
	queue_free()


## 真下を中心に扇形にばらまく
func _shoot_fan(n: int) -> void:
	if bullet_container == null:
		return
	var spread: float = def["fan_deg"]
	for i in n:
		var a := -spread * 0.5 + spread * float(i) / float(maxi(n - 1, 1))
		var dir := Vector2.DOWN.rotated(deg_to_rad(a))
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
	# 体（横幅いっぱいの壁のようなロボ）
	draw_rect(Rect2(-w, -h, w * 2.0, h * 2.0), outline)
	draw_rect(Rect2(-w + 5.0, -h + 5.0, w * 2.0 - 10.0, h * 2.0 - 10.0), body)
	# 左右の列の上にも目を並べて「3 列ぜんぶふさいでいる」ことを見せる
	var eye := Color(1.0, 0.2, 0.2) if phase == 2 else Color.WHITE
	for lane in Config.LANES:
		var x: float = Config.SCREEN_W * lane - Config.SCREEN_W * 0.5
		draw_circle(Vector2(x - 20.0, -h * 0.15), h * 0.2, outline)
		draw_circle(Vector2(x - 20.0, -h * 0.15), h * 0.14, eye)
		draw_circle(Vector2(x + 20.0, -h * 0.15), h * 0.2, outline)
		draw_circle(Vector2(x + 20.0, -h * 0.15), h * 0.14, eye)
		draw_rect(Rect2(x - 30.0, h * 0.3, 60.0, h * 0.22), outline)
	if kind == "big":
		# 角（つの）
		for sx in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.55 * sx, -h), Vector2(w * 0.75 * sx, -h), Vector2(w * 0.7 * sx, -h - 28.0)]), outline)
	# 名前と体力バー。ボスが画面の上の外にいる間は画面の上端に出す
	var bw := 300.0
	var by := maxf(-h - 22.0, 80.0 - position.y)
	draw_string_outline(FONT, Vector2(-bw * 0.5, by - 6.0), def["name"], HORIZONTAL_ALIGNMENT_CENTER, bw, 18, 5, outline)
	draw_string(FONT, Vector2(-bw * 0.5, by - 6.0), def["name"], HORIZONTAL_ALIGNMENT_CENTER, bw, 18, Color.WHITE)
	draw_rect(Rect2(-bw * 0.5, by, bw, 12.0), outline)
	draw_rect(Rect2(-bw * 0.5 + 2.0, by + 2.0, (bw - 4.0) * float(maxi(hp, 0)) / float(max_hp), 8.0), Color(0.95, 0.3, 0.3))
