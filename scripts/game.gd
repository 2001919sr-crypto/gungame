extends Node2D
## プレイ画面の親。進行管理を持つ。
## 流れ: 箱が落ちてくる → 取ると「銃を選ぶ画面」 → 選んだらプレイ開始 → ゲームオーバー
## タイトル・ボス・クリア・リザルトは Step 4 でここに足す。

enum State { CHOOSING_GUN, PLAYING, GAME_OVER }

const GIFT_SCENE := preload("res://scenes/gift.tscn")
const RETRY_DELAY := 0.8   # ゲームオーバー直後の誤タップでリトライしないための待ち時間

var state := State.CHOOSING_GUN
var kills := 0
var _over_time := 0.0

@onready var player: Player = $Player
@onready var bullets: Node2D = $Bullets
@onready var enemies: Node2D = $Enemies
@onready var enemy_bullets: Node2D = $EnemyBullets
@onready var items: Node2D = $Items
@onready var spawner: Node = $Spawner
@onready var background: Node2D = $Background
@onready var fps_label: Label = $UI/FpsLabel
@onready var gun_label: Label = $UI/GunLabel
@onready var hp_label: Label = $UI/HpLabel
@onready var reward_panel: Control = $UI/RewardPanel
@onready var game_over_panel: Control = $UI/GameOver
@onready var game_over_label: Label = $UI/GameOver/Label


func _ready() -> void:
	player.bullet_container = bullets
	player.hp_changed.connect(_on_hp_changed)
	player.died.connect(_on_player_died)
	spawner.enemy_container = enemies
	spawner.enemy_bullet_container = enemy_bullets
	spawner.enemy_killed.connect(_on_enemy_killed)
	reward_panel.chosen.connect(_on_gun_chosen)
	game_over_panel.hide()
	_on_hp_changed(player.hp, player.max_hp)
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
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autopick="):
			_on_gun_chosen.call_deferred(arg.trim_prefix("--autopick="))
			return
	get_tree().paused = true
	reward_panel.open(Config.GUN_ORDER)


func _on_gun_chosen(id: String) -> void:
	get_tree().paused = false
	player.set_gun(id)
	gun_label.text = "GUN: %s" % Config.GUNS[id]["name"]
	state = State.PLAYING
	spawner.active = true


func _process(delta: float) -> void:
	fps_label.text = "FPS %d   bullets %d   time %.1f" % [
		Engine.get_frames_per_second(), bullets.get_child_count(), spawner.elapsed]
	if state == State.GAME_OVER:
		_over_time += delta
	if "--debuglog" in OS.get_cmdline_user_args() and Engine.get_process_frames() % 60 == 0:
		var es := []
		for e in enemies.get_children():
			es.append("%s(%d,%d hp%d)" % [e.type_id, e.position.x, e.position.y, e.hp])
		var bs := []
		for b in bullets.get_children().slice(0, 3):
			bs.append("(%d,%d)" % [b.position.x, b.position.y])
		print("t=%.1f player=(%d,%d) hp=%d kills=%d bullets=%d %s enemies=%s" % [
			spawner.elapsed, player.position.x, player.position.y, player.hp, kills,
			bullets.get_child_count(), bs, es])


func _on_hp_changed(hp: int, max_hp: int) -> void:
	hp_label.text = "HP %d / %d     KILLS %d" % [hp, max_hp, kills]


func _on_enemy_killed(_enemy: Enemy) -> void:
	kills += 1
	_on_hp_changed(player.hp, player.max_hp)


func _on_player_died() -> void:
	state = State.GAME_OVER
	_over_time = 0.0
	spawner.active = false
	# 画面を止める（プレイヤー以外の動きを停止）
	for n in [bullets, enemies, enemy_bullets, items, background]:
		n.process_mode = Node.PROCESS_MODE_DISABLED
	game_over_label.text = "GAME OVER\n\n倒した数  %d\n生存時間  %.1f 秒\n\nタップでもう一度" % [kills, spawner.elapsed]
	game_over_panel.show()
	print("GAME OVER gun=%s kills=%d time=%.1f" % [player.gun_id, kills, spawner.elapsed])


func _unhandled_input(event: InputEvent) -> void:
	if state == State.GAME_OVER:
		var tapped: bool = event is InputEventScreenTouch and event.pressed
		var key: bool = event is InputEventKey and event.pressed and not event.echo
		if (tapped or key) and _over_time >= RETRY_DELAY:
			get_tree().reload_current_scene()


## テスト用: 「-- --shot=保存先.png」を付けて起動すると、5 秒後に画面写真を撮って終了する
## （一時停止中でも動くタイマーを使う）
func _setup_screenshot() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			await get_tree().create_timer(5.0, true).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--shot="))
			get_tree().quit()
