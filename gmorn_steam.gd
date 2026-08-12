extends Node

## Steam拡張の有無を吸収する境界。
##
## GodotSteam は配布形態によって入っていたり入っていなかったりする。無い側で
## `Steam.〜` を直に書くと、その1行のせいで起動しなくなる。しかも手元の
## Steam版ビルドでは通るため、気付くのは配った後になる。
##
## そこで拡張へ触るのはこの部品だけにして、外へは「拡張が無くても必ず答える口」
## を出す。呼ぶ側に `if` を書かせない。拡張が無ければ不活性のまま、
## 実績も何も起こさず、保存先も分けない。
##
## 確かめ方は二段にする。`Engine.has_singleton()` で在り処を見て、さらに
## `has_method()` で呼びたい関数があるかを見る。版が違う拡張が入っていると、
## 在るのに関数が無いことがあり、在り処だけの確認では落ちる。
##
## 使い方は README.md を参照。

## Steam が使えるようになったときに流れる。
signal initialized_changed(active: bool)

const SETTINGS := preload("gmorn_steam_settings.gd")

## Steam が使えるか。拡張が無い、初期化に失敗した、切ってある、のいずれでも false。
var active := false
## 利用者の識別子。不活性なら空。
var user_id := ""
## 利用者の表示名。不活性なら空。
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
	# 在り処があっても、版が違えば呼びたい関数が無いことがある。
	if _steam == null or not _steam.has_method("steamInitEx"):
		return
	var result: Variant = _steam.callv("steamInitEx", [settings.app_id, true])
	# 返る形は版によって違う。辞書なら status を見て、真偽値ならそのまま使う。
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

## 実績を解除する。不活性なら何も起きない。呼ぶ側で状態を見る必要はない。
func unlock_achievement(api_name: String) -> void:
	if not active or api_name.is_empty():
		return
	if _steam == null or not _steam.has_method("setAchievement"):
		return
	_steam.call("setAchievement", api_name)
	# 解除しただけでは送られない。送らないと、遊び終えても実績が付かない。
	if _steam.has_method("storeStats"):
		_steam.call("storeStats")

## 保存先に足す下の階層。利用者ごとに分けたいときに使う。
##
## 不活性のときは空を返す。分けてしまうと、拡張の有無で保存先が変わって
## それまでの進行が見えなくなる。識別子が取れないときも同じ理由で分けない。
## 空のまま分けると、その環境の全員が同じ場所を使う。
func save_subdirectory() -> String:
	if not active or user_id.is_empty():
		return ""
	return "steam/" + user_id
