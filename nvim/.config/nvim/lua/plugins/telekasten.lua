return {
	"renerocksai/telekasten.nvim",
	dependencies = { "nvim-telescope/telescope.nvim" },
	config = function()
		local telekasten = require("telekasten")

		-- Set your notes folder path
		local notes_home = vim.fn.expand("~/Zettelkasten")

		telekasten.setup({
			home = notes_home,
            auto_set_filetype = false,
		})

		-- Keymaps (same as before)
		vim.keymap.set("n", "<leader>z", "<cmd>Telekasten panel<CR>")
		vim.keymap.set("n", "<leader>zf", "<cmd>Telekasten find_notes<CR>")
		vim.keymap.set("n", "<leader>zg", "<cmd>Telekasten search_notes<CR>")
		vim.keymap.set("n", "<leader>zd", "<cmd>Telekasten goto_today<CR>")
		vim.keymap.set("n", "<leader>zz", "<cmd>Telekasten follow_link<CR>")
		vim.keymap.set("n", "<leader>zn", "<cmd>Telekasten new_note<CR>")
		vim.keymap.set("n", "<leader>zc", "<cmd>Telekasten show_calendar<CR>")
		vim.keymap.set("n", "<leader>zb", "<cmd>Telekasten show_backlinks<CR>")
		vim.keymap.set("n", "<leader>zI", "<cmd>Telekasten insert_img_link<CR>")
		vim.keymap.set("i", "[[", "<cmd>Telekasten insert_link<CR>")

		-- === BACKLINKS === --

		local function get_note_title(filepath)
			return vim.fn.fnamemodify(filepath, ":t:r")
		end

		local function insert_backlinks()
			local current_buf = vim.api.nvim_get_current_buf()
			local current_path = vim.api.nvim_buf_get_name(current_buf)
			local current_title = get_note_title(current_path)
			local backlinks = {}

			for _, file in ipairs(vim.fn.glob(notes_home .. "/*.md", 0, 1)) do
				if file ~= current_path then
					local lines = vim.fn.readfile(file)
					for _, line in ipairs(lines) do
						if string.match(line, "%[%[" .. current_title .. "%]%]") then
							table.insert(backlinks, string.format("- [[%s]]", get_note_title(file)))
							break
						end
					end
				end
			end

			-- Remove existing backlinks section
			local all_lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
			local new_lines = {}
			local in_backlinks = false

			for _, line in ipairs(all_lines) do
				if line == "## Backlinks" then
					in_backlinks = true
				elseif not in_backlinks then
					table.insert(new_lines, line)
				elseif in_backlinks and line:match("^## ") then
					in_backlinks = false
					table.insert(new_lines, line)
				end
			end

			-- Trim trailing blank lines before appending
			while #new_lines > 0 and new_lines[#new_lines]:match("^%s*$") do
				table.remove(new_lines)
			end

			-- Add backlinks section
			table.insert(new_lines, "")
			table.insert(new_lines, "")
			table.insert(new_lines, "## Backlinks")
			if #backlinks == 0 then
				table.insert(new_lines, "- No backlinks found.")
			else
				for _, link in ipairs(backlinks) do
					table.insert(new_lines, link)
				end
			end

			vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, new_lines)
		end

		-- Manual mapping (optional)
		vim.keymap.set("n", "<leader>bl", insert_backlinks, { desc = "Insert backlinks" })

		-- Auto-update on save
		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = "*.md",
			callback = function()
				local bufname = vim.api.nvim_buf_get_name(0)
				if string.find(bufname, notes_home, 1, true) then
					insert_backlinks()
				end
			end,
		})
		vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
			pattern = vim.fn.expand("~/Zettelkasten") .. "/*.md",
			callback = function()
				vim.bo.filetype = "markdown"
			end,
		})
	end,
}
