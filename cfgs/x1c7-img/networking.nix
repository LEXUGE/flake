{ config, lib, pkgs, ... }: {
  # Use local DNS server all the time
  networking.resolvconf.useLocalResolver = true;

  networking.networkmanager = {
    # Enable networkmanager. REMEMBER to add yourself to group in order to use nm related stuff.
    enable = true;
    # Don't use DNS advertised by connected network. Use local configuration
    dns = "none";
    # Use the random MAC Address when scan
    wifi.scanRandMacAddress = true;
  };

  # Setup our local DNS
  my.dcompass = {
    enable = true;
    package = pkgs.dcompass.dcompass-maxmind;
    settings = {
      cache_size = 1024;
      upstreams = {
        domestic = { hybrid = [ "feic" "ali" "aliudp" ]; };

        secure = { hybrid = [ "cloudflare" "quad9" ]; };

        feic = { udp = { addr = "[240C::6666]:53"; }; };

        aliudp = { udp = { addr = "223.5.5.6:53"; }; };

        ali = { tls = { domain = "dns.alidns.com"; max_reuse = 100; reuse_timeout = 5000; addr = "223.6.6.6:853"; }; };

        cloudflare = {
          https = {
            timeout = 4;
            # addr = "2606:4700:4700::1111";
            addr = "104.16.248.249";
            uri = "https://cloudflare-dns.com/dns-query";
          };
        };

        quad9 = {
          https = {
            timeout = 4;
            addr = "9.9.9.9";
            uri = "https://dns.quad9.net/dns-query";
          };
        };
      };
      script = ''pub async fn init() {
                   let domain = Domain::new()
                                  .add_file("${pkgs.chinalist}/google.china.raw.txt")?
                                  .add_file("${pkgs.chinalist}/apple.china.raw.txt")?
                                  .add_file("${pkgs.chinalist}/accelerated-domains.china.raw.txt")?.seal();
                   Ok(#{"domain": Utils::Domain(domain)})
                 }

                 pub async fn route(upstreams, inited, ctx, query) {
                   if query.first_question?.qtype == "AAAA" { return blackhole(query); }

                   if inited.domain.0.contains(query.first_question?.qname) {
                     query.push_opt(ClientSubnet::new(u8(15), u8(0), IpAddr::from_str("58.220.0.0")?).to_opt_data())?;
                     upstreams.send_default("domestic", query).await
                   } else {
                     upstreams.send("secure", CacheMode::Persistent, query).await
                   }
                 }
              '';
      address = "0.0.0.0:53";
      verbosity = "warn";
    };
  };
}
