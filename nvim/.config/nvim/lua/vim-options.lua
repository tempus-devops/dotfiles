vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.g.mapleader = " "
vim.opt.relativenumber = false
vim.opt.number = true

--Navigte vim panes better
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

--Reset hightlighting after the search
vim.keymap.set("n", "<leader>n", ":nohlsearch<CR>", { silent = true })
vim.keymap.set("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Find symbols in file" })

-- French TTS (macOS `say`). Voices: Thomas, Jacques, "Flo (French (France))", "Sandy (French (France))", "Rocko (French (France))"
local fr_voice = "Thomas"
local fr_ns = vim.api.nvim_create_namespace("french_tts")

vim.api.nvim_set_hl(0, "FrenchTTS", { bg = "white", fg = "black", bold = true })

local function fr_progress_file(buf)
    return vim.api.nvim_buf_get_name(buf) .. ".tts-progress"
end

local function fr_save(buf)
    local marks = vim.api.nvim_buf_get_extmarks(buf, fr_ns, 0, -1, {})
    local seen = {}
    local rows = {}
    for _, mark in ipairs(marks) do
        local row = mark[2]
        if not seen[row] then
            seen[row] = true
            table.insert(rows, row)
        end
    end
    local file = io.open(fr_progress_file(buf), "w")
    if file then
        file:write(table.concat(rows, "\n"))
        file:close()
    end
end

local function fr_load(buf)
    local file = io.open(fr_progress_file(buf), "r")
    if not file then return end
    for line in file:lines() do
        local row = tonumber(line)
        if row then
            vim.api.nvim_buf_add_highlight(buf, fr_ns, "FrenchTTS", row, 0, -1)
        end
    end
    file:close()
end

local function fr_highlight(buf, row)
    vim.api.nvim_buf_add_highlight(buf, fr_ns, "FrenchTTS", row, 0, -1)
    fr_save(buf)
end

local function fr_clear_range(buf, start_row, end_row)
    vim.api.nvim_buf_clear_namespace(buf, fr_ns, start_row, end_row + 1)
    fr_save(buf)
end

vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*.md",
    callback = function()
        fr_load(vim.api.nvim_get_current_buf())
    end,
})

-- Speak French sentence on current line (<leader>fr)
vim.keymap.set("n", "<leader>fr", function()
    local line = vim.api.nvim_get_current_line()
    local parts = vim.fn.split(line, "|", 1)
    if #parts >= 3 then
        local french = vim.fn.trim(parts[3])
        if french ~= "" then
            local buf = vim.api.nvim_get_current_buf()
            local row = vim.api.nvim_win_get_cursor(0)[1] - 1
            fr_highlight(buf, row)
            vim.fn.jobstart({ "say", "-v", fr_voice, "[[slnc 300]] " .. french .. " [[slnc 500]]" })
        end
    end
end, { desc = "Speak French sentence on current line" })

-- Speak French sentence on current line 5 times (<leader>f5)
vim.keymap.set("n", "<leader>f5", function()
    local line = vim.api.nvim_get_current_line()
    local parts = vim.fn.split(line, "|", 1)
    if #parts >= 3 then
        local french = vim.fn.trim(parts[3])
        if french ~= "" then
            local buf = vim.api.nvim_get_current_buf()
            local row = vim.api.nvim_win_get_cursor(0)[1] - 1
            fr_highlight(buf, row)
            local rep = "[[slnc 300]] " .. french .. " [[slnc 800]] "
            vim.fn.jobstart({ "say", "-v", fr_voice, rep:rep(5) .. "[[slnc 500]]" })
        end
    end
end, { desc = "Speak French sentence on current line 5 times" })

-- Speak all French sentences in buffer with per-line highlight (<leader>fa)
vim.keymap.set("n", "<leader>fa", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local buf = vim.api.nvim_get_current_buf()
    local sentences = {}
    local line_nums = {}
    for i, line in ipairs(lines) do
        local parts = vim.fn.split(line, "|", 1)
        if #parts >= 3 then
            local fr = vim.fn.trim(parts[3])
            if fr ~= "" and fr ~= "French translation" then
                table.insert(sentences, fr)
                table.insert(line_nums, i - 1)
            end
        end
    end
    local function speak_next(idx)
        if idx > #sentences then return end
        fr_highlight(buf, line_nums[idx])
        local text = "[[slnc 300]] " .. sentences[idx] .. " [[slnc 500]]"
        vim.fn.jobstart({ "say", "-v", fr_voice, text }, {
            on_exit = function() vim.schedule(function() speak_next(idx + 1) end) end,
        })
    end
    speak_next(1)
end, { desc = "Speak all French sentences in buffer" })

-- Clear highlight on current line (<leader>fx)
vim.keymap.set("n", "<leader>fx", function()
    local buf = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    fr_clear_range(buf, row, row)
end, { desc = "Clear French TTS highlight on current line" })

-- Clear highlight on selected lines (<leader>fx in visual mode)
vim.keymap.set("v", "<leader>fx", function()
    local buf = vim.api.nvim_get_current_buf()
    local start_row = vim.fn.line("'<") - 1
    local end_row = vim.fn.line("'>") - 1
    fr_clear_range(buf, start_row, end_row)
end, { desc = "Clear French TTS highlight on selected lines" })

-- Clear all highlights in buffer (<leader>fX)
vim.keymap.set("n", "<leader>fX", function()
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buf, fr_ns, 0, -1)
    fr_save(buf)
end, { desc = "Clear all French TTS highlights" })
