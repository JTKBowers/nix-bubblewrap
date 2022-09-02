rec {
  deps = nixpkgs: pkg: nixpkgs.lib.strings.splitString "\n" (nixpkgs.lib.strings.fileContents (nixpkgs.writeReferencesToFile pkg));

  roBindDirectory = path: "--ro-bind ${path} ${path}";
  generateBindArgs = paths: builtins.toString (map roBindDirectory paths);
  generateWrapperScript = pkgs: {pkg, name, logGeneratedCommand, roBindDirs, roBindCwd}: pkgs.writeShellScriptBin "bwrapped-${name}" ''set -e${if logGeneratedCommand then "x" else ""}
${pkgs.bubblewrap}/bin/bwrap --unshare-all ${generateBindArgs roBindDirs} ${if roBindCwd then roBindDirectory "$(pwd)" else ""} ${pkg}/bin/${name} "$@"
'';
  wrapPackage = nixpkgs: {pkg, name ? pkg.pname, logGeneratedCommand ? false, extraRoBindDirs? [], roBindCwd ? false}: let
    pkgDeps = deps nixpkgs pkg;
    roBindDirs = nixpkgs.lib.lists.unique (pkgDeps ++ extraRoBindDirs);
  in generateWrapperScript nixpkgs {pkg = pkg; name = name; logGeneratedCommand = logGeneratedCommand; roBindDirs = roBindDirs; roBindCwd = roBindCwd;};
}
