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
local focus_ns = vim.api.nvim_create_namespace("markdown_focus_line")

vim.api.nvim_set_hl(0, "FrenchTTS", { bg = "white", fg = "black", bold = true })

local function set_focus_highlight()
	vim.api.nvim_set_hl(0, "MarkdownFocusLine", {
		bg = "#3b4261",
		bold = true,
		underline = true,
	})
end

set_focus_highlight()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_focus_highlight })

local function fr_add_highlight(buf, row)
	-- A high-priority line highlight remains visible over render-markdown's
	-- heading, table, and code-block decorations.
	vim.api.nvim_buf_set_extmark(buf, fr_ns, row, 0, {
		line_hl_group = "FrenchTTS",
		priority = 10000,
	})
end

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
	if not file then
		return
	end
	for line in file:lines() do
		local row = tonumber(line)
		if row then
			fr_add_highlight(buf, row)
		end
	end
	file:close()
end

local function fr_highlight(buf, row)
	fr_add_highlight(buf, row)
	fr_save(buf)
end

local function fr_from_line(line)
	local parts = vim.fn.split(line, "|", 1)
	if #parts < 3 then
		return nil
	end
	local french = vim.fn.trim(parts[3])
	if french == "" or french == "French translation" or french:match("^[-: ]+$") then
		return nil
	end
	return french
end

local function fr_export(buf, rows)
	local source = vim.api.nvim_buf_get_name(buf)
	if source == "" then
		vim.notify("Save the Markdown document before exporting audio", vim.log.levels.WARN)
		return
	end

	local stem = vim.fn.fnamemodify(source, ":t:r")
	local output_dir = vim.fs.dirname(source) .. "/" .. stem .. "-french-audio"
	vim.fn.mkdir(output_dir, "p")

	local tracks = {}
	for _, row in ipairs(rows) do
		local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
		local french = line and fr_from_line(line) or nil
		if french then
			table.insert(tracks, { row = row, text = french })
		end
	end

	if #tracks == 0 then
		vim.notify("No French sentences found in those Markdown table rows", vim.log.levels.WARN)
		return
	end

	vim.notify(string.format("Exporting %d French M4A tracks…", #tracks))
	local function export_next(index)
		if index > #tracks then
			vim.notify(string.format("Exported %d tracks to %s", #tracks, output_dir))
			return
		end

		local track = tracks[index]
		local aiff = vim.fn.tempname() .. ".aiff"
		local m4a = string.format("%s/%03d-line-%d.m4a", output_dir, index, track.row + 1)
		vim.fn.jobstart({ "say", "-v", fr_voice, "-o", aiff, track.text }, {
			on_exit = function(_, say_code)
				vim.schedule(function()
					if say_code ~= 0 then
						vim.fn.delete(aiff)
						vim.notify("Failed to synthesize line " .. (track.row + 1), vim.log.levels.ERROR)
						return
					end
					-- vim.fn.jobstart({ "ffmpeg", "-y", "-loglevel", "error", "-i", aiff, "-af", "apad=pad_dur=1", "-codec:a", "pcm_s16le",     "-metadata", "artist=Andrii Petrenko", "-metadata", "album=French Shadowing", "-metadata", "title=" .. track.text, "-metadata", "track=" .. tostring(index), wav }, {
                    vim.fn.jobstart({ "ffmpeg", "-y", "-loglevel", "error", "-i", aiff, "-af", "apad=pad_dur=1", "-c:a", "aac", "-b:a", "96k", "-metadata", "artist=Andrii Petrenko", "-metadata", "album=French Shadowing", "-metadata", "title=" .. track.text, "-metadata", "track=" .. tostring(index), m4a }, {
						on_exit = function(_, ffmpeg_code)
							vim.schedule(function()
								vim.fn.delete(aiff)
								if ffmpeg_code ~= 0 then
									vim.notify("Failed to encode line " .. (track.row + 1), vim.log.levels.ERROR)
									return
								end
								fr_highlight(buf, track.row)
								export_next(index + 1)
							end)
						end,
					})
				end)
			end,
		})
	end
	export_next(1)
end

-- Export rows previously marked by <leader>fr.
vim.keymap.set("n", "<leader>fe", function()
	local buf = vim.api.nvim_get_current_buf()
	local rows = {}
	local seen = {}
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, fr_ns, 0, -1, {})) do
		if not seen[mark[2]] then
			seen[mark[2]] = true
			table.insert(rows, mark[2])
		end
	end
	table.sort(rows)
	fr_export(buf, rows)
end, { desc = "Export highlighted French rows to M4A" })

-- Export the French column from selected Markdown table rows.
vim.keymap.set("v", "<leader>fe", function()
	local buf = vim.api.nvim_get_current_buf()
	local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local anchor_row = vim.fn.getpos("v")[2] - 1
	local first, last = math.min(cursor_row, anchor_row), math.max(cursor_row, anchor_row)
	local rows = {}
	for row = first, last do
		table.insert(rows, row)
	end
	fr_export(buf, rows)
end, { desc = "Export selected French rows to M4A" })

local function update_focus_line(buf)
	vim.api.nvim_buf_clear_namespace(buf, focus_ns, 0, -1)
	if vim.b[buf].markdown_focus_line then
		local row = vim.api.nvim_win_get_cursor(0)[1] - 1
		vim.api.nvim_buf_set_extmark(buf, focus_ns, row, 0, {
			line_hl_group = "MarkdownFocusLine",
			priority = 20000,
		})
	end
end

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
	pattern = "*.md",
	callback = function(args)
		update_focus_line(args.buf)
	end,
})

-- Toggle a focus line that follows the cursor.
vim.keymap.set("n", "<leader>fh", function()
	local buf = vim.api.nvim_get_current_buf()
	vim.b[buf].markdown_focus_line = not vim.b[buf].markdown_focus_line
	update_focus_line(buf)
end, { desc = "Toggle moving Markdown focus line" })

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
		if idx > #sentences then
			return
		end
		fr_highlight(buf, line_nums[idx])
		local text = "[[slnc 300]] " .. sentences[idx] .. " [[slnc 500]]"
		vim.fn.jobstart({ "say", "-v", fr_voice, text }, {
			on_exit = function()
				vim.schedule(function()
					speak_next(idx + 1)
				end)
			end,
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
