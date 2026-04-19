{ ... }:

{
  docker-deploy."hikka" = {
    repo = "https://github.com/hikariatama/hikka";
    branch = "master";
    dockerfile = "Dockerfile";
    ports = [ "8003:8080" ];
    command = [
      "python"
      "-m"
      "hikka"
      "--data-root"
      "/data/sessions"
    ];
    volumes = [
      "/home/deploy/hikka-data:/data"
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
