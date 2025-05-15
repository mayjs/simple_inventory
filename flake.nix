# This file is pretty general, and you can adapt it in your project replacing
# only `name` and `description` below.
{
  description = "Devshell for the labelgen code";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {inherit system;};
        texWithPkgs = pkgs.texlive.combine {inherit (pkgs.texlive) scheme-small textpos;};
        backendPythonDeps = python-pkgs: with python-pkgs; [qrcode tqdm pillow];
      in {
        packages.default = self.packages.${system}.simple_inventory_labelgen;
        packages.simple_inventory_labelgen = let
          backend_data = pkgs.python3Packages.buildPythonApplication {
            # Simple backend collection for the required base files
            pname = "simple_inventory_labelgen_backend";
            version = "0.1.0";
            src = ./label_gen;
            propagatedBuildInputs = backendPythonDeps (pkgs.python3Packages) ++ [texWithPkgs];
            format = "other";
            dontBuild = true;
            dontConfigure = true;
            installPhase = ''
              install -Dm 0755 $src/generate_labels.py $out/bin/generate_labels.py
              install -Dm 0755 $src/generate_latex.py $out/bin/generate_latex.py
              install -D $src/latex_template.tex $out/latex_template.tex
            '';
          };
          fontPath = "${pkgs.liberation_ttf.outPath}/share/fonts/truetype/LiberationSans-Regular.ttf";
        in
          pkgs.writeShellApplication {
            # Small shell script package that does the required nix store replacements to generate some labels
            name = "simple_inventory_label_gen";
            runtimeInputs = [backend_data texWithPkgs];
            text = ''
              if [ "$#" -lt 1 ]; then
                echo "USAGE: $0 BASE_URL [OUT_FILE]" 1>&2
                exit 1
              fi
              TEMP_DIR="$(mktemp -d)" || { echo "Failed to create temp directory"; exit 1; }
              pushd "$TEMP_DIR"
              mkdir codes
              generate_labels.py -lf ${fontPath} -n 24 -b "$1" codes
              generate_latex.py generated.tex
              mkdir pdf
              pdflatex -output-directory pdf ${backend_data}/latex_template.tex
              if [ "$#" -lt 2 ]; then
                OUT_PATH="$(date +%y%m%d%H%M).pdf"
              else
                OUT_PATH="$2"
              fi
              popd
              mv "$TEMP_DIR/pdf/latex_template.pdf" "$OUT_PATH"
            '';
          };

        packages.simple_inventory_web = pkgs.python3Packages.buildPythonApplication {
          # We just bundle this using the development flask server - this is only meant for very small (hand full of people) deployments!
          pname = "simple_inventory_web";
          version = "0.1.0";
          src = ./web;
          propagatedBuildInputs = with pkgs.python3Packages; [
            flask
            waitress
          ];
          format = "other";
          dontBuild = true;
          dontConfigure = true;
          installPhase = ''
            install -Dm 0755 $src/inventory_web.py $out/bin/simple_inventory_web.py
            ln -s $out/bin/simple_inventory_web.py $out/bin/simple_inventory_web
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = [
            (pkgs.python3.withPackages (
              python-pkgs:
                [
                  python-pkgs.flask
                  python-pkgs.waitress
                ]
                ++ backendPythonDeps python-pkgs
            ))
            texWithPkgs
          ];
        };

        hydraJobs.label_gen_app = self.packages.${system}.simple_inventory_labelgen;
        formatter = pkgs.alejandra;
      }
    )
    // {
      nixosModules.simple_inventory_web = {
        lib,
        config,
        pkgs,
        ...
      }: let
        cfg = config.services.simple_inventory_web;
      in {
        options.services.simple_inventory_web = {
          enable = lib.mkEnableOption "Simple inventory web interface";
          listen = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1:8080";
          };
          package = lib.mkPackageOption self.packages.${pkgs.system} "simple_inventory_web" {};
          user = lib.mkOption {
            type = lib.types.str;
            default = "simple_inventory_web";
            description = "User account under which simple_inventory runs.";
          };
          group = lib.mkOption {
            type = lib.types.str;
            default = "simple_inventory_web";
            description = "Group under which simple_inventory runs.";
          };
        };

        config = lib.mkIf cfg.enable {
          systemd.services.simple_inventory_web = {
            description = "Simple inventory web interface";
            after = ["network-online.target"];
            wants = ["network-online.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              ExecStart = ''
                ${cfg.package}/bin/simple_inventory_web.py --waitress_listen_on=${cfg.listen}
              '';
              Restart = "on-failure";

              User = cfg.user;
              Group = cfg.group;
              DynamicUser = true;
              StateDirectory = "simple_inventory_web";
              WorkingDirectory = "%S/simple_inventory_web";

              CapabilityBoundingSet = "";
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              PrivateDevices = true;
              PrivateUsers = true;
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              SystemCallArchitectures = "native";
              UMask = "0066";
            };
            environment = {
              INVENTORY_WEB_DATA_DIR = "/var/lib/simple_inventory_web";
            };
          };
        };
      };

      nixosModules.default = self.nixosModules.simple_inventory_web;
    };
}
