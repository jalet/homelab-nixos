{
  pkgs,
  lib,
  ...
}: {
  system.stateVersion = "25.05";
  time.timeZone = "Europe/Stockholm";

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };

  # --- Nix settings ---
  nix.settings = {
    sandbox = false;
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes"];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.fstrim.enable = false; # Let Proxmox host handle fstrim
  security.pam.services.sshd.allowNullPassword = true;
  services.resolved.enable = false;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # --- Common user setup ---
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiptyR04iPnEFoOG/xYc49QHKQRASh8CupSojnVSD6D"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB2wThHfWe/wa6iqFk70dgE0lgQ1ZqxHGYldbzk20d7 jj@builder01"
  ];

  # --- Firewall base ---
  networking.firewall.enable = lib.mkDefault true;
  networking.useDHCP = lib.mkDefault false;
  networking.nameservers = lib.mkDefault ["9.9.9.11" "149.112.112.11"];

  # --- Logging ---
  services.journald.extraConfig = "SystemMaxUse=200M";

  # --- Packages ---
  environment.systemPackages = with pkgs; [dig git neovim curl];
  environment.variables = {
    EDITOR = "nvim";
  };
}
