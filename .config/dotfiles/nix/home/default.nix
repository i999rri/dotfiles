{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  home.username = username;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "26.05";

  # Config files are real files at their standard XDG paths, checked out by the
  # bare repository in ~/.dotfiles. home-manager deliberately does not manage
  # them: it would replace them with store symlinks and editing would stop
  # working. What it does provide is the environment those files assume.

  xdg.enable = true;

  # STARSHIP_CONFIG is set system-wide in nix/shared/common.nix instead of here:
  # home.sessionVariables lands in hm-session-vars.sh, which the repo's .zshrc
  # does not source (it has to stay portable to macOS and Windows).

  # tmux.conf ends with `run "$XDG_CONFIG_HOME/tmux/plugins/tpm/tpm"`, and
  # .config/tmux/.gitignore excludes plugins/, so tpm is never checked out.
  # Without this, every tmux start errors out until it is cloned by hand.
  home.activation.bootstrapTpm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    tpmDir="${config.xdg.configHome}/tmux/plugins/tpm"
    if [ ! -d "$tpmDir" ]; then
      run ${pkgs.git}/bin/git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpmDir"
    fi
  '';

  programs.home-manager.enable = true;
}
