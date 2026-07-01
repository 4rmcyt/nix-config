{pkgs, ...}: {
  programs.nixvim = {
    plugins.lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        nil_ls = {
          enable = true;
          settings.formatting.command = ["${pkgs.alejandra}/bin/alejandra"];
        };
        pyright.enable = true;
        lua_ls.enable = true;
        bashls.enable = true;
      };
    };

    # Formatter (like VSCode formatOnSave)
    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          nix = ["alejandra"];
          python = ["ruff_format"];
          sh = ["shfmt"];
          bash = ["shfmt"];
          lua = ["stylua"];
        };
        format_on_save = {
          lsp_fallback = true;
          timeout_ms = 500;
        };
      };
    };

    # Completion
    plugins.cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        sources = [
          {name = "nvim_lsp";}
          {name = "luasnip";}
          {name = "buffer";}
          {name = "path";}
        ];
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          "<C-d>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
        };
      };
    };

    plugins.luasnip = {
      enable = true;
      settings.history = true;
    };
    plugins.friendly-snippets.enable = true;

    # LSP UI improvements
    plugins.lspkind = {
      enable = true;
      cmp.enable = true;
    };
    plugins.fidget.enable = true;

    # claude-code LSP — same pattern as helix in modules/TUI/common/default.nix
    extraConfigLua = ''
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          vim.lsp.start({
            name = "claude-code",
            cmd = { "claude-code", "lsp" },
            root_dir = vim.fs.root(0, { ".git" }),
          })
        end,
      })
    '';

    # Formatters/linters as extra packages
    extraPackages = with pkgs; [
      alejandra
      ruff
      shfmt
      stylua
      bash-language-server
    ];
  };
}
