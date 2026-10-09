{
  description = "odysseus (NixOS, Ryzen 5 4600G + RX 6650 XT, ROCm) and ithaca (nix-darwin, MacBook Air)";

  inputs = {
    # Tracking unstable on purpose: ROCm 6.x and the `comfyui` package only
    # exist there. Stable (26.05) has no `comfyui` at all. ithaca shares it —
    # nixos-unstable is built and cached for aarch64-darwin too.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # User-level config (git) for joe on both machines.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim. Pins its own nixpkgs via its flake.lock; deliberately not
    # `follows`-ed, because nixvim is only tested against the rev it locks.
    joevim.url = "github:TheNightmanCodeth/joevim";
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      # A second nixpkgs with rocmSupport flipped on. Kept *out* of the system
      # closure on purpose: rocmSupport rebuilds torch (and everything else that
      # consumes ROCm) from source, which is hours of compiling. Only the
      # ComfyUI outputs below pay that cost, and only when you ask for them.
      pkgsRocm = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          rocmSupport = true;
        };
      };
    in
    {
      nixosConfigurations.odysseus = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/odysseus
        ];
      };

      darwinConfigurations.ithaca = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/ithaca
        ];
      };

      # ComfyUI built against ROCm, from nixpkgs. Fully declarative, very slow
      # to build the first time. See README for the fast alternative.
      packages.${system}.comfyui = pkgsRocm.comfyui;

      # The fast path: an FHS sandbox where AMD's official ROCm PyTorch wheels
      # run unmodified. `nix develop .#comfyui`, then pip-install ComfyUI.
      devShells.${system}.comfyui = import ./shells/comfyui.nix {
        pkgs = nixpkgs.legacyPackages.${system};
      };
    };
}
