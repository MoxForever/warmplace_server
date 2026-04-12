{
  config,
  lib,
  pkgs,
  ...
}:

let
  secretPath = config.sops.secrets.postgres_passwords.path;
in
{
  ########################################
  # Сервисы
  ########################################

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = true;

    authentication = ''
      host all all 172.16.0.0/12 scram-sha-256
    '';
  };

  sops.secrets.postgres_passwords = {
    owner = "postgres";
  };

  systemd.services.postgresql-set-passwords = {
    description = "Set PostgreSQL passwords from sops map";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };

    path = [
      pkgs.jq
      pkgs.yq
      pkgs.postgresql
    ];

    script = ''
      set -euo pipefail

      json=$(yq -o=json '.' ${config.sops.secrets.postgres_passwords.path})

      echo "$json" \
        | jq -r '.postgres_passwords | to_entries[] | "\(.key)\t\(.value)"' \
        | while IFS=$'\t' read -r user password; do

          echo "Processing user: $user"

          psql -v ON_ERROR_STOP=1 -d postgres <<EOF
          DO $$
          BEGIN
            IF NOT EXISTS (
              SELECT FROM pg_catalog.pg_roles WHERE rolname = '$user'
            ) THEN
              CREATE ROLE $user LOGIN;
            END IF;
          END
          $$;

          ALTER USER $user WITH PASSWORD '$password';
          EOF

        done
    '';
  };
}
