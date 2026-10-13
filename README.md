# odysseus + ithaca — Nix configs

- **odysseus**: barebones NixOS: hardware support, ROCm, ollama, NFS, and neovim.
- **ithaca**: nix-darwin on the Apple Silicon MacBook Air.

Both machines share the same nix settings, joevim, claude-code/codex, `EDITOR=nvim`, the
authorized SSH keys (key-only sshd), zsh as the login shell, and joe's git + zsh config via home-manager
(`modules/common.nix`, `modules/nix.nix`, `modules/home.nix`). ROCm, ollama,
ComfyUI and the NFS export exist only on odysseus.

## What it targets

Detected on the running Fedora install:

| | |
|---|---|
| Board | ASRock B550M-ITX/ac (BIOS P3.90), UEFI |
| CPU | AMD Ryzen 5 4600G, 6C/12T |
| GPU | Radeon RX 6650 XT — Navi 23, **gfx1032** |
| iGPU | Renoir Vega, **disabled in firmware** (one DRM node present) |
| RAM | 62 GiB |
| Disk | WD SN730 NVMe, 238 GB (only disk) |
| Net | `enp6s0` Realtek RTL8111 (live, DHCP) · `wlp7s0` Intel AC 3168 |

## Layout

```
flake.nix                     nixpkgs unstable, nix-darwin, home-manager, joevim; comfyui outputs
flake.lock                    pinned, evaluated, ready to install from
hosts/odysseus/
  default.nix                 the system: boot, user, ssh, nfs, nix-cache mount, zram
  hardware-configuration.nix  disks, modules, firmware, microcode
hosts/ithaca/
  default.nix                 hostname, key-only Remote Login, NAS nix-cache automount
modules/
  common.nix                  shared by both hosts: packages, ssh keys, home-manager
  home.nix                    joe's home-manager config: git, zsh + antidote plugins
  nix.nix                     flakes on day 1, caches, gc, optimise
  rocm.nix                    amdgpu + ROCm userspace + the gfx1032 fix
  ai.nix                      ollama on ROCm
shells/comfyui.nix            FHS sandbox for AMD's ROCm torch wheels
```

## The one ROCm detail that matters

The RX 6650 XT is **gfx1032**. ROCm ships compiled kernels for gfx1030 only in
the Navi 2x family — `rocmPackages.clr.gpuTargets` in nixpkgs lists gfx1010,
gfx1030, gfx1100–1201 and *no gfx1032*, and torch's ROCm target list is that
same list minus the RDNA1 entries.

So everything must be told to present the card as gfx1030. That is
`HSA_OVERRIDE_GFX_VERSION=10.3.0`, set globally in `modules/rocm.nix` and again
on the ollama unit. Skip it and `rocminfo` looks perfectly healthy while torch
and rocBLAS fail at kernel launch with *"no kernel image is available"*.

`/opt/rocm` is assembled by hand in `modules/rocm.nix` as a `symlinkJoin`.
nixpkgs used to provide `rocmPackages.rocmPath` for this; it was removed on
2025-09-30 and now throws. Plenty of ComfyUI custom nodes dlopen out of
`/opt/rocm`, so it needs to exist.

---

## Installing

### ⚠️ Read this first

This machine is **in use** and there is only one disk. The steps below erase it.
Currently on `/dev/nvme0n1`: Fedora 44 Server, 124 GB used, **97 GB in
`/home/joe`**, a live Docker stack (`odysseus`, nginx reverse proxy, chromadb,
searxng, ntfy — with named volumes `odysseus_chromadb-data`,
`odysseus_ntfy-cache`, `odysseus_searxng-data`), and Tailscale state in
`/var/lib/tailscale`.

Back all of that up to another machine before you start. Nothing in this repo
migrates it, and none of it was touched while the config was written.

Also worth deciding now: 238 GB is not much once model weights land on it.
Ollama models go to `/var/lib/ollama/models` and ComfyUI checkpoints are tens of
GB each — both on the root filesystem. Consider a second drive.

### 1. Back up, then boot the installer

Use the **NixOS 26.05** minimal ISO (that release is what `system.stateVersion`
records). Boot it, then `sudo -i`.

### 2. Partition

Erases the disk.

```sh
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root ext4 1GiB 100%

# The labels matter — hardware-configuration.nix mounts by label, not UUID.
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/BOOT /mnt/boot
```

### 3. Get this repo onto /mnt

Push it somewhere reachable first, or carry it on a USB stick.

```sh
mkdir -p /mnt/etc/nixos
# e.g. from a USB stick mounted at /src:
cp -r /src/nix-config/. /mnt/etc/nixos/
```

Optional sanity check — generate a config and compare the hardware half:

```sh
nixos-generate-config --no-filesystems --root /mnt
diff /mnt/etc/nixos/hardware-configuration.nix \
     /mnt/etc/nixos/hosts/odysseus/hardware-configuration.nix
```

### 4. Flakes, on the installer too

The installer ISO ships with flakes off, so enable them for this shell before
installing. This is the step people miss.

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
```

(The installed system needs no such flag — `modules/nix.nix` turns flakes on
permanently, which is the day-1 part of the ask.)

### 5. Install

```sh
nixos-install --flake /mnt/etc/nixos#odysseus
reboot
```

### 6. First boot

Log in as `joe` / `changeme` and immediately:

```sh
passwd
```

`initialPassword` is world-readable in the Nix store; it exists only to get you
through the first login and first `sudo`. After `passwd` it is irrelevant
(`users.mutableUsers` defaults to true). SSH is already key-only using the two
ed25519 keys from your Fedora `authorized_keys`, so password login over the
network was never possible.

---

## Verifying ROCm

```sh
rocminfo | grep -i gfx        # expect gfx1032 as the agent…
rocm-smi                      # …and VRAM/temps/clocks for the 6650 XT
systemctl status ollama
```

`rocminfo` reports the card's **real** name, gfx1032 — that is correct and not a
sign the override failed. The override acts on what ROCm *loads kernels for*.
The real test is arithmetic on the GPU:

```sh
ollama run llama3.2:3b "hi"
rocm-smi                      # watch GPU% move while it generates
```

Ollama listens on `127.0.0.1:11434` only, and the firewall opens nothing. Reach
it over an SSH tunnel, or set `host = "0.0.0.0"` and `openFirewall = true` in
`modules/ai.nix` once you've decided who should be able to talk to it.

## ComfyUI

Two routes, because the pure one is expensive.

**Fast — AMD's prebuilt ROCm wheels in an FHS sandbox.** Recommended for
getting running today.

```sh
nix develop .#comfyui
git clone https://github.com/comfyanonymous/ComfyUI ~/comfyui && cd ~/comfyui
python -m venv .venv && source .venv/bin/activate
pip install --index-url https://download.pytorch.org/whl/rocm6.4 torch torchvision torchaudio
pip install -r requirements.txt
python main.py --listen 127.0.0.1
```

Check <https://pytorch.org/get-started/locally/> for the current `rocmX.Y` index
URL — that is the part of the recipe that moves.

**Pure — nixpkgs `comfyui` built against ROCm.**

```sh
nix run .#comfyui
```

Verified to evaluate with `torch.rocmSupport = true` and
`torch.cudaSupport = false`, so it is genuinely a ROCm build. But it compiles
torch, aotriton and composable_kernel from source: expect hours and a very large
build directory. This is deliberately a flake output rather than a system
package, so it can never hold up a `nixos-rebuild switch`.

## Day-to-day

```sh
sudo nixos-rebuild switch --flake /etc/nixos#odysseus
sudo darwin-rebuild switch --flake ~/Projects/nixos#ithaca   # on the Mac
nix flake update                      # all inputs
nix flake update nixpkgs              # just one
```

## Things left out, and why

- **No desktop.** "Barebones" plus Fedora *Server* Edition read as headless.
  Adding one is `services.xserver.desktopManager.<x>.enable = true` — the amdgpu
  and ROCm work here is independent of it.
- **No Tailscale, no Docker.** Both are running on the box today. Neither is
  hardware or ROCm, so neither is here. `services.tailscale.enable = true` and
  `virtualisation.docker.enable = true` when you want them back — note that
  reaching the machine after the install relies on LAN SSH, not Tailscale.
- **No swap partition.** 62 GiB of RAM; `zramSwap` covers spikes without giving
  NVMe space to swap.
- **Default kernel.** Navi 23 has been solid in amdgpu since 5.15.
  `boot.kernelPackages = pkgs.linuxPackages_latest;` if you want newer KFD.

## Caveats

- **joevim is stale.** Its HEAD is 2025-03-15 and it pins nixpkgs and nixvim
  from March 2025. The full system evaluates fine, but 18-month-old derivations
  may have been garbage-collected out of the binary caches, so neovim could
  build from source on first install. `modules/nix.nix` adds the
  `khanelivim` and `nix-community` caches to improve the odds — joevim's own
  flake dropped the `nixConfig` block its upstream carries. Running
  `nix flake update` *inside your joevim fork* and pushing is the real fix.
- **Unstable, not stable.** `comfyui` does not exist in nixpkgs 26.05 — only in
  unstable. That drove the channel choice.
- **If you `git init` this directory**, remember flakes only see tracked files.
  A new module you forgot to `git add` is silently invisible.
- **The gfx override is global** and correct *because there is one GPU*. If you
  ever re-enable the 4600G's iGPU in BIOS, ROCm will enumerate gfx90c as well,
  `10.3.0` will be wrong for it, and you'll want `ROCR_VISIBLE_DEVICES` to pin
  the discrete card.

## How this was checked

No Nix on the Fedora host, so everything was evaluated in a `nixos/nix`
container:

- all seven `.nix` files parse;
- `nixosConfigurations.odysseus.config.system.build.toplevel` evaluates to a
  derivation with the real joevim input — so every option name here is valid
  against nixpkgs `e158d9e`;
- `packages.comfyui` and `devShells.comfyui` both evaluate;
- `comfyui.python.pkgs.torch` reports `rocmSupport = true` / `cudaSupport = false`.

Evaluated, not built, and not booted on hardware.
