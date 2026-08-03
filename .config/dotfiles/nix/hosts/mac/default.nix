{ hostname, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = hostname;
  networking.computerName = hostname;
}
