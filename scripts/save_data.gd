extends Node
## 保存データ（自己ベスト）。user://save.json に JSON で書く。
## user:// は PC なら %APPDATA%\Godot\app_userdata\GUNGAME、Web 版ならブラウザの中に保存される。
## Step 5 でコインと恒久強化もここに足す。

const PATH := "user://save.json"

var best_distance := 0      # 自己ベストの距離（m）
var best_reach := ""        # その時どこまで行けたか（例: 「2 周目 中ボス 1」）


func _ready() -> void:
	load_data()


func load_data() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		best_distance = int(data.get("best_distance", 0))
		best_reach = str(data.get("best_reach", ""))


func save_data() -> void:
	if TestTools.is_test_run():   # 自動テストの記録は本物の自己ベストにしない
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("保存に失敗しました: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify({"best_distance": best_distance, "best_reach": best_reach}))


## ランの結果を渡す。自己ベストを更新したら true
func submit_run(distance: int, reach: String) -> bool:
	if distance <= best_distance:
		return false
	best_distance = distance
	best_reach = reach
	save_data()
	return true


## 1250 → 「1,250」
static func format_distance(m: int) -> String:
	var s := str(m)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
