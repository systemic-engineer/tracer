{
  description = "Reed's body - Ghost sync service";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            elixir
            erlang
          ];

          shellHook = ''
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            mkdir -p .nix-mix .nix-hex

            # Install hex and rebar if not already installed
            mix local.hex --force --if-missing >/dev/null 2>&1
            mix local.rebar --force --if-missing >/dev/null 2>&1
          '';
        };
      }
    );
}
