{ pkgs ? import <nixpkgs> {}
, modules ? []
, specialArgs ? {}
, ...
}@args:
let
  inherit (builtins) removeAttrs;
  inherit (pkgs) lib;
  inherit (lib) evalModules;
in
let 
  mainModule = removeAttrs args ["pkgs" "specialArgs"];
  input = evalModules {
    modules = [
      ./options.nix
      ./target.nix
      (args: mainModule)
    ];
    specialArgs = specialArgs // {
      inherit pkgs;
    };
  };
in input.config.target.app // {
  inherit (input) config options;
  inherit input;
  inherit (input.config.target) editor desktop settings;
}
