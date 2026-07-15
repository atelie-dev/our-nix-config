{
  description = "flake for atelie-dev machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    solaar.url = "github:Svenum/Solaar-Flake/main";
    solaar.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    basecamp-cli.url = "github:basecamp/basecamp-cli/0eb7a9a64b6ffd43ec2ffaaf0c50e58e3d61c6da";
    basecamp-cli.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      solaar,
      nix-index-database,
      sops-nix,
      basecamp-cli,
    }@inputs:
    let
      inherit (self) outputs;
    in
    {
      nixosConfigurations = {
        fabio-nixos = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            solaar.nixosModules.default
            ./fabio-nixos/configuration.nix
            nix-index-database.nixosModules.default
            { programs.nix-index-database.comma.enable = true; }
          ];
        };
        marcel-nixos = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./marcel-nixos/configuration.nix
            nix-index-database.nixosModules.default
            { programs.nix-index-database.comma.enable = true; }
          ];
        };
        tania-nixos = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            solaar.nixosModules.default
            ./tania-nixos/configuration.nix
            nix-index-database.nixosModules.default
            { programs.nix-index-database.comma.enable = true; }
          ];
        };
        lg-gram-i7 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            solaar.nixosModules.default
            ./lg-gram-i7/configuration.nix
            nix-index-database.nixosModules.default
            { programs.nix-index-database.comma.enable = true; }
          ];
        };
      };
    };
}
