# GunGame 公開までの手順書（Windows + Claude Code）

最終更新: 2026-10-05（情報の確認日も同じ）
対象: 作者本人。「手順書のフェーズ 2 を進めて」と Claude Code に頼めば、そのまま作業できる粒度で書いてある。
前提: PC には何も入っていない Windows 11。VS Code と Claude Code だけがある。

---

## この手順書の読み方

| 記号 | 意味 |
|---|---|
| 🤖 | Claude Code がコマンドで実行できる。あなたは「やって」と頼むだけ |
| 🧑 | あなたが自分の手で行う（アカウント登録、支払い、本人確認、スマホの操作、画面の「はい」を押す） |
| 💰 | お金がかかる |
| ⚠️ | 初心者がつまずきやすい |

原則: **コードと設定ファイルは全部 Claude Code が書く。あなたがするのは「アカウント」「お金」「スマホを触る」「遊んで感想を言う」の 4 つ。**
変わりやすい情報（バージョン番号、ストアのルール）は第 9 章に出典つきでまとめた。作業前にそこを見直す。

---

## 0. 全体の流れ

```
フェーズ 0  PC の準備                 半日          💰 0 円
    ↓
フェーズ 1  ゲームを作る             1〜2 週間      💰 0 円
    ↓
フェーズ 2  Web 版を公開             半日          💰 0 円   ← ここで初めて人に遊んでもらえる
    ↓
フェーズ 3  Android の実機で動かす   半日〜1 日     💰 0 円
    ↓
フェーズ 4  Google Play で公開       作業 2〜3 日 + 待ち 3〜6 週間   💰 25 ドル（一度だけ）
    ↓
フェーズ 5  （後日）App Store        Mac で作業     💰 年間 99 ドル
```

| フェーズ | 終わると何ができるか | Claude Code でできる割合 |
|---|---|---|
| 0 | `godot_console --version` が通る | ほぼ全部（UAC の「はい」とログインだけ 🧑） |
| 1 | PC でゲームが遊べる | コードは全部 🤖。遊んで感想を言うのは 🧑 |
| 2 | URL をスマホで開くと遊べる | 全部 🤖 |
| 3 | 自分の Android に入れて遊べる | 設定は 🤖。スマホ側の操作は 🧑 |
| 4 | Google Play に並ぶ | 素材・文章・ビルドは 🤖。登録・支払い・入力・テスター集めは 🧑 |

**一番時間がかかるのは「テスター 12 人を 14 日間」です。** フェーズ 2 で Web 版を公開した時点から募集を始めてください。

---

## フェーズ 0: PC の準備

### 0-1 入れるものの一覧

| ツール | 何のため | 入れ方 | 誰が | いつ |
|---|---|---|---|---|
| Git | 変更履歴の保存、GitHub へのアップロード | winget | 🤖 | 今 |
| GitHub CLI（gh） | Claude Code から GitHub を操作 | winget | 🤖（ログインだけ 🧑） | 今 |
| Godot 4.7.2 | ゲームエンジン本体 | zip を展開 | 🤖 | 今 |
| Godot エクスポートテンプレート | Web / Android 用に書き出す部品 | tpz を展開 | 🤖 | 今 |
| Python 3 | Web 版をローカルで試す簡易サーバー | winget | 🤖 | フェーズ 2 |
| OpenJDK 17 | Android 書き出しに必要 | winget | 🤖（UAC 🧑） | フェーズ 3 |
| Android SDK コマンドラインツール | Android 書き出しに必要 | zip + sdkmanager | 🤖 | フェーズ 3 |

ディスク容量: 全部入れると約 8GB（Android SDK と NDK が大きい）。

### 0-2 Git と GitHub CLI 🤖

```powershell
winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
```

⚠️ 入れた直後は VS Code を一度閉じて開き直す。そうしないと `git` コマンドが見つからない（PATH の反映）。
補足: Claude Code 自体が Git を必要とするので、Git はすでに入っていることが多い。先に `git --version` と `gh --version` で確認する。

続いて 🧑 GitHub のアカウントを作り（無料）、🧑 VS Code のターミナルで `gh auth login` を実行。質問には Enter で答え、ブラウザが開いたらログインを許可する。ログインはあなたの操作が必要なので Claude Code には任せられない。すでにログイン済みかは 🤖 `gh auth status` で分かる。
🤖 名前とメールを登録:

```powershell
git config --global user.name "あなたの表示名"
git config --global user.email "GitHub に登録したメール"
```

### 0-3 Godot 本体 🤖

winget でも入るが、**zip を決まった場所に置く方が後が楽**（コマンドから呼びやすい、バージョンを固定できる）。

```powershell
New-Item -ItemType Directory -Force C:\Godot
Invoke-WebRequest "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip" -OutFile "$env:TEMP\godot.zip"
Expand-Archive "$env:TEMP\godot.zip" -DestinationPath C:\Godot -Force
Copy-Item C:\Godot\Godot_v4.7.2-stable_win64.exe         C:\Godot\godot.exe
Copy-Item C:\Godot\Godot_v4.7.2-stable_win64_console.exe C:\Godot\godot_console.exe
# ユーザーの PATH に追加
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";C:\Godot", "User")
```

VS Code を再起動してから確認: `godot_console --version` → `4.7.2.stable.official.xxxxxxx` と出れば OK。

⚠️ **exe が 2 つある理由**: `godot.exe` は画面を出す用、`godot_console.exe` はターミナルに結果を表示する用。
Claude Code はエラーを読む必要があるので **常に console 版を使う**。あなたがエディタを開きたい時は `godot.exe`。

### 0-4 エクスポートテンプレート 🤖

書き出し（Web / Android）に必要な部品。約 1GB。

```powershell
$v = "4.7.2"
Invoke-WebRequest "https://github.com/godotengine/godot-builds/releases/download/$v-stable/Godot_v$v-stable_export_templates.tpz" -OutFile "$env:TEMP\templates.tpz"
Copy-Item "$env:TEMP\templates.tpz" "$env:TEMP\templates.zip"          # tpz は中身が zip
Expand-Archive "$env:TEMP\templates.zip" -DestinationPath "$env:TEMP\templates_x" -Force
$dest = "$env:APPDATA\Godot\export_templates\$v.stable"               # フォルダ名は 4.7.2.stable
New-Item -ItemType Directory -Force $dest
Copy-Item "$env:TEMP\templates_x\templates\*" $dest -Recurse -Force
```

確認: `$dest` の中に `web_nothreads_release.zip` と `android_release.apk` があれば OK。
うまくいかない時の逃げ道 🧑: Godot エディタを開き、メニュー「エディター → エクスポートテンプレートの管理 → ダウンロードしてインストール」。

### 0-5 Claude Code 側の準備（任意）🤖

`godot_console`、`git`、`gh`、`adb` を毎回許可しなくて済むように、プロジェクトの `.claude/settings.json` に許可リストを追加できる。頼めば Claude Code が設定する。

---

## フェーズ 1: ゲームを作る

### 1-1 プロジェクト作成 🤖

Claude Code が `project.godot` 以下を作る。最初に必ず入れる設定:

| 設定 | 値 | 理由 |
|---|---|---|
| 基準解像度 | 540 × 960 | 縦画面のスマホ基準 |
| 画面の向き | Portrait（縦）固定 | |
| 拡大縮小 | stretch mode = canvas_items、aspect = expand | 縦長の端末でも上下に広げて対応 |
| レンダラー | **Compatibility（gl_compatibility）** | ⚠️ Web 書き出しはこれ以外動かない。スマホでも軽い |
| マウスでタッチを模倣 | ON（emulate_touch_from_mouse） | PC でスマホ操作の確認ができる |
| テクスチャフィルタ | Nearest | ドット絵がぼやけない |

作ったら 🧑 一度 `godot .`（または `project.godot` をダブルクリック）でエディタを開く。初回の取り込み（インポート）が走り、必要なファイルが生成される。開いて閉じるだけでよい。

### 1-2 毎日の開発ループ

```
Claude Code がコードを書く
  → 🤖 godot_console --headless --path . --quit        （起動時エラーがないか確認）
  → 🤖 godot_console --path .                          （ゲームの窓が開く）
  → 🧑 遊ぶ。感想を一言（「弾が遅い」「敵が硬い」でよい）
  → Claude Code が直す
  → 🤖 git add -A ; git commit -m "Step1: 左右移動と自動射撃"
```

- 画像や音を追加した後は 🤖 `godot_console --headless --path . --import` で取り込み直す
- バランス調整は `scripts/config.gd` の数値だけ。コードは触らない
- Godot エディタを開く必要は基本ない。「画面の見た目を直接見たい」「原因不明のエラー」の時だけ使う

### 1-3 作る順番

[GAME_DESIGN.md](GAME_DESIGN.md) 第 6 章の Step 1〜5 の通り。
⚠️ **Step 2 が終わったら、一度フェーズ 2 の Web 書き出しを試す。** 書き出しの問題は早く見つけるほど楽。

### 1-4 Git の運用 🤖

- 最初のコミット前に `.gitignore` を作る。入れないもの: `.godot/`、`build/`、`android/`、`export_credentials.cfg`、`*.keystore`
- GitHub にリポジトリを作る: `gh repo create gungame --public --source . --push`
  ⚠️ 無料プランの GitHub Pages は **公開（public）リポジトリのみ**。非公開にしたい場合は Web 版だけ別の公開リポジトリに置く
- 各 Step の終わりにコミット。「どこまで動いたか」が履歴に残り、ブログの材料になる

---

## フェーズ 2: Web 版を公開（費用 0 円）

### 2-1 書き出し設定 🤖

Claude Code が `export_presets.cfg` に「Web」プリセットを作る。重要な設定:

| 設定 | 値 | 理由 |
|---|---|---|
| Thread Support | **OFF** | ⚠️ ON だと iPhone の Safari で動かず、GitHub Pages でも特別なヘッダーが必要になる |
| Extensions Support | OFF | 同上 |
| Progressive Web App | 最初は OFF | ON にすると更新が反映されにくくなることがある。慣れてから |
| Canvas Resize Policy | Adaptive | 画面いっぱいに表示 |
| 出力先 | `build/web/index.html` | |

### 2-2 書き出しとローカル確認 🤖

```powershell
New-Item -ItemType Directory -Force build/web | Out-Null     # ⚠️ Godot は出力先フォルダを作ってくれない
godot_console --headless --path . --export-release "Web" build/web/index.html
```

`build/web/` に `index.html`、`index.js`、`index.wasm`、`index.pck` などができる。
元のサイズは 40MB 前後だが、GitHub Pages が自動で圧縮するので実際の読み込みは 10MB 前後。スマホで初回 10〜30 秒。

ローカルで試す（初回のみ `winget install --id Python.Python.3.12 -e`）:

```powershell
python -m http.server 8060 --directory build/web
```

PC のブラウザで `http://localhost:8060`。スマホで試すなら同じ Wi-Fi につないで `http://<PC の IP アドレス>:8060`（IP は `ipconfig` で見る。Windows のファイアウォールの許可ダイアログは 🧑「許可」）。

### 2-3 GitHub Pages に公開 🤖

Claude Code が `tools/publish_web.ps1` を作る。中身の流れ:

1. `build/web` フォルダを作ってから Web 書き出し（2-2 のコマンド）
2. `build/web/.nojekyll` を置く（空ファイル。GitHub の加工を止める）
3. `gh-pages` ブランチの作業フォルダに `build/web` の中身をコピー
4. `git add` → `commit` → `push origin gh-pages`

以後、公開は **「publish_web を実行して」と頼むだけ**。

Pages を有効にする（初回のみ）: GitHub のリポジトリ → Settings → Pages → Source を「Deploy from a branch」、Branch を `gh-pages` / `(root)` 🧑。コマンドでも可 🤖:

```powershell
'{"source":{"branch":"gh-pages","path":"/"}}' | gh api -X POST repos/<GitHub ユーザー名>/gungame/pages --input -
```

公開 URL: `https://<GitHub ユーザー名>.github.io/gungame/`（反映に 1〜2 分）。

### 2-4 スマホで確認 🧑

- Android の Chrome と iPhone の Safari で URL を開く
- 「ホーム画面に追加」でアプリのように起動できる
- この URL を X やブログに貼れば、今日から遊んでもらえる。**ここでテスター募集の告知も始める**

別の置き場所: itch.io（🧑 `build/web` を zip にしてアップロード。ゲーム好きに見つけてもらいやすい）。両方に置いてもよい。

---

## フェーズ 3: Android の実機で動かす（費用 0 円）

### 3-1 OpenJDK 17 🤖（UAC の「はい」は 🧑）

```powershell
winget install --id Microsoft.OpenJDK.17 -e --accept-source-agreements --accept-package-agreements
```

VS Code 再起動後に `java -version` で `17.x` と出れば OK。
`$env:JAVA_HOME` が空なら設定する（インストール先は `C:\Program Files\Microsoft\jdk-17.0.xx-hotspot`。Claude Code が探して設定する）。

### 3-2 Android SDK 🤖

Android Studio は入れない。コマンドラインツールだけで足りる。

```powershell
New-Item -ItemType Directory -Force C:\Android\cmdline-tools
# ファイル名の数字（15859902）は更新で変わる。第 9 章のリンクで最新を確認
Invoke-WebRequest "https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip" -OutFile "$env:TEMP\cmdtools.zip"
Expand-Archive "$env:TEMP\cmdtools.zip" -DestinationPath "$env:TEMP\cmdtools_x" -Force
Move-Item "$env:TEMP\cmdtools_x\cmdline-tools" "C:\Android\cmdline-tools\latest"   # ⚠️ latest という名前のフォルダに入れる決まり

$sdkm = "C:\Android\cmdline-tools\latest\bin\sdkmanager.bat"
# ライセンス同意（y を連打する代わり）
1..30 | ForEach-Object { "y" } | & $sdkm --sdk_root=C:\Android --licenses
# Godot 4.7 の公式ドキュメントが指定する部品
& $sdkm --sdk_root=C:\Android "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"
# Google Play の 2026 年要件（Android 16 = API 36）向けに追加
& $sdkm --sdk_root=C:\Android "platforms;android-36" "build-tools;36.0.0"
# adb を PATH に追加
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";C:\Android\platform-tools", "User")
```

数 GB のダウンロード。10〜30 分かかる。

### 3-3 Godot にパスを教える 🤖

エディタ設定ファイル `%APPDATA%\Godot\editor_settings-4.7.tres`（エディタを一度開くと作られる。名前の数字はバージョンで変わる）に追記:

```
export/android/java_sdk_path = "C:/Program Files/Microsoft/jdk-17.0.xx-hotspot"
export/android/android_sdk_path = "C:/Android"
```

（区切りはスラッシュ `/`）。GUI なら 🧑 エディター → エディター設定 → Export → Android。

デバッグ用の鍵（debug keystore）は未設定なら Godot が書き出し時に自動生成する。もし「keystore が無い」と言われたら手動で作る 🤖:

```powershell
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore "$env:APPDATA\Godot\debug.keystore" -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

そして `export/android/debug_keystore`、`debug_keystore_user = "androiddebugkey"`、`debug_keystore_pass = "android"` を同じ設定ファイルに追記。

### 3-4 Android の書き出し設定 🤖

`export_presets.cfg` に 2 つのプリセットを作る。

| プリセット名 | 形式 | 用途 |
|---|---|---|
| `Android APK` | APK | 自分のスマホに入れて試す |
| `Android AAB` | AAB | Google Play に提出する（Play は AAB 必須） |

共通の重要設定:

| 設定 | 値 | 理由 |
|---|---|---|
| Use Gradle Build | ON | AAB と API 36 対応に必要 |
| Target SDK | 36（Godot 4.7 の既定値） | ⚠️ 2026-08-31 以降、Google Play の新規アプリは API 36 以上が必須 |
| Min SDK | 既定（24） | Android 7.0 以上 |
| Unique Name（パッケージ名） | `jp.<あなたの名前>.gungame` のような形 | ⚠️ 世界で唯一。小文字と `.` のみ。**公開後は変更不可**。`com.example` は使えない |
| Version Code | 1 から。提出ごとに +1 | ⚠️ 同じ番号は 2 度アップロードできない |
| Version Name | `0.1.0` など | 人が読む版番号 |
| Architectures | arm64-v8a のみ ON | Play は 64bit 必須。32bit を外すと小さくなる |

Gradle ビルド用のテンプレートを入れる（初回のみ）:

```powershell
godot_console --headless --path . --install-android-build-template
```

`android/build/` フォルダができる。⚠️ Git には入れない（1-4 の .gitignore）。
初回の Gradle ビルドはネットから部品を落とすので 5〜15 分かかる。2 回目以降は 1〜2 分。

### 3-5 スマホに入れる

🧑 スマホ側（一度だけ）: 設定 → デバイス情報 → 「ビルド番号」を 7 回タップ → 開発者向けオプション → **USB デバッグ ON**。USB で PC につなぎ、スマホに出る「USB デバッグを許可しますか」で許可。

🤖 PC 側:

```powershell
New-Item -ItemType Directory -Force build/android | Out-Null
adb devices                                    # スマホの ID が出れば接続 OK
godot_console --headless --path . --export-debug "Android APK" build/android/gungame-debug.apk
adb install -r build/android/gungame-debug.apk
adb shell monkey -p jp.<あなたの名前>.gungame -c android.intent.category.LAUNCHER 1   # 起動
adb logcat -s godot                            # ゲームのログ・エラーを PC で読む（止めるのは Ctrl+C）
```

🧑 遊んで、動き・速度（カクつき）・タップの反応を確認。感想を Claude Code に伝える。

便利コマンド 🤖:
- スクリーンショット: `adb exec-out screencap -p > shot.png`（ストア掲載やブログに使える）
- 画面録画: `adb shell screenrecord /sdcard/demo.mp4`（YouTube 用）→ `adb pull /sdcard/demo.mp4`
- USB なしで接続（Android 11 以上）: 開発者向けオプション → ワイヤレスデバッグ → `adb pair` と `adb connect`

---

## フェーズ 4: Google Play で公開（💰 25 ドル、一度だけ）

### 4-1 必要なものの一覧（先に全部そろえる）

| 必要なもの | 誰が | 備考 |
|---|---|---|
| Google Play Console の開発者アカウント | 🧑💰 | 25 ドル。身分証・住所・電話番号・クレジットカード（プリペイド不可）。本人確認に数日 |
| リリース用の鍵（keystore） | 🧑 | 第 4-3。**失くさない。Git に入れない** |
| AAB ファイル | 🤖 | 第 4-4 |
| プライバシーポリシーのページ（URL） | 🤖 | データを集めなくても必須。GitHub Pages に置く |
| アイコン 512×512 PNG | 🤖 | 1MB 以下 |
| フィーチャーグラフィック 1024×500 | 🤖 | JPG または PNG |
| スマホのスクリーンショット 2〜8 枚 | 🤖（遊ぶのは 🧑） | 9:16。短辺 320px 以上、長辺 3840px 以下。`adb exec-out screencap` で撮れる |
| アプリ名（30 文字）、短い説明（80 文字）、詳しい説明（4000 文字） | 🤖 下書き → 🧑 確認 | |
| **テスター 12 人以上** | 🧑 | 14 日間ずっと参加し続けてもらう。一番時間がかかる |

### 4-2 開発者アカウント 🧑💰

1. play.google.com/console で「個人」として登録。25 ドル支払い
2. 本人確認（身分証の写真、電話番号の認証）。承認まで数日
3. ⚠️ 2023 年 11 月 13 日以降に作った個人アカウントは、本番公開の前に「12 人 × 14 日のクローズドテスト」が必須

### 4-3 リリース用の鍵を作る 🧑（この手順書で唯一、あなた自身がコマンドを打つところ）

パスワードを Claude Code に見せないため、これだけは自分で VS Code のターミナルに貼って実行する。
`<パスワード>` と `<あなたの名前>` を書き換えてから実行:

```powershell
$ks = "C:\Users\20019\gungame-keys\gungame-release.keystore"     # ⚠️ プロジェクトフォルダの外に置く
New-Item -ItemType Directory -Force (Split-Path $ks)
keytool -v -genkeypair -keystore $ks -alias gungame -keyalg RSA -keysize 2048 -validity 10000 -storepass "<パスワード>" -keypass "<パスワード>" -dname "CN=<あなたの名前>, O=<あなたの名前>, C=JP"

# Godot が書き出し時に読む環境変数（ファイルに書かずに済む）
[Environment]::SetEnvironmentVariable("GODOT_ANDROID_KEYSTORE_RELEASE_PATH", $ks, "User")
[Environment]::SetEnvironmentVariable("GODOT_ANDROID_KEYSTORE_RELEASE_USER", "gungame", "User")
[Environment]::SetEnvironmentVariable("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD", "<パスワード>", "User")
```

実行後に VS Code を再起動。鍵ファイルは USB メモリやクラウドにもコピーして保管。
補足: Google Play は「Play App Signing」で本当の署名鍵を Google が保管する。この鍵は「アップロード鍵」で、万一失くしても Google に再発行を申請できる（数日かかる）。それでも失くさないのが一番。

### 4-4 AAB を書き出す 🤖

```powershell
godot_console --headless --path . --export-release "Android AAB" build/android/gungame-0.1.0.aab
```

提出のたびに `export_presets.cfg` の Version Code を +1 する（Claude Code がやる）。

### 4-5 Play Console での登録 🧑（文章と素材は 🤖 が用意）

1. **アプリを作成**: 名前、既定の言語（日本語）、「ゲーム」、「無料」。⚠️ 無料から有料には後で変えられない
2. **アプリの設定（ダッシュボードの一覧を上から順に）**: プライバシーポリシーの URL、アプリへのアクセス（制限なし）、広告（最初の版は「なし」。広告を入れた版を出す時に「あり」へ変更）、コンテンツのレーティング（質問に正直に答える。図形を撃つゲームなら低年齢向けの評価になる）、ターゲット層（**13 歳以上**を推奨。13 歳未満を含めると「ファミリー ポリシー」で要件が増える）、ニュースアプリ（いいえ）、データ セーフティ（広告なしなら「収集しない」。広告を入れたら広告 SDK の項目を申告し直す）、政府アプリ（いいえ）、金融機能（なし）、健康（なし）
3. **ストアの掲載情報**: 4-1 の素材と文章を貼る
4. **クローズド テスト**: テスト → クローズド テスト → リリースを作成 → AAB をアップロード → Play App Signing に同意 → テスターのメールアドレス一覧を登録 → 公開。審査に数時間〜数日
5. 🧑 **テスターに「参加リンク」を送る**。各自がリンクを開いて「参加」→ Play からインストール。**12 人以上が 14 日間ずっと参加状態**を保つ。途中で 12 人を切ると日数が 0 に戻る
6. 14 日経過後、ダッシュボードの **「本番環境へのアクセスを申請」**。テストで何が分かったか、どう直したかを質問形式で答える（下書きは 🤖）。審査は通常 7 日以内
7. 承認後、**製品版 → リリースを作成** → 新しい Version Code の AAB をアップロード → 公開する国（最初は日本だけでも全世界でもよい）→ 審査（数時間〜数日。初回は長めになることがある）
8. 公開 🎉。ストアの URL をブログ・X・YouTube に貼る

全体の待ち時間: **AAB ができてから最短 3〜4 週間、現実的には 1〜1.5 か月**。

### 4-6 テスター 12 人の集め方

- 家族・友人・同僚（Android 端末と Google アカウントが必要）
- フェーズ 2 の Web 版を遊んでくれた X のフォロワーに「Android テスター募集」と告知
- Reddit の r/AndroidClosedTesting や Discord の相互テストコミュニティ
- ⚠️ 「12 人のテスターを売ります」という有料サービスは使わない。本番申請の質問で「テスターからどんな意見が出たか」を聞かれる。中身のないテストは落ちる
- 募集・進捗・結果そのものがブログと動画のネタになる

---

## フェーズ 5: App Store（後日。概要のみ）

- 必要なもの: Mac、Xcode（無料）、Apple Developer Program 💰 年間 99 ドル（日本では 1 万数千円）
- 流れ: Godot で iOS 書き出し（Xcode プロジェクトが出る）→ Xcode でアーカイブ → App Store Connect にアップロード → TestFlight でテスト → 審査 → 公開
- 開発中に自分の iPhone で試すだけなら無料の Apple ID で可能（7 日ごとに入れ直し）
- Google Play での反応を見て、払う価値があると判断してから着手する

---

## 6. 時間とお金のまとめ

| 項目 | 金額 | タイミング |
|---|---|---|
| Godot、Git、GitHub、GitHub Pages、JDK、Android SDK | 0 円 | |
| Google Play 開発者登録 | 25 ドル（約 4,000 円）一度だけ | フェーズ 4 の最初 |
| Apple Developer Program | 99 ドル / 年 | フェーズ 5（任意） |
| Android 端末（手持ちでよい） | 0 円 | |

| フェーズ | あなたの作業時間 | 待ち時間 |
|---|---|---|
| 0 | 1〜2 時間（ダウンロード待ち含む） | なし |
| 1 | 1〜2 週間（1 日 1 Step） | なし |
| 2 | 1〜2 時間 | なし |
| 3 | 2〜4 時間 | なし |
| 4 | 2〜3 日 | 3〜6 週間 |

---

## 7. Claude Code への頼み方（コピペ用）

| 場面 | 頼み方 |
|---|---|
| フェーズ 0 | 「PUBLISH_GUIDE のフェーズ 0 を上から順に進めて。UAC が出たら教えて」 |
| フェーズ 1 開始 | 「GAME_DESIGN の Step 1 を作って。できたら起動して」 |
| 遊んだ後 | 「敵が硬すぎる。倒すのに 3 発くらいにして」 |
| バランス | 「config.gd のゲートの出現率を見せて」 |
| 区切り | 「ここまでをコミットして。メッセージは日本語で」 |
| Web 公開 | 「publish_web を実行して。URL を教えて」 |
| Android 準備 | 「フェーズ 3 の 3-1 から 3-4 をやって。sdkmanager のダウンロードは時間がかかっていい」 |
| 実機 | 「スマホをつないだ。APK を入れて起動して。ログも見て」 |
| ストア素材 | 「アイコン 512 とフィーチャーグラフィック 1024×500 を作って。スクショは今から撮るから準備して」 |
| 文章 | 「Play ストアの短い説明と詳しい説明の下書きを書いて。ターゲットは Arrow a Row が好きな人」 |
| 本番申請 | 「本番環境アクセス申請の質問への回答案を、テスターの感想（貼る）をもとに書いて」 |
| 困った | 「エラーが出た（貼る）。原因と直し方を初心者向けに説明してから直して」 |

---

## 8. よくあるつまずき

| 症状 | 原因と対処 |
|---|---|
| `godot_console` や `git` が見つからない | PATH がまだ反映されていない。VS Code を閉じて開き直す |
| コマンドを打っても何も表示されない | `godot.exe` を使っている。`godot_console.exe` に替える |
| `対象となるフォルダが存在しないか、アクセスできません` | 出力先フォルダ（`build/web` など）を先に作る。Godot は作ってくれない |
| `Export preset not found` | `export_presets.cfg` の name とコマンドの名前が一致していない（大文字小文字・空白） |
| `No export template found` | 0-4 のフォルダ名が `4.7.2.stable` になっているか確認 |
| Web 版が真っ白 | レンダラーが Compatibility か、Thread Support が OFF か。ブラウザの F12 → Console のエラーを Claude Code に貼る |
| Web 版を更新しても古いまま | ブラウザのキャッシュ。スーパーリロード（Ctrl+Shift+R）か、スマホならサイトデータを削除 |
| Web 版で音が出ない | ブラウザは操作前に音を出せない。「タップしてスタート」画面を最初に置く |
| Gradle ビルドが失敗 | `JAVA_HOME` が 17 を指しているか。初回はダウンロードで長い。`android/build` を消して 3-4 のテンプレート再インストール |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | 別の鍵で署名した旧版が入っている。`adb uninstall <パッケージ名>` してから入れ直す |
| Play に「Target SDK が低い」と言われる | 3-4 の Target SDK を 36 に。`android/build/config.gradle` も確認 |
| Play に「Version Code は使用済み」 | +1 して再書き出し |
| テストの日数が 0 に戻った | 参加者が 12 人を切った。予備のテスターを 15 人ほど確保しておく |
| 鍵を失くした | Play App Signing を使っていればアップロード鍵の再発行を Google に申請できる |

---

## 9. 変わりやすい情報（2026-10-05 時点）

| 項目 | 現在の値 | 出典 |
|---|---|---|
| Godot 最新安定版 | 4.7.2（2026-08-18）。4.8 は開発中 | https://godotengine.org/download/archive/ |
| Godot Android 書き出しの要件 | OpenJDK 17、Build-Tools 35.0.1、Platform 35、NDK 28.1.13356709、CMake 3.10.2.4988404 | https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html |
| Godot Web 書き出し | Thread Support OFF で iOS/macOS でも動き、特別なヘッダー不要。レンダラーは Compatibility のみ | https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html |
| Godot コマンドライン | `--headless --export-release`、`--import`、`--install-android-build-template` | https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html |
| Google Play ターゲット API | 2026-08-31 以降、新規は Android 16（API 36）以上。延長申請は 2026-11-01 まで | https://support.google.com/googleplay/android-developer/answer/11926878 |
| Google Play 個人アカウントのテスト要件 | 12 人以上が 14 日間継続参加 → 本番申請 → 審査は通常 7 日以内 | https://support.google.com/googleplay/android-developer/answer/14151465 |
| Google Play 登録 | 25 ドル一度だけ。本人確認（身分証・電話・住所・クレカ） | https://support.google.com/googleplay/android-developer/answer/6112435 |
| ストア掲載の文字数 | アプリ名 30、短い説明 80、詳しい説明 4000 | https://support.google.com/googleplay/android-developer/answer/9859152 |
| Android コマンドラインツール | `commandlinetools-win-15859902_latest.zip` | https://developer.android.com/studio#command-line-tools-only |

---

## 10. チェックリスト

### フェーズ 0
- [ ] Git、gh を入れた。`gh auth login` 済み
- [ ] `godot_console --version` が 4.7.2 を返す
- [ ] エクスポートテンプレートのフォルダに `web_nothreads_release.zip` がある
- [ ] 空のプロジェクトで Web 書き出しが通る（Godot と部品の連携テスト。2026-10-05 実施済み）

### フェーズ 1
- [ ] Step 1〜5 がそれぞれコミットされている
- [ ] Step 2 の後に Web 書き出しを一度試した

### フェーズ 2
- [ ] `https://<ユーザー名>.github.io/gungame/` が Android と iPhone で動く
- [ ] URL を発信した。テスター募集を始めた

### フェーズ 3
- [ ] `adb devices` にスマホが出る
- [ ] APK を入れて 60fps 近くで動く

### フェーズ 4
- [ ] 開発者アカウント承認済み
- [ ] リリース用の鍵をバックアップした
- [ ] プライバシーポリシー URL、アイコン、フィーチャーグラフィック、スクショ 2 枚以上、説明文
- [ ] クローズドテスト公開。テスター 12 人以上が参加
- [ ] 14 日経過 → 本番申請 → 承認
- [ ] 製品版リリース → 公開
