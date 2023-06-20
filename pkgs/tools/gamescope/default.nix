{ source
, stdenv
, fetchFromGitHub
, meson
, pkg-config
, ninja
, xorg
, libdrm
, vulkan-headers
, vulkan-loader
, wayland
, wayland-protocols
, libxkbcommon
, libcap
, SDL2
, pipewire
, udev
, pixman
, libinput
, seatd
, xwayland
, glslang
, stb
, wlroots_0_16
, libliftoff
, lib
, makeBinaryWrapper
, cmake
, glm
, gbenchmark
, hwdata
, libXmu
, python3
}:
stdenv.mkDerivation {
  inherit (source) pname version src;

  postPatch = ''
    substituteInPlace subprojects/libdisplay-info/tool/gen-search-table.py \
      --replace '/usr/bin/env python3' ${python3}/bin/python3
  '';

  nativeBuildInputs = [
    meson
    pkg-config
    ninja
    makeBinaryWrapper
    cmake
  ];

  buildInputs = [
    xorg.libXdamage
    xorg.libXcomposite
    xorg.libXrender
    xorg.libXext
    xorg.libXxf86vm
    xorg.libXtst
    xorg.libXres
    xorg.libXi
    xorg.xcbutilwm
    xorg.xcbutilerrors
    libdrm
    libliftoff
    vulkan-headers
    vulkan-loader
    # vulkan-validation-layers
    glslang
    glm
    gbenchmark
    SDL2
    wayland
    wayland-protocols
    wlroots_0_16
    xwayland
    seatd
    libinput
    libxkbcommon
    udev
    pixman
    pipewire
    libcap
    stb
    hwdata
    libXmu
  ];

  # --debug-layers flag expects these in the path
  postInstall = ''
    wrapProgram "$out/bin/gamescope" \
     --prefix PATH : ${with xorg; lib.makeBinPath [xprop xwininfo]}
  '';

  meta = with lib; {
    description = "SteamOS session compositing window manager";
    homepage = "https://github.com/Plagman/gamescope";
    license = licenses.bsd2;
    maintainers = with maintainers; [ nrdxp zhaofengli ];
    platforms = platforms.linux;
  };
}
