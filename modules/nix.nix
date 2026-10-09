# Nix itself: flakes on from the first boot, plus the caches that make the
# neovim input cheap to build. Shared by odysseus (NixOS) and ithaca
# (nix-darwin), so only options both module systems have belong here. GC
# scheduling differs between the two (`dates` vs launchd `interval`) and lives
# in each host.
{ inputs, ... }:
{
  nix = {
    settings = {
      # The day-1 requirement. Also needs passing by hand to the *installer* —
      # see README, step 4.
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      trusted-users = [
        "root"
        "joe"
      ];

      # joevim's fork dropped the nixConfig block its upstream carries, so it
      # advertises no caches of its own. Declaring them here means most of the
      # nixvim closure comes down prebuilt instead of compiling locally.
      extra-substituters = [
        "https://khanelivim.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "khanelivim.cachix.org-1:Tb0jsMlhXSJDtI2ISiGPBrvL1XIzQrWap80AiJuBGI0="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;

    # Make `nix shell nixpkgs#foo` resolve to the same nixpkgs the system was
    # built from, instead of a stale channel.
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}
