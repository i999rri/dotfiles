# NixOS-only system settings. Anything nix-darwin also understands lives in
# nix/shared/common.nix.
{ pkgs, ... }:
{
  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

  # Store grows without bound otherwise; every rebuild keeps the old closure.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Interface stays English so tool output matches upstream docs; formats are local.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_TIME = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
    };
  };

  console.keyMap = "us";

  # mason.nvim and other tools download prebuilt binaries that expect a standard
  # FHS loader, which NixOS does not have. nix-ld provides one so they run as-is.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      libxml2
      icu
    ];
  };

  environment.systemPackages = with pkgs; [ killall ];
}
