extends Node
## ゲームの数値はここだけ触る。コードを書き換えずにバランス調整できるようにする。

# ---- 画面 ----
const SCREEN_W := 540
const SCREEN_H := 960

# ---- プレイヤー ----
const PLAYER_SPEED := 460.0          # 横移動の速さ（px/秒）
const PLAYER_HALF_W := 26.0          # 画面端で止まるための半分の幅
const PLAYER_BOTTOM_MARGIN := 140.0  # 画面下端からプレイヤーまでの距離
const MUZZLE_Y := -36.0              # 弾が出る位置（プレイヤー中心からの上方向）

# ---- 弾 ----
const BULLET_SPACING := 16.0         # 平行に並ぶ弾の間隔
const MAX_BULLETS := 200             # 画面内の弾の上限（スマホの処理落ち対策）

# ---- 銃 3 種 ----
# barrels: 銃口の横位置の一覧。要素の数だけ「弾のパラメータの組」ができる（二丁拳銃は 2 つ）
# count: 1 回に撃つ弾の数 / damage: 1 発の威力 / fire_rate: 1 秒に撃つ回数
# spread_deg: 0 なら平行に並ぶ、0 より大きければ扇状に広がる角度
# range_px: 0 なら画面外まで届く、0 より大きければその距離で消える
const GUNS := {
	"handgun": {
		"label": "HANDGUN",
		"barrels": [0.0],
		"colors": [Color(1.0, 0.85, 0.2)],
		"count": 1,
		"damage": 10,
		"fire_rate": 3.0,
		"pierce": 0,
		"bounce": 0,
		"size": 1.0,
		"spread_deg": 0.0,
		"range_px": 0.0,
		"bullet_speed": 900.0,
	},
	"shotgun": {
		"label": "SHOTGUN",
		"barrels": [0.0],
		"colors": [Color(1.0, 0.45, 0.35)],
		"count": 3,
		"damage": 14,
		"fire_rate": 1.6,
		"pierce": 0,
		"bounce": 0,
		"size": 1.1,
		"spread_deg": 30.0,
		"range_px": 420.0,
		"bullet_speed": 800.0,
	},
	"dual": {
		"label": "DUAL",
		"barrels": [-16.0, 16.0],
		"colors": [Color(0.3, 0.85, 0.9), Color(0.75, 0.45, 0.95)],
		"count": 1,
		"damage": 7,
		"fire_rate": 3.0,
		"pierce": 0,
		"bounce": 0,
		"size": 0.9,
		"spread_deg": 0.0,
		"range_px": 0.0,
		"bullet_speed": 900.0,
	},
}
const GUN_ORDER := ["handgun", "shotgun", "dual"]
