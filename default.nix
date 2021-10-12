{ pkgs ? import <nixpkgs> {}
, modules ? []
, specialArgs ? {}
}:
let 
  input = pkgs.lib.evalModules {
    modules = [
      ./module.nix
      ./options.nix
      ./target.nix
      ./test.nix
    ] ++ modules;
    specialArgs = specialArgs // {inherit pkgs;};
  };
  vscodeModules = pkgs.vscode-utils.extensionsFromVscodeMarketplace input.config.extensions;
in {inherit input;}
