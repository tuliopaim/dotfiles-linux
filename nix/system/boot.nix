{
  boot = {
    kernel.sysctl."fs.inotify.max_user_instances" = 524288;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
