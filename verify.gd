extends SceneTree

## 拡張が無い側での約束を固定する。
##
## 拡張は配布形態によって有無が変わる。無い側で落ちると、書き出した後の環境で
## だけ起動しなくなる。ここで見るのは「無くても必ず答える」ことである。

const STEAM_PATH := "res://addons/gmorn_steam/gmorn_steam.gd"
const SETTINGS_PATH := "res://addons/gmorn_steam/gmorn_steam_settings.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var service_script: GDScript = load(STEAM_PATH)
	var service: Node = service_script.new()
	root.add_child(service)
	await process_frame

	# 拡張が無ければ不活性で、識別子も表示名も空のまま。
	if not Engine.has_singleton("Steam"):
		assert(not service.active, "拡張が無いのに活性になっている")
		assert(service.user_id.is_empty(), "識別子が %s" % service.user_id)
		assert(service.persona_name.is_empty(), "表示名が %s" % service.persona_name)

	# 不活性なら保存先を分けない。分けると、拡張の有無で保存先が変わって
	# それまでの進行が見えなくなる。
	if not service.active:
		assert(service.save_subdirectory().is_empty(),
			"不活性なのに %s へ分けている" % service.save_subdirectory())

	# 実績の通知は不活性でも落ちない。呼んでも何も起きないだけ。
	service.unlock_achievement("TEST_ACHIEVEMENT")
	service.unlock_achievement("")

	# 活性側の経路は、拡張の無い環境では一度も通らない。値を差し替えて通す。
	# ここを通していないと、Steam版でだけ保存先が壊れていても気付けない。
	var kept_active: bool = service.active
	var kept_user: String = service.user_id
	service.active = true
	service.user_id = "76561190000000000"
	assert(service.save_subdirectory() == "steam/76561190000000000",
		"利用者ごとの置き場が %s" % service.save_subdirectory())

	# 識別子が取れないときは分けない。空のまま分けると全員が同じ場所を使う。
	service.user_id = ""
	assert(service.save_subdirectory().is_empty(), "識別子が無いのに分けている")

	# 活性でも実績の呼び出しで落ちない。拡張が無いので何も起きないだけ。
	service.user_id = kept_user
	service.unlock_achievement("TEST_ACHIEVEMENT")
	service.active = kept_active

	# 切ってあれば、拡張があっても初期化しない。
	ProjectSettings.set_setting("gmorn_steam/disabled", true)
	ProjectSettings.set_setting("gmorn_steam/app_id", 480)
	var settings_script: GDScript = load(SETTINGS_PATH)
	var settings: RefCounted = settings_script.new()
	settings.load_from_environment()
	assert(settings.disabled, "切る設定が読めていない")
	assert(settings.app_id == 480, "アプリ番号が %d" % settings.app_id)
	var stopped: Node = service_script.new()
	root.add_child(stopped)
	await process_frame
	assert(not stopped.active, "切ってあるのに活性になった")

	print("拡張=%s 活性=%s" % [Engine.has_singleton("Steam"), service.active])
	print("GMORN STEAM VERIFY: PASS")
	quit(0)
