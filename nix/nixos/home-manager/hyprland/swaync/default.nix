{ ... }:
{
  services.swaync = {
    enable = true;
    style = ./mocha.css;
    settings = ./config.json;
  };
}
