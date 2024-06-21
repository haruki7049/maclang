{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, flake-utils, treefmt-nix, rust-overlay, crane }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ (import rust-overlay) ]; };
        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        craneLib = (crane.mkLib pkgs).overrideToolchain rust;
        src = ./.;
        buildInputs = with pkgs; [
          llvmPackages_16.llvm.dev
          libffi
          libxmlxx
        ];
        cargoArtifacts = craneLib.buildDepsOnly {
          inherit src buildInputs;
        };
        mcl = craneLib.buildPackage {
          inherit src cargoArtifacts buildInputs;
          strictDeps = true;

          doCheck = true;
        };
        cargo-clippy = craneLib.cargoClippy {
          inherit src cargoArtifacts;
          cargoClippyExtraArgs = "--verbose -- --deny warnings";
        };
        cargo-doc = craneLib.cargoDoc {
          inherit src cargoArtifacts;
        };
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        packages.default = mcl;
        packages.doc = cargo-doc;

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };

        checks = {
          inherit mcl cargo-clippy cargo-doc;
          formatting = treefmtEval.config.build.check self;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            rust
            pkgs.llvmPackages_16.llvm
            pkgs.libffi
            pkgs.libxmlxx
          ];

          env = {
            LLVM_SYS_160_PREFIX = "${pkgs.llvmPackages_16.llvm.dev}";
          };

          shellHook = ''
            export PS1="\n[nix-shell:\w]$ "
          '';
        };
      }
    );
}
