{ config, ... }: {
  imports = [
    ./soft-serve.nix
  ];

  config.services.softserve = {
    enable = true;
    stateDir = "/mnt/data/Apps/SoftServe";
    initialAdminKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKRI4+bmHb0DWvx3BFVPkqbMQfSNPss6LATB34mYTTBd";
    settings = {
      name = "Joe Rulez";
      log_format = "text";
      ssh = {
        listen_addr = ":23231";
        public_url = "ssh://homelab.local:23231";
      };
      stats.listen_addr = ":23233";
    };
  };
}
