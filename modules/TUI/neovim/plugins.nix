{config, ...}: {
  programs.nixvim.plugins = {
    neo-tree = {
      enable = true;
      settings = {
        window.width = 30;
        filesystem.follow_current_file.enabled = true;
      };
    };

    # fuzzy finder
    telescope = {
      enable = true;
      extensions = {
        fzf-native.enable = true;
        ui-select.enable = true;
      };
    };

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

    # statusline
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

    lazygit.enable = true;

    # keybind hints
    which-key = {
      enable = true;
      settings.delay = 300;
    };

    nvim-autopairs = {
      enable = true;
      settings.check_ts = true;
    };

    comment.enable = true;

    indent-blankline = {
      enable = true;
      settings = {
        indent.char = "│";
        scope.enabled = true;
      };
    };

    todo-comments = {
      enable = true;
      settings.signs = true;
    };

    # LSP progress notifications
    fidget = {
      enable = true;
      settings.progress.display.done_icon = "✓";
    };

    render-markdown = {
      enable = true;
      settings = {
        file_types = ["markdown"];
        html.enabled = false;
        latex.enabled = false;
      };
    };

    rainbow-delimiters.enable = true;

    # nicer UI for inputs/selects
    dressing.enable = true;

    # motion hints
    precognition.enable = false;

    illuminate.enable = true;

    # diagnostics list
    trouble = {
      enable = true;
      settings.modes.diagnostics.auto_open = false;
    };

    # jump anywhere on screen with search labels
    flash.enable = true;

    diffview.enable = true;

    # notification backend for noice
    notify = {
      enable = true;
      settings.timeout = 3000;
    };

    # floating cmdline, messages, popups
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

    # auto-save/restore session per directory
    persistence.enable = true;

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

    # surround: add/delete/replace surrounding chars
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

    # af/if (function), ac/ic (class), etc.
    treesitter-textobjects.enable = true;

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
