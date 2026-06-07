{
  virtualisation.oci-containers = {
    backend = "docker";

    containers.dozzle = {
      image = "amir20/dozzle:latest";

      ports = [
        "8080:19999"
      ];

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "dozzle-data:/data"
      ];

      extraOptions = [
        "--pull=always"
      ];
    };
  };
}
