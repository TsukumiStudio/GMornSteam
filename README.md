# GMornSteam

## 概要

Steam拡張（GodotSteam）が入っていない環境でも落ちないように、拡張へ触る場所を1つにまとめるGodotアドオン。

拡張は配布形態によって入っていたり入っていなかったりする。無い側で `Steam.〜` を直に書くと、その1行のせいで起動しなくなる。しかも手元のSteam版ビルドでは通るため、気付くのは配った後になる。

触るのはこの部品だけにして、外へは「拡張が無くても必ず答える口」を出す。呼ぶ側に `if` を書かせない。

## 動作環境

- Godot 4.x（4.7で確認）
- [GodotSteam](https://godotsteam.com/)（無くても動く。そのとき不活性のまま）

## 何ができるか

- **無い環境で落ちない**。`Engine.has_singleton()` で在り処を見て、さらに `has_method()` で呼びたい関数があるかを見る。版が違う拡張が入っていると、在るのに関数が無いことがあり、在り処だけの確認では落ちる。
- **呼ぶ側に分岐を書かせない**。`unlock_achievement()` は不活性なら何も起きないだけ。状態を見てから呼ぶ必要はない。
- **保存先を勝手に分けない**。不活性のとき、識別子が取れないときは空を返す。分けてしまうと、拡張の有無で保存先が変わってそれまでの進行が見えなくなる。
- **切って確かめられる**。`GMORN_STEAM_DISABLED=1` を付ければ、拡張が入っていてもつながない状態を作れる。

## 使い方

### 1. 取り込む

アドオン一式をリポジトリ直下へ置いてある。取り込む側の `addons/gmorn_steam` へそのまま submodule として足せる。

```
git submodule add https://github.com/TsukumiStudio/GMornSteam.git addons/gmorn_steam
```

Godotのエディタで「プロジェクト設定 → プラグイン」から `GMornSteam` を有効にする。自動読み込みへ `GMornSteam` が登録される。

**リポジトリ直下に `project.godot` は置かない。** 置くとGodotがそこを別のプロジェクトと見なし、**そのフォルダを丸ごとスキャンから外す**。submoduleとして取り込んだ場合、エディタでは動くのに書き出した実行ファイルにだけアドオンが入らない。

### 2. アプリ番号を書く

`project.godot` に足す。0 のままだと初期化しない。

```
[gmorn_steam]

app_id=480
```

リポジトリ直下の `steam_appid.txt` にも同じ番号を書く。手元でSteamクライアント経由でなく起動したとき、拡張はそのファイルから番号を読む。

### 3. 呼ぶ

```gdscript
var steam := get_node_or_null("/root/GMornSteam")
if steam != null:
    steam.unlock_achievement("FIRST_CLEAR")
```

実績の一覧はこの部品では持たない。どの実績があるかは作品ごとに違うので、呼ぶ側が持つ。

保存先を利用者ごとに分けるならこうなる。

```gdscript
func save_path() -> String:
    var steam := get_node_or_null("/root/GMornSteam")
    var sub := steam.save_subdirectory() if steam != null else ""
    return "user://".path_join(sub).path_join("save.json")
```

### 4. 動かし方を変える

| 項目 | プロジェクト設定 | 環境変数 | 既定 |
| --- | --- | --- | --- |
| アプリ番号 | `gmorn_steam/app_id` | — | `0`（初期化しない） |
| つながない | `gmorn_steam/disabled` | `GMORN_STEAM_DISABLED=1` | `false` |

### その他の口

| 呼び出し | 何をするか |
| --- | --- |
| `active` | Steam が使えるか |
| `user_id` | 利用者の識別子。不活性なら空 |
| `persona_name` | 利用者の表示名。不活性なら空 |
| `unlock_achievement(api_name)` | 実績を解除して送る。不活性なら何も起きない |
| `save_subdirectory()` | 保存先に足す下の階層。不活性・識別子なしなら空 |
| `initialized_changed(active)` | 使えるようになったときに流れる |

### 手を入れる

`verify.sh` で、拡張が無い側での約束が守られていることを確かめられる。一時の置き場へ最小のプロジェクトを作り、この部品を写して回す。

```
./verify.sh
```

## ライセンス

Unlicense（パブリックドメイン）。
