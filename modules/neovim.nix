{ config, pkgs, lib, ... }:

# Neovim configuration module
# Uncomment the import in modules/home.nix to enable
#
# This is a skeleton configuration - customize as needed

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Extra packages for LSP and tools
    extraPackages = with pkgs; [
      # Language servers
      nil                    # Nix
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted  # HTML, CSS, JSON, ESLint
      pyright                # Python
      rust-analyzer          # Rust
      lua-language-server    # Lua
      gopls                  # Go
      terraform-ls           # Terraform
      yaml-language-server   # YAML
      marksman               # Markdown

      # Formatters
      nixpkgs-fmt
      stylua
      black
      isort
      prettierd
      shfmt

      # Linters
      shellcheck

      # Tools
      ripgrep
      fd
      tree-sitter
    ];

    plugins = with pkgs.vimPlugins; [
      # Core plugins
      {
        plugin = lazy-nvim;
        type = "lua";
        config = ''
          -- Lazy.nvim bootstrap is handled by Nix
          -- Plugin configuration goes in extraLuaConfig
        '';
      }

      # Treesitter for syntax highlighting
      nvim-treesitter.withAllGrammars

      # LSP
      nvim-lspconfig
      mason-nvim
      mason-lspconfig-nvim

      # Autocompletion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip
      friendly-snippets

      # UI
      lualine-nvim
      bufferline-nvim
      nvim-tree-lua
      nvim-web-devicons
      indent-blankline-nvim
      which-key-nvim

      # Git
      gitsigns-nvim
      diffview-nvim

      # Fuzzy finder
      telescope-nvim
      plenary-nvim

      # Colorschemes
      catppuccin-nvim
      tokyonight-nvim

      # Utilities
      nvim-autopairs
      comment-nvim
      todo-comments-nvim
    ];

    extraLuaConfig = ''
      -- Leader key
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- Basic options
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.mouse = "a"
      vim.opt.showmode = false
      vim.opt.clipboard = "unnamedplus"
      vim.opt.breakindent = true
      vim.opt.undofile = true
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.signcolumn = "yes"
      vim.opt.updatetime = 250
      vim.opt.timeoutlen = 300
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      vim.opt.list = true
      vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
      vim.opt.inccommand = "split"
      vim.opt.cursorline = true
      vim.opt.scrolloff = 10
      vim.opt.hlsearch = true

      -- Tabs and indentation
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.autoindent = true
      vim.opt.smartindent = true

      -- Colorscheme
      vim.cmd.colorscheme("catppuccin")

      -- Basic keymaps
      vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
      vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
      vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

      -- Window navigation
      vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
      vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
      vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
      vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

      -- Telescope
      local telescope = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "[F]ind [F]iles" })
      vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "[F]ind by [G]rep" })
      vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "[F]ind [B]uffers" })
      vim.keymap.set("n", "<leader>fh", telescope.help_tags, { desc = "[F]ind [H]elp" })

      -- Nvim-tree
      vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file [E]xplorer" })

      -- LSP setup
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Configure LSP servers
      local servers = {
        "nil_ls",          -- Nix
        "ts_ls",           -- TypeScript
        "pyright",         -- Python
        "rust_analyzer",   -- Rust
        "lua_ls",          -- Lua
        "gopls",           -- Go
        "terraformls",     -- Terraform
        "yamlls",          -- YAML
        "marksman",        -- Markdown
      }

      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          capabilities = capabilities,
        })
      end

      -- LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", telescope.lsp_definitions, "[G]oto [D]efinition")
          map("gr", telescope.lsp_references, "[G]oto [R]eferences")
          map("gI", telescope.lsp_implementations, "[G]oto [I]mplementation")
          map("<leader>D", telescope.lsp_type_definitions, "Type [D]efinition")
          map("<leader>ds", telescope.lsp_document_symbols, "[D]ocument [S]ymbols")
          map("<leader>ws", telescope.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
          map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        end,
      })

      -- Autocompletion setup
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = "menu,menuone,noinsert" },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })

      -- Other plugin setup
      require("nvim-autopairs").setup({})
      require("Comment").setup({})
      require("gitsigns").setup({})
      require("todo-comments").setup({})
      require("which-key").setup({})
      require("lualine").setup({})
      require("bufferline").setup({})
      require("nvim-tree").setup({})
      require("ibl").setup({})
    '';
  };
}
