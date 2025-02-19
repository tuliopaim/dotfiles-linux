{ pkgs, ...}:
{
    services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
            PasswordAuthentication = true;
            UseDns = true;
            X11Forwarding = false;
            PermitRootLogin = "forced-commands-only";
        };
    };
}
