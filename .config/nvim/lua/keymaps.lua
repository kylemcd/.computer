-- Basic nvim settings
vim.g.mapleader = " "

-- UI
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"

-- Editing
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false

-- Search
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Temporarily disable treesitter for vim files to fix highlighting error
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vim",
  callback = function()
    vim.cmd("TSBufDisable highlight")
  end,
})

-- Files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.updatetime = 50

-- Movement
vim.opt.scrolloff = 8

-- Netrw (built-in file browser)
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- Key mappings
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end)

-- Movement
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Editing
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z")

-- Copy/Paste/Delete
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Search and replace
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Window management
vim.keymap.set("n", "<leader>vs", "<C-w>v<C-w>l")
vim.keymap.set("n", "<leader>sh", "<C-w>h")
vim.keymap.set("n", "<leader>sj", "<C-w>j")
vim.keymap.set("n", "<leader>sk", "<C-w>k")
vim.keymap.set("n", "<leader>sl", "<C-w>l")

-- Disable Q
vim.keymap.set("n", "Q", "<nop>")

-- Zen mode
vim.keymap.set("n", "<leader>zz", function()
  require("zen-mode").toggle()
end)

-- Telescope - lazy load when needed
vim.keymap.set('n', '<leader>pf', function() require('telescope.builtin').find_files() end, {})
vim.keymap.set('n', '<C-p>', function() require('telescope.builtin').git_files() end, {})
vim.keymap.set('n', '<leader>ps', function()
    require('telescope.builtin').grep_string({ search = vim.fn.input("Grep > ") })
end)
vim.keymap.set('n', '<leader>pg', function() require('telescope.builtin').live_grep() end, {})
vim.keymap.set('n', '<leader>pb', function() require('telescope.builtin').buffers() end, {})
vim.keymap.set('n', '<leader>ph', function() require('telescope.builtin').help_tags() end, {})

-- Install missing tools
vim.keymap.set("n", "<leader>mi", function()
  vim.cmd("Mason")
end, { desc = "Open Mason to install tools" })

-- Auto commands
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", {}),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 40,
    })
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = vim.api.nvim_create_augroup("RemoveTrailingSpaces", {}),
  pattern = "*",
  command = [[%s/\s\+$//e]],
})