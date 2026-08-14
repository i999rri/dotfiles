# dotfiles

NixOS (WSL・ベアメタル) と macOS (nix-darwin) で、同じ環境を `switch` 一発で
再現するための個人 dotfiles。パッケージ・システム設定・シェルまわりまで宣言的に
そろえる。

## 特徴

- **シンボリックリンクを 1 本も張らない。** リポジトリを bare repository として
  `$HOME` に直接展開するので、`~/.config/nvim` などは実ファイルとしてその場所に
  ある。編集はそのまま git の差分になる。
- **展開も自動。** home-manager の activation が bare repository の取得と
  `$HOME` への展開までやる。`switch` 以外にやることはない。
- **OS をまたいで共有。** NixOS と nix-darwin の両方で通る設定は `nix/shared/`
  にまとめてあり、片方だけ更新されて環境がずれることがない。

## クイックスタート

`bootstrap.sh` を flake の app として公開しているので、**clone せずに**実行できる。
OS を判定して反映まで通しでやる。

```sh
nix --extra-experimental-features 'nix-command flakes' \
  run 'github:i999rri/dotfiles?dir=.config/dotfiles'
```

- **macOS** — 先に Nix が要る。未導入なら:

  ```sh
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```

- **NixOS-WSL の初回だけは root で実行する** (`wsl -d NixOS -u root`)。暫定ユーザー
  で走らせると、作成するユーザーへの切り替えでそのユーザー自身を消してしまうため。

判定できないマシンではホスト名を渡す (`... -- wsl` / `... -- mac`)。ホストの一覧は
[`flake.nix`](../.config/dotfiles/flake.nix) を参照。

## 収録しているもの

| 分類 | 中身 |
| --- | --- |
| エディタ | Neovim (lazy.nvim), Emacs |
| シェル | zsh + sheldon + starship, ghostty, tmux, lazygit |
| Windows | PowerShell プロファイル |
| システム | nix-darwin / NixOS の設定, home-manager, 共有パッケージ一覧 |

## ドキュメント

- [セットアップ手順 (NixOS / macOS)](../.config/dotfiles/docs/setup-nix.md) —
  方針・手動手順・日常運用・トラブルシューティング
- [macOS の覚え書き](../.config/dotfiles/docs/macos.md) — nix-darwin で素直に
  書けなかった箇所とその理由
- [Windows セットアップ](../.config/dotfiles/docs/setup-windows.md)
- [Kubernetes セットアップ](../.config/dotfiles/docs/setup-k8s.md)

## 構成

リポジトリ自身の管理ファイルは `$HOME` を散らかさないよう `.config/dotfiles/`
配下にまとめてある。

```
$HOME
├── .dotfiles/              bare repository (git-dir)
├── .zshenv
└── .config/
    ├── nvim/ emacs/ tmux/ zsh/ starship/ sheldon/ lazygit/ ghostty/ pwsh/
    └── dotfiles/           このリポジトリのメタ情報
        ├── bootstrap.sh    初回セットアップ
        ├── flake.nix
        ├── nix/            shared / modules(NixOS) / darwin(macOS) / hosts / home
        └── docs/
```
