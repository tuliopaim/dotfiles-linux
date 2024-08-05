{
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "Hyprland";
        user = "tuliopaim";
      };
      default_session = {
        command = "initial_session";
      };
    };
  };
  environment.etc."greetd/environments".text = ''
    Hey hey
  '';
}
