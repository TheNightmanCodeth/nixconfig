# The fast route to ComfyUI on ROCm.
#
# `nix run .#comfyui` (the packages output) is the pure one, but it builds torch
# with rocmSupport from source — hours of compiling and a large build directory.
# This shell instead gives you an FHS sandbox where AMD's *prebuilt* ROCm PyTorch
# wheels from download.pytorch.org run as-is, so you're generating images today.
#
#   nix develop .#comfyui
#   git clone https://github.com/comfyanonymous/ComfyUI ~/comfyui && cd ~/comfyui
#   python -m venv .venv && source .venv/bin/activate
#   pip install --index-url https://download.pytorch.org/whl/rocm6.4 torch torchvision torchaudio
#   pip install -r requirements.txt
#   python main.py --listen 127.0.0.1
#
# Check https://pytorch.org/get-started/locally/ for the current rocmX.Y index —
# the URL above is the moving part of these instructions.
#
# HSA_OVERRIDE_GFX_VERSION is already global (modules/rocm.nix) and the wheels
# honour it, so the 6650 XT is picked up as gfx1030 in here too.
{ pkgs }:
pkgs.buildFHSEnv {
  name = "comfyui-rocm";

  targetPkgs =
    p: with p; [
      python312
      python312Packages.pip
      python312Packages.virtualenv
      uv

      git
      gcc
      stdenv.cc.cc.lib # libstdc++ — the wheels link against it
      zlib

      # The wheels bundle their own ROCm userspace but still dlopen these from
      # the system.
      libdrm
      numactl # libnuma
      elfutils # libelf
      libglvnd
      ocl-icd

      # imaging / video deps ComfyUI reaches for at runtime
      libGL
      glib
      ffmpeg
    ];

  # Kernel-side GPU access comes from /dev/dri, which the FHS env passes
  # through; membership in `render` (see the host config) is what authorises it.
  runScript = "bash";

  profile = ''
    export ROCM_PATH=/opt/rocm
    echo "comfyui-rocm shell — see shells/comfyui.nix for the setup steps."
  '';
}
