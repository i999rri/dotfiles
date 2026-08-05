{
  inputs,
  pkgs,
  username,
  ...
}:
let
  # gh auth login のように「ブラウザを開く」CLI のための $BROWSER。
  #
  # explorer.exe に URL を渡すと Windows 側の既定のブラウザで開くが、成功して
  # も終了コード 1 を返すため、それを見ている呼び出し元が失敗と誤判定する。
  # ここで握りつぶしておく。
  #
  # この用途では wslu の wslview が定番だったが、プロジェクトが終了して
  # nixpkgs からも削除された (2026-04)。
  wslBrowser = pkgs.writeShellScriptBin "wsl-browser" ''
    /mnt/c/Windows/explorer.exe "$@" || true
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
  # WSLg exposes a Wayland clipboard, so the normal Linux tool works.
  environment.systemPackages = [
    pkgs.wl-clipboard
    wslBrowser
  ];

  environment.variables.BROWSER = "wsl-browser";

  system.stateVersion = "26.05";
}
