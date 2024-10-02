{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.softserve;
  configFile = format.generate "config.yaml" cfg.settings;
  format = pkgs.formats.yaml { };
  docUrl = "https://charm.sh/blog/self-hosted-soft-serve/";
in
{
  options = {
    services.softserve = {
      enable = mkEnableOption "soft-serve";
      package = mkPackageOption pkgs "soft-serve" { };
      settings = mkOption {
        type = format.type;
        default = { };
        description = ''
          The contents of the configuration file for soft-serve.

          See <${docUrl}>.
        '';
        example = literalExpression ''
          {
            name = "joe's repos";
            log_format = "text";
            ssh = {
              listen_addr = ":69420";
            };
          }
        '';
      };

      stateDir = mkOption {
        type = types.path;
        default = "/var/lib/soft-serve";
        description = "Path for configuration and state";
        example = literalExpression ''
          "/mnt/data/Apps/SoftServe";
        '';
      };

      initialAdminKey = mkOption {
        type = types.nonEmptyStr;
        description = "Public key of the inital admin account. Soft-serve is unusable without this option set";
        example = literalExpression ''
          "ssh-ed25519 AAAAC3NzaC1lZDI1..."
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    users = {
      users.soft-serve = {
        isNormalUser = true;
        #isSystemUser = false;
        group = "soft-serve";
      };

      groups = {
        soft-serve = {};
      };
    };

    systemd.tmpfiles.rules = [
      # The config file has to be inside the state dir
      "L+ ${cfg.stateDir}/config.yaml - - - - ${configFile}"
    ];

    systemd.services.soft-serve = {
      description = "Soft Serve git server";
      documentation = [ docUrl ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment.SOFT_SERVE_DATA_PATH = cfg.stateDir;
      environment.SOFT_SERVE_INITIAL_ADMIN_KEYS = cfg.initialAdminKey;

      serviceConfig = {
        Type = "simple";
        User = "soft-serve";
        Group = "soft-serve";
        Restart = "always";
        ExecStart = "${getExe cfg.package} serve";
        StateDirectory = "soft-serve";
        WorkingDirectory = cfg.stateDir;
        RuntimeDirectory = "soft-serve";
        RuntimeDirectoryMode = "0750";
        ProcSubset = "pid";
        ProtectProc = "invisible";
        UMask = "0027";
        CapabilityBoundingSet = "";
        ProtectHome = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RemoveIPC = true;
        PrivateMounts = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@cpu-emulation @debug @keyring @module @mount @obsolete @privileged @raw-io @reboot @setuid @swap"
        ];
      };
    };
  };
}
