# This file is pretty general, and you can adapt it in your project replacing
# only `name` and `description` below.

{
  # TODO: Transform this into a buildable package!
  description = "Devshell for the labelgen code";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem 
      (system:
        let
          pkgs = import nixpkgs { inherit system ; };
          pythonWithPkgs = pkgs.python39.withPackages ( p : [ p.qrcode p.tqdm p.pillow ] );
          texWithPkgs  = (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-small textpos; });
        in
        {
          devShell = pkgs.mkShell {
            packages = with pkgs; [ pythonWithPkgs texWithPkgs ];
            LABEL_FONT = "${pkgs.liberation_ttf.outPath}/share/fonts/truetype/LiberationSans-Regular.ttf";
          };
        }
      );
}

