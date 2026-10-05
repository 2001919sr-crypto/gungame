class_name WeaponState
extends RefCounted
## 「弾のパラメータの組」。銃 1 丁ぶんの状態。
## ゲートやアイテムはこの数値を書き換えるだけで効果を出す。ペットもこれを使う。

var label := ""
var count := 1            # 1 回に撃つ弾の数
var damage := 10          # 1 発の威力
var fire_rate := 3.0      # 1 秒に撃つ回数
var pierce := 0           # 貫通できる敵の数
var bounce := 0           # 壁で跳ね返る回数
var size := 1.0           # 弾の大きさ倍率
var spread_deg := 0.0     # 扇状に広がる角度（0 なら平行）
var range_px := 0.0       # 届く距離（0 なら画面外まで）
var bullet_speed := 900.0
var color := Color.WHITE
var offset_x := 0.0       # 銃口の横位置
var cooldown := 0.0       # 次に撃てるまでの残り秒


static func from_gun(def: Dictionary, barrel_index: int) -> WeaponState:
	var w := WeaponState.new()
	w.label = def["label"]
	w.count = def["count"]
	w.damage = def["damage"]
	w.fire_rate = def["fire_rate"]
	w.pierce = def["pierce"]
	w.bounce = def["bounce"]
	w.size = def["size"]
	w.spread_deg = def["spread_deg"]
	w.range_px = def["range_px"]
	w.bullet_speed = def["bullet_speed"]
	w.offset_x = def["barrels"][barrel_index]
	var colors: Array = def["colors"]
	w.color = colors[barrel_index % colors.size()]
	return w
