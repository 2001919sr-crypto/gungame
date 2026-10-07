extends Node
## テスト用の起動オプション（「-- 」の後ろに付ける）。どの画面でも使えるよう、ここにまとめる。
##   --autopick=handgun  タイトルを飛ばし、銃とボスのご褒美を自動で選ぶ
##   --shot=保存先.png   画面写真を撮って終了（--shotat=秒 で時刻を指定。既定 5 秒）
##   --zakotime=秒       雑魚区間の長さを変える（ボスを早く確かめたい時）
##   --dieat=秒          この秒数でわざと倒れる（リザルト画面の確認用）
##   --openreward=mid    ご褒美の 3 択をすぐ出す（big も可）
##   --skiptitle         タイトルを飛ばす（銃を選ぶ画面の確認用）
##   --godmode           やられない（1 周を通しで確かめる時）
##   --openpause / --debuglog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_screenshot()


func value(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


## 自動で遊ぶテスト中か（この時は保存しない）
func is_test_run() -> bool:
	return value("--autopick=") != ""


func has(flag: String) -> bool:
	return flag in OS.get_cmdline_user_args()


## 一時停止中でも動くタイマーを使う。画面が切り替わっても撮れる
func _setup_screenshot() -> void:
	var path := value("--shot=")
	if path == "":
		return
	var at := value("--shotat=")
	await get_tree().create_timer(5.0 if at == "" else float(at), true, false, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
