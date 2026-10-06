extends Node
## ゲームの数値はここだけ触る。コードを書き換えずにバランス調整できるようにする。

# ---- 画面 ----
const SCREEN_W := 540
const SCREEN_H := 960
const SCROLL_SPEED := 220.0          # 地面が流れる速さ。ゲートとアイテムもこの速さで流れてくる
const SPEED_STEPS := [1.0, 1.5, 2.0]  # 倍速ボタンで切り替わる速さ


## ゲームの世界の大きさ。幅はいつも 540（画面が横に広くても中央に寄せて表示する）。高さは端末に合わせて伸びる
func world_size(node: CanvasItem) -> Vector2:
	return Vector2(SCREEN_W, node.get_viewport_rect().size.y)

# ---- プレイヤー ----
const PLAYER_SPEED := 460.0          # 横移動の速さ（px/秒）
const PLAYER_HALF_W := 26.0          # 画面端で止まるための半分の幅
const PLAYER_BOTTOM_MARGIN := 140.0  # 画面下端からプレイヤーまでの距離
const MUZZLE_Y := -36.0              # 弾が出る位置（プレイヤー中心からの上方向）
const PLAYER_MAX_HP := 100
const PLAYER_HIT_RADIUS := 16.0      # やられ判定の大きさ（見た目より小さめ＝やさしめ）
const PLAYER_INVINCIBLE_TIME := 0.8  # ダメージを受けた後の無敵時間（秒）

# ---- 弾 ----
const BULLET_SPACING := 16.0         # 平行に並ぶ弾の間隔
const MAX_BULLETS := 200             # 画面内の弾の上限（スマホの処理落ち対策）
const BOUNCE_SEARCH_RADIUS := 320.0  # 跳弾が次の敵を探す範囲
const BOUNCE_RANGE_BONUS := 160.0    # 跳ねた時に射程を少し回復する量

# ---- 銃 3 種 ----
# barrels: 銃口の横位置の一覧。要素の数だけ「弾のパラメータの組」ができる（二丁拳銃は 2 つ）
# count: 1 回に撃つ弾の数 / damage: 1 発の威力 / fire_rate: 1 秒に撃つ回数
# spread_deg: 0 なら平行に並ぶ、0 より大きければ扇状に広がる角度
# range_px: 弾の届く距離。最初は画面の上端（約 780px 先）まで届かない。
#           伸ばすと画面の上の外にいる「これから来る敵」を見える前に倒せる
const GUNS := {
	"handgun": {
		"label": "HANDGUN",
		"name": "ハンドガン",
		"desc": "弾 1 発\n連射 ふつう\n素直で扱いやすい",
		"barrels": [0.0],
		"colors": [Color(1.0, 0.85, 0.2)],
		"count": 1,
		"damage": 10,
		"fire_rate": 3.0,
		"pierce": 0,
		"bounce": 0,
		"size": 1.0,
		"spread_deg": 0.0,
		"range_px": 560.0,
		"bullet_speed": 900.0,
	},
	"shotgun": {
		"label": "SHOTGUN",
		"name": "ショットガン",
		"desc": "扇状に 3 発\n威力 高い\n届く距離が短い",
		"barrels": [0.0],
		"colors": [Color(1.0, 0.45, 0.35)],
		"count": 3,
		"damage": 14,
		"fire_rate": 1.6,
		"pierce": 0,
		"bounce": 0,
		"size": 1.1,
		"spread_deg": 30.0,
		"range_px": 360.0,
		"bullet_speed": 800.0,
	},
	"dual": {
		"label": "DUAL",
		"name": "二丁拳銃",
		"desc": "左右に 1 丁ずつ\n左右のゲートで\n別々に育つ",
		"barrels": [-16.0, 16.0],
		"colors": [Color(0.3, 0.85, 0.9), Color(0.75, 0.45, 0.95)],
		"count": 1,
		"damage": 7,
		"fire_rate": 3.0,
		"pierce": 0,
		"bounce": 0,
		"size": 0.9,
		"spread_deg": 0.0,
		"range_px": 560.0,
		"bullet_speed": 900.0,
	},
}
const GUN_ORDER := ["handgun", "shotgun", "dual"]
const SHOTGUN_SPREAD_PER_PELLET := 6.0   # ショットガンは弾数 +1 ごとに扇がこれだけ広がる


# ---- 敵 3 種 ----
# hp: 体力 / speed: 下に進む速さ（px/秒） / radius: 当たり判定の半径
# contact_damage: ぶつかった時にプレイヤーが受けるダメージ
const ENEMIES := {
	"walker": {
		"hp": 20, "speed": 130.0, "radius": 22.0, "contact_damage": 20,
		"color": Color(0.35, 0.6, 1.0),
	},
	"tank": {
		"hp": 80, "speed": 70.0, "radius": 34.0, "contact_damage": 35,
		"color": Color(0.55, 0.6, 0.55),
	},
	"shooter": {
		"hp": 30, "speed": 150.0, "radius": 22.0, "contact_damage": 20,
		"color": Color(0.75, 0.4, 0.95),
		"stop_y": 260.0,          # ここで止まって撃つ
		"shoot_delay": 0.7,       # 止まってから撃つまで（予告の時間）
		"after_shot_wait": 0.8,   # 撃った後に止まっている時間
		"bullet_speed": 330.0,
		"bullet_damage": 15,
	},
}

# ---- 敵の出現表 ----
# until: この秒数まで / interval: 何秒ごとに 1 体出すか / weights: 種類ごとの出やすさ
# 中ボス・大ボスの周回は Step 4。それまでは最後の行が続く
const WAVES := [
	{"until": 15.0, "interval": 1.0, "weights": {"walker": 1}},
	{"until": 35.0, "interval": 0.8, "weights": {"walker": 3, "tank": 1}},
	{"until": 99999.0, "interval": 0.65, "weights": {"walker": 3, "tank": 1, "shooter": 1}},
]
# 敵が出てくる列（画面の幅に対する割合）。左・中央・右の 3 列
const LANES := [1.0 / 6.0, 0.5, 5.0 / 6.0]
# 敵は画面の上端よりこれだけ上（画面の外）で生まれる。射程が長いと見える前に倒せる
const SPAWN_AHEAD := 520.0

# ---- 最初のアイテム（銃を決める箱） ----
const GIFT_FALL_SPEED := 220.0
const GIFT_RADIUS := 26.0

# ---- 道中のアイテム（本家と同じ「+1」単位） ----
# 「+1」で実際にどれだけ上がるか
const ITEM_STEP := {
	"damage": 1,          # 威力 +1
	"range": 40.0,        # 射程 +1 = 40px
	"speed": 60.0,        # 弾速 +1 = 60px/秒
	"rate": 0.25,         # 連射 +1 = 1 秒あたり 0.25 回
}
const ITEMS := {
	"heart":  {"label": "回復",   "weight": 2, "color": Color(1.0, 0.35, 0.45)},
	"damage": {"label": "威力+1", "weight": 2, "color": Color(1.0, 0.55, 0.15)},
	"range":  {"label": "射程+1", "weight": 2, "color": Color(0.3, 0.75, 0.4)},
	"speed":  {"label": "弾速+1", "weight": 1, "color": Color(0.3, 0.6, 1.0)},
	"rate":   {"label": "連射+1", "weight": 1, "color": Color(0.75, 0.45, 0.95)},
	"coin":   {"label": "コイン", "weight": 4, "color": Color(1.0, 0.82, 0.2)},
}
const ITEM_FIRST := 3.0              # 最初のアイテムが出る秒
const ITEM_INTERVAL := 2.5           # 何秒ごとに 1 個流れてくるか
const ITEM_RADIUS := 24.0
# タンクが必ず落とすアイテムの出やすさ（コインは出ない）
const TANK_DROP_WEIGHTS := {"heart": 2, "damage": 2, "range": 2, "speed": 1, "rate": 1}
# ハートの回復量は進むほど大きくなる: 基本 + 1 分ごとの増加
const HEART_HEAL_BASE := 10
const HEART_HEAL_PER_MIN := 15

# ---- ゲート（弾の「形」を変える 2 択） ----
const GATES := {
	"count_up":   {"label": "弾数\n+1",   "good": true,  "weight": 5},
	"pierce":     {"label": "貫通\n+1",   "good": true,  "weight": 3},
	"bounce":     {"label": "跳弾\n+1",   "good": true,  "weight": 2},
	"size":       {"label": "巨大弾",     "good": true,  "weight": 2},
	"count_down": {"label": "弾数\n-1",   "good": false, "weight": 3},
	"range_down": {"label": "射程\n-2",   "good": false, "weight": 2},
}
const GATE_FIRST := 5.0              # 最初のゲートが出る秒
const GATE_INTERVAL := 9.0           # 何秒ごとにゲートが来るか
const GATE_BAD_CHANCE := 0.3         # 片方が悪いゲートになる確率
const GATE_HEIGHT := 76.0
const MIN_RANGE := 120.0             # 射程はこれより短くならない
