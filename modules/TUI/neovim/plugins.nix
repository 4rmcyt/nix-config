{config, pkgs, ...}: {
  programs.nixvim.plugins = {
    # File tree (like VSCode Explorer)
    neo-tree = {
      enable = true;
      settings = {
        window.width = 30;
        filesystem.follow_current_file.enabled = true;
      };
    };

    # Fuzzy finder (like VSCode Cmd+P / Ctrl+Shift+F)
    telescope = {
      enable = true;
      extensions = {
        fzf-native.enable = true;
        ui-select.enable = true;
      };
    };

    # Syntax highlighting
    treesitter = {
      enable = true;
      highlight.enable = true;
      indent.enable = true;
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        nix
        python
        lua
        bash
        json
        yaml
        toml
        markdown
        markdown_inline
        regex
        comment
        diff
        vim
        vimdoc
      ];
    };

    # Statusline (like VSCode status bar)
    lualine = {
      enable = true;
      settings.options = {
        theme = "auto";
        globalstatus = true;
        component_separators = {
          left = "";
          right = "";
        };
        section_separators = {
          left = "";
          right = "";
        };
      };
    };

    # Buffer tabs (like VSCode tabs)
    bufferline = {
      enable = true;
      settings.options = {
        diagnostics = "nvim_lsp";
        offsets = [
          {
            filetype = "neo-tree";
            text = "Explorer";
            highlight = "Directory";
            text_align = "center";
          }
        ];
      };
    };

    # Git decorations (like VSCode GitLens)
    gitsigns = {
      enable = true;
      settings = {
        signs = {
          add.text = "▎";
          change.text = "▎";
          delete.text = "";
          topdelete.text = "";
          changedelete.text = "▎";
          untracked.text = "▎";
        };
        current_line_blame = true;
        current_line_blame_opts.delay = 500;
      };
    };

    # Git TUI
    lazygit.enable = true;

    # Keybind hints (no VSCode equivalent, but extremely useful)
    which-key = {
      enable = true;
      settings.delay = 300;
    };

    # Auto pairs
    nvim-autopairs = {
      enable = true;
      settings.check_ts = true;
    };

    # Comments (like VSCode Ctrl+/)
    comment.enable = true;

    # Indent guides (like VSCode indent guides)
    indent-blankline = {
      enable = true;
      settings = {
        indent.char = "│";
        scope.enabled = true;
      };
    };

    # Todo highlights (like VSCode Todo Tree)
    todo-comments = {
      enable = true;
      settings.signs = true;
    };

    # LSP progress notifications
    fidget = {
      enable = true;
      settings.progress.display.done_icon = "✓";
    };

    # Markdown rendering
    render-markdown = {
      enable = true;
      settings = {
        file_types = ["markdown"];
        html.enabled = false;
        latex.enabled = false;
      };
    };

    # Bracket pair colorization (like VSCode bracketPairColorization)
    rainbow-delimiters.enable = true;

    # Nicer UI for inputs/selects
    dressing.enable = true;

    # Smooth scrolling
    precognition.enable = false;

    # Highlight word under cursor
    illuminate.enable = true;

    # Better diagnostics list
    trouble = {
      enable = true;
      settings.modes.diagnostics.auto_open = false;
    };

    # Jump anywhere on screen with search labels
    flash.enable = true;

    # Side-by-side diff viewer + file history
    diffview.enable = true;

    # Notification backend for noice
    notify = {
      enable = true;
      settings.timeout = 3000;
    };

    # Floating cmdline, messages, popups
    noice = {
      enable = true;
      settings = {
        lsp.override = {
          "vim.lsp.util.convert_input_to_markdown_lines" = true;
          "vim.lsp.util.stylize_markdown" = true;
          "cmp.entry.get_documentation" = true;
        };
        presets = {
          bottom_search = true;
          command_palette = true;
          long_message_to_split = true;
          inc_rename = false;
        };
      };
    };

    # Auto-save/restore session per directory
    persistence.enable = true;

    # Claude Code terminal integration
    claude-code = {
      enable = true;
      settings = {
        window = {
          position = "rightbelow vsplit";
          split_ratio = 0.35;
        };
        keymaps.toggle.modes.normal = "<leader>ac";
      };
    };

    # Surround — add/delete/replace surrounding chars (",',(,[,{,<,...)
    mini = {
      enable = true;
      mockDevIcons = true;
      modules = {
        icons = {};
        surround = {
          mappings = {
            add = "gsa";
            delete = "gsd";
            replace = "gsr";
            find = "gsf";
            find_left = "gsF";
            highlight = "gsh";
            update_n_lines = "gsn";
          };
        };
      };
    };

    # Treesitter textobjects — af/if (function), ac/ic (class), etc.
    treesitter-textobjects.enable = true;

    # Undo history visualizer
    undotree = {
      enable = true;
      settings = {
        FocusOnToggle = true;
        HelpLine = false;
        ShortIndicators = true;
      };
    };
  };
}
