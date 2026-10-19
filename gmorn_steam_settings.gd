extends RefCounted

## `class_name` は付けない。エディタが一度走査するまで名前を引けず、取り込んだ
## 直後のヘッドレス実行で読み込みごと失敗する。使う側は `preload` で直に指す。

## 0 なら初期化しない。`steam_appid.txt` にも同じ番号が要る（クライアント外で
## 起動したとき拡張はそのファイルから読む）。
var app_id := 0
## true なら拡張が入っていても初期化しない。検証でつながない状態を作る用途。
var disabled := false

const SETTING_PREFIX := "gmorn_steam/"

func load_from_environment() -> void:
	app_id = int(_setting("app_id", app_id))
	disabled = bool(_setting("disabled", disabled))
	# 環境変数は最後。手元だけつながない用途なので設定より優先する。
	if OS.get_environment("GMORN_STEAM_DISABLED") == "1":
		disabled = true

static func _setting(key: String, fallback_value: Variant) -> Variant:
	var path := SETTING_PREFIX + key
	if not ProjectSettings.has_setting(path):
		return fallback_value
	return ProjectSettings.get_setting(path, fallback_value)
