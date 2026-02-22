return {
	{
		"diepm/vim-rest-console",
		ft = "rest",
		config = function()
			local response_name = vim.g.vrc_output_buffer_name or "__REST_response__"

			-- Harden curl opts: must be a dictionary
			if type(vim.g.vrc_curl_opts) ~= "table" then
				vim.g.vrc_curl_opts = { ["-s"] = "", ["-S"] = "" }
			end

			-- Force the response buffer to be shown in a HORIZONTAL split (bottom).
			-- If VRC opened it elsewhere (vertical), we move it and close the old window.
			local function force_response_horizontal()
				local bufnr = vim.fn.bufnr(response_name)
				if bufnr == -1 then
					return false
				end

				-- Find any existing window(s) displaying the response buffer
				local wins = vim.fn.win_findbuf(bufnr)

				-- Open our own horizontal split at the bottom and display the response buffer
				vim.cmd("botright split")
				local new_win = vim.api.nvim_get_current_win()
				vim.api.nvim_win_set_buf(new_win, bufnr)

				-- Close any old windows that were showing the response buffer (except the new one)
				for _, w in ipairs(wins) do
					if w ~= new_win then
						-- pcall so we don't error if a window is already gone
						pcall(vim.api.nvim_win_close, w, true)
					end
				end

				return true
			end

			local function vrc_run_and_jump()
				vim.cmd("silent! call VrcQuery()")

				-- Poll briefly until the response buffer exists, then force it into a horizontal split.
				local attempts, max_attempts, interval_ms = 0, 30, 40 -- ~1.2s total
				local timer = vim.loop.new_timer()

				timer:start(
					interval_ms,
					interval_ms,
					vim.schedule_wrap(function()
						attempts = attempts + 1
						if force_response_horizontal() or attempts >= max_attempts then
							timer:stop()
							timer:close()
						end
					end)
				)
			end

			-- Run with headers + latency (temporarily add curl -i)
			local function vrc_run_headers_and_jump()
				-- Save current curl opts
				local saved = {}
				for k, v in pairs(vim.g.vrc_curl_opts) do
					saved[k] = v
				end

				vim.g.vrc_curl_opts["-i"] = ""

				local t0 = vim.loop.hrtime()
				vim.cmd("silent! call VrcQuery()")
				local ms = (vim.loop.hrtime() - t0) / 1e6

				-- Restore curl opts
				vim.g.vrc_curl_opts = saved

				-- Force into horizontal split
				local attempts, max_attempts, interval_ms = 0, 30, 40
				local timer = vim.loop.new_timer()

				timer:start(
					interval_ms,
					interval_ms,
					vim.schedule_wrap(function()
						attempts = attempts + 1
						if force_response_horizontal() or attempts >= max_attempts then
							timer:stop()
							timer:close()
							vim.notify(string.format("VRC latency: %.0f ms", ms))
						end
					end)
				)
			end

			-- Pretty-print JSON in response buffer (keeps prefix lines if headers exist)
			local function format_response_json(bufnr)
				if vim.fn.executable("jq") ~= 1 then
					return
				end

				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

				local start
				for i, l in ipairs(lines) do
					if l:find("^%s*[{%[]") then
						start = i
						break
					end
				end
				if not start then
					return
				end

				local prefix = {}
				if start > 1 then
					prefix = vim.list_slice(lines, 1, start - 1)
				end

				local json_input = table.concat(vim.list_slice(lines, start, #lines), "\n")
				local out = vim.fn.system({ "jq", "." }, json_input)
				if vim.v.shell_error ~= 0 then
					return
				end

				local formatted = vim.split(out, "\n", { plain = true, trimempty = true })

				local new_lines = {}
				for _, l in ipairs(prefix) do
					table.insert(new_lines, l)
				end
				if #prefix > 0 then
					table.insert(new_lines, "")
				end
				for _, l in ipairs(formatted) do
					table.insert(new_lines, l)
				end

				local was_modifiable = vim.api.nvim_get_option_value("modifiable", { buf = bufnr })
				local was_readonly = vim.api.nvim_get_option_value("readonly", { buf = bufnr })

				vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
				vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
				vim.api.nvim_set_option_value("modifiable", was_modifiable, { buf = bufnr })
				vim.api.nvim_set_option_value("readonly", was_readonly, { buf = bufnr })
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "rest",
				callback = function()
					vim.schedule(function()
						-- Keep tmux-navigator on <C-j>
						pcall(vim.keymap.del, "n", "<C-j>", { buffer = true })
						vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", {
							buffer = true,
							silent = true,
							desc = "Tmux: down",
						})

						vim.keymap.set("n", "<leader>r", vrc_run_and_jump, {
							buffer = true,
							silent = true,
							desc = "REST: run (horizontal response)",
						})

						vim.keymap.set("n", "<leader>rh", vrc_run_headers_and_jump, {
							buffer = true,
							silent = true,
							desc = "REST: run with headers + latency",
						})
					end)
				end,
			})


			vim.api.nvim_create_autocmd("BufWinEnter", {
				pattern = response_name,
				callback = function(args)
					local bufnr = args.buf

					vim.bo[bufnr].filetype = "json"
					vim.bo[bufnr].syntax = "on"

                    vim.api.nvim_set_hl(0, "VrcResponseNormal", {
                        bg = "#15132e",
                    })

                    vim.wo.winhl = "Normal:VrcResponseNormal,NormalNC:VrcResponseNormal"

					-- Close response window with q
					vim.keymap.set("n", "q", "<cmd>close<CR>", {
						buffer = true,
						silent = true,
						desc = "Close response window",
					})

					-- Auto-format after content arrives
					vim.schedule(function()
						format_response_json(bufnr)
					end)
					vim.defer_fn(function()
						format_response_json(bufnr)
					end, 120)
				end,
			})
		end,
	},
}
