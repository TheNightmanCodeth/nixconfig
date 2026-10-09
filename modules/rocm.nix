# ROCm for the Radeon RX 6650 XT.
#
# The one thing that matters here: the 6650 XT is Navi 23, which is **gfx1032**,
# and ROCm ships compiled kernels for gfx1030 only in that family. Verified
# against nixpkgs — `rocmPackages.clr.gpuTargets` lists gfx1010, gfx1030,
# gfx1100…1201 and no gfx1032, and torch's ROCm target list is that same list
# minus the RDNA1 entries. So every ROCm consumer has to be told to present the
# card as gfx1030, which is what HSA_OVERRIDE_GFX_VERSION=10.3.0 does.
#
# Without it: rocminfo shows the agent, and hipblas/rocblas/torch then fail at
# kernel-launch time with "no kernel image is available".
{ pkgs, ... }:
let
  # gfx1032 -> report as gfx1030 (10.3.0).
  hsaGfxOverride = "10.3.0";

  # A single tree that looks like a conventional /opt/rocm. nixpkgs used to ship
  # `rocmPackages.rocmPath` for this; it was removed 2025-09-30 and now throws,
  # so the join is assembled here instead. Anything that hardcodes ROCM_PATH or
  # dlopen()s out of /opt/rocm (much of the ComfyUI extension ecosystem does)
  # needs this to exist.
  rocmPath = pkgs.symlinkJoin {
    name = "rocm-path";
    paths = with pkgs.rocmPackages; [
      rocm-core
      rocm-runtime
      rocm-comgr
      rocm-device-libs
      clr
      hipcc
      hipblas-common
      hipblas
      rocblas
      rocfft
      hipfft
      rocrand
      hiprand
      rocsparse
      hipsparse
      rocsolver
      hipsolver
      miopen
      rccl
      rocminfo
      rocm-smi
    ];
  };
in
{
  hardware.graphics.enable = true;

  # Pulls in rocmPackages.clr and clr.icd as the OpenCL driver — this is the
  # module's entire job, so clr is deliberately not repeated in extraPackages.
  hardware.amdgpu.opencl.enable = true;

  # amdgpu in stage 1 so the console comes up at native resolution rather than
  # switching modes partway through boot.
  hardware.amdgpu.initrd.enable = true;

  # Applies to every process on the box, which is correct *because this machine
  # has exactly one GPU*. The 4600G's iGPU (gfx90c) is disabled in firmware —
  # only one DRM node exists today. If you ever re-enable it in BIOS, ROCm will
  # enumerate both, this override will be wrong for the APU, and you'll want
  # ROCR_VISIBLE_DEVICES to pin the discrete card instead.
  environment.variables = {
    HSA_OVERRIDE_GFX_VERSION = hsaGfxOverride;
    ROCM_PATH = "/opt/rocm";
  };

  systemd.tmpfiles.rules = [
    "L+ /opt/rocm - - - - ${rocmPath}"
  ];

  environment.systemPackages = with pkgs.rocmPackages; [
    rocminfo # `rocminfo | grep gfx` — first thing to run after boot
    rocm-smi # utilisation, VRAM, temps, clocks
  ];
}
