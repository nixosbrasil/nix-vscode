lib: with lib; rec {
  extensionMetadata = {
      publisher = mkOption {
        type = types.str;
        description = "Publisher of the extension";
      };
      name = mkOption {
        type = types.str;
        description = "Name of the extension";
      };
      version = mkOption {
        type = types.str;
        description = "Version of the extension";
      };
    };
}

