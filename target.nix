{pkgs, lib, config, ...}:
let
  inherit (import ./common.nix lib) commonMetadata;
  inherit (lib) mkOption types;
  inherit (pkgs) symlinkJoin makeDesktopItem writeTextFile runCommand;
  inherit (pkgs.vscode-utils) extensionFromVscodeMarketplace;
  inherit (builtins) toPath concatStringsSep toJSON;
in
{
  options.target = mkOption {
    type = types.attrsOf types.package;
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
  config.target.app = symlinkJoin {
    name = "vscode-${config.identifier}";
    paths = [
      config.target.desktop
      config.target.editor
    ];
  };
  config.target.desktop = makeDesktopItem {
    name = "vscode-${config.identifier}";
    desktopName = "VSCode (${config.identifier})";
    comment = "Code Editing. Redefined.";
    exec = "${config.target.editor}/bin/code %F";
    icon = "code";
    startupNotify = true;
    categories = [
      "Utility"
      "TextEditor"
      "Development"
      "IDE"
    ];
    mimeTypes = [
      "text/plain"
      "inode/directory"
    ];
    keywords = [
      "vscode"
    ];
    actions = {
      new-empty-window = {
        name = "New Empty Window";
        exec = "${config.target.editor} --new-window %F";
        icon = "code";
      };
    };
  };
  config.target.settings = writeTextFile {
    name = "settings.json";
    text = toJSON config.settings;
  };
  config.target.extensionDirectory =
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
    expandByMarketplace = e: expandByPath {
      inherit (e) publisher name version;
      path = toPath (extensionFromVscodeMarketplace e);
    };
    packages = (map expandByPath config.extensionsByPath)
            ++ (map expandByMarketplace config.extensions);
  in runCommand "extensions" {} ''
    mkdir -p $out
    function lnTo {
      echo "ln '$1' '$2'"
      ln -s "$1" "$2"
    }
    ${concatStringsSep "\n" packages}
  '';
}
