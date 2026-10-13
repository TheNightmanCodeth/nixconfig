# Nix binary cache on the NAS (/mnt/data/nix-cache over NFS). Each host
# mounts it somewhere different and sets lanNixCache.path. Both read from it
# and push every build to it. Works under nixOS and nix-darwin.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.lanNixCache;
  store = "file://${cfg.path}";
  nix = "${config.nix.package}/bin/nix";

  # nix-daemon runs this as root after every build, with the built paths in
  # $OUT_PATHS.
  push = pkgs.writeShellScript "push-lan-cache" ''
    set -f
    export IFS=' '
    [ -n "$OUT_PATHS" ] || exit 0
    ${nix} copy --to '${store}?compression=zstd&secret-key=/etc/nix/keys/cache.sec' $OUT_PATHS \
      || echo "push-lan-cache: push to ${store} failed, continuing" >&2
    exit 0
  '';
in
{
  options.lanNixCache.path = lib.mkOption {
    type = lib.types.str;
    description = "Where this host mounts the NAS nix cache";
  };

  config.nix.settings = {
    # extra-* adds to cache.nixos.org instead of replacing it. Priority 30
    # means the cache is checked before cache.nixos.org (40).
    extra-substituters = [ "${store}?priority=30" ];
    extra-trusted-public-keys = [ "lan-cache-1:VdZ1vPy4o0LUJdmzMkF7H3jiplTqbhmzDS2fCnjrf5c=" ];
    post-build-hook = push;
  };
}
