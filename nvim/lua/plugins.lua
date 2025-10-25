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
                            "--single-quote",
                            "--trailing-comma",
                            "es5",
                            "--print-width",
                            "80",
                            "--tab-width",
                            "2",
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
            }
        }
    },
    { 'datsfilipe/vesper.nvim',
        config = function()
            vim.cmd.colorscheme("vesper")
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
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")

            telescope.setup({
                defaults = {
                    file_ignore_patterns = {
                        "node_modules",
                        ".git",
                        "dist",
                        "build",
                        ".next",
                        ".cache",
                    },
                },
            })
        end,
    }
})
