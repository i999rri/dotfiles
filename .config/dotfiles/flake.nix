{
  description = "i999rri dotfiles - NixOS / nix-darwin system and home configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }@inputs:
    let
      defaultUser = "i999rri";

      # home-manager がこのリポジトリを $HOME に展開するときの取得元。
      # 手元に取得済みならネットワークには触らない (nix/home/default.nix)
      repoUrl = "https://github.com/i999rri/dotfiles.git";

      # home-manager is wired the same way on either OS; only the module it
      # hangs off differs.
      homeModule = user: hmModule: {
        imports = [ hmModule ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-bak";
          extraSpecialArgs = {
            inherit inputs repoUrl;
            username = user;
          };
          users.${user} = import ./nix/home;
        };
      };

      # A host is one machine. Everything shared lives in nix/shared and
      # nix/modules; everything specific to the machine lives in nix/hosts.
      mkNixos =
        {
          hostname,
          system ? "x86_64-linux",
          username ? defaultUser,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs username hostname; };
          modules = [
            ./nix/modules
            ./nix/hosts/${hostname}
            (homeModule username home-manager.nixosModules.home-manager)
          ] ++ extraModules;
        };

      mkDarwin =
        {
          hostname,
          username ? defaultUser,
          extraModules ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs username hostname; };
          modules = [
            ./nix/darwin
            ./nix/hosts/${hostname}
            (homeModule username home-manager.darwinModules.home-manager)
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        wsl = mkNixos { hostname = "wsl"; };
      };

      darwinConfigurations = {
        mac = mkDarwin { hostname = "mac"; };
      };

      formatter = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ] (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
