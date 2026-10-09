{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/rocm.nix
    ../../modules/ai.nix
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # /boot is a 1 GiB ESP; unbounded generations will fill it.
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "odysseus";
    # NetworkManager because of the Intel AC 3168 — wpa_supplicant by hand is a
    # worse trade for a card you may want occasionally. Ethernet (enp6s0) is the
    # live link and just takes DHCP.
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.joe = {
    isNormalUser = true;
    uid = 1000;
    description = "joe";
    extraGroups = [
      "wheel" # sudo
      "video" # /dev/dri/card*
      "render" # /dev/dri/renderD* — this is the one ROCm needs
      "networkmanager"
    ];
    # Shell (zsh) and authorized SSH keys are shared with ithaca; see
    # modules/common.nix.

    # World-readable in the Nix store. It exists so the first console login and
    # the first `sudo` work; run `passwd` once you're in and it stops mattering
    # (users.mutableUsers defaults to true, so your change sticks).
    initialPassword = "changeme";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.nfs = {
    settings = {
      nfsd."vers4.0" = true;
    };
    server = {
      enable = true;
      exports = ''
        /home/joe/Projects 192.168.1.0/24(rw,sync,no_subtree_check,insecure,all_squash,anonuid=1000,anongid=100)
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 2049 ];

  services.tailscale.enable = true;

  environment.systemPackages = [
    pkgs.git # flakes fetch git inputs; without it `nixos-rebuild` on a repo fails
  ];

  # 238 GB of NVMe shared with model weights. Don't let generations pile up.
  # (NixOS's default schedule is daily; nix-darwin's is already weekly.)
  nix.gc.dates = "weekly";

  # 62 GiB RAM, no swap partition; this is the safety net.
  zramSwap.enable = true;

  # Matches the 26.05 install media. Don't bump this to chase unstable's 26.11 —
  # it isn't a version to keep current, it's a marker for which release's
  # stateful defaults this machine was built against.
  system.stateVersion = "26.05";
}
