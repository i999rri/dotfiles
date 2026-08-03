# Nix セットアップ手順 (NixOS / macOS)

NixOS (WSL・ベアメタル) と macOS (nix-darwin) でこのリポジトリの環境を再現するための runbook。

システムのパッケージからシェル設定まで、`switch` 一発で揃う状態になる。

## 方針

このリポジトリは **bare repository として `$HOME` に直接展開する**。

`~/.config/nvim` などが実ファイルとしてその場所に存在するため、シンボリックリンクは 1 本も張らない。編集はそのまま git の変更として見える。

リポジトリ自身の管理ファイル (`flake.nix` / `nix/` / `docs/`) は `$HOME` を散らかさないよう `.config/dotfiles/` 配下にまとめてある。

```
$HOME
├── .dotfiles/              bare repository (git-dir)
├── .zshenv
└── .config/
    ├── nvim/ tmux/ zsh/ starship/ sheldon/ lazygit/ ghostty/ pwsh/
    └── dotfiles/           このリポジトリのメタ情報
        ├── bootstrap.sh    初回セットアップ
        ├── flake.nix
        ├── nix/
        │   ├── shared/     NixOS と nix-darwin の両方で使う設定
        │   ├── modules/    NixOS 固有
        │   ├── darwin/     macOS 固有
        │   ├── hosts/      マシン固有
        │   └── home/       home-manager
        └── docs/
```

OS 別の設定が分かれているのは、`i18n` や `nix-ld` のように片方にしか存在しないオプションがあるため。パッケージ一覧のように両者で共有できるものは `nix/shared/` にまとめてあり、片方だけ更新されて環境がずれることがない。

## クイックスタート

`bootstrap.sh` が OS を判定して、clone から反映までを通しでやる。

```sh
curl -fsSL https://raw.githubusercontent.com/i999rri/dotfiles/main/.config/dotfiles/bootstrap.sh | bash
```

判定できないマシンではホスト名を渡す:

```sh
bash ~/.config/dotfiles/bootstrap.sh wsl
```

ホストの一覧は `flake.nix` の `nixosConfigurations` / `darwinConfigurations` を参照。

前提となるもの:

| OS | 必要なもの |
| --- | --- |
| NixOS (WSL) | [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) で導入済みであること |
| NixOS (ベアメタル) | NixOS 26.05 以降 |
| macOS | Nix。未導入なら `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \| sh -s -- install` |

## 手動でやる場合

`bootstrap.sh` が中でやっていることを分解すると以下になる。

### 1. dotfiles を bare repository として展開する

素の NixOS には git が入っていないため、`nix-shell` で一時的に借りる (macOS では不要)。

```sh
nix-shell -p git --run '
  git clone --bare https://github.com/i999rri/dotfiles.git "$HOME/.dotfiles" &&
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config status.showUntrackedFiles no &&
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
'
```

2 行目の `status.showUntrackedFiles no` は必須。work-tree が `$HOME` なので、これがないと `git status` が `$HOME` 配下の全ファイルを untracked として列挙する。

`checkout` が既存ファイルと衝突した場合は、そのファイルを退避してからやり直す。

### 2. システムを反映する

初回だけ flakes が無効なので、この実行の間だけ有効化する。

`nixos-rebuild` / `darwin-rebuild` は `--extra-experimental-features` を受け付けない (引数エラーになる) ため、`NIX_CONFIG` で渡す。`sudo` は環境変数を落とすので明示的に引き継ぐ。

NixOS:

```sh
sudo NIX_CONFIG="experimental-features = nix-command flakes" \
  nixos-rebuild switch --flake "$HOME/.config/dotfiles#wsl"
```

macOS (nix-darwin が未導入の初回):

```sh
sudo NIX_CONFIG="experimental-features = nix-command flakes" \
  nix run nix-darwin -- switch --flake "$HOME/.config/dotfiles#mac"
```

反映後は `nix/shared/common.nix` が flakes を恒久的に有効化するため、2 回目以降は `NIX_CONFIG` 不要:

```sh
sudo nixos-rebuild switch --flake "$HOME/.config/dotfiles#wsl"   # NixOS
sudo darwin-rebuild switch --flake "$HOME/.config/dotfiles#mac"  # macOS
```

### 3. ユーザーを切り替える (NixOS-WSL の初回のみ)

NixOS-WSL の初期ユーザーは `nixos` だが、このリポジトリは `i999rri` を作る。ステップ 2 の時点でユーザーは作られているので、WSL を再起動して切り替える。

Windows 側 (pwsh) から:

```powershell
wsl --shutdown
wsl -d NixOS
```

`whoami` が `i999rri` になっていれば成功。

新しいユーザーの `$HOME` は空なので、**ステップ 1 をもう一度実行する**。以降このホストで bootstrap が必要になることはない。

## 確認

```sh
whoami
echo $SHELL   # .../zsh
git --version
gh --version
nvim --version
starship --version
```

新しい zsh を開いてプロンプトが以下のようになれば成功:

```
[ ~ ]                                       [ 23:45:12 ]
nixos zsh ~❯
```

- 上段: ディレクトリブロック (オレンジ) + 時計 (右端)
- 下段: `nixos zsh ~❯` (macOS なら `macos zsh ~❯`)

`sudo -i` で root になると下段が赤い `#❯` に変わる。

nvim は初回起動時に lazy.nvim が自身を clone してプラグインを入れる。tmux の tpm は home-manager が用意するので、`prefix + I` でプラグインを入れるところから始められる。

## 日常運用

### dotfiles を編集する

ファイルはすべて本来の場所にある実ファイルなので、普通に編集するだけ。

git 操作だけは git-dir の指定が必要で、`dot` alias が `.config/zsh/aliases.zsh` に定義してある:

```sh
dot status
dot add .config/nvim/init.lua
dot commit -m "nvim: ..."
dot push
```

### システム設定を変える

`.config/dotfiles/nix/` 配下を編集してから `switch` する。

| 変えたいもの | 場所 |
| --- | --- |
| 全 OS 共通のパッケージ | `nix/shared/packages.nix` |
| 全 OS 共通の設定 | `nix/shared/common.nix` |
| NixOS だけの設定 | `nix/modules/` |
| macOS だけの設定 | `nix/darwin/default.nix` |
| そのマシンだけの設定 | `nix/hosts/<host>/default.nix` |

反映せずに評価だけ試すなら:

```sh
nixos-rebuild dry-build --flake "$HOME/.config/dotfiles#wsl"
```

### パッケージを新しくする

```sh
cd "$HOME/.config/dotfiles"
nix flake update
sudo nixos-rebuild switch --flake ".#wsl"
dot add .config/dotfiles/flake.lock && dot commit -m "flake: update inputs"
```

`flake.lock` をコミットしておくことで、他のマシンでも同じバージョンが再現される。

### 前の世代に戻す

```sh
sudo nixos-rebuild switch --rollback    # NixOS
sudo darwin-rebuild switch --rollback   # macOS
```

## ホストを追加する

別のマシンで使うときは、そのマシン固有の設定だけを足す。

1. `nix/hosts/<hostname>/default.nix` を作る (NixOS のベアメタルならここに `hardware-configuration.nix` を置く)
2. `flake.nix` に 1 行足す:

   ```nix
   nixosConfigurations = {
     wsl = mkNixos { hostname = "wsl"; };
     desktop = mkNixos { hostname = "desktop"; };
   };

   darwinConfigurations = {
     mac = mkDarwin { hostname = "mac"; };
   };
   ```

ユーザー名がマシンによって違う場合は `mkNixos { hostname = "..."; username = "..."; }` で上書きする。

`nix/shared/` と `nix/modules/` は共通なので触らなくてよい。

## トラブルシューティング

### `git status` が `$HOME` 中のファイルを大量に表示する

`status.showUntrackedFiles` が設定されていない。

```sh
dot config status.showUntrackedFiles no
```

### `error: experimental Nix feature 'nix-command' is disabled`

初回の反映がまだ。「2. システムを反映する」の `NIX_CONFIG` 付きで実行する。

### `nixos-rebuild: error: unrecognized arguments: --extra-experimental-features`

`nixos-rebuild` はこのフラグを受け付けない。`NIX_CONFIG` 環境変数で渡す。

### mason.nvim が LSP のインストールに失敗する

mason はビルド済みバイナリを落としてくるが、NixOS には標準的な動的リンカがないため通常は動かない。`nix/modules/base.nix` で `programs.nix-ld` を有効にしてあるので、`nixos-rebuild switch` 済みであれば動く。

それでも解決しないバイナリがある場合は、必要な共有ライブラリを `programs.nix-ld.libraries` に足す。

macOS ではこの問題は起きない。

### プロンプトの記号が出ない / スラントが豆腐文字になる

- 記号が出ない: `echo $STARSHIP_CONFIG` が `~/.config/starship/starship.toml` を指しているか確認 (`nix/shared/common.nix` で設定)
- 豆腐文字: 端末側のフォント設定。Nerd Font (JetBrainsMono Nerd Font Mono) を当てる。WSL の場合はホストの Windows Terminal / Ghostty 側の設定

### クリップボード連携が効かない

nvim の `clipboard=unnamedplus` は外部コマンドを呼ぶ。WSL では WSLg 経由の `wl-clipboard` を入れてある (`nix/hosts/wsl/default.nix`)。macOS は `pbcopy` があるので設定不要。WSLg のないベアメタル Linux では、そのホストの環境に合わせて `xclip` などをホスト設定に足す。
