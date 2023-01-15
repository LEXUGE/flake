{ lib
, stdenv
, makeDesktopItem
, copyDesktopItems
}:

stdenv.mkDerivation rec {
  pname = "steam-session-desktop-item";
  version = "0.1.0";

  phases = [ "installPhase" ];

  installPhase = "runHook postInstall";

  nativeBuildInputs = [
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "steam-session";
      desktopName = "Steam Deck";
      genericName = "Steam Deck";
      exec = "steam-session";
      icon = "steamicon.png";
      type = "Application";
      categories = [ "Application" ];
    })
  ];
}
