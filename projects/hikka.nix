{ ... }:

{
  docker-deploy."hikka" = {
    repo = "https://github.com/hikariatama/hikka";
    branch = "master";
    dockerfile = "Dockerfile";
    ports = [ "8003:8080" ];
    volumes = [
      "/home/deploy/hikka-data:/data"
    ];
  };
}
