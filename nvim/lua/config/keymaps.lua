-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap = vim.keymap
-- define common options
local opts = { noremap = true, silent = true }
----------------------------------------------------------------
-- There are seven sets of mappings
-- Normal mode: When typing commands.
-- Visual mode: When typing commands while the Visual area is highlighted.
-- Select mode: like Visual mode but typing text replaces the selection.
-- Operator-pending mode: When an operator is pending (after "d", "y", "c", etc.).
-- Insert mode. These are also used in Replace mode.
-- Command-line mode: When entering a ":" or "/" command.
-- Terminal mode: When typing in a :terminal buffer.
----------------------------------------------------------------
keymap.set({ "i", "v" }, "jk", "<Esc>", opts)
-- keymap.set("n", ";;", ":", opts)

-- Delete something without colbbering unnamed register
keymap.set("n", "x", '"_x')
keymap.set("n", "dd", '"_dd')
-- keymap.set("n", "ss", '"_dd')

-- Better navigation
keymap.set({ "n", "o", "v" }, "H", "^")
keymap.set({ "n", "o", "v" }, "L", "$")

keymap.set("n", "<Up>", "7gk", opts)
keymap.set("n", "<Down>", "7gj", opts)
keymap.set("n", "<Left>", "7h", opts)
keymap.set("n", "<Right>", "7l", opts)

-- New tab
-- keymap.set("n", "te", "tabedit")
keymap.set("n", "<tab>", ":tabnext<CR>", opts)
keymap.set("n", "<s-tab>", ":tabprev<CR>", opts)

-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)

-- Move window
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")

-- Fast saving
keymap.set("n", ",w", ":w!<CR>", opts)
keymap.set("n", ",q", ":q<CR>", opts)

-- Increment/Decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Delete a word backwards
-- keymap.set('n', 'dw', 'vb'_d')

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Jumplist
keymap.set("n", "<C-m>", "<C-i>", opts)

-- code runner
keymap.set("n", "<leader>o", ":!g++ -std=c++2a % -o %:r<CR>", opts)
-- keymap.set("n", "<leader>r", ":!./%:r<CR>", opts)
