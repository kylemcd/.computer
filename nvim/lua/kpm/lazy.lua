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

vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct

local plugins = {
	"nvim-lua/plenary.nvim",
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.4",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	-- Visuals
	"datsfilipe/vesper.nvim",
	"nvim-tree/nvim-web-devicons",
	"nvim-lualine/lualine.nvim",
	-- LSP
	{
		"folke/trouble.nvim",
		config = function()
			require("trouble").setup({
				icons = false,
			})
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},
	{
		"j-hui/fidget.nvim",
		tag = "legacy",
	},
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
	},
	"neovim/nvim-lspconfig", -- easily configure language servers
	"hrsh7th/cmp-nvim-lsp", -- for autocompletion
	{
		"nvimdev/lspsaga.nvim",
		config = function()
			require("lspsaga").setup({})
		end,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"nvim-treesitter/nvim-treesitter",
		},
	},
	-- enhanced lsp uis
	"onsails/lspkind.nvim", -- VS code like pictograms
	"nvimtools/none-ls.nvim",
	-- Autocompletion
	"hrsh7th/nvim-cmp", -- completion plugin
	"hrsh7th/cmp-buffer", -- source for text in buffer
	"hrsh7th/cmp-path", -- source for file system paths
	"windwp/nvim-autopairs", -- auto close brackets
	-- Navigation
	"theprimeagen/harpoon",
	"theprimeagen/refactoring.nvim",
	"mbbill/undotree",
	-- Utils
	"numToStr/Comment.nvim", -- Comment blocks
	"folke/zen-mode.nvim", -- Focus one pane
	"github/copilot.vim", -- AI Autocomplete
	-- remove typescript.nvim unless wired up later
	"tpope/vim-surround", -- Wrap Things
	-- Git
	"tpope/vim-fugitive",
	{
		"petertriho/cmp-git",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
	"lewis6991/gitsigns.nvim",
	-- Snippets
	"L3MON4D3/LuaSnip", -- snippet engine
	"saadparwaiz1/cmp_luasnip", -- for autocompletion
	"rafamadriz/friendly-snippets", -- useful snippets
    -- Search: use Telescope live_grep instead of legacy rg plugins
}

require("lazy").setup(plugins)
