# macOS 以外には brew がないため、存在するときだけ読み込む
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if command -v sheldon > /dev/null 2>&1; then
    eval "$(sheldon source)"
fi

if command -v starship > /dev/null 2>&1; then
    # starship.toml の env_var モジュールが参照する。どちらか片方だけを設定する
    if [ "$EUID" -eq 0 ]; then
        export STARSHIP_PROMPT_ADMIN='#❯'
        unset STARSHIP_PROMPT_USER
    else
        export STARSHIP_PROMPT_USER='~❯'
        unset STARSHIP_PROMPT_ADMIN
    fi

    eval "$(starship init zsh)"

    # starship には git の有無で書式を変える機能がないため、リポジトリの外にいる
    # ことを環境変数で伝えて directory ブロックの閉じスラントを出し分ける
    # (pwsh プロファイル側と同じ役割)
    _starship_no_git() {
        if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
            unset STARSHIP_NO_GIT
        else
            export STARSHIP_NO_GIT=1
        fi
    }

    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _starship_no_git
fi

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


# uv などのインストーラが置くもの。ない環境ではスキップする
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

. ~/.config/zsh/.zshenv
