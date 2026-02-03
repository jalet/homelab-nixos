{
  config,
  sops,
  modulesPath,
  pkgs,
  lib,
  name,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  networking = {
    firewall.allowedTCPPorts = [22 53 5353 8080 8081];
    firewall.allowedUDPPorts = [53 5353];
  };

  environment.systemPackages = with pkgs; [pdns];
  environment.variables = {
    EDITOR = "nvim";
  };

  environment.etc."blocky/allowlist.txt".text = ''
    jarsater.lan
    xethub.hf.co
    cas-server.xethub.hf.co
  '';

  sops.secrets.powerdns = {
    sopsFile = ./dns.yaml;
    format = "yaml";
    key = "powerdns";
    owner = "pdns";
    group = "pdns";
    mode = "0440";
  };

  services.powerdns = {
    enable = true;
    secretFile = config.sops.secrets.powerdns.path;
    extraConfig = ''
      launch=gpgsql
      server-id=${name}
      local-address=0.0.0.0:5353

      dnsupdate=yes
      allow-dnsupdate-from=127.0.0.1/32,10.10.99.0/24

      api=yes
      api-key=''${API_KEY}
      webserver=yes
      webserver-address=0.0.0.0
      webserver-port=8081
      webserver-allow-from=10.10.99.0/24,172.16.0.0/24

      gpgsql-host=''${PSQL_HOST}
      gpgsql-port=''${PSQL_PORT}

      gpgsql-dbname=''${PSQL_DBNAME}
      gpgsql-user=''${PSQL_USER}
      gpgsql-password=''${PSQL_PASS}
    '';
  };

  services.blocky = {
    enable = true;
    package = pkgs.stdenv.mkDerivation rec {
      pname = "blocky";
      version = "v0.28.2";

      src = pkgs.fetchurl {
        url = "https://github.com/0xERR0R/blocky/releases/download/v0.28.2/blocky_v0.28.2_Linux_x86_64.tar.gz";
        hash = "sha256-vJOSH7AzwlNwgIY58fa2LyNW0Uz6AKjhELUU9QAcrtA=";
      };

      unpackPhase = "tar xzf $src";
      installPhase = ''
        mkdir -p $out/bin
        cp blocky $out/bin/
      '';

      meta.mainProgram = "blocky";

      dontPatch = true;
      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;
    };
    settings = {
      ports = {
        dns = 53;
        tls = 853;
        http = 8080;
        https = 8443;
      };

      prometheus = {
        enable = true;
        path = "/metrics";
      };

      queryLog = {
        type = "postgresql";
        target = "postgres://blocky:yyrdkz2iECp4PkTjWZXrL2RA48Rhe7mJ@172.16.99.2:5432/blocky";
        logRetentionDays = 90;
      };

      log = {
        level = "info";
        format = "json";
        timestamp = false;
        privacy = false;
      };

      # TODO: Change to Quad9
      bootstrapDns = [
        "tcp+udp:1.1.1.1"
        "https://1.1.1.1/dns-query"
        {
          upstream = "https://dns.digitale-gesellschaft.ch/dns-query";
          ips = [
            "185.95.218.42"
          ];
        }
      ];

      upstreams = {
        timeout = "5s";
        groups = {
          default = [
            "tcp-tls:dns.quad9.net:853"
            "https://dns.quad9.net/dns-query"
          ];
        };
      };

      clientLookup = {
        upstream = "10.10.99.1";
        singleNameOrder = [1];
      };

      caching = {
        minTime = "5m";
        maxTime = "0m";
        maxItemsCount = 0;
        prefetching = true;
        prefetchExpires = "2h";
        prefetchThreshold = 5;
        prefetchMaxItemsCount = 0;
        cacheTimeNegative = "30m";
      };

      conditional = {
        fallbackUpstream = false;
        mapping = {
          "jarsater.lan" = "127.0.0.1:5353";
        };
      };

      blocking = {
        allowlists = {
          misc = [
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/native.apple.txt"
            "/etc/blocky/allowlist.txt"
          ];
          ads = [ "/etc/blocky/allowlist.txt" ];
          security = [ "/etc/blocky/allowlist.txt" ];
        };

        denylists = {
          misc = [
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/anti.piracy.txt"
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/gambling.txt"
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/nsfw-onlydomains.txt"
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/urlshortener.txt"
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/hoster.txt"
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/dyndns.txt"
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/nosafesearch.txt"
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/nrd14-8.txt"
          ];
          security = [
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.txt"
          ];

          ads = [
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/ultimate.txt"
          ];
        };

        clientGroupsBlock = {
          default = ["ads" "security" "misc"];
        };
      };
    };
  };
}
