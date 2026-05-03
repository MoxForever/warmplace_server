{
  config,
  lib,
  pkgs,
  ...
}:
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

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    location = "/var/backup/postgresql/backups";
    startAt = "daily";
  };

  sops.secrets.postgres_password_warmplace = {
    key = "postgres_passwords/warmplace";
    owner = "postgres";
  };

  sops.secrets.postgres_password_warmplace_dev = {
    key = "postgres_passwords/warmplace_dev";
    owner = "postgres";
  };

  sops.secrets.postgres_password_yaeshop = {
    key = "postgres_passwords/yaeshop";
    owner = "postgres";
  };

  sops.secrets.postgres_password_mock_service = {
    key = "postgres_passwords/mock_service";
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
      config.services.postgresql.package
    ];

    script = ''
            set -euo pipefail

            set_role_password() {
              local user="$1"
              local password_file="$2"
              local password

              password="$(cat "$password_file")"

              psql -v ON_ERROR_STOP=1 -d postgres --set=role_name="$user" <<'SQL'
              SELECT format('CREATE ROLE %I LOGIN', :'role_name')
              WHERE NOT EXISTS (
                SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = :'role_name'
              )
              \gexec
      SQL

              psql -v ON_ERROR_STOP=1 -d postgres --set=role_name="$user" --set=role_password="$password" <<'SQL'
              SELECT format('ALTER ROLE %I WITH PASSWORD %L', :'role_name', :'role_password') \gexec
      SQL
            }

            set_role_password "warmplace" "${config.sops.secrets.postgres_password_warmplace.path}"
            set_role_password "yaeshop" "${config.sops.secrets.postgres_password_yaeshop.path}"
            set_role_password "warmplace-dev" "${config.sops.secrets.postgres_password_warmplace_dev.path}"
            set_role_password "mock-service" "${config.sops.secrets.postgres_password_mock_service.path}"
    '';
  };
}
