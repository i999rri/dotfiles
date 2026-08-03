#!/usr/bin/env bash
#
# 初回セットアップ。OS を判定して NixOS / nix-darwin のどちらを反映するか決める。
#
# dotfiles は bare repository として $HOME に直接展開するため、シンボリックリンクは
# 1 本も張らない。詳細は docs/setup-nixos.md を参照。
#
#   curl -fsSL https://raw.githubusercontent.com/i999rri/dotfiles/main/.config/dotfiles/bootstrap.sh | bash
#
# 展開済みの環境では、そのまま実行してもよい:
#
#   bash ~/.config/dotfiles/bootstrap.sh
#
set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/i999rri/dotfiles.git}"
GIT_DIR="$HOME/.dotfiles"
FLAKE_DIR="$HOME/.config/dotfiles"

# 初回は flakes がまだ有効になっていない。この実行の間だけ有効にする
# (反映後は nix/shared/common.nix が恒久的に有効化する)
export NIX_CONFIG="experimental-features = nix-command flakes"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die() {
    printf '\033[1;31m==>\033[0m %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
usage: bootstrap.sh [host]

  host  適用するホスト名。省略すると OS から判定する
          WSL   -> wsl
          macOS -> mac
        ホストの一覧は flake.nix の nixosConfigurations /
        darwinConfigurations を参照。

環境変数:
  DOTFILES_REPO  clone 元 (既定: i999rri/dotfiles)
EOF
}

dot() { git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }

# 素の NixOS には git が入っていないため、必要なら nix-shell で一時的に借りる
run_with_git() {
    if command -v git > /dev/null 2>&1; then
        "$@"
    elif command -v nix-shell > /dev/null 2>&1; then
        log "git がないため nix-shell で一時的に用意する"
        nix-shell -p git --run "$(printf '%q ' "$@")"
    else
        die "git も nix-shell も見つからない。先に Nix を入れる"
    fi
}

detect_os() {
    case "$(uname -s)" in
        Darwin) echo darwin ;;
        Linux) echo linux ;;
        *) echo unknown ;;
    esac
}

detect_host() {
    case "$(detect_os)" in
        darwin) echo mac ;;
        linux)
            if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2> /dev/null; then
                echo wsl
            else
                echo ""
            fi
            ;;
        *) echo "" ;;
    esac
}

ensure_nix() {
    command -v nix > /dev/null 2>&1 && return 0

    if [ "$(detect_os)" = darwin ]; then
        die "Nix が入っていない。先に入れる:
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    fi

    die "Nix が入っていない。NixOS 以外の Linux では先に Nix を入れる"
}

# bare repository として $HOME に展開する。既存ファイルと衝突したら退避してから続ける
bootstrap_repo() {
    if [ -d "$GIT_DIR" ]; then
        log "dotfiles は展開済み ($GIT_DIR)"
        return
    fi

    log "dotfiles を bare repository として clone する"
    run_with_git git clone --bare "$REPO_URL" "$GIT_DIR"

    # work-tree が $HOME なので、これがないと $HOME 配下の全ファイルが
    # untracked として列挙されて git status が使い物にならない
    run_with_git git --git-dir="$GIT_DIR" --work-tree="$HOME" config status.showUntrackedFiles no

    log "$HOME に展開する"
    if ! run_with_git git --git-dir="$GIT_DIR" --work-tree="$HOME" checkout 2> /dev/null; then
        local backup
        backup="$HOME/.dotfiles-backup"
        warn "既存ファイルと衝突した。$backup に退避してから展開する"

        run_with_git git --git-dir="$GIT_DIR" --work-tree="$HOME" checkout 2>&1 \
            | grep -E '^\s+\.' | sed 's/^[[:space:]]*//' \
            | while read -r f; do
                mkdir -p "$backup/$(dirname "$f")"
                mv "$HOME/$f" "$backup/$f"
            done

        run_with_git git --git-dir="$GIT_DIR" --work-tree="$HOME" checkout
    fi
}

apply_nixos() {
    local host="$1"
    log "nixos-rebuild switch --flake .#$host"

    # nixos-rebuild は --extra-experimental-features を受け付けないため
    # NIX_CONFIG で渡す。sudo は環境変数を落とすので明示的に引き継ぐ
    sudo NIX_CONFIG="$NIX_CONFIG" nixos-rebuild switch --flake "$FLAKE_DIR#$host"
}

apply_darwin() {
    local host="$1"

    if command -v darwin-rebuild > /dev/null 2>&1; then
        log "darwin-rebuild switch --flake .#$host"
        sudo darwin-rebuild switch --flake "$FLAKE_DIR#$host"
    else
        log "nix-darwin が未導入のため nix run で初回反映する"
        sudo nix run nix-darwin -- switch --flake "$FLAKE_DIR#$host"
    fi
}

main() {
    case "${1:-}" in
        -h | --help)
            usage
            exit 0
            ;;
    esac

    ensure_nix
    bootstrap_repo

    local host
    host="${1:-$(detect_host)}"

    if [ -z "$host" ]; then
        usage
        die "OS からホストを判定できなかった。引数で指定する"
    fi

    [ -d "$FLAKE_DIR" ] || die "$FLAKE_DIR がない。展開に失敗している"

    case "$(detect_os)" in
        linux) apply_nixos "$host" ;;
        darwin) apply_darwin "$host" ;;
        *) die "対応していない OS: $(uname -s)" ;;
    esac

    log "完了。新しいシェルを開くと反映される"

    if [ "$(detect_host)" = wsl ] && [ "$(whoami)" != "$(basename "$HOME")" ]; then
        warn "ユーザーが切り替わる設定になっている。Windows 側で 'wsl --shutdown' してから開き直し、"
        warn "新しい \$HOME でこのスクリプトをもう一度実行する"
    fi
}

main "$@"
