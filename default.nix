{ pkgs ? import <nixpkgs> {}
, modules ? []
, specialArgs ? {}
}:
let 
  input = pkgs.lib.evalModules {
    modules = [
      ./options.nix
      ./target.nix
    ] ++ modules;
    specialArgs = specialArgs // {inherit pkgs;};
  };
in input.config.target.app // {
  inherit input;
  inherit (input.config.target) editor desktop settings;
}
