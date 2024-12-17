{ pkgs }:
{
  cache_size = 1024;
  upstreams = {
    domestic = {
      hybrid = [
        "feic"
        "ali"
        "aliudp"
      ];
    };

    secure = {
      hybrid = [
        "cloudflare"
        "google"
        "switch"
        "a-and-a"
      ];
    };

    feic = {
      udp = {
        addr = "[240C::6666]:53";
      };
    };

    aliudp = {
      udp = {
        addr = "223.5.5.6:53";
      };
    };

    ali = {
      tls = {
        domain = "dns.alidns.com";
        max_reuse = 100;
        reuse_timeout = 5000;
        addr = "223.6.6.6:853";
      };
    };

    cloudflare = {
      https = {
        timeout = 4;
        # addr = "2606:4700:4700::1111";
        addr = "104.16.248.249";
        uri = "https://cloudflare-dns.com/dns-query";
      };
    };

    google = {
      https = {
        timeout = 4;
        addr = "8.8.8.8";
        uri = "https://dns.google/dns-query";
      };
    };

    a-and-a = {
      https = {
        timeout = 4;
        addr = "217.169.20.22";
        uri = "https://dns.aa.net.uk/dns-query";
      };
    };

    switch = {
      https = {
        timeout = 4;
        addr = "130.59.31.248";
        uri = "https://dns.switch.ch/dns-query";
      };
    };
  };
  script = ''
    pub async fn init() {
                       let domain = Domain::new()
                                      // .add_file("${pkgs.chinalist}/google.china.raw.txt")?
                                      // .add_file("${pkgs.chinalist}/apple.china.raw.txt")?
                                      .add_file("${pkgs.chinalist}/accelerated-domains.china.raw.txt")?
                                      .add_qname("flibrary.info")?
                                      .seal();

                       Ok(#{"domain": Utils::Domain(domain)})
                     }

                     pub async fn route(upstreams, inited, ctx, query) {
                       if query.first_question?.qtype == "AAAA" { return blackhole(query); }

                       if inited.domain.0.contains(query.first_question?.qname) {
                         // query.push_opt(ClientSubnet::new(u8(15), u8(0), IpAddr::from_str("58.220.0.0")?).to_opt_data())?;
                         upstreams.send_default("domestic", query).await
                       } else {
                         upstreams.send("secure", CacheMode::Disabled, query).await
                       }
                     }
  '';
  address = "127.0.0.1:53";
  verbosity = "warn";
}
