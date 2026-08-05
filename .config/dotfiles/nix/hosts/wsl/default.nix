{
  inputs,
  pkgs,
  username,
  ...
}:
let
  # gh auth login のように「ブラウザを開く」CLI のための $BROWSER。
  #
  # explorer.exe は使わない。URL を渡せば既定のブラウザで開くものの、引数が
  # 空だったり URL でなかったりすると代わりにファイルエクスプローラが開いて
  # しまうため、$BROWSER としては挙動が広すぎる。
  #
  # rundll32 の FileProtocolHandler は URL プロトコルのハンドラだけを呼ぶので、
  # 開くのは既定のブラウザに限られる。引数が不正なら何も起きない。
  #
  # この用途では wslu の wslview が定番だったが、プロジェクトが終了して
  # nixpkgs からも削除された (2026-04)。
  wslBrowser = pkgs.writeShellScriptBin "wsl-browser" ''
    set -eu

    url="''${1:-}"

    # 受け取るのは http(s) の URL だけに絞る。ブラウザを開くつもりで別のものが
    # 起動する経路を残さない
    case "$url" in
      http://* | https://*) ;;
      *)
        echo "wsl-browser: http(s) の URL のみ受け付ける: ''${url:-(引数なし)}" >&2
        exit 2
        ;;
    esac

    exec /mnt/c/Windows/System32/rundll32.exe url.dll,FileProtocolHandler "$url"
  '';

  # WSLg を切っているため Wayland のクリップボードが存在しない。Windows 側の
  # クリップボードを直接読み書きする。
  #
  # clip.exe は入力をそのまま UTF-16 に変換して取り込むので、書き込みはこれで
  # 済む。
  wslClipboardCopy = pkgs.writeShellScriptBin "wsl-copy" ''
    exec /mnt/c/Windows/System32/clip.exe
  '';

  # 読み出しは PowerShell を経由する。Get-Clipboard は行ごとに CRLF を付けて
  # 返すため、CR を落としてから渡す。末尾に余計な改行が付くのも削る
  # (nvim の unnamedplus は 1 行ヤンクでも末尾改行があると行指向として貼る)。
  wslClipboardPaste = pkgs.writeShellScriptBin "wsl-paste" ''
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe \
      -NoProfile -NonInteractive -Command \
      "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-Clipboard -Raw" \
      2> /dev/null | ${pkgs.coreutils}/bin/tr -d '\r' | ${pkgs.gnused}/bin/sed -e '$ { /^$/ d }'
  '';
in
{
  imports = [
    inputs.nixos-wsl.nixosModules.default

    # ローカルの Kubernetes。常駐するのでホスト単位で入れる
    ../../modules/k3s.nix
  ];

  wsl = {
    enable = true;
    defaultUser = username;

    # Windows PATH on $PATH makes exec lookups walk /mnt/c on every miss, which
    # is slow. The interop entries that matter are added explicitly below.
    interop.includePath = false;
  };

  users.users.${username} = {
    isNormalUser = true;

    # Pinned rather than auto-allocated. Ownership on disk is recorded by uid,
    # so an account that gets a different number on another machine - or a
    # replaced account that inherits a recycled one - ends up owning the wrong
    # files. 1000 is what NixOS-WSL's stock user already holds.
    uid = 1000;

    extraGroups = [ "wheel" ];
  };

  # Single-user development box behind the Windows login; a sudo password here
  # buys nothing and breaks non-interactive rebuilds.
  security.sudo.wheelNeedsPassword = false;

  networking.hostName = "nixos-wsl";

  # Only the Windows interop paths that are actually used, instead of the whole
  # Windows PATH.
  # Appended rather than set through environment.variables.PATH, which
  # NixOS-WSL already defines and which allows only one definition.
  environment.extraInit = ''
    export PATH="$PATH:/mnt/c/Windows/System32:/mnt/c/Windows"
  '';

  # nvim sets clipboard=unnamedplus, which needs something to shell out to.
  # Windows' own clipboard tools are used rather than wl-clipboard: reaching the
  # Wayland clipboard requires WSLg, and WSLg's msrdc process steals window
  # focus on the Windows side even when nothing here has opened a GUI. It is
  # disabled in .wslconfig, so there is no Wayland socket to talk to.
  environment.systemPackages = [
    wslClipboardCopy
    wslClipboardPaste
    wslBrowser
  ];

  environment.variables.BROWSER = "wsl-browser";

  system.stateVersion = "26.05";
}
