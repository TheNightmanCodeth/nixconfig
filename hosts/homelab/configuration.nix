{ config, lib, pkgs, ... }:
let
  homelabSystemPackages = with pkgs; [
    ethtool
    networkd-dispatcher
  ];
in {
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

    #### IP Forwarding (Tailscale Exit Node)
      kernel.sysctl."net.ipv4.ip_forward" = lib.mkForce 1;
      kernel.sysctl."net.ipv6.conf.all.forwarding" = lib.mkForce 1;
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

  #### NFS - ROMS
    fileSystems."/export/roms" = {
      device = "/mnt/data/roms";
      options = [ "bind" ];
    };

    swapDevices = [
      { device = "/dev/disk/by-label/swap"; }
    ];

#### NFS Config
    services.nfs.server.enable = true;
    networking.firewall.allowedTCPPorts = [ 2049 ];
    # path            ip-addr-or-subnet(opts,...) ...
    services.nfs.server.exports = ''
      /export/roms    100.0.0.0/8(rw,nohide,insecure,no_subtree_check)
    '';

#### Time Machine
    services.samba = {
      enable = true;
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

#### Tailscale (homelab specific)
    services.tailscale.useRoutingFeatures = "both";
    # services.tailscale.interfaceName = "enp4s0f0u2";

    services.networkd-dispatcher = {
      enable = true;
      rules."50-tailscale" = {
        onState = ["routable"];
        script = ''
          NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
          ${pkgs.ethtool} -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };

#### Virt-manager
    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = [ "joe" ];
    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;

#### RDP
    services.xrdp.enable = true;
    services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
    services.xrdp.openFirewall = true;

    environment.systemPackages = with pkgs; [ gnome-remote-desktop ] ++ homelabSystemPackages; 

#### Disable auto-suspend
    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

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
        vaapiVdpau
        libvdpau-va-gl
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
