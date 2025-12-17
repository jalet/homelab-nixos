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
    firewall.allowedTCPPorts = [22 443];
    firewall.allowedUDPPorts = [];
  };

  sops.defaultSopsFile = ./rootca.yaml;
  sops.secrets."stepca" = {};
  services.step-ca = {
    enable = true;
    port = 443;
    address = "0.0.0.0";
    settings = builtins.fromJSON config.sops.secrets.stepca.content;
  };
}
