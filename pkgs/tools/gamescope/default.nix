{ stdenv
, fetchFromGitHub
, meson
, pkg-config
, ninja
, xorg
, libdrm
, vulkan-headers
, vulkan-loader
  # , vulkan-validation-layers
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
, hwdata
, vkroots
}:
let
  pname = "gamescope";
  version = "3.11.51";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "Plagman";
    repo = "gamescope";
    rev = "refs/tags/${version}";
    sha256 = "sha256-alJaB7uZORaHV+VNlIMGuCCkPjHCF9wQ//Jv2pzitmM=";
  };

  patches = [ ./use-pkgconfig.patch ];

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
    libdrm
    libliftoff
    vulkan-headers
    vulkan-loader
    # vulkan-validation-layers
    glslang
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
    vkroots
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
