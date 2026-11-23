# ithaca — nix-darwin on joe's Apple Silicon MacBook Air.
{ inputs, ... }:
{
  imports = [ ../../modules/common.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Renames the machine: hostname, Bonjour name (ithaca.local), and the name
  # shown in Sharing settings.
  networking = {
    hostName = "ithaca";
    computerName = "ithaca";
  };

  system.primaryUser = "joe";

  # Existing macOS account. Not in users.knownUsers, so nix-darwin never
  # creates or deletes it; `home` is what home-manager needs to find it.
  users.users.joe.home = "/Users/joe";

  # Remote Login, key-only. Apple's sshd includes /etc/ssh/sshd_config.d/*,
  # and neither 100-macos.conf nor sshd_config sets these. With UsePAM on,
  # keyboard-interactive has to go too, or PAM still offers a password.
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      PermitRootLogin no
    '';
  };

  # Nix binary cache on the NAS. ithaca pushes its aarch64-darwin builds too.
  # nix-darwin has no fileSystems, so this is an autofs direct map: auto_master
  # gains one line pointing at auto_nixcache. /etc/fstab is left alone — it
  # holds the installer's /nix volume entry. knownSha256Hashes is the stock
  # auto_master nix-darwin is allowed to replace; if a macOS update rewrites
  # it, activation stops and asks for the new hash.
  environment.etc."auto_master" = {
    knownSha256Hashes = [
      "b2aac03248e8f229c703561f5bb059f9be491e5db9f447692398d775a9fb12a5"
    ];
    text = ''
      #
      # Automounter master map
      #
      +auto_master		# Use directory service
      #/net			-hosts		-nobrowse,hidefromfinder,nosuid
      /home			auto_home	-nobrowse,hidefromfinder
      /Network/Servers	-fstab
      /-			-static
      /-			auto_nixcache	-nobrowse,nosuid
    '';
  };
  # macOS's client only speaks NFSv4.0. resvport because Linux nfsd rejects
  # unprivileged source ports by default; soft so an absent NAS (off the
  # LAN) errors out instead of hanging nix-daemon. deadtimeout=0 so the
  # kernel never force-unmounts ("squishes") it while the NAS is briefly
  # unreachable, e.g. across sleep or a reboot; it recovers instead. No
  # nolocks: locking is part of NFSv4 itself, and mount_nfs fails with
  # EINVAL if it's given.
  #
  # LAN address, not homelab-mm's tailnet one (100.109.104.32): the tailnet
  # route depends on Tailscale being up, which it isn't right after wake or
  # boot, and that's what kept killing the mount. Off the LAN the cache is
  # simply unavailable and nix falls back to cache.nixos.org.
  environment.etc."auto_nixcache".text = ''
    /opt/nix-cache	-fstype=nfs,vers=4,resvport,soft,timeo=50,deadtimeout=0	10.20.30.210:/mnt/data/nix-cache
  '';
  system.activationScripts.postActivation.text = ''
    /usr/sbin/automount -c
  '';

  lanNixCache.path = "/opt/nix-cache";

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Carried over from the original /etc/nix-darwin flake. Read
  # `darwin-rebuild changelog` before changing.
  system.stateVersion = 6;
}
