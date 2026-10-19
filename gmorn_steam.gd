extends Node

## Steam 拡張（GodotSteam）へ触る唯一の場所。拡張が無い配布形態でも必ず答える。
##
## `Steam.〜` を直に書かない。拡張の無いビルドではその1行で起動しなくなり、
## 手元の Steam 版では通るので配った後にしか気付けない。
## 在り処（`Engine.has_singleton()`）だけでなく `has_method()` も見る。版の違う
## 拡張では在るのに関数が無いことがある。

signal initialized_changed(active: bool)

const SETTINGS := preload("gmorn_steam_settings.gd")

## 拡張が無い、初期化に失敗した、切ってある、のいずれでも false。
var active := false
## 不活性なら空。
var user_id := ""
## 不活性なら空。
var persona_name := ""

var settings: RefCounted
var _steam: Object

func _ready() -> void:
	settings = SETTINGS.new()
	settings.load_from_environment()
	_initialize()

func _initialize() -> void:
	if settings.disabled:
		return
	if not Engine.has_singleton("Steam"):
		return
	_steam = Engine.get_singleton("Steam")
	if _steam == null or not _steam.has_method("steamInitEx"):
		return
	var result: Variant = _steam.callv("steamInitEx", [settings.app_id, true])
	# 返る形は版によって違う（辞書か真偽値）。
	if result is Dictionary:
		active = int((result as Dictionary).get("status", 1)) == 0
	else:
		active = bool(result)
	if not active:
		return
	if _steam.has_method("getSteamID"):
		user_id = str(_steam.call("getSteamID"))
	if _steam.has_method("getPersonaName"):
		persona_name = str(_steam.call("getPersonaName"))
	initialized_changed.emit(true)

## 不活性なら何も起きない。呼ぶ側に `if` を書かせない。
func unlock_achievement(api_name: String) -> void:
	if not active or api_name.is_empty():
		return
	if _steam == null or not _steam.has_method("setAchievement"):
		return
	_steam.call("setAchievement", api_name)
	# 解除しただけでは Steam へ送られない。
	if _steam.has_method("storeStats"):
		_steam.call("storeStats")

## 利用者ごとに分ける保存先の下の階層。不活性・識別子なしでは分けない。分けると
## 拡張の有無で保存先が変わり、それまでの進行が見えなくなる。
func save_subdirectory() -> String:
	if not active or user_id.is_empty():
		return ""
	return "steam/" + user_id
