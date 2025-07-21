#
# This is the neovim config from the provided github link
#
{ pkgs, ... }: {
  # an absolute dumpster fire of a config
  # some plugins might not be in the right groups
  # but they work so who am i to complain
  plugins = with pkgs.vimPlugins; [
    # list of plugins
    # essential plugins
    nvim-tree-lua
    plenary-nvim # dependency for telescope
    nvim-web-devicons
    lualine-nvim
    nvim-autopairs
    which-key-nvim
    impatient-nvim

    # themes
    (catppuccin-nvim.overrideAttrs (oldAttrs: {
      # version = "main";
      # src = pkgs.fetchFromGitHub {
      #   owner = "catppuccin";
      #   repo = "nvim";
      #   rev = "main";
      #   sha256 = "sha256-k/4N8p/L99e2D4Zl/E8r4L6z4wJ2z3a4k5l6n7m8o9i=";
      # };
    }))

    # syntax highlighting/completion
    nvim-treesitter.withAllGrammars
    nvim-cmp
    cmp-buffer
    cmp-path
    cmp-nvim-lsp
    cmp-nvim-lua
    cmp-vsnip
    nvim-lspconfig
    nvim-jdtls

    # utilities
    alpha-nvim
    telescope-nvim
    telescope-fzf-native-nvim
    (gitsigns-nvim.overrideAttrs (oldAttrs: {
      # broken on aarch64-darwin for some reason
      # postPatch = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
      #   rm -r lua/gitsigns/is_aarch64_darwin
      # '';
    }))

    trouble-nvim # pretty list for diagnostics
    comment-nvim
    nvim-colorizer
    indent-blankline-nvim
    (vim-illuminate.overrideAttrs (oldAttrs: {
      # treesitter is a dependency for this but its not specified in the package
      # postPatch = ''
      #   sed -i 's/config = function()/config = function(plugin, values)/' lua/illuminate/init.lua
      #   sed -i '/local default_config = {/a\  providers = { "lsp", "treesitter", "regex" },' lua/illuminate/init.lua
      # '';
    }))

    # filetype specific plugins
    vim-vsnip
    friendly-snippets # snippets for vsnip
    vim-visual-multi

    vim-nix
    (rust-tools-nvim.overrideAttrs (oldAttrs: {
      # version = "master";
      # src = pkgs.fetchFromGitHub {
      #   owner = "simrat39";
      #   repo = "rust-tools.nvim";
      #   rev = "master";
      #   sha256 = "sha256-k/4N8p/L99e2D4Zl/E8r4L6z4wJ2z3a4k5l6n7m8o9i=";
      # };
    }))

    # fun
    neotest
    neotest-vitest
    neotest-jest
    (neotest-go.overrideAttrs (oldAttrs: {
      # version = "master";
      # src = pkgs.fetchFromGitHub {
      #   owner = "nvim-neotest";
      #   repo = "neotest-go";
      #   rev = "master";
      #   sha256 = "sha256-k/4N8p/L99e2D4Zl/E8r4L6z4wJ2z3a4k5l6n7m8o9i=";
      # };
    }))
    (neotest-python.overrideAttrs (oldAttrs: {
      # version = "master";
      # src = pkgs.fetchFromGitHub {
      #   owner = "nvim-neotest";
      #   repo = "neotest-python";
      #   rev = "master";
      #   sha256 = "sha256-k/4N8p/L99e2D4Zl/E8r4L6z4wJ2z3a4k5l6n7m8o9i=";
      # };
    }))
    neotest-plenary
    (neotest-vim-test.overrideAttrs (oldAttrs: {
      # version = "master";
      # src = pkgs.fetchFromGitHub {
      #   owner = "nvim-neotest";
      #   repo = "neotest-vim-test";
      #   rev = "master";
      #   sha256 = "sha256-k/4N8p/L99e2D4Zl/E8r4L6z4wJ2z3a4k5l6n7m8o9i=";
      # };
    }))
    vim-startuptime
  ];

  extraConfig = ''
    " vim options
    set termguicolors
    set mouse=a
    set number
    set relativenumber
    set signcolumn=yes
    set scrolloff=8
    set sidescrolloff=8
    set showmode
    set showcmd
    set wildmenu
    set wildmode=list:longest,full
    set visualbell
    set t_vb=
    set noerrorbells
    set encoding=utf-8
    set laststatus=3
    set expandtab
    set tabstop=2
    set shiftwidth=2
    set softtabstop=2
    set smarttab
    set autoindent
    set smartindent
    set wrap
    set textwidth=80
    set linebreak
    set nolist
    set formatoptions-=l
    set showbreak=…
    set whichwrap+=<,>,h,l,[,]
    set listchars=tab:▸\ ,eol:¬,trail:·,extends:⟩,precedes:⟨,nbsp:␣
    set fillchars=eob:\ ,fold: ,vert:│
    set ignorecase
    set smartcase
    set gdefault
    set incsearch
    set hlsearch
    set nobackup
    set nowritebackup
    set noswapfile
    set completeopt=menu,menuone,noselect
    set updatetime=500
    set timeoutlen=500
    set shortmess+=c
    set inccommand=split
    set splitright
    set splitbelow
    set hidden
    set path+=**
    set wildignore+=*/node_modules/*,*/.git/*,*/.next/*,*/dist/*,*/build/*
    set wildignore+=*.o,*.obj,*.pyc,*.swp,*.DS_Store
    set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.7z
    set wildignore+=*.png,*.jpg,*.jpeg,*.gif,*.svg
    set wildignore+=*.pdf,*.doc,*.docx,*.xls,*.xlsx,*.ppt,*.pptx
    set wildignorecase
    set undofile
    set undodir=~/.config/nvim/undodir

    " leader keys
    let mapleader = " "
    let maplocalleader = " "

    " key mappings
    " switch between buffers
    nnoremap <silent> <S-l> :bnext<CR>
    nnoremap <silent> <S-h> :bprevious<CR>

    " move lines up and down
    nnoremap <A-j> :m .+1<CR>==
    nnoremap <A-k> :m .-2<CR>==
    inoremap <A-j> <Esc>:m .+1<CR>==gi
    inoremap <A-k> <Esc>:m .-2<CR>==gi
    vnoremap <A-j> :m '>+1<CR>gv=gv
    vnoremap <A-k> :m '<-2<CR>gv=gv

    " copy/paste to system clipboard
    vnoremap <leader>y "+y
    vnoremap <leader>d "+d
    nnoremap <leader>p "+p
    nnoremap <leader>P "+P
    vnoremap <leader>p "+p
    vnoremap <leader>P "+P

    " better window movement
    nnoremap <C-h> <C-w>h
    nnoremap <C-j> <C-w>j
    nnoremap <C-k> <C-w>k
    nnoremap <C-l> <C-w>l

    " resize windows
    nnoremap <C-Up> :resize +2<CR>
    nnoremap <C-Down> :resize -2<CR>
  '';

  # lua config
  luaConfig = ''
    -- impatient.nvim
    require("impatient")

    -- disable netrw
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- catppuccin
    vim.g.catppuccin_flavour = "macchiato" -- latte, frappe, macchiato, mocha
    require("catppuccin").setup({
        transparent_background = true,
        integrations = {
            cmp = true,
            gitsigns = true,
            nvimtree = true,
            telescope = true,
            treesitter = true,
            which_key = true,
            illuminate = {
                enabled = true,
            }
        }
    })
    vim.cmd([[colorscheme catppuccin]])

    -- nvim-tree
    require("nvim-tree").setup({
        -- sort_by = "case_sensitive",
        view = {
            adaptive_size = true,
            -- mappings = {
            --   list = {
            --     { key = "u", action = "dir_up" },
            --   },
            -- },
        },
        renderer = {
            group_empty = true,
        },
        filters = {
            dotfiles = true,
        },
    })
    vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>')

    -- lualine
    require('lualine').setup {
        options = {
            icons_enabled = true,
            theme = 'catppuccin',
            component_separators = { left = '', right = ''},
            section_separators = { left = '', right = ''},
            disabled_filetypes = {
                statusline = {},
                winbar = {},
            },
            ignore_focus = {},
            always_divide_middle = true,
            globalstatus = false,
            refresh = {
                statusline = 1000,
                tabline = 1000,
                winbar = 1000,
            }
        },
        sections = {
            lualine_a = {'mode'},
            lualine_b = {'branch', 'diff', 'diagnostics'},
            lualine_c = {'filename'},
            lualine_x = {'encoding', 'fileformat', 'filetype'},
            lualine_y = {'progress'},
            lualine_z = {'location'}
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {'filename'},
            lualine_x = {'location'},
            lualine_y = {},
            lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
    }

    -- which-key
    require("which-key").setup {}

    -- autopairs
    require("nvim-autopairs").setup {}

    -- treesitter
    require'nvim-treesitter.configs'.setup {
        ensure_installed = { "c", "lua", "vim", "help", "nix", "rust", "go", "python", "typescript", "javascript", "html", "css", "json", "yaml", "toml", "bash", "dockerfile", "markdown", "markdown_inline" },
        sync_install = false,
        auto_install = true,
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
    }

    -- lsp
    local lsp = require('lspconfig')
    local cmp = require('cmp')
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    local servers = { "pyright", "rust_analyzer", "gopls", "nil_ls", "tsserver", "emmet_ls", "cssls", "html", "jsonls", "yamlls", "dockerls", "bashls", "vimls", "tailwindcss" }
    for _, l in ipairs(servers) do
        lsp[l].setup {
            capabilities = capabilities,
        }
    end

    -- cmp
    cmp.setup({
        snippet = {
            expand = function(args)
                vim.fn["vsnip#anonymous"](args.body)
            end,
        },
        mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'vsnip' },
        }, {
            { name = 'buffer' },
        })
    })

    -- alpha
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    dashboard.section.header.val = {
        [[                               __                ]],
        [[  ____  _________  ____  _____/ /_  ____ __  __   ]],
        [[ / __ \/ ___/ __ \/ __ \/ ___/ __ \/ __ `| |/_/   ]],
        [[/ /_/ / /  / /_/ / /_/ (__  ) / / / /_/ />  <     ]],
        [[\____/_/   \____/ .___/____/_/ /_/\__,_/_/|_|     ]],
        [[               /_/                               ]],
    }
    dashboard.section.buttons.val = {
        dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
        dashboard.button("r", "  Recent files", ":Telescope oldfiles <CR>"),
        dashboard.button("g", "  Find text", ":Telescope live_grep <CR>"),
        dashboard.button("c", "  Config", ":e ~/.config/nix/dots/nvim/init.lua <CR>"),
        dashboard.button("q", "  Quit", ":qa<CR>"),
    }
    dashboard.config.opts.noautocmd = true
    alpha.setup(dashboard.config)

    -- telescope
    require('telescope').setup{
        defaults = {
            file_ignore_patterns = { "node_modules", ".git", "dist", ".next", "build" },
        },
    }
    require('telescope').load_extension('fzf')
    vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>')
    vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')
    vim.keymap.set('n', '<leader>fb', ':Telescope buffers<CR>')
    vim.keymap.set('n', '<leader>fh', ':Telescope help_tags<CR>')

    -- gitsigns
    require('gitsigns').setup()

    -- trouble
    require("trouble").setup {
        icons = false,
    }

    -- comment
    require('Comment').setup()

    -- colorizer
    require('colorizer').setup()

    -- indent-blankline
    require("indent_blankline").setup {
        -- for example, context is off by default, use this to turn it on
        show_current_context = true,
        show_current_context_start = true,
    }

    -- illuminate
    require("illuminate").configure({
        delay = 200,
        filetypes_denylist = {
            "NvimTree",
            "alpha",
            "packer",
            "Trouble",
            "trouble",
            "help"
        },
    })

    -- rustaceanvim
    vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {
        },
        -- LSP configuration
        server = {
            on_attach = function(client, bufnr)
                -- you can also put keymaps in here
            end,
            default_settings = {
                -- rust-analyzer language server configuration
                ['rust-analyzer'] = {
                },
            },
        },
    }

    -- neotest
    require("neotest").setup({
        adapters = {
            require("neotest-vitest"),
            require("neotest-jest")({
                jest_command = "npm test --",
                jest_config = "jest.config.js",
            }),
            require("neotest-go")({
                args = { "-count=1", "-timeout=60s" }
            }),
            require("neotest-python")({
                dap = { justMyCode = false },
            }),
            require("neotest-plenary"),
            require("neotest-vim-test")({
                ignore_file_types = { "go", "python", "vim", "lua" },
            })
        }
    })
  '';
}