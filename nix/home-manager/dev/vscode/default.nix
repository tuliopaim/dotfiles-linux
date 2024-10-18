{ pkgs, pkgs-unstable, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode.fhs;
    extensions = [
      pkgs.vscode-extensions.vscodevim.vim
      pkgs.vscode-extensions.ms-dotnettools.csdevkit
      pkgs.vscode-extensions.ms-dotnettools.vscodeintellicode-csharp
      pkgs.vscode-extensions.ms-dotnettools.csharp
      pkgs.vscode-extensions.catppuccin.catppuccin-vsc-icons
      pkgs.vscode-extensions.catppuccin.catppuccin-vsc
      pkgs.vscode-extensions.github.copilot
    ];
    keybindings =
      [
        {
          "key" = "ctrl+n";
          "command" = "workbench.action.terminal.focusNext";
          "when" = "terminalFocus";
        }
        {
          "key" = "ctrl+p";
          "command" = "workbench.action.terminal.focusPrevious";
          "when" = "terminalFocus";
        }
        {
          "key" = "ctrl+shift+j";
          "command" = "workbench.action.togglePanel";
        }
        {
          "key" = "shift+n";
          "command" = "workbench.action.terminal.new";
          "when" = "terminalFocus";
        }
        {
          "key" = "ctrl+h";
          "command" = "workbench.action.navigateLeft";
        }
        {
          "key" = "ctrl+l";
          "command" = "workbench.action.navigateRight";
        }
        {
          "key" = "ctrl+k";
          "command" = "workbench.action.navigateUp";
        }
        {
          "key" = "ctrl+j";
          "command" = "workbench.action.navigateDown";
        }
        {
          "key" = "a";
          "command" = "explorer.newFile";
          "when" = "explorerViewletFocus";
        }
        {
          "key" = "ctrl+shift+n";
          "command" = "explorer.newFolder";
          "when" = "explorerViewletFocus";
        }
        {
          "key" = "ctrl+shift+n";
          "command" = "workbench.action.newWindow";
          "when" = "!explorerViewletFocus";
        }
        {
          "key" = "ctrl+shift+d";
          "command" = "deleteFile";
          "when" = "explorerViewletVisible && filesExplorerFocus && !explorerResourceReadonly && !inputFocus";
        }
        {
          "key" = "ctrl+shift+5";
          "command" = "editor.emmet.action.matchTag";
        }
        {
          "key" = "shift+alt+l";
          "command" = "workbench.action.nextEditor";
        }
        {
          "key" = "shift+alt+h";
          "command" = "workbench.action.previousEditor";
        }
      ];
    userSettings = {
      "security.workspace.trust.untrustedFiles" = "open";
      "redhat.telemetry.enabled" = true;
      "files.exclude" = {
        "**/bin" = true;
        "**/obj" = true;
      };
      "github.copilot.enable" = {
        "*" = true;
        "plaintext" = false;
        "markdown" = true;
        "scminput" = false;
        "yaml" = true;
      };
      "grammarly.files.include" = [
        "**/*.md"
        "**/*.txt"
      ];
      "catppuccin.italicComments" = false;
      "catppuccin.italicKeywords" = false;
      "zenMode.hideLineNumbers" = false;
      "editor.stickyScroll.enabled" = true;
      "vsicons.dontShowNewVersionMessage" = true;
      "workbench.iconTheme" = "vscode-icons";
      "editor.suggest.insertMode" = "replace";
      "workbench.startupEditor" = "newUntitledFile";
      "git.autofetch" = true;
      "diffEditor.wordWrap" = "off";
      "terminal.integrated.fontFamily" = "'Fira Code Nerd Font'; Consolas, 'Courier New', monospace";
      "explorer.confirmDragAndDrop" = false;
      "editor.fontFamily" = "'FiraCode Nerd Font'; Consolas, 'Courier New', monospace";
      "editor.inlineSuggest.enabled" = true;
      "editor.cursorBlinking" = "solid";
      "editor.minimap.enabled" = false;
      "editor.formatOnSave" = true;
      "editor.lineNumbers" = "relative";
      "editor.acceptSuggestionOnCommitCharacter" = false;
      "dotnet.server.path" = "/home/tuliopaim/.nix-profile/bin/Microsoft.CodeAnalysis.LanguageServer";
      "vim.cursorStypePerMode.normal" = "block";
      "vim.smartRelativeLine" = true;
      "vim.searchHighlightColor" = "rgba(150; 255, 255, 0.3)";
      "vim.incsearch" = true;
      "vim.hlsearch" = true;
      "vim.useSystemClipboard" = false;
      "vim.leader" = "<space>";
      "vim.handleKeys" = {
        "<C-c>" = false;
        "<C-v>" = false;
        "<C-z>" = false;
        "<C-f>" = false;
      };
      "vim.visualModeKeyBindingsNonRecursive" = [
        {
          "before" = [
            "<leader>"
            "y"
          ];
          "after" = [
            "\""
            "+"
            "y"
          ];
        }
        {
          "before" = [
            "<leader>"
            "p"
          ];
          "after" = [
            "\""
            "0"
            "p"
          ];
        }
        {
          "before" = [
            "<"
          ];
          "commands" = [
            "editor.action.outdentLines"
          ];
        }
        {
          "before" = [
            ">"
          ];
          "commands" = [
            "editor.action.indentLines"
          ];
        }
        {
          "before" = [
            "J"
          ];
          "commands" = [
            "editor.action.moveLinesDownAction"
          ];
        }
        {
          "before" = [
            "K"
          ];
          "commands" = [
            "editor.action.moveLinesUpAction"
          ];
        }
        {
          "before" = [
            "leader"
            "c"
          ];
          "commands" = [
            "editor.action.commentLine"
          ];
        }
      ];
      "vim.normalModeKeyBindingsNonRecursive" = [
        {
          "before" = [
            "<leader>"
            "h"
            "a"
          ];
          "commands" = [
            "workbench.action.closePanel"
            "workbench.action.closeSidebar"
          ];
        }
        {
          "before" = [
            "<leader>"
            "v"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.splitEditor";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "b"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.splitEditorDown";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "w"
            "l"
          ];
          "commands" = [
            "workbench.action.moveEditorToRightGroup"
          ];
        }
        {
          "before" = [
            "<leader>"
            "w"
            "h"
          ];
          "commands" = [
            "workbench.action.moveEditorToLeftGroup"
          ];
        }
        {
          "before" = [
            "<leader>"
            "w"
            "k"
          ];
          "commands" = [
            "workbench.action.moveEditorToAboveGroup"
          ];
        }
        {
          "before" = [
            "<leader>"
            "w"
            "j"
          ];
          "commands" = [
            "workbench.action.moveEditorToBelowGroup"
          ];
        }
        {
          "before" = [
            "<leader>"
            "s"
            "l"
          ];
          "commands" = [
            "workbench.action.increaseViewWidth"
          ];
        }
        {
          "before" = [
            "<leader>"
            "s"
            "h"
          ];
          "commands" = [
            "workbench.action.decreaseViewWidth"
          ];
        }
        {
          "before" = [
            "<leader>"
            "s"
            "k"
          ];
          "commands" = [
            "workbench.action.increaseViewHeight"
          ];
        }
        {
          "before" = [
            "<leader>"
            "s"
            "j"
          ];
          "commands" = [
            "workbench.action.decreaseViewHeight"
          ];
        }
        {
          "before" = [
            "<leader>"
            "s"
            "="
          ];
          "commands" = [
            "workbench.action.evenEditorWidths"
          ];
        }
        {
          "before" = [
            "g"
            "k"
          ];
          "after" = [
            "g"
            "t"
          ];
        }
        {
          "before" = [
            "g"
            "j"
          ];
          "after" = [
            "g"
            "T"
          ];
        }
        {
          "before" = [
            "<leader>"
            "t"
            "p"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.pinEditor";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "t"
            "u"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.unpinEditor";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "x"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.closeActiveEditor";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "a"
            "x"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.closeAllEditor";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "t"
            "t"
          ];
          "commands" = [
            "workbench.view.testing.focus"
          ];
        }
        {
          "before" = [
            "<leader>"
            "t"
            "r"
          ];
          "commands" = [
            "workbench.action.terminal.focus"
          ];
        }
        {
          "before" = [
            "<leader>"
            "t"
            "h"
          ];
          "commands" = [
            "workbench.action.togglePanel"
          ];
        }
        {
          "before" = [
            "<leader>"
            "f"
            "f"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.quickOpen";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "f"
            "a"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.showCommands";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "f"
            "d"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "action.find";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "f"
            "s"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.action.findInFiles";
            }
          ];
        }
        {
          "before" = [
            "g"
            "d"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "editor.action.revealDefinition";
            }
          ];
        }
        {
          "before" = [
            "g"
            "i"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "editor.action.goToImplementation";
            }
          ];
        }
        {
          "before" = [
            "g"
            "r"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "editor.action.goToReferences";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "g"
            "c"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "workbench.view.scm";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "g"
            "b"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "gitlens.views.branches.focus";
            }
          ];
        }
        {
          "before" = [
            "<leader>"
            "g"
            "w"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "gitlens.views.worktrees.focus";
            }
          ];
        }
        {
          "before" = [
            "K"
          ];
          "after" = [ ];
          "commands" = [
            {
              "command" = "editor.action.showHover";
            }
          ];
        }
        {
          "before" = [
            "<C-d>"
          ];
          "after" = [
            "<C-d>"
            "z"
            "z"
          ];
        }
        {
          "before" = [
            "<C-u>"
          ];
          "after" = [
            "<C-u>"
            "z"
            "z"
          ];
        }
        {
          "before" = [
            "<space>"
            "."
          ];
          "commands" = [
            "workbench.view.explorer"
          ];
        }
        {
          "before" = [
            "<space>"
            "e"
          ];
          "commands" = [
            "workbench.action.toggleSidebarVisibility"
          ];
        }
        {
          "before" = [
            "<leader>"
            "g"
            "m"
          ];
          "commands" = [
            "workbench.view.scm"
          ];
        }
        {
          "before" = [
            "<leader>"
            "g"
            "p"
            "l"
          ];
          "commands" = [
            "git.pull"
          ];
        }
        {
          "before" = [
            "<leader>"
            "g"
            "p"
            "s"
          ];
          "commands" = [
            "git.push"
          ];
        }
        {
          "before" = [
            "<leader>"
            "r"
            "s"
          ];
          "commands" = [
            "csdevkit.rebuildSolution"
          ];
        }
        {
          "before" = [
            "<leader>"
            "r"
            "c"
          ];
          "commands" = [
            "csdevkit.cleanSolution"
          ];
        }
      ];
      "workbench.colorTheme" = "Catppuccin Mocha";
      "window.menuBarVisibility" = "toggle";
      "vim.cursorStylePerMode.normal" = "block";
      "diffEditor.ignoreTrimWhitespace" = false;
      "window.zoomLevel" = 1;
    };
  };
}
