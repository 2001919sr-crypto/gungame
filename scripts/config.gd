extends Node
## ゲームの数値はここだけ触る。コードを書き換えずにバランス調整できるようにする。

# ---- 画面 ----
const SCREEN_W := 540
const SCREEN_H := 960
const SCROLL_SPEED := 220.0          # 地面が流れる速さ。ゲートと落ちたアイテムもこの速さで流れてくる
const SPEED_STEPS := [1.0, 1.5, 2.0]  # 倍速ボタンで切り替わる速さ


## ゲームの世界の大きさ。幅はいつも 540（画面が横に広くても中央に寄せて表示する）。高さは端末に合わせて伸びる
func world_size(node: CanvasItem) -> Vector2:
	return Vector2(SCREEN_W, node.get_viewport_rect().size.y)

# ---- プレイヤー ----
const PLAYER_SPEED := 460.0          # 横移動の速さ（px/秒）
const PLAYER_HALF_W := 26.0          # 画面端で止まるための半分の幅
const PLAYER_BOTTOM_MARGIN := 140.0  # 画面下端からプレイヤーまでの距離
const MUZZLE_Y := -36.0              # 弾が出る位置（プレイヤー中心からの上方向）
const PLAYER_START_HP := 100         # 最初の体力。上限はない（与えたダメージの吸収でどこまでも増える）
const LIFESTEAL_START := 0.05        # 与えたダメージのうち体力に戻る割合（5%）
const PLAYER_HIT_RADIUS := 16.0      # やられ判定の大きさ（見た目より小さめ＝やさしめ）
const PLAYER_INVINCIBLE_TIME := 0.8  # ダメージを受けた後の無敵時間（秒）

# ---- 弾 ----
const BULLET_SPACING := 16.0         # 平行に並ぶ弾の間隔
const MAX_BULLETS := 1000            # 画面内の弾の上限（安全柵。Web 公開後に実機で測って決める）
const VOLLEY_CAP := 40               # 1 回に撃つ弾は 1 丁あたりここまで。超えた分は 1 発の威力に上乗せ
const MAX_POWER_SIZE := 2.0          # 上乗せで弾が大きくなる上限（倍率）
const MAX_SPREAD_DEG := 110.0        # 扇の広がりの上限

# ---- 銃 3 種 ----
# barrels: 銃口の横位置の一覧。要素の数だけ「弾のパラメータの組」ができる（今の 3 種はすべて 1 つ）
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
		"size": 1.1,
		"spread_deg": 30.0,
		"range_px": 360.0,
		"bullet_speed": 800.0,
	},
	# 威力・射程・貫通が少し強い代わりに連射が遅い（1 秒あたりのダメージはハンドガンとほぼ同じ）
	"sniper": {
		"label": "SNIPER",
		"name": "スナイパー",
		"desc": "敵 2 体を貫通\n遠くまで届く\n連射 遅い",
		"barrels": [0.0],
		"colors": [Color(0.3, 0.85, 0.9)],
		"long_barrel": true,   # 見た目: 長い銃身とスコープ
		"count": 1,
		"damage": 14,
		"fire_rate": 2.2,
		"pierce": 1,
		"size": 0.85,
		"spread_deg": 0.0,
		"range_px": 700.0,
		"bullet_speed": 1300.0,
	},
}
const GUN_ORDER := ["handgun", "shotgun", "sniper"]
const SHOTGUN_SPREAD_PER_PELLET := 6.0   # ショットガンは弾数 +1 ごとに扇がこれだけ広がる


# ---- 敵 3 種 ----
# hp: 体力 / speed: 下に進む速さ（px/秒） / size: 当たり判定の四角（幅は列 180px いっぱい近く）
# contact_damage: ぶつかった時にプレイヤーが受けるダメージ
const ENEMIES := {
	"walker": {
		"hp": 20, "speed": 130.0, "size": Vector2(150, 64), "contact_damage": 20,
		"color": Color(0.35, 0.6, 1.0),
	},
	"tank": {
		"hp": 80, "speed": 70.0, "size": Vector2(160, 110), "contact_damage": 35,
		"color": Color(0.55, 0.6, 0.55),
	},
	"shooter": {
		"hp": 30, "speed": 150.0, "size": Vector2(140, 80), "contact_damage": 20,
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
# 時間は「雑魚区間にいた時間の合計」で数える（ボス戦の間は進まない）
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

# ---- 敵が落とすアイテム（本家と同じ「+1」単位） ----
# 敵は倒されると必ず 1 個落とす。道中に流れてくるアイテムはない。回復は吸収だけ（ハートはない）
# 「+1」で実際にどれだけ上がるか
const ITEM_STEP := {
	"damage": 1,          # 威力 +1
	"range": 40.0,        # 射程 +1 = 40px
	"speed": 60.0,        # 弾速 +1 = 60px/秒
	"rate": 0.25,         # 連射 +1 = 1 秒あたり 0.25 回
}
# weight: 落とす時の出やすさ
const ITEMS := {
	"damage": {"label": "威力+1", "weight": 2, "color": Color(1.0, 0.55, 0.15)},
	"range":  {"label": "射程+1", "weight": 2, "color": Color(0.3, 0.75, 0.4)},
	"speed":  {"label": "弾速+1", "weight": 1, "color": Color(0.3, 0.6, 1.0)},
	"rate":   {"label": "連射+1", "weight": 1, "color": Color(0.75, 0.45, 0.95)},
	"coin":   {"label": "コイン", "weight": 3, "color": Color(1.0, 0.82, 0.2)},
}
const ITEM_RADIUS := 24.0

# ---- ゲート（弾の「形」を変える 2 択） ----
const GATES := {
	"count_up":   {"label": "弾数\n+1",   "good": true,  "weight": 5},
	"pierce":     {"label": "貫通\n+1",   "good": true,  "weight": 3},
	"size":       {"label": "巨大弾",     "good": true,  "weight": 2},
	"count_down": {"label": "弾数\n-1",   "good": false, "weight": 3},
	"range_down": {"label": "射程\n-2",   "good": false, "weight": 2},
}
const GATE_FIRST := 5.0              # 最初のゲートが出る秒
const GATE_INTERVAL := 9.0           # 何秒ごとにゲートが来るか
const GATE_BAD_CHANCE := 0.3         # 片方が悪いゲートになる確率
const GATE_HEIGHT := 76.0
const MIN_RANGE := 120.0             # 射程はこれより短くならない

# ---- 周回とボス ----
# 1 周 = 雑魚 → 中ボス → 雑魚 → 中ボス → 雑魚 → 大ボス。死ぬまで繰り返す
const LAP_STAGES := ["zako", "mid", "zako", "mid", "zako", "big"]
const ZAKO_SECTION_TIME := 30.0      # 雑魚区間 1 つの長さ（秒）
const BOSS_WARNING_TIME := 3.0       # 雑魚が止まってからボスが出るまで（予告の時間）
const REWARD_DELAY := 1.0            # ボスを倒してからご褒美の 3 択が出るまで
const HP_MULT_MID := 1.2             # 中ボスを倒すたびに敵の体力がこの倍率で増える（掛け算で重なる）
const HP_MULT_BIG := 1.5             # 大ボスを倒すたびに
const DISTANCE_PER_SEC := 10.0       # スコア（進んだ距離）: 1 秒 = 10m
const BOSS_ENTER_SPEED := 140.0      # 大ボスが上から降りてくる速さ
const BOSS_MAX_Y := 520.0            # 大ボスが射程の短い銃に合わせて下がってくる限界
const BOSS_WIDTH := 510.0            # ボスは横幅いっぱい（避けられない）
const CRUSH_DAMAGE_RATE := 0.2       # ボスに着かれた時のダメージ = ボスの残り体力 × この割合。ボスは消える

# 中ボス: 雑魚と同じ速さで画面の上の外から降りてくる。弾は撃たない。着かれる前に倒しきる
# 大ボス: 第 1 段階は上に居座って扇形にばらまく。体力 50% 以下で赤くなり、速く降りてくる
# size: 当たり判定の四角の大きさ / coins: 倒した時のコイン
const BOSSES := {
	"mid": {
		"name": "中ボス", "hp": 400, "size": Vector2(BOSS_WIDTH, 90), "contact_damage": 30,
		"color": Color(0.95, 0.5, 0.25), "coins": 10,
		"speed": 130.0,           # 降りてくる速さ（ウォーカーと同じ）
	},
	"big": {
		"name": "大ボス", "hp": 4000, "size": Vector2(BOSS_WIDTH, 120), "contact_damage": 40,
		"color": Color(0.55, 0.4, 0.9), "rage_color": Color(0.92, 0.25, 0.25), "hover_y": 180.0, "coins": 30,
		"fire_interval": 1.3, "fan": 5, "fan_deg": 70.0,
		"rage_fire_interval": 1.7, "rage_fan": 3,
		"bullet_speed": 280.0, "bullet_damage": 15,
		"charge_speed": 90.0,     # 第 2 段階で降りてくる速さ（px/秒）
	},
}

# ---- ボスのご褒美（3 択） ----
# 中ボス: アイテム +1 の 10 個分（吸収だけは +5%）。毎回この中からランダムに 3 つ
const REWARD_LIFESTEAL_STEP := 0.05
const REWARD_MID_STEPS := 10
const REWARDS_MID := {
	"damage": {"name": "威力 +10", "badge": "+10", "desc": "1 発の威力が\n10 上がる", "color": Color(1.0, 0.55, 0.15)},
	"range":  {"name": "射程 +10", "badge": "+10", "desc": "弾が\nずっと遠くまで\n届く", "color": Color(0.3, 0.75, 0.4)},
	"speed":  {"name": "弾速 +10", "badge": "+10", "desc": "弾が\nとても速くなる", "color": Color(0.3, 0.6, 1.0)},
	"rate":   {"name": "連射 +10", "badge": "+10", "desc": "撃つ間隔が\nぐっと短くなる", "color": Color(0.75, 0.45, 0.95)},
	"lifesteal": {"name": "吸収 +5%", "badge": "+5%", "desc": "与えたダメージの\n回復する割合が\n5% 上がる", "color": Color(1.0, 0.35, 0.45)},
}
# 大ボス: ×2。いつもこの 3 つ（並び順はランダム）
const REWARDS_BIG := {
	"damage": {"name": "威力 ×2", "badge": "×2", "desc": "1 発の威力が\n2 倍", "color": Color(1.0, 0.55, 0.15)},
	"rate":   {"name": "連射 ×2", "badge": "×2", "desc": "撃つ回数が\n2 倍", "color": Color(0.75, 0.45, 0.95)},
	"count":  {"name": "弾数 ×2", "badge": "×2", "desc": "1 回に撃つ弾が\n2 倍", "color": Color(1.0, 0.82, 0.2)},
}
const REWARD_CHOICES := 3
