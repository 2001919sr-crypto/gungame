extends Node
## 操作はこのファイルだけ。操作方法を変えたい時はここだけ直す。
## 今の方式: 左右タップ。画面の左半分を押している間は左へ、右半分は右へ動く。
## PC では ← → キー（または A / D）。マウスのクリックはタッチとして扱われる（project.godot の設定）。

# 指ごとに「左(-1)か右(+1)か」を覚える。キーは指の番号
var _touch_sides: Dictionary = {}


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_sides[event.index] = _side_of(event.position)
		else:
			_touch_sides.erase(event.index)
	elif event is InputEventScreenDrag:
		# 押したまま指が反対側へ動いたら向きも変える
		if _touch_sides.has(event.index):
			_touch_sides[event.index] = _side_of(event.position)


func _side_of(pos: Vector2) -> int:
	var center_x := get_viewport().get_visible_rect().size.x * 0.5
	return -1 if pos.x < center_x else 1


## -1.0（左）〜 +1.0（右）。何も押していなければ 0
func get_move_dir() -> float:
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	for side in _touch_sides.values():
		dir += side
	return clampf(dir, -1.0, 1.0)
