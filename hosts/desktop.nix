{ inputs, pkgs, config, system, ... }:
let
  berkeley-mono = pkgs.callPackage ../fonts/berkeley-mono.nix { };

in {
  config = {
  
#### NIX
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
    hardware.enableRedistributableFirmware = true;
    nixpkgs.config.allowUnfree = true;
    # Fix "warning: nix search path entry {} does not exist ...
    # https://github.com/NixOS/nix/issues/2982#issuecomment-2477618346
    nix.channel.enable = false;

#### USERS
    users.users.joe = {
      isNormalUser = true;
      description = "Joe Diragi";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      shell = "${pkgs.zsh}/bin/zsh";
      home = "/home/joe";
      homeMode = "755";
      openssh.authorizedKeys.keys = [
        # MBP
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcMdWYLUmP9ySC2jm/3G8pkbk7VaOCJKWtfJ2iTgkt/ joe"
        # iPhone / iSH
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfRx14BGVoosZPjusWQmmoVagQANRYq45fxR40XwcKj joe"
      ];
    };

#### System Packages
    environment.systemPackages = with pkgs; [
      wget
      git
      drm_info
      libdrm
      firefox
      rsync
      tmux
      chromium
      tailscale
      distrobox
      boxbuddy
      devenv
      nfs-utils
      xsettingsd # here for assets in flatpaks
      cntr # Used to connect to failed nix-build via breakpointHook in nativeBuildInputs
      inputs.ghostty.packages.${system}.default
    ];

#### Tailscale
    services.tailscale.enable = true;

#### DOCKER
    virtualisation.docker.enable = true;

#### FLATPAK + FLATHUB
    services.flatpak.enable = true;
    systemd.services.flatpak-repo = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };

#### DESKTOP
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

#### AUDIO
    hardware.pulseaudio.enable = false;

#### UDEV
    services.udev.packages = with pkgs; [ 
      yubikey-personalization
      android-udev-rules
    ];

#### YUBIKEY (+udev)
    services.yubikey-agent.enable = true;
    services.pcscd.enable = true;

#### FONTS
    fonts = {
      packages = [
        berkeley-mono
      ];
      fontconfig = {
        defaultFonts = {
          monospace = [ "BerkeleyMono Nerd Font Mono" ];
        };
      };

      ## See flatpak if you forgot how to fix fonts/pointer
      fontDir.enable = true;
    };

#### Binary Caches
    nix.settings = {
      substituters = [
        "https://cosmic.cachix.org/"
        "https://nixos-x13s.cachix.org"
      ];
      allowed-users = [
        "joe"
        "root"
      ];
      trusted-public-keys = [
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nixos-x13s.cachix.org-1:SzroHbidolBD3Sf6UusXp12YZ+a5ynWv0RtYF0btFos="
      ];
    };

#### BOOT THEME
    # boot.plymouth = {
    #   enable = true;
    #   theme = "nixos-bgrt";
    #   themePackages = [ pkgs.nixos-bgrt-plymouth ];
    # };

#### NETWORKING
    networking = {
      networkmanager = {
        enable = true;
      };
    #### FIREWALL
      firewall = {
        enable = true;

        trustedInterfaces = [ "tailscale0" ];

        allowedTCPPorts = [ 
          22 # SSH
          23231 # Soft Serve
          111 2049 4000 4001 4002 20048 # NFS
          3389 3390 # RDP
          5900 # VNC
        ];
        allowedUDPPorts = [
          3389 3390 # RDP
          5900 # VNC
          111 2049 4000 4001 4002 20048 # NFS
          config.services.tailscale.port
        ];
        allowedTCPPortRanges = [
          { from = 1714; to = 1764; } # KDE Connect
        ];
        allowedUDPPortRanges = [
          { from = 1714; to = 1764; } # KDE Connect
        ];
      };
    };
  
#### AVAHI
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };

#### TIME 
    services.ntp.enable = true;

#### SSH
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

#### HOME-MANAGER
    home-manager = {
      users.joe = {
        imports = [
          ../home/desktop.nix
	      inputs.catppuccin.homeManagerModules.catppuccin
        ];
      };
    };
  };
}
