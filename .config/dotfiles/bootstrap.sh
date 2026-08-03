#!/usr/bin/env bash
#
# 初回セットアップ。OS を判定してシステムを構成する。
#
# dotfiles の $HOME への展開は home-manager の activation が行うため
# (nix/home/default.nix)、このスクリプトはシステムを反映するだけでよい。
# 反映さえすれば、そのユーザーの home-manager が bare repository を取得して
# $HOME に展開する。シンボリックリンクは 1 本も張らない。
#
#   curl -fsSL https://raw.githubusercontent.com/i999rri/dotfiles/main/.config/dotfiles/bootstrap.sh | bash
#
# NixOS-WSL の初回だけは root で実行する。stock の tarball が用意する暫定ユーザー
# (nixos) で作業すると、このリポジトリが作るユーザーへの切り替えでそのユーザー自身を
# 削除することになり、セッションが壊れるため。
#
# 詳細は docs/setup-nix.md を参照。
#
set -euo pipefail

# 手元にリポジトリがなければリモートの flake を直接指す。Nix は URL から flake を
# 引けるので、システムを構成する時点では clone が要らない
REMOTE_FLAKE="${DOTFILES_FLAKE:-github:i999rri/dotfiles?dir=.config/dotfiles}"
LOCAL_FLAKE="$HOME/.config/dotfiles"

# 初回は flakes がまだ有効になっていない。この実行の間だけ有効にする
# (反映後は nix/shared/common.nix が恒久的に有効化する)
export NIX_CONFIG="experimental-features = nix-command flakes"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
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

dotfiles の展開は home-manager が行うため、このスクリプトはシステムを
反映するだけ。NixOS-WSL の初回は root で実行する。

環境変数:
  DOTFILES_FLAKE  リモート flake (既定: github:i999rri/dotfiles?dir=.config/dotfiles)
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

# 展開済みならそれを使う。まだなら取得元をそのまま指す
flake_ref() {
    if [ -d "$LOCAL_FLAKE" ]; then
        echo "$LOCAL_FLAKE"
    else
        echo "$REMOTE_FLAKE"
    fi
}

ensure_nix() {
    command -v nix > /dev/null 2>&1 && return 0

    if [ "$(detect_os)" = darwin ]; then
        die "Nix が入っていない。先に入れる:
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    fi

    die "Nix が入っていない。NixOS 以外の Linux では先に Nix を入れる"
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

main() {
    case "${1:-}" in
        -h | --help)
            usage
            exit 0
            ;;
    esac

    ensure_nix

    local host flake
    host="${1:-$(detect_host)}"

    if [ -z "$host" ]; then
        usage
        die "OS からホストを判定できなかった。引数で指定する"
    fi

    flake="$(flake_ref)"

    case "$(detect_os)" in
        linux) apply_nixos "$host" "$flake" ;;
        darwin) apply_darwin "$host" "$flake" ;;
        *) die "対応していない OS: $(uname -s)" ;;
    esac

    if is_root && [ "$host" = wsl ]; then
        cat <<EOF

==> セットアップ完了。あとは WSL を落として入り直すだけ:

      wsl --shutdown
      wsl -d ${WSL_DISTRO_NAME:-NixOS}

    切り替わったユーザーで、dotfiles が展開された zsh が立ち上がる。
EOF
    else
        log "完了。新しいシェルを開くと反映される"
    fi
}

main "$@"
