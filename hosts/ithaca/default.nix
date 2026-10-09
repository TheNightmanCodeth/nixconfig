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

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Carried over from the original /etc/nix-darwin flake. Read
  # `darwin-rebuild changelog` before changing.
  system.stateVersion = 6;
}
