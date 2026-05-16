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