{
  source,
  lib,
  stdenv,
  kernel,
}:
stdenv.mkDerivation {
  inherit (source) pname version src;

  passthru.moduleName = source.pname;

  # hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildFlags = [
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
  ];

  installPhase = ''
    install -D ideapad-laptop-tb2024g6plus.ko $out/lib/modules/${kernel.modDirVersion}/misc/ideapad-laptop-tb2024g6plus.ko
  '';
}
