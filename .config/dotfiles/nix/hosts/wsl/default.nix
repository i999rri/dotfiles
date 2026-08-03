{
  inputs,
  pkgs,
  username,
  ...
}:
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl = {
    enable = true;
    defaultUser = username;

    # Windows PATH on $PATH makes exec lookups walk /mnt/c on every miss, which
    # is slow. The interop entries that matter are added explicitly below.
    interop.includePath = false;
  };

  users.users.${username} = {
    isNormalUser = true;
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
  environment.systemPackages = [ pkgs.wl-clipboard ];

  system.stateVersion = "26.05";
}
