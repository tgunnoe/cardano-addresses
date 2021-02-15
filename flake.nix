{
  description = "Cardano Addresses";

  inputs = {
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, haskell-nix, ... }:
    (utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let
        legacyPackages = import ./nix {
          ownHaskellNix = haskell-nix.legacyPackages.${system};
          inherit system;
        };
    in {
      inherit legacyPackages;
    }));
}
