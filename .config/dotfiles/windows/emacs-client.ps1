# Explorer・スタートメニュー・タスクバーから開くファイルを、裏で動いている Emacs の
# 1 つのフレームに集める。プロジェクトごとのタブへの振り分けは init.el 側が行う。
#
# Emacs は MSYS2 の mingw64 版を使う (pacman -S mingw-w64-x86_64-emacs)。ネイティブ
# コンパイルに要る libgccjit が同じ場所の DLL で揃うため。管理者権限は要らない。

$ErrorActionPreference = 'Stop'

# current は scoop が張るリンクなので、MSYS2 のバージョンを跨いでも壊れない
$bin = Join-Path (scoop prefix msys2) 'mingw64\bin'
$client = Join-Path $bin 'emacsclientw.exe'
$daemon = Join-Path $bin 'runemacs.exe'
$icon = "$daemon,0"
if (-not (Test-Path $client)) { throw "MSYS2 の Emacs が見つからない: $client" }

# -r: フレームがあればそれを使い、無ければ作る
# -a "": サーバーが居なければ daemon を立ててから繋ぐ
$clientArgs = '-r -n -a ""'

$shell = New-Object -ComObject WScript.Shell
function Set-Shortcut([string] $path, [string] $target, [string] $arguments) {
    $shortcut = $shell.CreateShortcut($path)
    $shortcut.TargetPath = $target
    $shortcut.Arguments = $arguments
    $shortcut.IconLocation = $icon
    $shortcut.Save()
    Write-Host "shortcut: $path"
}

$programs = [Environment]::GetFolderPath('Programs')

# スタートメニュー。runemacs を直接起動すると daemon とは別のプロセスになり、窓が
# 分かれるため、クライアント経由にする
Set-Shortcut (Join-Path $programs 'Emacs.lnk') $client $clientArgs

# ログイン時に daemon を立てておく。最初に開くときに起動を待たずに済む
Set-Shortcut (Join-Path ([Environment]::GetFolderPath('Startup')) 'Emacs Daemon.lnk') $daemon '--daemon'

# scoop 版の Emacs を残している間は、そのショートカットも同じ起動の仕方にそろえる
$scoopApps = Join-Path $programs 'Scoop Apps'
if (Test-Path $scoopApps) {
    foreach ($lnk in Get-ChildItem $scoopApps -Filter 'Emacs*.lnk') {
        Set-Shortcut $lnk.FullName $client $clientArgs
    }
}

# タスクバーのピン留め。開いている窓からピン留めすると、窓の持ち主の emacs.exe を
# 直接起動するショートカットになるため、付け直したらもう一度実行する。
# Emacs の窓は AppUserModelID に GNU.Emacs を名乗っており、ピンにも同じ ID が
# 付いている。書き換えても ID は残るので、クライアントから開いた窓もピンにまとまる
$pinned = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
$pinnedFolder = (New-Object -ComObject Shell.Application).Namespace($pinned)
foreach ($item in @($pinnedFolder.Items())) {
    if (-not $item.Path.EndsWith('.lnk')) { continue }

    $target = $shell.CreateShortcut($item.Path).TargetPath
    $isEmacs = $item.ExtendedProperty('System.AppUserModel.ID') -eq 'GNU.Emacs' -or
        $target -match '\\(run)?emacs(client)?w?\.exe$'
    if (-not $isEmacs) { continue }

    Set-Shortcut $item.Path $client $clientArgs
}

# Explorer の右クリック。* をパスとして扱うと wildcard に展開されるため、
# PSDrive を通さずにキーを作る
function Set-EmacsVerb([string] $class, [string] $target) {
    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("Software\Classes\$class\shell\emacs")
    $key.SetValue('', 'Emacs で開く')
    $key.SetValue('Icon', $icon)
    $key.CreateSubKey('command').SetValue('', "`"$client`" $clientArgs `"$target`"")
    Write-Host "verb: $class"
}

Set-EmacsVerb '*' '%1'                     # ファイル
Set-EmacsVerb 'Directory' '%1'             # フォルダ
Set-EmacsVerb 'Directory\Background' '%V'  # フォルダの中の余白

# 「プログラムから開く」の候補に出す。拡張子の既定アプリにするのは Windows が
# 手動の操作しか受け付けないため、ここではやらない
$app = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Software\Classes\Applications\emacsclientw.exe')
$app.SetValue('FriendlyAppName', 'Emacs')
$app.CreateSubKey('DefaultIcon').SetValue('', $icon)
$app.CreateSubKey('shell\open\command').SetValue('', "`"$client`" $clientArgs `"%1`"")
Write-Host 'open with: emacsclientw.exe'
