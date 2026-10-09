# Hand-written to match this machine (ASRock B550M-ITX/ac, Ryzen 5 4600G,
# Radeon RX 6650 XT, WD SN730 NVMe). After `nixos-generate-config` runs during
# install, diff its output against this file and reconcile any surprises.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # nvme: the SN730 root disk. ahci: B550 SATA ports. xhci_pci + usb*: keyboard
  # and installer media in stage 1.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];

  # AMD-V is present; kvm-amd costs nothing and you already run containers.
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Labels rather than UUIDs, so this file survives a reinstall unchanged.
  # The README's partitioning step creates exactly these two labels.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # 62 GiB of RAM: no swap partition. zramSwap (see ../../modules/nix.nix)
  # covers the rare spike without giving up NVMe space to models.
  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  # enp6s0 = Realtek RTL8111 (the live link). wlp7s0 = Intel AC 3168, currently down.
  networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;
  networking.interfaces.wlp7s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = true; # amdgpu + iwlwifi blobs
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
