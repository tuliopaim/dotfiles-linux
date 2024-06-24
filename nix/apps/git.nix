{ pkgs, config, ... }:

{
  programs.git = {
    enable = true;
    aliases = {
      "clone-wt" = "!sh clone-wt";
    };
    extraConfig = {
      user = {
        name = "tuliopaim";
        email = "tutpaim@gmail.com";
      };
      core = {
        editor = "nvim";
      };
      safe = {
        directory = "*";
      };
    };
    includes = [
      {
        condition = "gitdir:~/dev/personal/";
        contents = {
          user = {
            name = "tuliopaim";
            email = "tutpaim@gmail.com";
          };
        };
      }
      {

        condition = "gitdir:~/dev/tb/";
        contents = {
          user = {
            name = "tuliopaim";
            email = "tulio.p@thinkbridge.com";
          };
        };
      }
    ];
  };
}
