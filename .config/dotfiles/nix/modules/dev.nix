{ pkgs, ... }:
{
  # Language toolchains stay out of the system closure on purpose: per-project
  # flakes pin their own versions, and direnv loads them on cd. What lives here
  # is only what every project needs regardless of language.
  environment.systemPackages = with pkgs; [
    # nvim-treesitter compiles parsers on install, and node-based LSPs need node
    gcc
    gnumake
    pkg-config
    nodejs_22
    python3
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };
}
