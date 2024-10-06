{
  description = "Joe rules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    swift-59-nixpkgs.url = "github:TheNightmanCodeth/nixpkgs?ref=feat/swift-5.9";
    linux-firmware-main.url = "github:TheNightmanCodeth/linux-firmware-git-flake/main";
    x13s-nixos.url = "github:TheNightmanCodeth/x13s-nixos/jhovold-6.12-rc1";
    catppuccin.url = "github:catppuccin/nix";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    vpn-confinement = {
      url = "github:Maroka-chan/VPN-Confinement";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cosmic = {
       url = "github:lilyinstarlight/nixos-cosmic";
       inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "git+ssh://git@github.com/ghostty-org/ghostty";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
    };
  };

  outputs = { self,
  		     nixpkgs,
		     x13s-nixos,
		     catppuccin,
		     hyprland,
			 nixos-cosmic,
             home-manager,
             ghostty,
             linux-firmware-main,
             vpn-confinement,
		     ... }@inputs:
    let
      system = "aarch64-linux";
    in {
      config.hardware.enableRedistributableFirmware = true;

      inputs.nixpkgs.config.allowUnfree = true;

      nixosConfigurations = {
        # Thinkpad X13s
        thinkpad-X13s = nixpkgs.lib.nixosSystem {
          inherit system;
	      specialArgs = { inherit inputs system; };
	      modules = [
			x13s-nixos.nixosModules.default
			catppuccin.nixosModules.catppuccin
			home-manager.nixosModules.home-manager
            nixos-cosmic.nixosModules.default
            vpn-confinement.nixosModules.default
	        ./hosts/thinkpad-x13s/configuration.nix
	      ];
        };

        homelab = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; system = "x86_64-linux"; };
          modules = [
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            nixos-cosmic.nixosModules.default
            vpn-confinement.nixosModules.default
            ./hosts/homelab/configuration.nix 
          ];
        };

	    installer-iso = nixpkgs.lib.nixosSystem {
		  system = "aarch64-linux";
		  modules = [
		    x13s-nixos.nixosModules.default
			({ ... }: {
			  imports = [ "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix" ];
			  hardware.deviceTree = {
			    enable = true;
			    name = "qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
			  };

			  boot = {
			    initrd = {
				  systemd.enable = true;
				  systemd.emergencyAccess = true;
				};
				loader = {
				  grub.enable = false;
				  systemd-boot.enable = true;
				  systemd-boot.graceful = true;
				};
			  };
			  nixpkgs.config.allowUnfree = true;
			  nixos-x13s = {
				enable = true;
				bluetoothMac = "F4:A8:0D:2A:84:EA";
				wifiMac = "F4:A8:0D:FF:7C:87";
			  };
			})
		  ];
		};
      };
    };
}
