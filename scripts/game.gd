extends Node2D
## プレイ画面の親。進行管理（ステート）は Step 4 でここに足す。
## 今は: プレイヤーに弾の置き場を渡す / デバッグ表示 / 1・2・3 キーで銃を切り替え

@onready var player: Player = $Player
@onready var bullets: Node2D = $Bullets
@onready var fps_label: Label = $UI/FpsLabel
@onready var gun_label: Label = $UI/GunLabel


func _ready() -> void:
	player.bullet_container = bullets
	_update_gun_label()


func _process(_delta: float) -> void:
	fps_label.text = "FPS %d   bullets %d" % [Engine.get_frames_per_second(), bullets.get_child_count()]


func _unhandled_input(event: InputEvent) -> void:
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
