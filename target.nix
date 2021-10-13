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
    settings = lib.mkOption {
      type = types.package;
    };
    editor = lib.mkOption {
      type = types.package;
    };
  };
  config.target.editor = pkgs.writeShellScriptBin "code" ''
    TMP=`dirname $(mktemp -u)`
    IDENTIFIER="${config.identifier}"
    PROFILE_DIR="$TMP/nix-vscode-$IDENTIFIER"
    mkdir -p "$PROFILE_DIR/User"
    echo "Using profile dir '$PROFILE_DIR'"
    pushd "$PROFILE_DIR/User" > /dev/null
      ln -s "${config.target.settings}" settings.json
      mkdir -p extensions
      for d in ${config.target.extensionDirectory}/*; do
        ln -s "$d" extensions
      done
    popd > /dev/null
    ${config.package}/bin/code "$@" --user-data-dir="$PROFILE_DIR" --extensions-dir="$PROFILE_DIR/User/extensions" -w
    if [ -z "$DEBUG" ]; then
      echo "Cleaning up files..."
      rm "$PROFILE_DIR" -rf
    fi
  '';
  config.target.settings = pkgs.writeTextFile {
    name = "settings.json";
    text = builtins.toJSON config.settings;
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
