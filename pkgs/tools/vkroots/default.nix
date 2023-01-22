{ lib, stdenv, fetchFromGitHub, meson, pkg-config, ninja }:

stdenv.mkDerivation rec {
  pname = "vkroots";
  version = "git";

  src = fetchFromGitHub {
    owner = "Joshua-Ashton";
    repo = "vkroots";
    rev = "e6b89494142eec0ac6061f82a947d2f1246d3d7a";
    sha256 = "sha256-V3AEClIBo72JhbhwDTXWsIIJccxqA2IZfx3/VDPcLyE=";
  };

  patches = [ ./add-install-section-meson.patch ];

  nativeBuildInputs = [
    ninja
    meson
    pkg-config
  ];
}
