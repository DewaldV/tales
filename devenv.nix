{ pkgs, ... }:

{
  languages.go.enable = true;
  languages.go.package = pkgs.go_1_27;

  packages = [ pkgs.hugo ];
}
