extends RefCounted

## GMornSteam の設定。
##
## `class_name` は付けない。付けるとエディタが一度走査するまで名前を引けず、
## 取り込んだ直後にヘッドレスで走らせると読み込みごと失敗する。使う側は
## `preload` で直に指す。

## Steam のアプリ番号。0 のままだと初期化しない。
##
## `steam_appid.txt` にも同じ番号を書く。手元で Steam クライアント経由でなく
## 起動したとき、拡張はそのファイルから番号を読む。
var app_id := 0
## 切っておくか。true なら拡張が入っていても初期化しない。
##
## 検証や配布前の確認で、Steam へつながない状態を作りたいときに使う。
var disabled := false

const SETTING_PREFIX := "gmorn_steam/"

## 設定を読み込む。自分自身へ書き込むので、作ってから呼ぶ。
func load_from_environment() -> void:
	app_id = int(_setting("app_id", app_id))
	disabled = bool(_setting("disabled", disabled))
	# 環境変数は最後に効かせる。手元だけつながない状態にしたいときに使う。
	if OS.get_environment("GMORN_STEAM_DISABLED") == "1":
		disabled = true

static func _setting(key: String, fallback_value: Variant) -> Variant:
	var path := SETTING_PREFIX + key
	if not ProjectSettings.has_setting(path):
		return fallback_value
	return ProjectSettings.get_setting(path, fallback_value)
