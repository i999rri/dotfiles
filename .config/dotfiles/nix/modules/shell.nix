{ pkgs, ... }:
{
  # programs.zsh.enable and the completion opt-out are set in shared/common.nix.
  programs.zsh = {
    enableBashCompletion = false;
    histSize = 100000;
  };

  users.defaultUserShell = pkgs.zsh;

  # NixOS keeps a whitelist of login shells; zsh is not on it by default.
  environment.shells = with pkgs; [
    zsh
    bash
  ];

  environment.pathsToLink = [ "/share/zsh" ];
}
