extends Node2D
## プレイ画面の親。進行管理を持つ。
## 流れ: 箱が落ちてくる → 取ると「銃を選ぶ画面」 → 選んだらプレイ開始 → ゲームオーバー
## 道中: ゲート（弾の形が変わる 2 択）とアイテム（数値が +1）が流れてくる
## ボス・周回・リザルトは Step 4 でここに足す。

enum State { CHOOSING_GUN, PLAYING, GAME_OVER }

const GIFT_SCENE := preload("res://scenes/gift.tscn")
const RETRY_DELAY := 0.8   # ゲームオーバー直後の誤タップでリトライしないための待ち時間

var state := State.CHOOSING_GUN
var kills := 0
var coins := 0
var _over_time := 0.0

@onready var player: Player = $Player
@onready var bullets: Node2D = $Bullets
@onready var enemies: Node2D = $Enemies
@onready var enemy_bullets: Node2D = $EnemyBullets
@onready var items: Node2D = $Items
@onready var gates: Node2D = $Gates
@onready var effects: Node2D = $Effects
@onready var spawner: Node = $Spawner
@onready var background: Node2D = $Background
@onready var fps_label: Label = $UI/FpsLabel
@onready var gun_label: Label = $UI/GunLabel
@onready var hp_label: Label = $UI/HpLabel
@onready var stats_label: Label = $UI/StatsLabel
@onready var reward_panel: Control = $UI/RewardPanel
@onready var game_over_panel: Control = $UI/GameOver
@onready var game_over_label: Label = $UI/GameOver/Label


func _ready() -> void:
	player.bullet_container = bullets
	player.hp_changed.connect(_on_hp_changed)
	player.died.connect(_on_player_died)
	spawner.enemy_container = enemies
	spawner.enemy_bullet_container = enemy_bullets
	spawner.item_container = items
	spawner.gate_container = gates
	spawner.enemy_killed.connect(_on_enemy_killed)
	spawner.item_picked.connect(_on_item_picked)
	spawner.gate_passed.connect(_on_gate_passed)
	reward_panel.chosen.connect(_on_gun_chosen)
	game_over_panel.hide()
	_update_hud()
	gun_label.text = "GUN: -"
	get_viewport().size_changed.connect(_center_world)
	_center_world()
	_drop_gift()
	_setup_screenshot()


## 画面が幅 540 より広い時、ゲームの世界を中央に寄せる
func _center_world() -> void:
	var w := get_viewport_rect().size.x
	get_viewport().canvas_transform = Transform2D(0.0, Vector2(maxf((w - Config.SCREEN_W) * 0.5, 0.0), 0.0))


func _drop_gift() -> void:
	var gift := GIFT_SCENE.instantiate() as Gift
	gift.position = Vector2(Config.SCREEN_W * 0.5, -40.0)
	gift.picked.connect(_on_gift_picked)
	items.add_child(gift)


func _on_gift_picked() -> void:
	# テスト用: 起動時に「-- --autopick=handgun」を付けると画面を出さずに選ぶ
	var auto := _arg_value("--autopick=")
	if auto != "":
		_on_gun_chosen.call_deferred(auto)
		return
	get_tree().paused = true
	reward_panel.open(Config.GUN_ORDER)


func _on_gun_chosen(id: String) -> void:
	get_tree().paused = false
	player.set_gun(id)
	gun_label.text = "GUN: %s" % Config.GUNS[id]["name"]
	state = State.PLAYING
	spawner.active = true
	_update_hud()


# ---- アイテムとゲート ----

## ハートの回復量（進むほど大きくなる）
func heart_heal_amount() -> int:
	return Config.HEART_HEAL_BASE + int(spawner.elapsed / 60.0 * Config.HEART_HEAL_PER_MIN)


func _on_item_picked(item: Item) -> void:
	if not player.alive:
		return
	var def: Dictionary = Config.ITEMS[item.kind]
	var text: String = def["label"]
	match item.kind:
		"heart":
			var amount := heart_heal_amount()
			player.heal(amount)
			text = "回復+%d" % amount
		"coin":
			coins += 1
		_:
			for w in player.weapons:
				w.apply_item(item.kind, 1)
	FloatText.spawn(effects, player.position + Vector2(0, -60), text, def["color"].lightened(0.3))
	_update_hud()


func _on_gate_passed(kind: String, side: int) -> void:
	# 二丁拳銃は通った側の銃だけが育つ。それ以外は 1 丁なので全部に効く
	var targets: Array[WeaponState] = player.weapons
	if player.weapons.size() > 1:
		targets = [player.weapons[0 if side < 0 else 1]]
	for w in targets:
		w.apply_gate(kind)
	var def: Dictionary = Config.GATES[kind]
	var col := Color(0.6, 1.0, 0.7) if def["good"] else Color(1.0, 0.55, 0.55)
	FloatText.spawn(effects, player.position + Vector2(0, -70), String(def["label"]).replace("\n", ""), col, 26)
	_update_hud()


# ---- 表示 ----

func _process(delta: float) -> void:
	fps_label.text = "FPS %d   bullets %d   time %.1f" % [
		Engine.get_frames_per_second(), bullets.get_child_count(), spawner.elapsed]
	if state == State.GAME_OVER:
		_over_time += delta
	if "--debuglog" in OS.get_cmdline_user_args() and Engine.get_process_frames() % 60 == 0:
		print("t=%.1f hp=%d kills=%d coins=%d bullets=%d enemies=%d items=%d gates=%d | %s" % [
			spawner.elapsed, player.hp, kills, coins, bullets.get_child_count(),
			enemies.get_child_count(), items.get_child_count(), gates.get_child_count(), stats_label.text.replace("\n", " / ")])


func _on_hp_changed(_hp: int, _max_hp: int) -> void:
	_update_hud()


func _update_hud() -> void:
	hp_label.text = "HP %d / %d   倒した数 %d   コイン %d" % [player.hp, player.max_hp, kills, coins]
	var lines := []
	for w in player.weapons:
		lines.append(w.summary())
	stats_label.text = "\n".join(lines)


func _on_enemy_killed(enemy: Enemy) -> void:
	kills += 1
	# 画面の外で倒した時は、画面の上端に「撃破!」を出して分かるようにする
	if enemy.position.y < 0.0:
		FloatText.spawn(effects, Vector2(enemy.position.x, 40.0), "撃破!", Color(1.0, 0.9, 0.4), 20)
	_update_hud()


func _on_player_died() -> void:
	state = State.GAME_OVER
	_over_time = 0.0
	spawner.active = false
	# 画面を止める（プレイヤー以外の動きを停止）
	for n in [bullets, enemies, enemy_bullets, items, gates, effects, background]:
		n.process_mode = Node.PROCESS_MODE_DISABLED
	game_over_label.text = "GAME OVER\n\n倒した数  %d\nコイン  %d\n生存時間  %.1f 秒\n\nタップでもう一度" % [
		kills, coins, spawner.elapsed]
	game_over_panel.show()
	var stats := []
	for w in player.weapons:
		stats.append(w.summary())
	print("GAME OVER gun=%s kills=%d coins=%d time=%.1f | %s" % [
		player.gun_id, kills, coins, spawner.elapsed, " / ".join(stats)])


func _unhandled_input(event: InputEvent) -> void:
	if state == State.GAME_OVER:
		var tapped: bool = event is InputEventScreenTouch and event.pressed
		var key: bool = event is InputEventKey and event.pressed and not event.echo
		if (tapped or key) and _over_time >= RETRY_DELAY:
			get_tree().reload_current_scene()


# ---- テスト用の起動オプション ----

func _arg_value(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


## 「-- --shot=保存先.png」で画面写真を撮って終了する。「--shotat=秒」で撮る時刻を変えられる（既定 5 秒）
## （一時停止中でも動くタイマーを使う）
func _setup_screenshot() -> void:
	var path := _arg_value("--shot=")
	if path == "":
		return
	var at := _arg_value("--shotat=")
	await get_tree().create_timer(5.0 if at == "" else float(at), true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
