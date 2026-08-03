#!/usr/bin/env bash
#
# 初回セットアップ。OS を判定して NixOS / nix-darwin のどちらを反映するか決める。
#
# dotfiles は bare repository として $HOME に直接展開するため、シンボリックリンクは
# 1 本も張らない。詳細は docs/setup-nix.md を参照。
#
# 通常はセットアップ先のユーザーで実行する:
#
#   curl -fsSL https://raw.githubusercontent.com/i999rri/dotfiles/main/.config/dotfiles/bootstrap.sh | bash
#
# NixOS-WSL の初回だけは root で実行する。stock の tarball が用意する暫定ユーザー
# (nixos) で作業すると、このリポジトリが作るユーザーへの切り替えでそのユーザー自身を
# 削除することになり、セッションが壊れるため。
#
# root で実行した場合はこの 1 回で完結する:
#   1. clone せずリモートの flake からシステムを構成する ($HOME を汚さない)
#   2. そこで作られた目的のユーザーの $HOME に dotfiles を展開し、所有者を渡す
# あとは WSL を落として入り直すだけでよい。
#
set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/i999rri/dotfiles.git}"
REMOTE_FLAKE="${DOTFILES_FLAKE:-github:i999rri/dotfiles?dir=.config/dotfiles}"

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

root で実行した場合は、リモートの flake からシステムを構成したうえで、
そこで作られた目的のユーザーの $HOME に dotfiles まで展開する
(NixOS-WSL の初回セットアップ用。この 1 回で完結する)。

環境変数:
  DOTFILES_REPO   clone 元        (既定: i999rri/dotfiles)
  DOTFILES_FLAKE  リモート flake  (既定: github:i999rri/dotfiles?dir=.config/dotfiles)
EOF
}

is_root() { [ "$(id -u)" -eq 0 ]; }

# root ならそのまま、一般ユーザーなら sudo 経由で実行する。
# nixos-rebuild は --extra-experimental-features を受け付けないため NIX_CONFIG で
# 渡すが、sudo は環境変数を落とすので明示的に引き継ぐ
as_root() {
    if is_root; then
        env NIX_CONFIG="$NIX_CONFIG" "$@"
    else
        sudo NIX_CONFIG="$NIX_CONFIG" "$@"
    fi
}

# 素の NixOS には git が入っていないため、必要なら nix-shell で一時的に借りる
run_with_git() {
    if command -v git > /dev/null 2>&1; then
        "$@"
    elif command -v nix-shell > /dev/null 2>&1; then
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

# 反映後の目的ユーザー。NixOS-WSL は wsl.defaultUser を /etc/wsl.conf に書き出す
detect_target_user() {
    awk -F= '/^[[:space:]]*default[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2; exit}' \
        /etc/wsl.conf 2> /dev/null
}

home_of() { getent passwd "$1" | cut -d: -f6; }

ensure_nix() {
    command -v nix > /dev/null 2>&1 && return 0

    if [ "$(detect_os)" = darwin ]; then
        die "Nix が入っていない。先に入れる:
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    fi

    die "Nix が入っていない。NixOS 以外の Linux では先に Nix を入れる"
}

# bare repository として指定の home に展開する。
# owner を渡すと展開後に所有者をそのユーザーに移す (root が代理で展開する場合)。
bootstrap_repo_into() {
    local home="$1" owner="${2:-}"
    local git_dir="$home/.dotfiles"

    if [ -d "$git_dir" ]; then
        log "dotfiles は展開済み ($git_dir)"
        return
    fi

    [ -d "$home" ] || die "$home がない"

    local git=(git --git-dir="$git_dir" --work-tree="$home")

    log "dotfiles を bare repository として clone する -> $git_dir"
    run_with_git git clone --bare "$REPO_URL" "$git_dir"

    # work-tree が home なので、これがないと配下の全ファイルが untracked として
    # 列挙されて git status が使い物にならない
    run_with_git "${git[@]}" config status.showUntrackedFiles no

    log "$home に展開する"
    if ! run_with_git "${git[@]}" checkout 2> /dev/null; then
        local backup="$home/.dotfiles-backup"
        warn "既存ファイルと衝突した。$backup に退避してから展開する"

        run_with_git "${git[@]}" checkout 2>&1 \
            | grep -E '^\s+\.' | sed 's/^[[:space:]]*//' \
            | while read -r f; do
                mkdir -p "$backup/$(dirname "$f")"
                mv "$home/$f" "$backup/$f"
            done

        run_with_git "${git[@]}" checkout
    fi

    if [ -n "$owner" ]; then
        # root が代理で展開したので、新しいユーザーの持ち物にする。
        # 相手は作られたばかりの home なので、まるごと渡して問題ない
        log "所有者を $owner に移す"
        chown -R "$owner:$(id -gn "$owner")" "$home"
    fi
}

apply_nixos() {
    local host="$1" flake="$2"
    log "nixos-rebuild switch --flake $flake#$host"
    as_root nixos-rebuild switch --flake "${flake}#${host}"
}

apply_darwin() {
    local host="$1" flake="$2"

    if command -v darwin-rebuild > /dev/null 2>&1; then
        log "darwin-rebuild switch --flake $flake#$host"
        as_root darwin-rebuild switch --flake "${flake}#${host}"
    else
        log "nix-darwin が未導入のため nix run で初回反映する"
        as_root nix run nix-darwin -- switch --flake "${flake}#${host}"
    fi
}

# root での初回セットアップ。システム構成から目的ユーザーへの展開までを 1 回で終える
setup_as_root() {
    local host="$1"

    [ "$(detect_os)" = linux ] || die "macOS では root で実行しない"

    # まだ目的のユーザーが存在しないので、clone せずリモートの flake から構成する
    log "clone せずリモートの flake から構成する"
    apply_nixos "$host" "$REMOTE_FLAKE"

    # ここで目的のユーザーが作られている
    local user home
    user="$(detect_target_user)"

    if [ -z "$user" ] || [ "$user" = root ]; then
        warn "反映後のユーザーを特定できなかった。dotfiles の展開はそのユーザーで行う"
        return
    fi

    home="$(home_of "$user")"
    if [ -z "$home" ]; then
        warn "$user の home を特定できなかった。dotfiles の展開はそのユーザーで行う"
        return
    fi

    log "反映後のユーザー: $user ($home)"
    bootstrap_repo_into "$home" "$user"

    cat <<EOF

==> セットアップ完了。あとは WSL を落として入り直すだけ:

      wsl --shutdown
      wsl -d ${WSL_DISTRO_NAME:-NixOS}

    $user で入り、dotfiles が効いた zsh が立ち上がる。
EOF
}

main() {
    case "${1:-}" in
        -h | --help)
            usage
            exit 0
            ;;
    esac

    ensure_nix

    local host
    host="${1:-$(detect_host)}"

    if [ -z "$host" ]; then
        usage
        die "OS からホストを判定できなかった。引数で指定する"
    fi

    if is_root; then
        setup_as_root "$host"
        exit 0
    fi

    bootstrap_repo_into "$HOME"

    local flake_dir="$HOME/.config/dotfiles"
    [ -d "$flake_dir" ] || die "$flake_dir がない。展開に失敗している"

    case "$(detect_os)" in
        linux) apply_nixos "$host" "$flake_dir" ;;
        darwin) apply_darwin "$host" "$flake_dir" ;;
        *) die "対応していない OS: $(uname -s)" ;;
    esac

    log "完了。新しいシェルを開くと反映される"
}

main "$@"
