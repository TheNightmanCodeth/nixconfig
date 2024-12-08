{ config, pkgs, lib, ... }:
{
  config = {

#### USERS & GROUPS
    users = {
      users.streamer = {
        isSystemUser = true;
        group = "media";
      };

      users.sonarr = { isSystemUser = true; group = "media"; };
      users.radarr = { isSystemUser = true; group = "media"; };
      users.prowlarr = {
        group = "prowlarr";
        home = "/mnt/data/Apps/Prowlarr";
        uid = 293;
      };

      users.transmission = {
        isSystemUser = true;
        group = "media";
        extraGroups = [ "torrenter" ];
      };

      groups = {
        torrenter = {};
        media = {};
        streamer = {};
        prowlarr = {};
      };
    };

#### PLEX : 32400
    services.plex = {
      enable = true;
      user = "streamer";
      group = "media";
      openFirewall = true;
      dataDir = "/mnt/data/Apps/Plex";
    };

    services.jellyfin = {
      enable = true;
      user = "streamer";
      group = "media";
      openFirewall = true;
      dataDir = "/mnt/data/Apps/JellyFin";
    };

#### SONARR : 8989
    services.sonarr = {
      enable = true;
      user = "sonarr";
      group = "media";
      openFirewall = true;
      dataDir = "/mnt/data/Apps/Sonarr";
    };

#### RADARR : 7878
    services.radarr = {
      enable = true;
      user = "radarr";
      group = "media";
      openFirewall = true;
      dataDir = "/mnt/data/Apps/Radarr";
    };

#### PROWLARR : 9696
    systemd.tmpfiles.rules = [
      "d '/mnt/data/Apps/Prowlarr' 0700 prowlarr prowlarr - -"
    ];

    systemd.services.prowlarr = {
      description = "Prowlarr";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "prowlarr";
        Group = "prowlarr";
        ExecStart = "${lib.getExe pkgs.prowlarr} -nobrowser -data=/mnt/data/Apps/Prowlarr";
        Restart = "on-failure";
      };
    };

#### FIREWALL

    networking.firewall.allowedTCPPorts = [ 9696 7878 8989 9091 ];
    
#### VPN + Transmission
    vpnNamespaces.wg = {
      enable = true;
      wireguardConfigFile = /. + "/home/joe/.secrets/wireguard.conf";
      accessibleFrom = [
        "192.168.0.0/16"
      ];
      portMappings = [
        { from = 9091; to = 9091; }
      ];
      openVPNPorts = [{
        port = 60965;
        protocol = "both";
      }];
    };

    systemd.services.transmission.vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };

    services.transmission = {
      enable = true;
      user = "transmission";
      group = "media";
      home = "/mnt/data/Apps/Transmission";

      settings = {
        download-dir = "/mnt/media/downloads";
        incomplete-dir-enabled = true;
        incomplete-dir = "/mnt/media/downloads/incomplete";
        rpc-bind-address = "192.168.15.1";
        rpc-whitelist-enabled = true;
        rpc-whitelist = "192.168.*.*";
        blocklist-enabled = true;
        blocklist-url = "https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz";
        peer-port = 60965;
        dht-enabled = false;
        pex-enabled = false;
        utp-enabled = false;
        encryption = 1;
        port-forwarding-enabled = false;
        anti-brute-force-enabled = true;
        anti-brute-force-threshold = 3;
      };
    };
  };
}

