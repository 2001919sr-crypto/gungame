extends Node2D
## プレイ画面の親。進行管理（プレイ中 / ゲームオーバー）を持つ。
## タイトル・クリア・リザルトは Step 4 でここに足す。

enum State { PLAYING, GAME_OVER }

const RETRY_DELAY := 0.8   # ゲームオーバー直後の誤タップでリトライしないための待ち時間

var state := State.PLAYING
var kills := 0
var _over_time := 0.0

@onready var player: Player = $Player
@onready var bullets: Node2D = $Bullets
@onready var enemies: Node2D = $Enemies
@onready var enemy_bullets: Node2D = $EnemyBullets
@onready var spawner: Node = $Spawner
@onready var background: Node2D = $Background
@onready var fps_label: Label = $UI/FpsLabel
@onready var gun_label: Label = $UI/GunLabel
@onready var hp_label: Label = $UI/HpLabel
@onready var game_over_panel: Control = $UI/GameOver
@onready var game_over_label: Label = $UI/GameOver/Label


func _ready() -> void:
	player.bullet_container = bullets
	player.hp_changed.connect(_on_hp_changed)
	player.died.connect(_on_player_died)
	spawner.enemy_container = enemies
	spawner.enemy_bullet_container = enemy_bullets
	spawner.enemy_killed.connect(_on_enemy_killed)
	game_over_panel.hide()
	_on_hp_changed(player.hp, player.max_hp)
	_update_gun_label()


func _process(delta: float) -> void:
	fps_label.text = "FPS %d   bullets %d   time %.1f" % [
		Engine.get_frames_per_second(), bullets.get_child_count(), spawner.elapsed]
	if state == State.GAME_OVER:
		_over_time += delta


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
	for n in [bullets, enemies, enemy_bullets, background]:
		n.process_mode = Node.PROCESS_MODE_DISABLED
	game_over_label.text = "GAME OVER\n\nKILLS  %d\nTIME  %.1f s\n\nTAP TO RETRY" % [kills, spawner.elapsed]
	game_over_panel.show()
	print("GAME OVER kills=%d time=%.1f" % [kills, spawner.elapsed])


func _unhandled_input(event: InputEvent) -> void:
	if state == State.GAME_OVER:
		var tapped: bool = event is InputEventScreenTouch and event.pressed
		var key: bool = event is InputEventKey and event.pressed and not event.echo
		if (tapped or key) and _over_time >= RETRY_DELAY:
			get_tree().reload_current_scene()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				player.set_gun("handgun")
			KEY_2:
				player.set_gun("shotgun")
			KEY_3:
				player.set_gun("dual")
			_:
				return
		_update_gun_label()


func _update_gun_label() -> void:
	gun_label.text = "GUN: %s   (1/2/3 to switch)" % Config.GUNS[player.gun_id]["label"]
