# Options that NixOS and nix-darwin both understand, so the two stay in sync
# instead of drifting. Anything platform-specific lives in nix/modules (NixOS)
# or nix/darwin (macOS).
{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = import ./packages.nix { inherit pkgs; };

  time.timeZone = "Asia/Tokyo";

  programs.zsh = {
    enable = true;

    # .config/zsh/.zshrc owns the interactive setup. Leaving these on would
    # stack a second completion layer on top of it.
    enableCompletion = false;
  };

  environment.variables = {
    EDITOR = "nvim";

    # starship only looks at $XDG_CONFIG_HOME/starship.toml, but the repo keeps
    # the file namespaced under starship/ so Windows can share the same path.
    # Set at the system level rather than through home-manager because the
    # repo's .zshrc stays portable and never sources hm-session-vars.sh.
    STARSHIP_CONFIG = "$HOME/.config/starship/starship.toml";
  };
}
