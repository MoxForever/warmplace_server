{ ... }:

{
  docker-deploy."hikka" = {
    repo = "https://github.com/Heroku-userbot/Heroku";
    branch = "master";
    dockerfile = "Dockerfile";
    ports = [ "8003:8080" ];
    command = [
      "python3"
      "-m"
      "hikka"
      "--root"
      "--no-auth"
      "--data-dir=/data/sessions"
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
