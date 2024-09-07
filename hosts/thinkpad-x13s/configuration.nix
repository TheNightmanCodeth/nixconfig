{ inputs, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages."aarch64-linux";
in {
  nixos-x13s.enable = true;
  nixos-x13s.kernel = "jhovold";
  nixos-x13s.bluetoothMac = "F4:A8:0D:2A:84:EA";
  nixos-x13s.wifiMac = "F4:A8:0D:FF:7C:87";
  boot.initrd.systemd.enableTpm2 = false;

  hardware.graphics.enable = true;

  networking.hostName = "thinkpad-X13s";

  # services.fprintd = {
  #   enable = true;
  #   tod.enable = true;
  #   tod.driver = pkgs.libfprint-2-tod1-goodix;
  # };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  system.stateVersion = "24.11";
}
