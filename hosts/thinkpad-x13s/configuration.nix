{ inputs, ... }:
let
  pkgs = import inputs.nixpkgs { system = "aarch64-linux"; config.allowUnfree = true; };
in
{
  imports = [ ../desktop.nix ];
  
  config = {
    hardware.enableRedistributableFirmware = true;

    # There's updated wifi firmware in main branch.
    # Remove this once it's in nixpkgs
    nixpkgs.overlays = [
      (final: prev: {
        linux-firmware = inputs.linux-firmware-main.nixosModules.default;
      })    
    ];

    nixos-x13s.enable = true;
    nixos-x13s.kernel = "jhovold";
    nixos-x13s.bluetoothMac = "F4:A8:0D:2A:84:EA";
    nixos-x13s.wifiMac = "F4:A8:0D:FF:7C:87";
    boot.initrd.systemd.tpm2.enable = false;

    hardware.graphics.enable = true;

    networking.hostName = "thinkpad-X13s";

    services.fprintd = {
      enable = true;
      tod.enable = true;
      tod.driver = pkgs.libfprint-2-tod1-goodix;
    };

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

#### NFS
    services.rpcbind.enable = true;
    boot.initrd = {
      supportedFilesystems = [ "nfs" "rpc_pipefs" ];
      kernelModules = [ "nfs" "rpc_pipefs" ];
    };

    fileSystems."/mnt/Projects" = {
      device = "joe@homelab:/mnt/data";
      fsType = "sshfs";
      options = [ "nodev" "noatime" "allow_other" "IdentityFile=/home/joe/.ssh/id_ed25519" ];
    };

    system.stateVersion = "24.11";
  };
}
