{
  description = "Development environment";

  inputs = {
      nixpkgs = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (nixpkgs.lib) optional;
        pkgs = import nixpkgs { inherit system; };

	elixir = pkgs.elixir;
        locales = pkgs.glibcLocales;
      in
      {
          devShell = pkgs.mkShell
          {
              buildInputs = [
		elixir
            ] ++ optional pkgs.stdenv.isLinux locales;
          };
      }
    );
}
