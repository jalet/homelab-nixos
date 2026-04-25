{
  config,
  sops,
  modulesPath,
  pkgs,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  networking = {
    firewall.trustedInterfaces = [ "tailscale0" ];
    firewall.allowedTCPPorts = [22 443];
    firewall.allowedUDPPorts = [];
  };

  sops.defaultSopsFile = ./tailscale.yaml;
  sops.secrets."authkey" = {};

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.authkey.path;
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--advertise-routes=172.16.0.0/24,10.10.99.0/24"
    ];
  };
}
