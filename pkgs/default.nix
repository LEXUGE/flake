{
  lib,
  pkgs,
  overlay ? false,
}:
let
  # All source files generated by nvfetcher
  sources = (import ./_sources/generated.nix) {
    inherit (pkgs)
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
  ignoredPkgs = [
    "proton-ge"
    "ideapad-thinkbook14"
  ];
  listPackageRecursive =
    dir:
    (lib.lists.foldr (n: col: col // n) { } (
      lib.attrsets.mapAttrsToList (
        name: type:
        let
          path = dir + "/${name}";
        in
        if type == "directory" then
          # Ignore broken packages
          if (builtins.pathExists (path + "/default.nix")) && !(lib.lists.any (p: p == name) ignoredPkgs) then
            if overlay then
              { "${name}" = (pkgs.callPackage path { source = sources.${name}; }); }
            else
              { "${name}" = pkgs."${name}"; }
          else
            listPackageRecursive path
        else
          { }
      ) (builtins.readDir dir)
    ));
in
listPackageRecursive ./.
