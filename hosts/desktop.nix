{ inputs, pkgs, ... }:
let
  berkeley-mono = pkgs.callPackage ../fonts/berkeley-mono.nix { };

in {
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  users.users.joe = {
    isNormalUser = true;
    description = "Joe Diragi";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = "${pkgs.zsh}/bin/zsh";
    home = "/home/joe";
    homeMode = "755";
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    drm_info
    firefox
    devenv
  ];

  ## DESKTOP
  services.flatpak.enable = true;
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  services.desktopManager.cosmic.enable = true;
  hardware.pulseaudio.enable = false;
  networking.networkmanager.enable = true;

  fonts = {
    packages = with pkgs; [
      berkeley-mono
    ];
    # localConf = builtins.writeFile "fonts.xml" /* xml */ ''
    #   <?xml version="1.0"?>
    #   <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    #   <fontconfig>
    #     <match target="pattern">
    #       <test qual="any" name="family" compare="eq"><string>Berkeley Mono</string></test>
    #     </match>
    #   </fontconfig>
    # '';
  };

  ## Binary Caches
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

  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = [ pkgs.nixos-bgrt-plymouth ];
  };

  home-manager = {

    users.joe = {
      imports = [
        ../home/desktop.nix
	    inputs.catppuccin.homeManagerModules.catppuccin
      ];
    };
  };
}
