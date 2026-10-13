# Everything odysseus and ithaca share: nix settings, neovim, the CLI agents,
# joe's authorized SSH keys, and joe's home-manager config. Must evaluate under
# both NixOS and nix-darwin, so stick to options the two have in common.
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./nix.nix
    ./nix-cache.nix
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  environment = {
    systemPackages = [
      inputs.joevim.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.claude-code
      pkgs.codex
    ];

    variables.EDITOR = "nvim";

    # Completions shipped by system packages, for home-manager's compinit.
    pathsToLink = [ "/share/zsh" ];
  };

  # Carried over from the Fedora install's ~/.ssh/authorized_keys. The first is
  # ithaca's ~/.ssh/id_ed25519.pub, the only public key on that machine.
  users.users.joe.openssh.authorizedKeys.keys = [
    # ithica
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmW6OuZ1gSgM6ubqbE5ZWVqe/Ay/W3j4XhGnaB9folp joe@MacBook-Air.attlocal.net"
    # iphone / iSH
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfRx14BGVoosZPjusWQmmoVagQANRYq45fxR40XwcKj"
    # odysseus
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJeBvmFRJHthe3AgBdjUspBcVxEm9ODjErePP0+bFwJ9 joseph.diragi@icloud.com"
  ];

  # zsh everywhere; joe's actual config (plugins, prompt) is in home.nix.
  # System-wide compinit is off because home-manager runs its own after the
  # antidote plugins are on fpath. Leaving both on makes every shell run
  # compinit twice.
  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };
  users.users.joe.shell = pkgs.zsh;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Pre-existing dotfiles it takes over (~/.zshrc) get moved aside instead of
    # failing activation.
    backupFileExtension = "hm-backup";
    users.joe = import ./home.nix;
  };
}
