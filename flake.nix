{
  description = "Nix flake for the Odin programming language";

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      stdenv = pkgs.llvmPackages.stdenv;
    in {
      apps.x86_64-linux = {
        type = "app";
        program = "${self.packages.x86_64.odin}/bin/odin";
      };
      packages.x86_64-linux = {
        odin = stdenv.mkDerivation rec {
          pname = "odin";
          version = "dev-2022-09";
          src = pkgs.fetchFromGitHub {
            owner = "odin-lang";
            repo = "Odin";
            rev = "${version}";
            sha256 = "sha256-qBAObLbgry+r/wOsFf7LDWJdOyn7RvEIbFCyAvN0waA=";
          };
          depsBuildBuild = with pkgs; [
            llvmPackages.libllvm
            which
            makeWrapper
          ];
          prePatch = ''
            patchShebangs .
            sed -i 's/^GIT_SHA=.*$/GIT_SHA=${
              self.shortRev or "dirty"
            }/' build_odin.sh
          '';
          dontConfigure = true;
          makeFlags = [ "release_native" ];
          installPhase = ''
            mkdir -p $out/bin
            cp odin $out/bin/odin
            cp -r core $out/bin/core
            wrapProgram $out/bin/odin --prefix PATH : ${
              pkgs.lib.makeBinPath
              (with pkgs.llvmPackages; [ bintools llvm clang lld ])
            }
          '';
        };
        default = self.packages.x86_64-linux.odin;
      };
      devShells.x86_64-linux.flake-dev =
        pkgs.mkShell { inputsFrom = [ self.packages.x86_64-linux.odin ]; };
    };
}
