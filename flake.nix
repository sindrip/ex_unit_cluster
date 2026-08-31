{
  description = "Development environment for ex_unit_cluster";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          beam = pkgs.beam.packages.erlang_29;
        in
        {
          default = pkgs.mkShell {
            name = "ex_unit_cluster";
            packages = [
              beam.elixir_1_20
              beam.expert
            ];
          };
        }
      );
    };
}
