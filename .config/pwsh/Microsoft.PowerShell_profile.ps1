Clear-Host

# Predictive IntelliSense renders a greyed-out completion to the right of the
# cursor as you type. Dropping the source removes that suggestion while leaving
# history recall (up-arrow, Ctrl+R) untouched. PSReadLine is absent from
# non-interactive hosts, so guard before calling into it.
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -PredictionSource None
}

# Detect admin status for starship prompt symbol switching.
# Sets exactly ONE of STARSHIP_PROMPT_ADMIN / STARSHIP_PROMPT_USER so
# starship's env_var modules render the matching prompt with its own
# colour (red for admin, orange for user).
$isAdmin = ([System.Security.Principal.WindowsPrincipal]::new(
    [System.Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    $env:STARSHIP_PROMPT_ADMIN = '#❯'
    Remove-Item Env:STARSHIP_PROMPT_USER -ErrorAction SilentlyContinue
} else {
    $env:STARSHIP_PROMPT_USER = '~❯'
    Remove-Item Env:STARSHIP_PROMPT_ADMIN -ErrorAction SilentlyContinue
}

# Prompt
Invoke-Expression (&starship init powershell)

# After starship init: wrap the prompt function so we can flag whether
# the current directory is inside a git repository. starship has no
# built-in conditional formatting based on git presence, so we surface
# the answer through STARSHIP_NO_GIT (set when *outside* a repo) and
# let an env_var module render the directory's closing slant only in
# that case.
$global:_starshipPrompt = $function:prompt
$global:_lastPwd = $null
$global:_inGitRepo = $false

function global:prompt {
    if ($PWD.Path -ne $global:_lastPwd) {
        $global:_lastPwd = $PWD.Path
        $global:_inGitRepo = $false
        $dir = $PWD.Path
        while ($dir) {
            if (Test-Path -LiteralPath (Join-Path $dir '.git')) {
                $global:_inGitRepo = $true
                break
            }
            $parent = Split-Path -Parent $dir
            if (-not $parent -or $parent -eq $dir) { break }
            $dir = $parent
        }
    }
    if ($global:_inGitRepo) {
        Remove-Item Env:STARSHIP_NO_GIT -ErrorAction SilentlyContinue
    } else {
        $env:STARSHIP_NO_GIT = '1'
    }
    & $global:_starshipPrompt
}

# Start WSL in the Linux home rather than mirroring the Windows working
# directory. '~' stays quoted because PowerShell expands a bare ~ to the
# Windows profile path before wsl.exe ever sees it, which lands the shell in
# /mnt/c/Users/... instead.
#
# A native command inside a function does not inherit the pipeline, so piped
# input is forwarded explicitly. The forward is conditional: handing wsl.exe an
# empty $input closes stdin, and an interactive `wsl` would exit at once.
#
# Management subcommands (--shutdown, -l -v, ...) ignore the extra --cd, and an
# explicit --cd later on the line wins, so neither needs a special case.
function wsl {
    if ($MyInvocation.ExpectingInput) {
        $input | wsl.exe --cd '~' @args
    } else {
        wsl.exe --cd '~' @args
    }
}
