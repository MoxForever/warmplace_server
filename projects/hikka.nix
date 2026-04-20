{ ... }:

{
  docker-deploy."hikka" = {
    repo = "https://github.com/hikariatama/hikka";
    branch = "master";
    dockerfile = "Dockerfile";
    ports = [ "8003:8080" ];
    command = [
      "sh"
      "-c"
      "pip install aiogoogle pydantic && python -m hikka --data-root /data/sessions"
    ];
    volumes = [
      "/home/deploy/hikka-modules:/data/loaded_modules"
      "/home/deploy/hikka-data:/data/sessions"
    ];
  };

  services.nginx.virtualHosts."hikka.moxforever.me" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://localhost:8003/";
    };
  };
}
