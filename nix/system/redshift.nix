{
  services.redshift = {
    enable = true;
    brightness = {
      # Note the string values below.
      day = "1";
      night = "1";
    };
    temperature = {
      day = 5700;
      night = 3500;
    };
  };

  location.latitude = -16.6799;
  location.longitude = -49.255;
}
