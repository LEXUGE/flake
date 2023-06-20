# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chinalist = {
    pname = "chinalist";
    version = "ec4242a7575cb59771056d3a59f122bf0a53643c";
    src = fetchFromGitHub {
      owner = "felixonmars";
      repo = "dnsmasq-china-list";
      rev = "ec4242a7575cb59771056d3a59f122bf0a53643c";
      fetchSubmodules = false;
      sha256 = "sha256-13sqLAaLapEjonMxHscCqxcvtfBiCFSUI2JLnR/NDPk=";
    };
    date = "2023-06-19";
  };
  maxmind-geoip = {
    pname = "maxmind-geoip";
    version = "20230612";
    src = fetchurl {
      url = "https://github.com/Dreamacro/maxmind-geoip/releases/download/20230612/Country.mmdb";
      sha256 = "sha256-uD+UzMjpQvuNMcIxm4iHLnJwhxXstE3W+0xCuf9j/i8=";
    };
  };
  proton-ge = {
    pname = "proton-ge";
    version = "GE-Proton8-4";
    src = fetchTarball {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton8-4/GE-Proton8-4.tar.gz";
      sha256 = "sha256-UdX2qnC3s7e560b4Mw5BTWA9e0ehMo/+iGuVDO7nBhc=";
    };
  };
  yacd = {
    pname = "yacd";
    version = "v0.3.8";
    src = fetchTarball {
      url = "https://github.com/haishanh/yacd/releases/download/v0.3.8/yacd.tar.xz";
      sha256 = "sha256-YrqBRRyKtIKAzPTNp6YfTC8oGI4WTqQ1FohcaubD8XM=";
    };
  };
}
