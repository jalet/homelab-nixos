{
  description = "Homelab NixOS LXC systems for Proxmox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-generators.url = "github:nix-community/nixos-generators";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    sops-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    mkTailscale = {name}:
      nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          sops-nix.nixosModules.sops
          ./modules/common.nix
          ./modules/tailscale.nix
          {
            networking.hostName = name;
          }
        ];
      };

    mkDns = {
      name,
      lastOctet,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit name;
        };

        modules = [
          sops-nix.nixosModules.sops
          ./modules/common.nix
          ./modules/dns.nix
          {
            networking.hostName = name;
            networking.defaultGateway.address = "172.16.0.1";
            networking.defaultGateway.interface = "eth0";
            networking.interfaces = {
              eth0 = {
                ipv4.addresses = [
                  {
                    address = "172.16.0.${toString lastOctet}";
                    prefixLength = 24;
                  }
                ];
              };
            };
          }
        ];
      };
  in {
    nixosConfigurations = {
      tsr01 = mkTailscale {name = "tsr01";};
      dns01 = mkDns {
        name = "dns01";
        lastOctet = 254;
      };
      dns02 = mkDns {
        name = "dns02";
        lastOctet = 253;
      };
    };
  };
}
