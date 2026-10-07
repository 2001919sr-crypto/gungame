extends Node
## 「何秒に何を出すか」。敵とゲートを出し、倒された敵が落とすアイテムも出す。数値は config.gd。
## rng（乱数）を 1 つにまとめてあるので、後でデイリーチャレンジの「日付シード」を入れられる。

signal enemy_killed(enemy: Enemy)
signal item_picked(item: Item)
signal gate_passed(kind: String, side: int)

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const ITEM_SCENE := preload("res://scenes/item.tscn")
const GATE_SCRIPT := preload("res://scripts/gate.gd")

var enemy_container: Node = null
var enemy_bullet_container: Node = null
var item_container: Node = null
var gate_container: Node = null
var active := false   # 雑魚区間の間だけ true（game.gd が切り替える。ボス戦の間は何も出さない）
var elapsed := 0.0    # 雑魚区間にいた時間の合計。出現表（WAVES）はこれで進む
var hp_mult := 1.0    # 周回で強くなった敵の体力の倍率（game.gd が増やす）
var rng := RandomNumberGenerator.new()
var _enemy_cd := 0.6
var _gate_cd := Config.GATE_FIRST


func _ready() -> void:
	rng.randomize()


## 雑魚区間の始まり。ゲートとアイテムの間隔を最初から数え直す
func start_section() -> void:
	_enemy_cd = 0.6
	_gate_cd = Config.GATE_FIRST
	active = true


func _process(delta: float) -> void:
	if not active or enemy_container == null:
		return
	elapsed += delta
	_enemy_cd -= delta
	if _enemy_cd <= 0.0:
		var wave := _current_wave()
		_enemy_cd += wave["interval"]
		_spawn_enemy(_pick(wave["weights"]))
	_gate_cd -= delta
	if _gate_cd <= 0.0:
		_gate_cd += Config.GATE_INTERVAL
		_spawn_gate()


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


func _lane_x() -> float:
	var lane: float = Config.LANES[rng.randi_range(0, Config.LANES.size() - 1)]
	return Config.SCREEN_W * lane


func _spawn_enemy(type_id: String) -> void:
	var e := ENEMY_SCENE.instantiate() as Enemy
	# 画面の上の外で生まれる（射程が長ければ見える前に倒せる）
	e.setup(type_id, Vector2(_lane_x(), -Config.SPAWN_AHEAD), hp_mult)
	e.bullet_container = enemy_bullet_container
	e.died.connect(_on_enemy_died)
	enemy_container.add_child(e)


func _on_enemy_died(e: Enemy) -> void:
	enemy_killed.emit(e)
	# 敵は必ずアイテムを 1 個落とす（倒した場所から流れてくる）
	var weights := {}
	for k in Config.ITEMS:
		weights[k] = Config.ITEMS[k]["weight"]
	spawn_item.call_deferred(_pick(weights), e.position)


func spawn_item(kind: String, pos: Vector2) -> void:
	if item_container == null:
		return
	var it := ITEM_SCENE.instantiate() as Item
	it.setup(kind, pos)
	it.picked.connect(func(i: Item) -> void: item_picked.emit(i))
	item_container.add_child(it)


func _spawn_gate() -> void:
	if gate_container == null:
		return
	var good := []
	var good_w := {}
	var bad_w := {}
	for k in Config.GATES:
		if Config.GATES[k]["good"]:
			good.append(k)
			good_w[k] = Config.GATES[k]["weight"]
		else:
			bad_w[k] = Config.GATES[k]["weight"]
	var a := _pick(good_w)
	var b := ""
	if rng.randf() < Config.GATE_BAD_CHANCE:
		b = _pick(bad_w)
	else:
		# 良いゲート同士。同じものが並ばないようにする
		var rest := good_w.duplicate()
		rest.erase(a)
		b = _pick(rest)
	var pair := [a, b]
	if rng.randf() < 0.5:
		pair.reverse()
	var g := GATE_SCRIPT.new() as GatePair
	g.setup(pair[0], pair[1], -60.0)
	g.passed.connect(func(kind: String, side: int) -> void: gate_passed.emit(kind, side))
	gate_container.add_child(g)
