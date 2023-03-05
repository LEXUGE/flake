{ lib, rustPlatform, source, cmake, pkg-config, openssl, fontconfig, freetype, xorg, wayland, libGL, libxkbcommon, makeBinaryWrapper }:
rustPlatform.buildRustPackage rec {
  inherit (source) pname src version;

  cargoLock.lockFile = source.cargoLock."Cargo.lock".lockFile;

  nativeBuildInputs = [
    pkg-config
    cmake
    makeBinaryWrapper
  ];

  buildInputs = [
    libxkbcommon
    libGL

    # WINIT_UNIX_BACKEND=wayland
    wayland

    # WINIT_UNIX_BACKEND=x11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libX11
  ];

  postInstall = ''
    wrapProgram "$out/bin/boilr" --prefix LD_LIBRARY_PATH : "${LD_LIBRARY_PATH}"
  '';

  LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;

  # Don't know why vendoring doesn't work
  OPENSSL_NO_VENDOR = true;
  PKG_CONFIG_PATH = "${openssl.dev}/lib/pkgconfig:${fontconfig.dev}/lib/pkgconfig:${freetype.dev}/lib/pkgconfig";
}
