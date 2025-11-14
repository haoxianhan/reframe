{ lib, config, pkgs, ... }:
let
  cfg = config.services.reframe;
  types = lib.types;

  mkInstanceName = name: lib.removeSuffix ".conf" name;
  mkSocketUnit = name: "reframe@${mkInstanceName name}";
  mkServerUnit = name: "reframe-server@${mkInstanceName name}";
in {
  options.services.reframe = {
    enable = lib.mkEnableOption ("Enable ReFrame remote desktop services");

    package = lib.mkOption {
      type = types.package;
      default = if pkgs ? reframe then pkgs.reframe else throw "reframe package not found; add overlay or pass explicitly";
      description = "ReFrame package used for systemd units.";
    };

    configs = lib.mkOption {
      type = types.attrsOf types.lines;
      default = {};
      description = "Map of configuration file names to their textual contents, written to /etc/reframe/<name>.";
      example = {
        "DP-1.conf" = ''
          [reframe]
          card=card0
          connector=DP-1
          port=5933
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      etcFiles =
        lib.mapAttrs'
          (name: text: {
            name = "reframe/${name}";
            value.text = text;
          })
          cfg.configs;

      socketUnits =
        lib.listToAttrs (
          map (name: {
            name = mkSocketUnit name;
            value = {
              enable = true;
              overrideStrategy = "asDropin";
              wantedBy = [ "sockets.target" ];
            };
          }) (lib.attrNames cfg.configs)
        );

      serviceUnits =
        lib.listToAttrs (
          map (name: {
            name = mkServerUnit name;
            value = {
              enable = true;
              overrideStrategy = "asDropin";
              wantedBy = [ "multi-user.target" ];
            };
          }) (lib.attrNames cfg.configs)
        );
    in
    {
      systemd.packages = [ cfg.package ];
      environment.etc = etcFiles;
      systemd.sockets = socketUnits;
      systemd.services = serviceUnits;
    }
  );
}
