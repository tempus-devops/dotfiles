return {
	{
		"SmiteshP/nvim-navic",
		lazy = true, -- load only when needed
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("nvim-navic").setup({
				highlight = true,
				separator = " > ",
				depth_limit = 5,
				icons = {
					File = "📄 ",
					Module = "📦 ",
					Namespace = "🚀 ",
					Class = "🏛 ",
					Method = "🔧 ",
					Function = "⚙️ ",
					Variable = "🔣 ",
				},
			})
		end,
	},
}
