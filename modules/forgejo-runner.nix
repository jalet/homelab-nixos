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
    memory = 8192;
  };

  services.qemuGuest.enable = true;
  zramSwap.enable = true;

  boot.loader.grub.device = lib.mkForce "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";

  fileSystems."/var/lib/docker" = {
    device = "/dev/disk/by-label/docker";
    fsType = "ext4";
  };

  networking = {
    firewall.allowedTCPPorts = [22];
    firewall.allowedUDPPorts = [];
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
