{ config, lib, pkgs, ... }:
{
  imports = [ ../desktop.nix ./arrs ./apps ];

  config = {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    nixpkgs.config.permittedInsecurePackages = [
      "aspnetcore-runtime-wrapped-6.0.36"
      "aspnetcore-runtime-6.0.36"
      "dotnet-sdk-wrapped-6.0.428"
      "dotnet-sdk-6.0.428"
    ];
    networking.hostName = "homelab";

#### BOOT
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      initrd = {
        availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" ];
        kernelModules = [ "amdgpu" ];
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

#### Time Machine
    services.samba = {
      enable = true;
      securityType = "user";
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "homelab";
          "security" = "user";
          # Allow everyone on LAN, localhost v4/v6 and tailscale IPs
          "hosts allow" = "192.168.1. 127.0.0.1 localhost 100.0.0.0/8";
          # Could set to "never", which would disable grant guest access to failed logins
          "map to guest" = "bad user";
        };
        "time-machine" = {
          "valid users" = "@users";
          "path" = "/mnt/data/Backup/time-machine";
          "fruit:aapl" = "yes";
          "fruit:time machine" = "yes";
          "vfs objects" = "catia fruit streams_xattr acl_xattr";
          "browsable" = "yes";
          "writeable" = "yes";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    networking.firewall.allowPing = true;

#### GPU
    services.xserver.videoDrivers = [ "amdgpu" ];

    ## HIP
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    ## OpenGL / OpenCL / Vulkan
    hardware.graphics = {
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        amdvlk
      ];

      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];

      enable32Bit = true;
    };
    hardware.enableAllFirmware = true; 
    system.stateVersion = "24.11";
  };
}
