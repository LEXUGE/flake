{ lib
, stdenv
, makeDesktopItem
, copyDesktopItems
, writeShellScriptBin
}:

let
  steam-session-wrapped = writeShellScriptBin "steam-session-wrapped" ''
    sudo systemctl stop opensd
    steam-session
    sudo systemctl restart opensd
  '';
in
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
      exec = "${steam-session-wrapped}/bin/steam-session-wrapped";
      # icon = "steamicon.png";
      type = "Application";
      categories = [ "Application" ];
    })
  ];
}
