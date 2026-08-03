{
  config,
  lib,
  pkgs,
  username,
  repoUrl,
  ...
}:
let
  git = "${pkgs.git}/bin/git";
in
{
  home.username = username;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "26.05";

  # Config files are real files at their standard XDG paths, checked out by the
  # bare repository in ~/.dotfiles. home-manager deliberately does not manage
  # them: it would replace them with store symlinks and editing would stop
  # working. What it does provide is the environment those files assume, plus
  # the one-time bootstrap below.

  xdg.enable = true;

  # STARSHIP_CONFIG is set system-wide in nix/shared/common.nix instead of here:
  # home.sessionVariables lands in hm-session-vars.sh, which the repo's .zshrc
  # does not source (it has to stay portable to macOS and Windows).

  # Fetching and checking out are separate steps on purpose. Once the bare
  # repository exists nothing here touches the network again, so a rebuild works
  # offline; only the very first one needs to reach GitHub. Neither step is an
  # error hard enough to fail the activation - a machine with a working system
  # closure but no dotfiles is still usable, and the next switch retries.
  home.activation.bootstrapDotfiles = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gitDir="$HOME/.dotfiles"

    if [ ! -d "$gitDir" ]; then
      if run ${git} clone --bare --quiet ${repoUrl} "$gitDir"; then
        # Without this, git status lists every file under $HOME as untracked,
        # because the work tree is $HOME itself.
        run ${git} --git-dir="$gitDir" --work-tree="$HOME" \
          config status.showUntrackedFiles no
      else
        warnEcho "dotfiles を取得できなかった。次回の switch で再試行する"
      fi
    fi

    # .zshenv is the repository's marker file at the top of $HOME: present means
    # the checkout already happened.
    if [ -d "$gitDir" ] && [ ! -e "$HOME/.zshenv" ]; then
      run ${git} --git-dir="$gitDir" --work-tree="$HOME" checkout \
        || warnEcho "dotfiles の展開が既存ファイルと衝突した。退避してから checkout する"
    fi
  '';

  # tmux.conf ends with `run "$XDG_CONFIG_HOME/tmux/plugins/tpm/tpm"`, and
  # .config/tmux/.gitignore excludes plugins/, so tpm is never checked out.
  # Without this, every tmux start errors out until it is cloned by hand.
  home.activation.bootstrapTpm = lib.hm.dag.entryAfter [ "bootstrapDotfiles" ] ''
    tpmDir="${config.xdg.configHome}/tmux/plugins/tpm"
    if [ ! -d "$tpmDir" ]; then
      run ${git} clone --depth 1 --quiet https://github.com/tmux-plugins/tpm "$tpmDir" \
        || warnEcho "tpm を取得できなかった。次回の switch で再試行する"
    fi
  '';

  programs.home-manager.enable = true;
}
