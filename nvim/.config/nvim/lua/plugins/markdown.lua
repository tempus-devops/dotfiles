return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		-- Render only in Normal mode. Insert and Visual modes show raw Markdown.
		render_modes = { "n" },
		anti_conceal = {
			-- Do not reveal raw Markdown on the cursor line in Normal mode.
			enabled = false,
		},
	},
}
