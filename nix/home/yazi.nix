{ ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      manager = {
        show_hidden = true;
        sort_by = "modified";
        sort_dir_first = true;
        sort_reverse = true;
      };
    };
  };
}
