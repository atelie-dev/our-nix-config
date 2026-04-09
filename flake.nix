{
  description = "flake for fabio-nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    solaar.url = "github:Svenum/Solaar-Flake/main";
    solaar.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      solaar,
      nix-index-database,
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
