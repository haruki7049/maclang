{
  projectRootFile = "flake.nix";
  programs.nixpkgs-fmt.enable = true;
  programs.rustfmt.enable = true;
  programs.taplo.enable = true;
  programs.actionlint.enable = true;
}
