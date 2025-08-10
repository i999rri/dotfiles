eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(sheldon source)"
alias ghostty="/Applications/Ghostty.app/Contents/MacOS/ghostty"
alias config="vim ~/.config/ghostty/config"

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

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
