# flake.nix
#
# This file packages pythoneda-sandbox/flow-sample-tests as a Nix flake.
#
# Copyright (C) 2023-today rydnr's pythoneda-sandbox-def/flow-sample-tests
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
{
  description = "Nix flake for pythoneda-sandbox/flow-sample-tests";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/24.05";
    pythoneda-shared-pythonlang-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.71";
    };
    pythoneda-shared-pythonlang-domain = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      url = "github:pythoneda-shared-pythonlang-def/domain/0.0.92";
    };
    pythoneda-sandbox-flow-sample = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      inputs.pythoneda-shared-pythonlang-domain.follows =
        "pythoneda-shared-pythonlang-domain";
      url = "github:pythoneda-sandbox-def/flow-sample/0.0.49";
    };
    rydnr-testcontainers-python = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:rydnr/testcontainers-python/0.0.1";
    };
  };
  outputs = inputs:
    with inputs;
    let
      defaultSystems = flake-utils.lib.defaultSystems;
      supportedSystems = if builtins.elem "armv6l-linux" defaultSystems then
        defaultSystems
      else
        defaultSystems ++ [ "armv6l-linux" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        org = "pythoneda-sandbox";
        repo = "flow-sample-tests";
        version = "0.0.1";
        sha256 = "1j0wqndxrs976dyk1xyvs9zykm2nldqfacxc172zx9g5pjajrsmm";
        pname = "${org}-${repo}";
        pkgs = import nixos { inherit system; };
        description = "Tests for pythoneda-sandbox Flow Sample package";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/pythoneda-sandbox/flow-sample-tests";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        archRole = "S";
        space = "D";
        layer = "D";
        nixosVersion = builtins.readFile "${nixos}/.version";
        nixpkgsRelease =
          builtins.replaceStrings [ "\n" ] [ "" ] "nixos-${nixosVersion}";
        shared = import "${pythoneda-shared-pythonlang-banner}/nix/shared.nix";
        pythoneda-sandbox-flow-sample-tests-for = { python
          , pythoneda-sandbox-flow-sample, rydnr-testcontainers-python }:
          let
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            pythonpackage = "pythoneda_tests.sandbox.flows.sample";
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
          in python.pkgs.buildPythonPackage rec {
            inherit pname version;
            projectDir = ./.;
            pyprojectTemplateFile = ./pyprojecttoml.template;
            pyprojectTemplate = pkgs.substituteAll {
              authors = builtins.concatStringsSep ","
                (map (item: ''"${item}"'') maintainers);
              desc = description;
              inherit homepage pname pythonMajorMinorVersion pythonpackage
                version;
              package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
              pythonedaSandboxFlowSample =
                pythoneda-sandbox-flow-sample.version;

              pytest = python.pkgs.pytest.version;
              src = pyprojectTemplateFile;
            };
            src = pkgs.fetchFromGitHub {
              owner = org;
              rev = version;
              inherit repo sha256;
            };

            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip poetry-core ];
            propagatedBuildInputs = with python.pkgs; [
              pythoneda-sandbox-flow-sample
              pytest
              rydnr-testcontainers-python
            ];

            pythonImportsCheck = [ pythonpackage ];

            unpackPhase = ''
              cp -r ${src} .
              sourceRoot=$(ls | grep -v env-vars)
              chmod +w $sourceRoot
              cp ${pyprojectTemplate} $sourceRoot/pyproject.toml
            '';

            postInstall = ''
              pushd /build/$sourceRoot
              for f in $(find . -name '__init__.py'); do
                if [[ ! -e $out/lib/python${pythonMajorMinorVersion}/site-packages/$f ]]; then
                  cp $f $out/lib/python${pythonMajorMinorVersion}/site-packages/$f;
                fi
              done
              popd
              mkdir $out/dist
              cp dist/${wheelName} $out/dist
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        defaultPackage = packages.default;
        devShells = rec {
          default = pythoneda-sandbox-flow-sample-tests-python312;
          pythoneda-sandbox-flow-sample-tests-python39 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39
              }/bin/banner.sh";
            extra-namespaces = "pythoneda_tests";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-flow-sample-tests-python39;
            python = pkgs.python39;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-sandbox-flow-sample-tests-python310 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310
              }/bin/banner.sh";
            extra-namespaces = "pythoneda_tests";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-flow-sample-tests-python310;
            python = pkgs.python310;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-sandbox-flow-sample-tests-python311 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311
              }/bin/banner.sh";
            extra-namespaces = "pythoneda_tests";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-flow-sample-tests-python311;
            python = pkgs.python311;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python311;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-sandbox-flow-sample-tests-python312 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312
              }/bin/banner.sh";
            extra-namespaces = "pythoneda_tests";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-flow-sample-tests-python312;
            python = pkgs.python312;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python312;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-sandbox-flow-sample-tests-python313 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python313
              }/bin/banner.sh";
            extra-namespaces = "pythoneda_tests";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-sandbox-flow-sample-tests-python313;
            python = pkgs.python313;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python313;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python313;
            inherit archRole layer org pkgs repo space;
          };
        };
        packages = rec {
          default = pythoneda-sandbox-flow-sample-tests-python312;
          pythoneda-sandbox-flow-sample-tests-python39 =
            pythoneda-sandbox-flow-sample-tests-for {
              python = pkgs.python39;
              pythoneda-sandbox-flow-sample =
                pythoneda-sandbox-flow-sample.packages.${system}.pythoneda-sandbox-flow-sample-python39;
              rydnr-testcontainers-python =
                rydnr-testcontainers-python.packages.${system}.rydnr-testcontainers-python-python39;
            };
          pythoneda-sandbox-flow-sample-tests-python310 =
            pythoneda-sandbox-flow-sample-tests-for {
              python = pkgs.python310;
              pythoneda-sandbox-flow-sample =
                pythoneda-sandbox-flow-sample.packages.${system}.pythoneda-sandbox-flow-sample-python310;
              rydnr-testcontainers-python =
                rydnr-testcontainers-python.packages.${system}.rydnr-testcontainers-python-python310;
            };
          pythoneda-sandbox-flow-sample-tests-python311 =
            pythoneda-sandbox-flow-sample-tests-for {
              python = pkgs.python311;
              pythoneda-sandbox-flow-sample =
                pythoneda-sandbox-flow-sample.packages.${system}.pythoneda-sandbox-flow-sample-python311;
              rydnr-testcontainers-python =
                rydnr-testcontainers-python.packages.${system}.rydnr-testcontainers-python-python311;
            };
          pythoneda-sandbox-flow-sample-tests-python312 =
            pythoneda-sandbox-flow-sample-tests-for {
              python = pkgs.python312;
              pythoneda-sandbox-flow-sample =
                pythoneda-sandbox-flow-sample.packages.${system}.pythoneda-sandbox-flow-sample-python312;
              rydnr-testcontainers-python =
                rydnr-testcontainers-python.packages.${system}.rydnr-testcontainers-python-python312;
            };
          pythoneda-sandbox-flow-sample-tests-python313 =
            pythoneda-sandbox-flow-sample-tests-for {
              python = pkgs.python313;
              pythoneda-sandbox-flow-sample =
                pythoneda-sandbox-flow-sample.packages.${system}.pythoneda-sandbox-flow-sample-python313;
              rydnr-testcontainers-python =
                rydnr-testcontainers-python.packages.${system}.rydnr-testcontainers-python-python313;
            };
        };
      });
}
