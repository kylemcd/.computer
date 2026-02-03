-- Plugin Manager Setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin configurations
require("lazy").setup({
    {
        'stevearc/conform.nvim',
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local conform = require("conform")

            conform.setup({
                formatters_by_ft = {
                    lua = { "stylua" },
                    python = { "black", "isort" },
                    javascript = { "prettier" },
                    javascriptreact = { "prettier" },
                    typescript = { "prettier" },
                    typescriptreact = { "prettier" },
                    json = { "prettier" },
                    yaml = { "prettier" },
                    markdown = { "prettier" },
                },
                format_on_save = {
                    timeout_ms = 500,
                    lsp_fallback = true,
                },
                formatters = {
                    stylua = {
                        command = "stylua",
                    },
                    black = {
                        command = "black",
                        args = { "--line-length", "88", "$FILENAME" },
                    },
                    isort = {
                        command = "isort",
                        args = { "$FILENAME" },
                    },
                    prettier = {
                        command = "prettier",
                        args = {
                            "--stdin-filepath",
                            "$FILENAME",
                        },
                    },
                },
            })

            -- Format command
            vim.api.nvim_create_user_command("Format", function(args)
                local range = nil
                if args.count ~= -1 then
                    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
                    range = {
                        start = { args.line1, 0 },
                        ["end"] = { args.line2, end_line:len() },
                    }
                end
                require("conform").format({ async = true, lsp_fallback = true, range = range })
            end, { range = true })
        end,
    },
    {
        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {
                -- Formatters
                "stylua",
                "black",
                "isort",
                "prettier",
                -- LSP Servers
                "typescript-language-server",
                "lua-language-server",
            }
        }
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local lspconfig = require("lspconfig")
            local cmp_nvim_lsp = require("cmp_nvim_lsp")

            -- Configure diagnostic display
            vim.diagnostic.config({
                virtual_text = false, -- Don't show inline text
                signs = true,
                underline = true, -- Underline errors
                update_in_insert = false,
                severity_sort = true,
                float = {
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })

            -- Set up diagnostic highlights with underlines using nvim API
            -- This runs after colorscheme to avoid being overridden
            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = function()
                    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { 
                        undercurl = true, 
                        sp = "#ff0000" 
                    })
                    vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { 
                        undercurl = true, 
                        sp = "#ffff00" 
                    })
                    vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { 
                        undercurl = true, 
                        sp = "#0000ff" 
                    })
                    vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { 
                        undercurl = true, 
                        sp = "#00ffff" 
                    })
                end
            })
            
            -- Set them immediately as well
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { 
                undercurl = true, 
                sp = "#ff0000" 
            })
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { 
                undercurl = true, 
                sp = "#ffff00" 
            })
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { 
                undercurl = true, 
                sp = "#0000ff" 
            })
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { 
                undercurl = true, 
                sp = "#00ffff" 
            })

            -- Show diagnostic popup on cursor hold
            vim.api.nvim_create_autocmd("CursorHold", {
                callback = function()
                    local opts = {
                        focusable = false,
                        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                        border = "rounded",
                        source = "always",
                        prefix = " ",
                        scope = "cursor",
                    }
                    vim.diagnostic.open_float(nil, opts)
                end
            })

            -- Add completion capabilities
            local capabilities = cmp_nvim_lsp.default_capabilities()

            -- Keymaps for LSP
            local on_attach = function(client, bufnr)
                local opts = { buffer = bufnr, silent = true }

                -- Go to definition
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

                -- Hover documentation
                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

                -- Implementation and references
                vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

                -- Code actions
                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

                -- Rename
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

                -- Diagnostics
                vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
                vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
                vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
            end

            -- TypeScript/JavaScript
            lspconfig.ts_ls.setup({
                capabilities = capabilities,
                on_attach = on_attach,
            })

            -- Lua
            lspconfig.lua_ls.setup({
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                        },
                    },
                },
            })
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            -- Load friendly-snippets
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-k>"] = cmp.mapping.select_prev_item(),
                    ["<C-j>"] = cmp.mapping.select_next_item(),
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },
    {
        "hrsh7th/cmp-nvim-lsp",
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "lua",
                    "javascript",
                    "typescript",
                    "tsx",
                    "json",
                    "yaml",
                    "html",
                    "css",
                    "markdown",
                },
                auto_install = true,
                highlight = {
                    enable = true,
                },
                indent = {
                    enable = true,
                },
            })
        end,
    },
    {
        'projekt0n/github-nvim-theme',
        lazy = false,
        priority = 1000,
        config = function()
            require('github-theme').setup({
                options = {
                    transparent = false,
                    styles = {
                        comments = 'italic',
                        keywords = 'NONE',
                        types = 'NONE',
                    },
                },
                palettes = {
                    github_dark = {
                        bg0 = '#000000',  -- Pure black background
                        bg1 = '#000000',
                        bg2 = '#161b22',
                        bg3 = '#21262d',
                    },
                },
                specs = {
                    github_dark = {
                        syntax = {
                            keyword = '#ff7b72',      -- Red for keywords
                            conditional = '#ff7b72',   -- Red for if/else
                            builtin0 = '#ffa657',     -- Orange for built-ins
                            variable = '#79c0ff',     -- Blue for variables
                            field = '#79c0ff',        -- Blue for properties
                            func = '#d2a8ff',         -- Purple for functions
                            string = '#a5d6ff',       -- Light blue for strings
                            number = '#79c0ff',       -- Blue for numbers
                            const = '#79c0ff',        -- Blue for constants
                            operator = '#ff7b72',     -- Red for operators
                            type = '#ffa657',         -- Orange for types
                            tag = '#7ee787',          -- Green for JSX tags
                            comment = '#8b949e',      -- Gray for comments
                        },
                    },
                },
            })
            vim.cmd('colorscheme github_dark')
            
            -- Override background to pure black
            vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "SignColumn", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "LineNr", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "#000000" })
            
            -- Make statusline black
            vim.api.nvim_set_hl(0, "StatusLine", { bg = "#000000", fg = "#e6edf3" })
            vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#000000", fg = "#8b949e" })
            
            -- Disable bold everywhere (legacy vim highlight groups)
            vim.api.nvim_set_hl(0, "Statement", { fg = "#ff7b72", bold = false })
            vim.api.nvim_set_hl(0, "Keyword", { fg = "#ff7b72", bold = false })
            vim.api.nvim_set_hl(0, "Conditional", { fg = "#ff7b72", bold = false })
            vim.api.nvim_set_hl(0, "Repeat", { fg = "#ff7b72", bold = false })
            vim.api.nvim_set_hl(0, "Type", { fg = "#ffa657", bold = false })
            vim.api.nvim_set_hl(0, "Function", { fg = "#d2a8ff", bold = false })
            vim.api.nvim_set_hl(0, "Operator", { fg = "#ff7b72", bold = false })
            
            -- AMOLED Github Theme - Exact syntax highlighting
            -- Keywords (import, export, from, const, let, var, if, else, return, etc.) - RED/PINK
            vim.api.nvim_set_hl(0, "@keyword", { fg = "#ff7b72" })
            vim.api.nvim_set_hl(0, "@keyword.import", { fg = "#ff7b72" })
            vim.api.nvim_set_hl(0, "@keyword.export", { fg = "#ff7b72" })
            vim.api.nvim_set_hl(0, "@keyword.return", { fg = "#ff7b72" })
            vim.api.nvim_set_hl(0, "@keyword.function", { fg = "#ff7b72" })
            vim.api.nvim_set_hl(0, "@keyword.operator", { fg = "#ff7b72" })
            vim.api.nvim_set_hl(0, "@keyword.repeat", { fg = "#ff7b72" })
            vim.api.nvim_set_hl(0, "@keyword.conditional", { fg = "#ff7b72" })
            
            -- Storage keywords (const, let, var, type, interface) - RED/PINK  
            vim.api.nvim_set_hl(0, "@storageclass", { fg = "#ff7b72" })
            vim.api.nvim_set_hl(0, "@keyword.type", { fg = "#ff7b72" })
            
            -- Types and interfaces - ORANGE/YELLOW
            vim.api.nvim_set_hl(0, "@type", { fg = "#ffa657" })
            vim.api.nvim_set_hl(0, "@type.builtin", { fg = "#ffa657" })
            vim.api.nvim_set_hl(0, "@type.definition", { fg = "#ffa657" })
            
            -- Variables - WHITE (default foreground)
            vim.api.nvim_set_hl(0, "@variable", { fg = "#e6edf3" })
            vim.api.nvim_set_hl(0, "@variable.builtin", { fg = "#79c0ff" })
            
            -- Parameters - ORANGE
            vim.api.nvim_set_hl(0, "@parameter", { fg = "#ffa657" })
            
            -- Properties and fields - LIGHT BLUE
            vim.api.nvim_set_hl(0, "@property", { fg = "#79c0ff" })
            vim.api.nvim_set_hl(0, "@field", { fg = "#79c0ff" })
            vim.api.nvim_set_hl(0, "@variable.member", { fg = "#79c0ff" })
            
            -- Functions and methods - PURPLE
            vim.api.nvim_set_hl(0, "@function", { fg = "#d2a8ff" })
            vim.api.nvim_set_hl(0, "@function.call", { fg = "#d2a8ff" })
            vim.api.nvim_set_hl(0, "@function.builtin", { fg = "#d2a8ff" })
            vim.api.nvim_set_hl(0, "@method", { fg = "#d2a8ff" })
            vim.api.nvim_set_hl(0, "@method.call", { fg = "#d2a8ff" })
            vim.api.nvim_set_hl(0, "@constructor", { fg = "#ffa657" })
            
            -- Strings - LIGHT BLUE
            vim.api.nvim_set_hl(0, "@string", { fg = "#a5d6ff" })
            vim.api.nvim_set_hl(0, "@string.escape", { fg = "#79c0ff" })
            vim.api.nvim_set_hl(0, "@string.special", { fg = "#79c0ff" })
            
            -- Numbers and booleans - LIGHT BLUE
            vim.api.nvim_set_hl(0, "@number", { fg = "#79c0ff" })
            vim.api.nvim_set_hl(0, "@boolean", { fg = "#79c0ff" })
            
            -- Constants - BLUE
            vim.api.nvim_set_hl(0, "@constant", { fg = "#79c0ff" })
            vim.api.nvim_set_hl(0, "@constant.builtin", { fg = "#79c0ff" })
            
            -- Operators - RED/PINK
            vim.api.nvim_set_hl(0, "@operator", { fg = "#ff7b72" })
            
            -- Punctuation - WHITE
            vim.api.nvim_set_hl(0, "@punctuation.delimiter", { fg = "#e6edf3" })
            vim.api.nvim_set_hl(0, "@punctuation.bracket", { fg = "#e6edf3" })
            vim.api.nvim_set_hl(0, "@punctuation.special", { fg = "#e6edf3" })
            
            -- Comments - GRAY
            vim.api.nvim_set_hl(0, "@comment", { fg = "#8b949e", italic = true })
            vim.api.nvim_set_hl(0, "@comment.documentation", { fg = "#8b949e", italic = true })
            
            -- JSX/TSX/HTML tags - GREEN
            vim.api.nvim_set_hl(0, "@tag", { fg = "#7ee787" })
            vim.api.nvim_set_hl(0, "@tag.builtin", { fg = "#7ee787" })
            vim.api.nvim_set_hl(0, "@tag.attribute", { fg = "#79c0ff" })
            vim.api.nvim_set_hl(0, "@tag.delimiter", { fg = "#7ee787" })
            
            -- Special identifiers
            vim.api.nvim_set_hl(0, "@namespace", { fg = "#e6edf3" })
            vim.api.nvim_set_hl(0, "@label", { fg = "#ff7b72" })
        end
    },
    {
        "folke/zen-mode.nvim",
        config = function()
            require("zen-mode").setup({
                window = {
                    width = 1,
                }
            })
        end
    },
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.4",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            require("telescope").setup({
                defaults = {
                    file_ignore_patterns = {
                        "node_modules/",
                        ".git/",
                        "dist/",
                        "build/",
                        ".next/",
                        ".cache/",
                    },
                    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                },
                pickers = {
                    find_files = {
                        find_command = { "rg", "--files", "--iglob", "!.git", "--hidden" },
                    },
                },
            })
            
            -- Set Telescope backgrounds to pure black
            vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "TelescopePromptBorder", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { bg = "#000000" })
            
            -- Fix the gray backdrop behind Telescope
            vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })
            vim.api.nvim_set_hl(0, "TelescopeTitle", { bg = "#000000" })
        end,
    }
})
