# Windows セットアップ手順

新しい Windows マシンで pwsh + starship + Ghostty / Windows Terminal の環境を再現するための runbook。

順番に上から実行すれば、PR #1 で構築した「tmux2k Asiimov 風スラント + 管理者切替 + OS/シェル表示」の状態になる。

## 前提

- Windows 10 1903 以降 (winget 利用) / Windows 11 推奨
- 管理者権限が必要なステップは明記する
- 既存のシェル環境 (`powershell.exe` 5.1 等) は壊さない

## ステップ

### 1. PowerShell 7 を入れる

```powershell
winget install --id Microsoft.PowerShell --source winget
```

確認:

```powershell
pwsh -Version
# PowerShell 7.x.x が表示されればOK
```

### 2. Scoop を入れる

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

### 3. Starship を入れる

```powershell
scoop install starship
```

確認:

```powershell
starship --version
# starship 1.x.x
```

### 4. Nerd Font を入れる

JetBrainsMono Nerd Font Mono を使う前提:

```powershell
scoop bucket add nerd-fonts
scoop install JetBrainsMono-NF-Mono
```

`Win + R` → `intl.cpl` 等で確認しなくても、Ghostty / Windows Terminal の font-family に `JetBrainsMono Nerd Font Mono` を指定して描画されればOK。

### 5. アップデート通知を抑止する環境変数

```powershell
[Environment]::SetEnvironmentVariable('POWERSHELL_UPDATECHECK', 'Off', 'User')
```

これでログイン中ずっと適用される。再起動・再ログイン不要 (新規プロセスから反映)。

### 6. このリポジトリをクローン

```powershell
mkdir $HOME\source\repos -ErrorAction SilentlyContinue
git clone git@github.com:i999rri/dotfiles.git $HOME\source\repos\dotfiles
```

### 7. シンボリックリンクを張る

`.config` ディレクトリと PowerShell プロファイルディレクトリを準備してからリンク:

```powershell
# starship.toml
New-Item -ItemType Directory -Force -Path "$HOME\.config" | Out-Null
New-Item -ItemType SymbolicLink -Force `
  -Path "$HOME\.config\starship.toml" `
  -Target "$HOME\source\repos\dotfiles\config\starship\starship.toml"

# pwsh profile
$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
New-Item -ItemType SymbolicLink -Force `
  -Path $PROFILE `
  -Target "$HOME\source\repos\dotfiles\config\pwsh\Microsoft.PowerShell_profile.ps1"

# Ghostty config
New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\ghostty" | Out-Null
New-Item -ItemType SymbolicLink -Force `
  -Path "$env:LOCALAPPDATA\ghostty\config" `
  -Target "$HOME\source\repos\dotfiles\config\ghostty\config"
```

シンボリックリンク作成には**管理者権限**が必要。管理者 pwsh から実行する。あるいは Windows 設定 → 「開発者向け」→ 「開発者モード」を有効化すると一般ユーザーでも `mklink` 系が通る。

### 8. Windows Terminal の pwsh プロファイルに `-NoLogo` を追加

`Ctrl + ,` → 設定画面 → PowerShell プロファイル → 「コマンド ライン」を以下に変更:

```
pwsh.exe -NoLogo
```

これで起動時のバージョンバナーが出なくなる。Ghostty 側は `command=pwsh -NoLogo` が `config/ghostty/config` に書かれているのでステップ 7 で自動適用される。

### 9. 確認

新しい pwsh タブを開いて以下が表示されれば成功:

```
[ ~ ]                                       [ 23:45:12 ]
windows pwsh ~❯
```

- 上段: ディレクトリブロック (オレンジ) + 時計 (右端)
- 下段: `windows pwsh ~❯` (グレー + オレンジプロンプト)

管理者 pwsh で開くと下段が `windows pwsh #❯` (赤プロンプト) に変わる。

## トラブルシューティング

### スラントが豆腐文字 (□) になる

Nerd Font が当たっていない。確認:

```powershell
fc-list | Select-String "Nerd Font"   # WSL/git-bash 系のみ
# あるいは Windows: コントロールパネル → フォント で JetBrainsMono Nerd Font Mono の存在確認
```

Ghostty / Windows Terminal の `font-family` に `JetBrainsMono Nerd Font Mono` が指定されているかも確認。

### プロンプト記号が出ない

`STARSHIP_PROMPT_ADMIN` / `STARSHIP_PROMPT_USER` のどちらも未設定の可能性。pwsh プロファイルがロードされているか:

```powershell
Test-Path $PROFILE   # True なら symlink 自体は存在
. $PROFILE           # 手動でロード
$env:STARSHIP_PROMPT_USER   # 一般シェルなら '~❯' が返る
$env:STARSHIP_PROMPT_ADMIN  # 管理者シェルなら '#❯' が返る
```

何も返らない場合、プロファイル内の admin 判定ロジックが失敗している。`. $PROFILE` のエラー出力を確認。

### 管理者切替が効かない

シェル起動時の `IsInRole` 判定の結果と、実際の elevation 状態が一致しているか確認:

```powershell
([System.Security.Principal.WindowsPrincipal]::new(
    [System.Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
# True = 管理者、False = 一般
```

### `[Environment]::SetEnvironmentVariable` が効かない

`-Scope 'User'` (3 番目の引数) を渡しているか確認。`'Process'` だと現プロセスのみ。`'Machine'` だと全ユーザー (要管理者)。

## macOS / Linux への移植

このリポジトリの `config/starship/starship.toml` 自体はクロスプラットフォーム。各 OS で必要な作業:

1. starship インストール (`brew install starship` / `apt install starship`)
2. Nerd Font インストール
3. シェルの rc (`~/.zshrc` / `~/.bashrc`) に init 行と admin 判定を追加:
   ```sh
   eval "$(starship init zsh)"
   if [[ $EUID -eq 0 ]]; then
       export STARSHIP_PROMPT_ADMIN='#❯'
   else
       export STARSHIP_PROMPT_USER='~❯'
   fi
   ```
4. `~/.config/starship.toml` を本リポジトリの `config/starship/starship.toml` にシンボリックリンク

zsh / bash 側は本 runbook では扱わない (必要になったタイミングで別 runbook を追加する)。
