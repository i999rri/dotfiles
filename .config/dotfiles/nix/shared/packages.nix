# Command line environment shared by every OS. The list is driven by what the
# config files under .config/ actually assume exists: .zshrc calls sheldon and
# starship, tmux.conf clones tpm with git, nvim's fzf-lua shells out to fzf, rg
# and fd, and init.lua opens lazygit.
#
# Language toolchains deliberately stay out: per-project flakes pin their own
# versions and direnv loads them on cd.
{ pkgs }:
with pkgs;
[
  # version control
  git
  git-lfs
  gh
  lazygit
  delta

  # editor
  neovim

  # terminal multiplexer
  tmux

  # prompt and shell plumbing
  starship
  sheldon
  zoxide
  fzf

  # search and file tooling
  ripgrep
  fd
  bat
  eza
  tree

  # data wrangling
  jq
  yq-go

  # network and archives
  curl
  wget
  unzip
  zip

  # system inspection
  htop
  dust
  procs
  file
  which

  # task runner
  just

  # nix authoring
  nixfmt
  nil
]
