return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown" },
	config = function()
		vim.fn["mkdp#util#install"]()
	end,

	vim.keymap.set("n", "<leader>md", ":MarkdownPreview<CR>", {}),
}
