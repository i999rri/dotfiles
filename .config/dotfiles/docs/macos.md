# macOS (nix-darwin) の覚え書き

macOS を nix-darwin で構成するうえで、素直に書けなかった箇所と、その理由を
残す。セットアップ手順そのものは [setup-nix.md](./setup-nix.md) を見る。ここは
「なぜこう書いてあるのか」「なぜ nix に載せていないのか」の記録。

宣言先は基本 `nix/darwin/default.nix`、ユーザー領域は `nix/home/default.nix`。

## 入力メソッド (AquaSKK) は実体コピーで置く

AquaSKK は nixpkgs に無いので、配布の `.pkg` から `.app` を取り出す derivation
(`nix/pkgs/aquaskk.nix`) を置いている。問題は置き場所の方。

macOS が入力メソッドを探すのは `/Library/Input Methods` **だけ**で、しかも
**実体の bundle でないと登録されない**。ここへ `/nix/store` を指す symlink を
張っても、ログイン時の走査で無視される (セッション内で動く入力メソッドは検証
済みの実体しか受け付けない、というセキュリティ上の制約)。`lsregister` で手動
登録しても、再ログインで消える。

そこで `system.activationScripts.postActivation` で store から実体を
`/Library/Input Methods` へ **コピー** する。コピー済みかは、最後に展開した
store パスをマーカー (`.aquaskk.nix-store`) に記録して判定する。マーカーが
無いのに bundle があるときは、手で入れたものと見なして触らない。

- 署名は notarized のまま保たれるので Gatekeeper は通る (`spctl -a` で確認可)
- **反映には再ログインが要る**。macOS が `/Library/Input Methods` を走査するのは
  ログイン時だけなので、switch 直後は入力ソースに出てこない
- 入力ソースへの追加 (システム設定 → キーボード → 入力ソース → +) は手でやる。
  下の「宣言化しないもの」を参照

## SKK 辞書は参照側ごとに扱いが違う

`nix/home/default.nix` が置くのは **skkeleton (nvim) 用の基礎辞書だけ**。

| 用途 | パス | 管理 |
| --- | --- | --- |
| skkeleton の基礎辞書 | `~/.skk/SKK-JISYO.L` | home-manager (store へのリンク) |
| skkeleton の学習辞書 | `~/.skk/skkeleton-jisyo` | 管理しない (書き込み対象) |
| AquaSKK の基礎辞書 | `~/Library/Application Support/AquaSKK/SKK-JISYO.L` | **管理しない** |
| AquaSKK の学習辞書 | `~/Library/Application Support/AquaSKK/skk-jisyo.utf8` | 管理しない (書き込み対象) |

AquaSKK に基礎辞書を渡さないのは、**AquaSKK が基礎辞書を自前で持って更新もする**
ため。ここへ home-manager がリンクを張ると、activation のたびに取り合いになる
(AquaSKK が実体で置き直す → home-manager が退避しようとして `.hm-bak` と衝突し、
switch が止まる)。基礎辞書は AquaSKK に任せる。

学習辞書はどちらも書き込みが要るので触らない。消えると困るので、バックアップは
Time Machine 任せか、必要なら private な同期先を別に用意する
(リポジトリは public なので、登録語をそのまま置くと中身が漏れる)。

## sudo — Touch ID と PATH

`security.pam.services.sudo_local` で Touch ID を有効化している。tmux の中でも
効くよう `reattach = true` (pam_reattach) を入れる。tmux のサーバはブートスト
ラップセッションから切り離されて動くので、これが無いと中の sudo が指紋を出せず
パスワード入力に落ちる。

あわせて `environment.etc."sudoers.d/20-secure-path"` で `secure_path` を固定して
いる。sudo 越しに `darwin-rebuild` を叩いたとき、呼び出し元の PATH に
`/run/current-system/sw/bin` が無いと command not found になるのを防ぐため。

注意: **制御端末を持たないプロセス (エージェント越しの実行など) からは Touch ID
が出せない**。`pam_tid` は GUI セッションに紐づくので、この種の環境からの sudo は
パスワード入力に落ちるか、pty が無いと即座に失敗する。switch を人手で叩く前提に
しているのはこのため。

## GUI アプリは nix と Homebrew cask の二系統

| 入れ方 | 置き場所 | 対象 |
| --- | --- | --- |
| `environment.systemPackages` | `/Applications/Nix Apps/` (trampoline) | nixpkgs で素直に動くもの (Raycast, Ghostty) |
| `homebrew.casks` | `/Applications/` 直下 | それ以外 (Firefox, 1Password, Tailscale, Windows App, Zen) |

cask 側にしているアプリは、`/Applications` 直下にある前提で動くもの (自己更新・
署名検証・Network Extension など) が中心。`/nix/store` から動かすと連携が壊れる。
Homebrew 本体は flake input の nix-homebrew が入れる。

Spotlight まわりの都合が 2 つある:

- Nix Apps はシステムボリューム上にあるが、switch では再 index が促されない。
  Raycast / Spotlight から引けるよう、postActivation で `mdimport` をかけている
- 実体を指す `/nix` は別ボリュームで index 対象外。だから Dock に Ghostty を
  置くときは trampoline のパス (`/Applications/Nix Apps/Ghostty.app`) を直に指す。
  このパスは世代をまたいでも変わらない

## 宣言化しないもの

macOS 側が実行中に書き換える / 確認ダイアログを挟むため、nix に載せると綱引きに
なるか、そもそも自動化できないもの。**意図的に手作業に残している**。

- **入力ソースの有効化** (`com.apple.HIToolbox` の AppleEnabledInputSources) —
  HIToolbox が実行中に書き換える動的な状態で、plist だけ見ても姿が一致しない
  (登録は private API 側にもある)。書き損じると入力ソースが 1 つも無い状態に
  なり得るので、手で + する
- **既定ブラウザ** — LaunchServices が持っていて、変更時に必ず確認ダイアログが
  出る (乗っ取り対策)。スクリプトからダイアログは消せないので、GUI で一度指定する

## system.defaults の注意

- nix-darwin は書いた項目に `defaults write` を撃つが、**消した項目に
  `defaults delete` は撃たない**。ここから項目を消しても、一度反映したマシンには
  値が残る (新しいマシンでは書かれないので初期値になる)。戻すには手で
  `defaults delete` する
- 反映タイミングは項目による。スクロール方向のように、WindowServer が起動時に
  読む値は switch 直後には効かず、ログインし直しで反映される
- キーボードショートカット (`CustomUserPreferences` 経由の symbolichotkeys) の
  parameters は `(文字コード, キーコード, 修飾キーのビットマスク)`。値は推測せず、
  **システム設定で一度割り当てて macOS 自身に書かせた plist を写す**。キーボード
  配列によって同じキーでも値が変わるため、実機に書かせるのが確実
