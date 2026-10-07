class_name Player
extends Node2D
## プレイヤー。左右に動き、持っている銃を自動で撃つ。
## 銃は「弾のパラメータの組」（WeaponState）の一覧。銃口が 2 つある銃なら 2 つ入る（今の 3 種は 1 つ）。
## 敵や敵の弾に当たると体力が減り、少しの間だけ無敵になる。
## 体力に上限はない。敵に与えたダメージの lifesteal（最初は 5%）ぶん回復する（吸収）。

signal hp_changed(hp: int)
signal died

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

var gun_id := ""   # 最初は銃なし。最初のアイテムで決まり、その後は変えられない
var weapons: Array[WeaponState] = []
var bullet_container: Node = null   # 弾を入れる場所（game.gd が渡す）
var hp: int = Config.PLAYER_START_HP
var lifesteal: float = Config.LIFESTEAL_START   # 与えたダメージのうち体力に戻る割合
var _absorb_pool := 0.0   # 1 に満たない回復を貯めておく（威力 10 の 5% = 0.5 など）
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


## 敵に与えたダメージを吸収して回復する（enemy.gd が呼ぶ）
func absorb(dealt: int) -> void:
	if not alive or dealt <= 0:
		return
	_absorb_pool += dealt * lifesteal
	if _absorb_pool >= 1.0:
		var gain := int(_absorb_pool)
		_absorb_pool -= gain
		hp += gain
		hp_changed.emit(hp)


## ignore_invincible: ボスに着かれた時など、無敵時間中でも必ず受けるダメージ
func take_damage(amount: int, ignore_invincible: bool = false) -> void:
	if not alive or (_invincible > 0.0 and not ignore_invincible):
		return
	if TestTools.has("--godmode") and amount < 99999:   # テスト用: やられない（--dieat の時だけ倒れる）
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp)
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
		# 連射が速すぎて 1 コマに何回も撃つ時は、まとめて 1 回にして威力に上乗せする
		var shots := 0
		while wpn.cooldown <= 0.0:
			wpn.cooldown += 1.0 / wpn.fire_rate
			shots += 1
		if shots > 0:
			_fire(wpn, shots)


func _fire(wpn: WeaponState, shots: int) -> void:
	if bullet_container == null:
		return
	if bullet_container.get_child_count() >= Config.MAX_BULLETS:
		return
	# 弾は 1 丁 VOLLEY_CAP 発まで。超えた分は 1 発の威力に上乗せする（弾数 ×2 = 攻撃力 2 倍は崩さない）
	var n := mini(wpn.count, Config.VOLLEY_CAP)
	var power := float(wpn.count) / float(n) * float(shots)
	var dmg := int(round(wpn.damage * power))
	var size_mult := minf(sqrt(power), Config.MAX_POWER_SIZE)
	var spread := minf(wpn.spread_deg, Config.MAX_SPREAD_DEG)
	# 弾が多い時は間隔を詰めて画面の幅に収める
	var spacing := Config.BULLET_SPACING
	if n > 1:
		spacing = minf(spacing, (Config.SCREEN_W - 60.0) / float(n - 1))
	for i in n:
		var angle_deg := 0.0
		var x_off := 0.0
		if spread > 0.0 and n > 1:
			# 扇状: -spread/2 〜 +spread/2 に均等に並べる
			angle_deg = -spread * 0.5 + spread * float(i) / float(n - 1)
		else:
			# 平行: 中心をそろえて横に並べる
			x_off = (float(i) - float(n - 1) * 0.5) * spacing
		var bullet := BULLET_SCENE.instantiate()
		var start := position + Vector2(wpn.offset_x + x_off, Config.MUZZLE_Y)
		bullet.setup(wpn, start, angle_deg, dmg, size_mult)
		bullet_container.add_child(bullet)


## 一番遠くまで届く銃の射程（ボスが下がってくる位置を決めるのに使う）
func max_range() -> float:
	var r := 0.0
	for w in weapons:
		r = maxf(r, w.range_px)
	return r


func _draw() -> void:
	# おもちゃ風: 丸い本体と、銃ごとの銃口。絵は後で差し替える
	var body := Color(1.0, 0.55, 0.15) if alive else Color(0.55, 0.55, 0.55)
	draw_circle(Vector2.ZERO, 24.0, Color(0.12, 0.12, 0.16))
	draw_circle(Vector2.ZERO, 20.0, body)
	draw_circle(Vector2(-6.0, -4.0), 4.0, Color(1.0, 1.0, 1.0, 0.8))
	var long_barrel: bool = gun_id != "" and Config.GUNS[gun_id].get("long_barrel", false)
	for wpn in weapons:
		var r := Rect2(wpn.offset_x - 6.0, -44.0, 12.0, 26.0)
		if long_barrel:
			r = Rect2(wpn.offset_x - 5.0, -62.0, 10.0, 44.0)   # スナイパーは細長い銃身
		draw_rect(r, Color(0.12, 0.12, 0.16))
		draw_rect(r.grow(-2.5), wpn.color)
		if long_barrel:
			draw_circle(Vector2(wpn.offset_x + 9.0, -32.0), 5.0, Color(0.12, 0.12, 0.16))   # スコープ
