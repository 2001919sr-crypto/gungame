class_name WeaponState
extends RefCounted
## 「弾のパラメータの組」。銃 1 丁ぶんの状態。
## ゲートやアイテムはこの数値を書き換えるだけで効果を出す。ペットもこれを使う。

var label := ""
var count := 1            # 1 回に撃つ弾の数
var damage := 10          # 1 発の威力
var fire_rate := 3.0      # 1 秒に撃つ回数
var pierce := 0           # 貫通できる敵の数
var bounce := 0           # 当たった後に近くの敵へ跳ねる回数
var size := 1.0           # 弾の大きさ倍率
var spread_deg := 0.0     # 扇状に広がる角度（0 なら平行）
var range_px := 560.0     # 届く距離
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


## アイテムの効果（「+1」を steps 回ぶん）。中ボスの「+10」も steps=10 で使える
func apply_item(kind: String, steps: int = 1) -> void:
	match kind:
		"damage":
			damage += Config.ITEM_STEP["damage"] * steps
		"range":
			range_px += Config.ITEM_STEP["range"] * steps
		"speed":
			bullet_speed += Config.ITEM_STEP["speed"] * steps
		"rate":
			fire_rate += Config.ITEM_STEP["rate"] * steps


## ゲートの効果（弾の形を変える）
func apply_gate(kind: String) -> void:
	match kind:
		"count_up":
			count += 1
			if spread_deg > 0.0:
				spread_deg += Config.SHOTGUN_SPREAD_PER_PELLET
		"count_down":
			if count > 1:
				count -= 1
				if spread_deg > 0.0:
					spread_deg = maxf(spread_deg - Config.SHOTGUN_SPREAD_PER_PELLET, 12.0)
		"pierce":
			pierce += 1
		"bounce":
			bounce += 1
		"size":
			size += 0.3
		"range_down":
			range_px = maxf(range_px - Config.ITEM_STEP["range"] * 2.0, Config.MIN_RANGE)


## 画面に出す短い説明
func summary() -> String:
	return "威力%d 射程%d 弾速%d 連射%.2f 弾数%d 貫通%d 跳弾%d" % [
		damage, range_px, bullet_speed, fire_rate, count, pierce, bounce]
