{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];

  proxmox.qemuConf = {
    cores = 4;
    memory = 4096;
  };

  networking = {
    useNetworkd = true;
    firewall.allowedTCPPorts = [22];
    firewall.allowedUDPPorts = [];
  };

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en* eth*";
    networkConfig.DHCP = "ipv4";
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  sops.defaultSopsFile = ./forgejo-runner.yaml;
  sops.secrets.token = {};

  services.gitea-actions-runner.instances.default = {
    enable = true;
    name = config.networking.hostName;
    url = "https://codeberg.org/";
    tokenFile = config.sops.secrets.token.path;
    labels = [
      "ubuntu-24.04:docker://catthehacker/ubuntu:act-24.04"
      "nix:docker://nixos/nix:latest"
    ];
  };

  systemd.services.gitea-runner-default.serviceConfig.SupplementaryGroups = [ "docker" ];
}
