{ username, ...}:
{
  users.users.${username} = {
    isNormalUser = true;
    description = "tuliopaim";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };
}
