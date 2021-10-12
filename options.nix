{pkgs, lib, ...}:
let
  inherit (import ./common.nix lib) extensionMetadata;
in
with lib;
{
  options = {
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "VSCode configuration file";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.vscode;
      defaultText = literalExample "pkgs.vscode";
      description = "VSCode package";
    };
    identifier = mkOption {
      type = types.str;
      description = "Just an unique name for this configuration to avoid conflicts";
    };
    extensionsByPath = mkOption {
      default = [];
      type = types.listOf (types.submodule {
        inherit (commonMetadata) publisher name version;
        path = mkOption {
          type = types.path;
          description = "Where the extension is located?";
        };
      });
      description = "Additional extensions expected to be in the derivation root";
    };
    extensions = mkOption {
      default = [];
      type = types.listOf (types.submodule {
        options = {
          inherit (extensionMetadata) publisher name version;
          sha256 = mkOption {
            type = types.str;
            description = "SHA256 of the extension";
            default = "0000000000000000000000000000000000000000000000000000";
          };
        };
      });
    };
  };
}
