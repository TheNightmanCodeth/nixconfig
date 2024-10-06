{ config, lib, pkgs, ... }:
{
  imports = [ ../desktop.nix ./arrs ./apps ];

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

#### NFS Shares
  fileSystems."/export/Documents" = {
    device = "/mnt/data/Shared/Documents";
    options = [ "bind" ];
  };

  fileSystems."/export/Projects" = {
    device = "/mnt/data/Shared/Projects";
    options = [ "bind" ];
  };

  services.nfs.server = {
    enable = true;

    # Fixed rpc.statdPort for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';

    exports = ''
      /export             thinkpad-X13s(rw,fsid=0,no_subtree_check)
      /export/Documents   thinkpad-X13s(rw,nohide,insecure,no_subtree_check)
      /export/Projects    thinkpad-X13s(rw,nohide,insecure,no_subtree_check)
    '';
  };

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
}
