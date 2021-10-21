{ pkgs ? import <nixpkgs> {}
, modules ? []
, specialArgs ? {}
, ...
}@args:
let 
  mainModule = builtins.removeAttrs args ["pkgs" "specialArgs"];
  input = pkgs.lib.evalModules {
    modules = [
      ./options.nix
      ./target.nix
      (args: mainModule)
    ];
    specialArgs = specialArgs // {inherit pkgs;};
  };
in input.config.target.app // {
  inherit input;
  inherit (input.config.target) editor desktop settings;
}
