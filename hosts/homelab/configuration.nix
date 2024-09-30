{ config, lib, ... }:
{
  imports = [ ../desktop.nix ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.hostName = "homelab";

#### BOOT
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

#### FILESYSTEMS
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  fileSystems."/mnt/media" = {
    device = "/dev/disk/by-label/MEDIA";
    fsType = "ext4";
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-label/DATA";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

#### VPN + Transmission
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = /. + "/home/joe/.secrets/wireguard.conf";
    accessibleFrom = [
      "0.0.0.0"
      "192.168.1.0/24"
    ];
    portMappings = [
      { from = 9091; to = 9091; }
    ];
    openVPNPorts = [{
      port = 60965;
      protocol = "both";
    }];
  };

  systemd.services.transmission.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  services.transmission = {
    enable = true;
    settings = {
      "rpc-bind-address" = "192.168.15.1";
      "rpc-whitelist-enabled" = true;
      "rpc-whitelist" = "127.0.0.1,192.168.1.*";
    };
  };

#### *ARR
  

  system.stateVersion = "24.11";
}
