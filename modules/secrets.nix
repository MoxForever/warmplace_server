{ pkgs, ... }:

{
  sops.defaultSopsFile = ../secrets.yaml;
}
