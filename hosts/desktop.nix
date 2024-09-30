{ inputs, pkgs, system, ... }:
let
  berkeley-mono = pkgs.callPackage ../fonts/berkeley-mono.nix { };

in {

#### NIX
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

#### USERS
  users.users.joe = {
    isNormalUser = true;
    description = "Joe Diragi";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" "plugdev" ];
    shell = "${pkgs.zsh}/bin/zsh";
    home = "/home/joe";
    homeMode = "755";
  };

#### System Packages
  environment.systemPackages = with pkgs; [
    wget
    git
    drm_info
    libdrm
    firefox
    ungoogled-chromium
    distrobox
    boxbuddy
    devenv
    kdeconnect
    xsettingsd # here for assets in flatpaks
    cntr # Used to connect to failed nix-build via breakpointHook in nativeBuildInputs
    zig
    inputs.ghostty.packages.${system}.default
  ];

#### DOCKER
  virtualisation.docker.enable = true;

#### FLATPAK + FLATHUB
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      
      ## !!! Flatpak fonts !!!
      ## NOTE: I don't think this is doing anything atp

      ## Source: https://nixos.wiki/wiki/Fonts#Flatpak_applications_can.27t_find_system_fonts
      # ln -s /run/current-system/sw/share/X11/fonts ~/.local/share/fonts 
      flatpak --user override --filesystem=$HOME/.local/share/fonts:ro
      flatpak --user override --filesystem=$HOME/.icons:ro
      flatpak --user override --filesystem=/nix/store:ro
    '';
  };

#### DESKTOP
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  services.desktopManager.cosmic.enable = true;

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
  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = [ pkgs.nixos-bgrt-plymouth ];
  };

#### NETWORKING
  networking = {
    networkmanager = {
      enable = true;
    };
  #### FIREWALL
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        22 # SSH
        8989 # Sonarr
      ];
      allowedUDPPorts = [
        8989 # Sonarr
      ];
      allowedTCPPortRanges = [
        { from = 1714; to = 1764; } # KDE Connect
      ];
      allowedUDPPortRanges = [
        { from = 1714; to = 1764; } # KDE Connect
      ];
    };
  };

#### TIME 
  services.ntp.enable = true;

#### SSH
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null; # Allow all users. Can be [ "joe" "urmomma" ]
      UseDns = true;
      X11Forwarding = false; # idk what this does but wayland better ?
      PermitRootLogin = "prohibit-password"; # sudo who
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
}
