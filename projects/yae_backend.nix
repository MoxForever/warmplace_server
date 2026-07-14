{ lib, ... }:

{
  services.postgresql = {
    ensureDatabases = [ "yae_backend" ];
    ensureUsers = [
      {
        name = "yae_backend";
        ensureDBOwnership = true;
      }
    ];
  };

  docker-deploy."yae_backend" = {
    repo = "https://github.com/WarmYaeShop/yae_backend";
    branch = "dev";
    dockerfile = "docker/Dockerfile";
    ports = [ "8007:8000" ];
  };

  services.nginx.virtualHosts."api.yaeshop.net" = {
    forceSSL = true;
    enableACME = true;

    locations."/site/" = {
      proxyPass = "http://localhost:8007/site/";
    };
  };
}
