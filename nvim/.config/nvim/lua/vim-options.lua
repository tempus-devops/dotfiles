vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.g.mapleader = " "
vim.opt.relativenumber = false
vim.opt.number = true


--Navigte vim panes better
vim.keymap.set('n', '<c-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>')
vim.keymap.set('n', '<c-h>', ':wincmd h<CR>')
vim.keymap.set('n', '<c-l>', ':wincmd l<CR>')

--Reset hightlighting after the search
vim.keymap.set('n', '<leader>n', ':nohlsearch<CR>', { silent = true })
vim.keymap.set("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Find symbols in file" })
