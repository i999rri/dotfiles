# Explorer とスタートメニューから開くファイルを、起動中の Emacs の 1 つのフレームに
# 集める。プロジェクトごとのタブへの振り分けは init.el 側が行う。
#
# scoop update emacs を実行するとショートカットが manifest の既定 (-c で毎回新しい
# 窓を作る) に戻るため、更新後にもう一度実行する。管理者権限は要らない。

$ErrorActionPreference = 'Stop'

# current は scoop が更新のたびに張り替えるリンクなので、バージョンを跨いでも壊れない
$bin = Join-Path (scoop prefix emacs) 'bin'
$client = Join-Path $bin 'emacsclientw.exe'
$icon = "$(Join-Path $bin 'runemacs.exe'),0"

# -r: フレームがあればそれを使い、無ければ作る
# -a "": サーバーが居なければ daemon を立ててから繋ぐ
$clientArgs = '-r -n -a ""'

# スタートメニュー。runemacs を直接起動すると別のプロセスになり、窓が分かれるため、
# Emacs.lnk もクライアント経由にする
$shell = New-Object -ComObject WScript.Shell
$scoopApps = Join-Path ([Environment]::GetFolderPath('Programs')) 'Scoop Apps'
foreach ($lnk in Get-ChildItem $scoopApps -Filter 'Emacs*.lnk') {
    $shortcut = $shell.CreateShortcut($lnk.FullName)
    $shortcut.TargetPath = $client
    $shortcut.Arguments = $clientArgs
    $shortcut.IconLocation = $icon
    $shortcut.Save()
    Write-Host "shortcut: $($lnk.Name)"
}

# タスクバーのピン留め。開いている窓からピン留めすると、窓の持ち主の emacs.exe を
# 直接起動するショートカットになるため、付け直したらもう一度実行する。
# Emacs の窓は AppUserModelID に GNU.Emacs を名乗っており、ピンにも同じ ID が
# 付いている。書き換えても ID は残るので、クライアントから開いた窓もピンにまとまる
$pinned = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
$pinnedFolder = (New-Object -ComObject Shell.Application).Namespace($pinned)
foreach ($item in @($pinnedFolder.Items())) {
    if (-not $item.Path.EndsWith('.lnk')) { continue }

    $shortcut = $shell.CreateShortcut($item.Path)
    $isEmacs = $item.ExtendedProperty('System.AppUserModel.ID') -eq 'GNU.Emacs' -or
        $shortcut.TargetPath -match '\\(run)?emacs\.exe$'
    if (-not $isEmacs) { continue }

    $shortcut.TargetPath = $client
    $shortcut.Arguments = $clientArgs
    $shortcut.IconLocation = $icon
    $shortcut.Save()
    Write-Host "taskbar: $(Split-Path -Leaf $item.Path)"
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
