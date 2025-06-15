return {
	"simrat39/symbols-outline.nvim",
	cmd = { "SymbolsOutline", "SymbolsOutlineOpen" },
	keys = {
		{ "<leader>so", "<cmd>SymbolsOutline<CR>", desc = "Symbols Outline" },
	},
	config = function()
		require("symbols-outline").setup({
			highlight_hovered_item = true,
			show_guides = true,
			auto_preview = false,
			position = "right",
			width = 35,
			show_numbers = false,
			show_relative_numbers = false,
			show_symbol_details = true,
		})
	end,
}
