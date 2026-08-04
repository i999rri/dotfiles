Clear-Host

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