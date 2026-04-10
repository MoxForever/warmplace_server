{ lib, ... }:

{
  services.postgresql = {
    ensureDatabases = [ "warmplace" ];
    ensureUsers = [
      {
        name = "warmplace";
        ensureDBOwnership = true;
      }
    ];
  };

  services.redis.servers.warmplace = {
    enable = true;
    port = 6379;
    settings = {
      bind = lib.mkForce "0.0.0.0";
      "protected-mode" = "no";
    };
  };

  docker-deploy."warmplace" = {
    repo = "git@github.com:WarmYaeShop/warmplace_shop.git";
    branch = "main";
    ports = [ "8001:8000" ];
  };
}
