extends Node2D
## プレイ画面の親。進行管理を持つ。
## 流れ: 箱が落ちてくる → 取ると「銃を選ぶ画面」 → プレイ開始 → 倒れたらリザルト
## 1 周 = 雑魚 → 中ボス → 雑魚 → 中ボス → 雑魚 → 大ボス（config.gd の LAP_STAGES）。死ぬまで繰り返す
## 雑魚区間: ゲート（弾の形が変わる 2 択）とアイテム（数値が +1）が流れてくる
## ボス戦: 横幅いっぱいのボスが迫る。倒すとご褒美の 3 択（中ボス +10 / 大ボス ×2）。着かれると大ダメージでご褒美なし
## アイテムは敵が倒されると必ず落とす。回復は与えたダメージの吸収だけ

enum State { CHOOSING_GUN, PLAYING, GAME_OVER }

const GIFT_SCENE := preload("res://scenes/gift.tscn")
const TITLE_SCENE := "res://scenes/title.tscn"

var state := State.CHOOSING_GUN
var kills := 0
var coins := 0
var mid_kills := 0
var big_kills := 0
var run_time := 0.0          # プレイしていた時間（スコアの距離はここから出す）
var lap := 1                 # 何周目か
var stage_index := 0         # LAP_STAGES の何番目か
var stage_phase := "zako"    # zako（雑魚区間） / warning（ボスの予告） / boss / reward（ご褒美待ち）
var _stage_time := 0.0
var _boss: Boss = null
var _reward_kind := ""       # 今出しているご褒美が "mid" か "big" か（空なら銃選び）
var _picked_items := {}      # 取ったアイテムの名前 → 個数（リザルト用）
var _rewards := []           # 選んだボスのご褒美の名前（リザルト用）
var _zako_time := Config.ZAKO_SECTION_TIME

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
@onready var stage_label: Label = $UI/StageLabel
@onready var reward_panel: Control = $UI/RewardPanel
@onready var pause_button: Button = $UI/PauseButton
@onready var speed_label: Label = $UI/SpeedLabel
@onready var pause_menu: Control = $UI/PauseMenu
@onready var result_panel: Control = $UI/ResultPanel


func _ready() -> void:
	get_tree().paused = false
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
	reward_panel.chosen.connect(_on_card_chosen)
	pause_button.pressed.connect(_pause)
	pause_menu.resume_pressed.connect(_resume)
	pause_menu.retry_pressed.connect(_retry)
	pause_menu.quit_pressed.connect(_to_title)
	pause_menu.speed_changed.connect(func(_s: float) -> void: _update_speed_label())
	result_panel.retry_pressed.connect(_retry)
	result_panel.title_pressed.connect(_to_title)
	var zt := TestTools.value("--zakotime=")
	if zt != "":
		_zako_time = float(zt)
	_update_speed_label()
	_update_hud()
	gun_label.text = "GUN: -"
	get_viewport().size_changed.connect(_center_world)
	_center_world()
	_drop_gift()
	var die_at := TestTools.value("--dieat=")
	if die_at != "":
		get_tree().create_timer(float(die_at), false).timeout.connect(
			func() -> void: player.take_damage(99999))


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
	var auto := TestTools.value("--autopick=")
	if auto != "":
		_on_gun_chosen.call_deferred(auto)
		return
	_reward_kind = ""
	get_tree().paused = true
	reward_panel.open_guns(Config.GUN_ORDER)


func _on_card_chosen(id: String) -> void:
	if _reward_kind == "":
		_on_gun_chosen(id)
	else:
		_on_reward_chosen(id)


func _on_gun_chosen(id: String) -> void:
	get_tree().paused = false
	player.set_gun(id)
	gun_label.text = "GUN: %s" % Config.GUNS[id]["name"]
	state = State.PLAYING
	_start_stage()
	_update_hud()
	if TestTools.has("--openpause"):   # テスト用: 一時停止メニューを開いた状態にする
		_pause.call_deferred()
	var open_reward := TestTools.value("--openreward=")   # テスト用: ご褒美の 3 択をすぐ出す（mid / big）
	if open_reward != "":
		_open_reward.call_deferred(open_reward)


# ---- 周回の進行 ----

func _stage_kind() -> String:
	return Config.LAP_STAGES[stage_index]


## 「雑魚 2」「中ボス 1」「大ボス」など、今の区間の名前
func _stage_name() -> String:
	var kind := _stage_kind()
	var n := 0
	for i in stage_index + 1:
		if Config.LAP_STAGES[i] == kind:
			n += 1
	match kind:
		"zako":
			return "雑魚 %d" % n
		"mid":
			return "中ボス %d" % n
		_:
			return "大ボス"


func _reach_text() -> String:
	return "%d 周目 %s" % [lap, _stage_name()]


func _start_stage() -> void:
	_stage_time = 0.0
	if _stage_kind() == "zako":
		stage_phase = "zako"
		spawner.start_section()
	else:
		stage_phase = "warning"
		var boss_name: String = Config.BOSSES[_stage_kind()]["name"]
		_banner("WARNING\n%s 出現!" % boss_name, Color(1.0, 0.4, 0.35), 40, Config.BOSS_WARNING_TIME)
	_update_hud()


func _update_stage(delta: float) -> void:
	_stage_time += delta
	match stage_phase:
		"zako":
			if _stage_time >= _zako_time:
				spawner.active = false
				_stage_index_next()
		"warning":
			if _stage_time >= Config.BOSS_WARNING_TIME:
				_spawn_boss(_stage_kind())


## 次の区間へ。6 つ目（大ボス）の次は次の周
func _stage_index_next() -> void:
	stage_index += 1
	if stage_index >= Config.LAP_STAGES.size():
		stage_index = 0
		lap += 1
		_banner("%d 周目 スタート!\n敵が強くなった" % lap, Color(1.0, 0.85, 0.3), 34, 2.2)
	_start_stage()


func _spawn_boss(kind: String) -> void:
	stage_phase = "boss"
	_boss = Boss.new()
	_boss.setup_boss(kind, spawner.hp_mult)
	_boss.bullet_container = enemy_bullets
	_boss.died.connect(_on_boss_killed)
	_boss.enraged.connect(func() -> void:
		_banner("怒った!\n迫ってくる!", Color(1.0, 0.35, 0.3), 34, 1.6))
	_boss.escaped.connect(_on_boss_escaped.bind(kind))
	enemies.add_child(_boss)


## ボスに着かれた: ダメージはボスが与え済み。ご褒美とコインはなしで次の区間へ
func _on_boss_escaped(damage: int, kind: String) -> void:
	_boss = null
	if state != State.PLAYING:
		return
	_raise_enemy_hp(kind)
	_banner("突破された!\nHP -%d" % damage, Color(1.0, 0.35, 0.3), 36, 1.6)
	_stage_index_next()


## 区間が進んだので敵を強くする（倒しても突破されても同じ）
func _raise_enemy_hp(kind: String) -> void:
	spawner.hp_mult *= Config.HP_MULT_MID if kind == "mid" else Config.HP_MULT_BIG


func _on_boss_killed(boss: Enemy) -> void:
	var kind := (boss as Boss).kind
	_boss = null
	var def: Dictionary = Config.BOSSES[kind]
	coins += def["coins"]
	if kind == "mid":
		mid_kills += 1
	else:
		big_kills += 1
	_raise_enemy_hp(kind)
	_banner("%s 撃破!\nコイン +%d" % [def["name"], def["coins"]], Color(1.0, 0.9, 0.4), 36, 1.4)
	stage_phase = "reward"
	_update_hud()
	await get_tree().create_timer(Config.REWARD_DELAY, false).timeout
	if state == State.PLAYING and player.alive:
		_open_reward(kind)


func _open_reward(kind: String) -> void:
	_reward_kind = kind
	var table: Dictionary = Config.REWARDS_MID if kind == "mid" else Config.REWARDS_BIG
	var ids: Array = table.keys()
	ids.shuffle()
	ids = ids.slice(0, Config.REWARD_CHOICES)
	# テスト用: --autopick の時は 1 枚目を自動で選ぶ
	if TestTools.value("--autopick=") != "" and not TestTools.has("--openreward=" + kind):
		_on_reward_chosen.call_deferred(ids[0])
		return
	var cards := []
	for id in ids:
		var c: Dictionary = table[id].duplicate()
		c["id"] = id
		cards.append(c)
	var title := "中ボスのご褒美" if kind == "mid" else "大ボスのご褒美"
	get_tree().paused = true
	reward_panel.open(title, "1 つ選んでください", cards)


func _on_reward_chosen(id: String) -> void:
	get_tree().paused = false
	var kind := _reward_kind
	_reward_kind = ""
	var table: Dictionary = Config.REWARDS_MID if kind == "mid" else Config.REWARDS_BIG
	var def: Dictionary = table[id]
	if kind == "mid":
		if id == "lifesteal":
			player.lifesteal += Config.REWARD_LIFESTEAL_STEP
		else:
			for w in player.weapons:
				w.apply_item(id, Config.REWARD_MID_STEPS)
	else:
		for w in player.weapons:
			w.apply_multiplier(id, 2)
	_rewards.append(def["name"])
	FloatText.spawn(effects, player.position + Vector2(0, -70), def["name"], def["color"].lightened(0.3), 30)
	print("REWARD %s: %s" % [kind, def["name"]])
	_stage_index_next()


## 画面の真ん中に大きく出す文字
func _banner(text: String, col: Color, size: int, life: float) -> void:
	FloatText.spawn(effects, Vector2(Config.SCREEN_W * 0.5, 360.0), text, col, size, life)


# ---- 一時停止メニュー ----

func _pause() -> void:
	if state != State.PLAYING or get_tree().paused:
		return
	get_tree().paused = true
	pause_menu.open()


func _resume() -> void:
	pause_menu.hide()
	get_tree().paused = false


func _retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()   # 倍速の設定はそのまま引き継ぐ


func _to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func _update_speed_label() -> void:
	var s := Engine.time_scale
	speed_label.text = "" if is_equal_approx(s, 1.0) else "×%s" % pause_menu._speed_text(s)


## スマホで別のアプリに切り替えた時などは自動で一時停止する
func _notification(what: int) -> void:
	if TestTools.value("--shot=") != "":   # 画面写真を撮るテストの時は止めない
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_pause()


# ---- アイテムとゲート ----

func _on_item_picked(item: Item) -> void:
	if not player.alive:
		return
	var def: Dictionary = Config.ITEMS[item.kind]
	var text: String = def["label"]
	_picked_items[text] = _picked_items.get(text, 0) + 1
	match item.kind:
		"coin":
			coins += 1
		_:
			for w in player.weapons:
				w.apply_item(item.kind, 1)
	FloatText.spawn(effects, player.position + Vector2(0, -60), text, def["color"].lightened(0.3))
	_update_hud()


func _on_gate_passed(kind: String, side: int) -> void:
	# 銃口が 2 つある銃は通った側の銃だけが育つ（今の 3 種は 1 つなので全部に効く）
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

func distance() -> int:
	return int(run_time * Config.DISTANCE_PER_SEC)


func _process(delta: float) -> void:
	if state == State.PLAYING and player.alive:
		run_time += delta
		_update_stage(delta)
		stage_label.text = "%s\n%s m" % [_reach_text(), SaveData.format_distance(distance())]
	fps_label.text = "FPS %d   bullets %d   time %.1f   敵の体力 ×%.2f" % [
		Engine.get_frames_per_second(), bullets.get_child_count(), run_time, spawner.hp_mult]
	if TestTools.has("--debuglog") and Engine.get_process_frames() % 60 == 0:
		var boss_text := "" if _boss == null or not is_instance_valid(_boss) else " boss=%s hp=%d/%d phase=%d y=%d" % [
			_boss.kind, _boss.hp, _boss.max_hp, _boss.phase, _boss.position.y]
		print("t=%.1f %s [%s] hp=%d kills=%d coins=%d bullets=%d enemies=%d%s | %s" % [
			run_time, _reach_text(), stage_phase, player.hp, kills, coins, bullets.get_child_count(),
			enemies.get_child_count(), boss_text, stats_label.text.replace("\n", " / ")])


func _on_hp_changed(_hp: int) -> void:
	_update_hud()


func _update_hud() -> void:
	hp_label.text = "HP %d   吸収 %d%%   倒した数 %d   コイン %d" % [
		player.hp, int(round(player.lifesteal * 100.0)), kills, coins]
	var lines := []
	for w in player.weapons:
		lines.append(w.summary())
	stats_label.text = "\n".join(lines)
	stage_label.text = "%s\n%s m" % [_reach_text(), SaveData.format_distance(distance())]


func _on_enemy_killed(enemy: Enemy) -> void:
	kills += 1
	# 画面の外で倒した時は、画面の上端に「撃破!」を出して分かるようにする
	if enemy.position.y < 0.0:
		FloatText.spawn(effects, Vector2(enemy.position.x, 40.0), "撃破!", Color(1.0, 0.9, 0.4), 20)
	_update_hud()


func _on_player_died() -> void:
	state = State.GAME_OVER
	spawner.active = false
	# 画面を止める（プレイヤー以外の動きを停止）
	for n in [bullets, enemies, enemy_bullets, items, gates, effects, background]:
		n.process_mode = Node.PROCESS_MODE_DISABLED
	pause_button.hide()
	var reach := _reach_text()
	var new_record := SaveData.submit_run(distance(), reach)
	var secs := int(run_time)
	result_panel.open({
		"distance": distance(),
		"new_record": new_record,
		"reach": reach,
		"time_text": "%d:%02d" % [secs / 60, secs % 60],
		"coins": coins,
		"kills": kills,
		"mid_kills": mid_kills,
		"big_kills": big_kills,
		"items": _picked_items,
		"rewards": _rewards,
	})
	var stats := []
	for w in player.weapons:
		stats.append(w.summary())
	print("GAME OVER gun=%s distance=%dm reach=%s kills=%d mid=%d big=%d coins=%d time=%.1f | %s" % [
		player.gun_id, distance(), reach, kills, mid_kills, big_kills, coins, run_time, " / ".join(stats)])


func _unhandled_input(event: InputEvent) -> void:
	# PC では Esc か P キーでも一時停止 / 再開できる
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_P]:
		if pause_menu.visible:
			_resume()
		else:
			_pause()
