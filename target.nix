{pkgs, lib, config, ...}:
with lib;
let
  inherit (import ./common.nix lib) commonMetadata;
in
{
  options.target = {
    extensionDirectory = lib.mkOption {
      type = types.package;
    };
  };
  config.target.extensionDirectory = with builtins; 
  let 
    expandByPath = e: ''
filename="${e.publisher}.${e.name}"
expanded="${e.path}/share/vscode/extensions/$filename"
if [ -d "$expanded" ]; then
  lnTo "$expanded" "$out/$filename"
else
  lnTo "${e.path}" "$out/$filename"
fi
    '';
    expandByMarketplace = e:
    let
      ext = pkgs.vscode-utils.extensionFromVscodeMarketplace e;
    in expandByPath {
      inherit (e) publisher name version;
      path = toPath ext;
    };
    packages = (map expandByPath config.extensionsByPath)
            ++ (map expandByMarketplace config.extensions);
  in pkgs.runCommand "extensions" {} ''
    mkdir -p $out
    function lnTo {
      echo "ln '$1' '$2'"
      ln -s "$1" "$2"
    }
    ${concatStringsSep "\n" packages}
  '';
}
