eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(sheldon source)"
source ~/.config/zsh/aliases.zsh 

set -o ignoreeof

# tmuxでexitしたときにアタッチしているセッションを消さないための処理
if [ -n "$TMUX" ]; then
    exit() {
        echo "現在のtmuxセッションを閉じますか?	(y/N): "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                builtin exit "$@"
                ;;
            *)
                echo "このセッションを継続します"
                ;;
        esac
    }
fi


. "$HOME/.local/bin/env"
. ~/.config/zsh/.zshenv
