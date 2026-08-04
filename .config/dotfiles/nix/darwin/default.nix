# nix-darwin-only system settings. Anything NixOS also understands lives in
# nix/shared/common.nix.
{ pkgs, username, ... }:
{
  imports = [ ../shared/common.nix ];

  # macOS puts administrators in @admin, not @wheel.
  nix.settings.trusted-users = [
    "root"
    "@admin"
  ];

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  # User-level settings (defaults, home) need to know whose account to touch.
  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  environment.shells = with pkgs; [
    zsh
    bash
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Homebrew is left alone on purpose: .zshrc already sources it when present,
  # and the casks on a Mac are GUI apps that Nix has no business managing here.

  system.stateVersion = 6;
}
