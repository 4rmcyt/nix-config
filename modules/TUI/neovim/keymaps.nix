{...}: {
  programs.nixvim.keymaps = [
    # ── Explorer ──────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<CR>";
      options.desc = "Toggle Explorer";
    }
    {
      mode = "n";
      key = "<leader>o";
      action = "<cmd>Neotree focus<CR>";
      options.desc = "Focus Explorer";
    }

    # ── Telescope ─────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<CR>";
      options.desc = "Find Files";
    }
    {
      mode = "n";
      key = "<leader>fg";
      action = "<cmd>Telescope live_grep<CR>";
      options.desc = "Live Grep";
    }
    {
      mode = "n";
      key = "<leader>fb";
      action = "<cmd>Telescope buffers<CR>";
      options.desc = "Buffers";
    }
    {
      mode = "n";
      key = "<leader>fh";
      action = "<cmd>Telescope help_tags<CR>";
      options.desc = "Help Tags";
    }
    {
      mode = "n";
      key = "<leader>fr";
      action = "<cmd>Telescope oldfiles<CR>";
      options.desc = "Recent Files";
    }
    {
      mode = "n";
      key = "<leader>fd";
      action = "<cmd>Telescope diagnostics<CR>";
      options.desc = "Diagnostics";
    }
    {
      mode = "n";
      key = "<leader>fs";
      action = "<cmd>Telescope lsp_document_symbols<CR>";
      options.desc = "Document Symbols";
    }

    # ── Git (LazyGit + Gitsigns) ──────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>gg";
      action = "<cmd>LazyGit<CR>";
      options.desc = "LazyGit";
    }
    {
      mode = "n";
      key = "<leader>gp";
      action = "<cmd>Gitsigns preview_hunk<CR>";
      options.desc = "Preview Hunk";
    }
    {
      mode = "n";
      key = "<leader>gb";
      action = "<cmd>Gitsigns blame_line<CR>";
      options.desc = "Blame Line";
    }
    {
      mode = "n";
      key = "]h";
      action = "<cmd>Gitsigns next_hunk<CR>";
      options.desc = "Next Hunk";
    }
    {
      mode = "n";
      key = "[h";
      action = "<cmd>Gitsigns prev_hunk<CR>";
      options.desc = "Prev Hunk";
    }

    # ── LSP ───────────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "gd";
      action = "<cmd>Telescope lsp_definitions<CR>";
      options.desc = "Go to Definition";
    }
    {
      mode = "n";
      key = "gr";
      action = "<cmd>Telescope lsp_references<CR>";
      options.desc = "References";
    }
    {
      mode = "n";
      key = "gi";
      action = "<cmd>Telescope lsp_implementations<CR>";
      options.desc = "Implementations";
    }
    {
      mode = "n";
      key = "K";
      action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      options.desc = "Hover Docs";
    }
    {
      mode = "n";
      key = "<leader>ca";
      action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      options.desc = "Code Action";
    }
    {
      mode = "n";
      key = "<leader>rn";
      action = "<cmd>lua vim.lsp.buf.rename()<CR>";
      options.desc = "Rename Symbol";
    }
    {
      mode = "n";
      key = "<leader>f";
      action = "<cmd>lua require('conform').format({ async = true })<CR>";
      options.desc = "Format Buffer";
    }

    # ── Diagnostics ───────────────────────────────────────────────────────
    {
      mode = "n";
      key = "]d";
      action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
      options.desc = "Next Diagnostic";
    }
    {
      mode = "n";
      key = "[d";
      action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
      options.desc = "Prev Diagnostic";
    }
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<CR>";
      options.desc = "Diagnostics (Trouble)";
    }
    {
      mode = "n";
      key = "<leader>xb";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
      options.desc = "Buffer Diagnostics";
    }

    # ── Buffers ───────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<S-h>";
      action = "<cmd>BufferLineCyclePrev<CR>";
      options.desc = "Prev Buffer";
    }
    {
      mode = "n";
      key = "<S-l>";
      action = "<cmd>BufferLineCycleNext<CR>";
      options.desc = "Next Buffer";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bd<CR>";
      options.desc = "Close Buffer";
    }

    # ── Window splits ─────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>wv";
      action = "<cmd>vsplit<CR>";
      options.desc = "Split Vertical";
    }
    {
      mode = "n";
      key = "<leader>wh";
      action = "<cmd>split<CR>";
      options.desc = "Split Horizontal";
    }
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w>h";
      options.desc = "Move to Left Window";
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      options.desc = "Move to Right Window";
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      options.desc = "Move to Lower Window";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      options.desc = "Move to Upper Window";
    }

    # ── Misc ──────────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>nohlsearch<CR>";
      options.desc = "Clear Search Highlight";
    }
    {
      mode = "v";
      key = "<";
      action = "<gv";
      options.desc = "Indent Left (keep selection)";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
      options.desc = "Indent Right (keep selection)";
    }
    {
      mode = ["n" "v"];
      key = "<leader>tc";
      action = "<cmd>TodoTelescope<CR>";
      options.desc = "Search TODOs";
    }

    # ── Flash ─────────────────────────────────────────────────────────────
    {
      mode = ["n" "x" "o"];
      key = "s";
      action = "<cmd>lua require('flash').jump()<CR>";
      options.desc = "Flash Jump";
    }
    {
      mode = ["n" "x" "o"];
      key = "S";
      action = "<cmd>lua require('flash').treesitter()<CR>";
      options.desc = "Flash Treesitter";
    }

    # ── Diffview ──────────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>gd";
      action = "<cmd>DiffviewOpen<CR>";
      options.desc = "Diff View";
    }
    {
      mode = "n";
      key = "<leader>gh";
      action = "<cmd>DiffviewFileHistory %<CR>";
      options.desc = "File History";
    }
    {
      mode = "n";
      key = "<leader>gq";
      action = "<cmd>DiffviewClose<CR>";
      options.desc = "Close Diff View";
    }

    # ── Persistence ───────────────────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>qs";
      action = "<cmd>lua require('persistence').load()<CR>";
      options.desc = "Restore Session";
    }
    {
      mode = "n";
      key = "<leader>ql";
      action = "<cmd>lua require('persistence').load({ last = true })<CR>";
      options.desc = "Restore Last Session";
    }
    {
      mode = "n";
      key = "<leader>qd";
      action = "<cmd>lua require('persistence').stop()<CR>";
      options.desc = "Don't Save Session";
    }
  ];
}
