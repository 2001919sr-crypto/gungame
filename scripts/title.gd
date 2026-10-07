extends Control
## タイトル画面。スタート・自己ベスト・ショップ（Step 5 までは「準備中」）。

const GAME_SCENE := "res://scenes/game.tscn"

var _toast: Label


func _ready() -> void:
	get_tree().paused = false
	# テスト用: --autopick か --skiptitle が付いていたらタイトルを飛ばしてすぐ遊ぶ
	if TestTools.value("--autopick=") != "" or TestTools.has("--skiptitle"):
		_start.call_deferred()
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.96, 0.94, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	add_child(_Decor.new())

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	var dark := Color(0.15, 0.15, 0.2)
	var logo := UiKit.make_label("GUNGAME", 72, Color(1.0, 0.55, 0.15))
	logo.add_theme_color_override("font_outline_color", dark)
	logo.add_theme_constant_override("outline_size", 14)
	box.add_child(logo)
	box.add_child(UiKit.make_label("おもちゃの銃で どこまで行ける?", 22, dark))
	box.add_child(_spacer(30))

	var best := "まだ記録がありません"
	if SaveData.best_distance > 0:
		best = "%s m\n%s" % [SaveData.format_distance(SaveData.best_distance), SaveData.best_reach]
	box.add_child(UiKit.make_label("自己ベスト", 20, Color(dark, 0.7)))
	box.add_child(UiKit.make_label(best, 30, dark))
	box.add_child(_spacer(30))

	for b in [
		UiKit.make_button("スタート", Color(1.0, 0.55, 0.15), _start, Vector2(300, 84), 34),
		UiKit.make_button("ショップ", Color(0.3, 0.6, 1.0), _shop),
	]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(b)

	_toast = UiKit.make_label("", 20, Color(0.85, 0.3, 0.3))
	box.add_child(_toast)


func _start() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _shop() -> void:
	_toast.text = "ショップは準備中です（Step 5 で作ります）"


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## 背景の飾り: ゆっくり流れる横線（プレイ画面と同じ雰囲気）
class _Decor:
	extends Control
	var _offset := 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_offset = fmod(_offset + 60.0 * delta, 90.0)
		queue_redraw()

	func _draw() -> void:
		var y := _offset - 90.0
		while y < size.y:
			draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0.3, 0.3, 0.4, 0.10), 3.0)
			y += 90.0
