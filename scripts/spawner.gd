extends Node
## 「何秒に何を出すか」。数値は config.gd の WAVES。
## rng（乱数）を 1 つにまとめてあるので、後でデイリーチャレンジの「日付シード」を入れられる。

signal enemy_killed(enemy: Enemy)

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

var enemy_container: Node = null
var enemy_bullet_container: Node = null
var active := false   # 銃を選ぶまでは出さない（game.gd が true にする）
var elapsed := 0.0
var rng := RandomNumberGenerator.new()
var _cooldown := 0.6


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	if not active or enemy_container == null:
		return
	elapsed += delta
	_cooldown -= delta
	if _cooldown <= 0.0:
		var wave := _current_wave()
		_cooldown += wave["interval"]
		_spawn(_pick(wave["weights"]))


func _current_wave() -> Dictionary:
	for w in Config.WAVES:
		if elapsed < w["until"]:
			return w
	return Config.WAVES[-1]


func _pick(weights: Dictionary) -> String:
	var total := 0
	for k in weights:
		total += weights[k]
	var roll := rng.randi_range(1, total)
	for k in weights:
		roll -= weights[k]
		if roll <= 0:
			return k
	return weights.keys()[0]


func _spawn(type_id: String) -> void:
	var view_w := float(Config.SCREEN_W)
	var r: float = Config.ENEMIES[type_id]["radius"]
	var lane: float = Config.LANES[rng.randi_range(0, Config.LANES.size() - 1)]
	var x := view_w * lane
	var e := ENEMY_SCENE.instantiate() as Enemy
	e.setup(type_id, Vector2(x, -r - 10.0))
	e.bullet_container = enemy_bullet_container
	e.died.connect(func(en: Enemy) -> void: enemy_killed.emit(en))
	enemy_container.add_child(e)
