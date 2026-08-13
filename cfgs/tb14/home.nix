{
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ../home/core.nix
    ../home/gnome.nix
  ];

  home = {
    username = "ash";
    homeDirectory = "/home/ash";
    stateVersion = "22.11";
  };
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    restic
    newsflash
    mat2
    signal-desktop
    zulip
    tor-browser
    tpm2-tools
    sbctl
    firefox
    telegram-desktop
    htop
    qbittorrent
    zoom-us
    thunderbird-bin
    pavucontrol
    resources
    kiwix
    keepassxc
    dnsperf
    dnsutils
    smartmontools
    powertop
    steam
    zotero
    profanity
    jetbrains.idea-oss
    ripgrep
    lmstudio
    anki
    amdgpu_top
    uv
    inputs.guardian.packages.${system}.default
    inputs.pi-flake.packages.${system}.default
  ];

  dconf.settings."org/gnome/desktop/interface"."scaling-factor" =
    inputs.home-manager.lib.hm.gvariant.mkUint32 2;
}
