# Local LLM serving. ComfyUI is not here — it comes from the flake's outputs
# (`nix run .#comfyui` / `nix develop .#comfyui`), because building it against
# ROCm means building torch from source and that has no business gating a
# `nixos-rebuild switch`. See README.
{ pkgs, ... }:
{
  services.ollama = {
    enable = true;

    # `services.ollama.acceleration = "rocm"` was REMOVED from the module
    # (it's in its mkRemovedOptionModule list now) — selecting the package is
    # the current way to pick a backend.
    package = pkgs.ollama-rocm;

    # Sets HSA_OVERRIDE_GFX_VERSION on the unit. Redundant with the global one
    # in rocm.nix, but stated explicitly so the GPU story survives someone
    # later deciding that global env var was too broad a hammer.
    rocmOverrideGfx = "10.3.0";

    # Loopback only. The default firewall is on and no port is opened; reach it
    # over an SSH tunnel, or set `host = "0.0.0.0"` + `openFirewall = true` once
    # you've decided who should be able to talk to it.
    host = "127.0.0.1";

    # Weights land in /var/lib/ollama/models on the root filesystem. That is the
    # same 238 GB device as everything else — `ollama list` before you pull.
  };
}
