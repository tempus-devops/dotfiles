return {
	"neovim/nvim-lspconfig",
	lazy = false,
	config = function()
		local navic = require("nvim-navic") -- <--- require navic here
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		local on_attach = function(client, bufnr)
			if client.server_capabilities.documentSymbolProvider then
				navic.attach(client, bufnr)
			end
		end

		local lspconfig = require("lspconfig")

		lspconfig.lua_ls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.dockerls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.docker_compose_language_service.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.bashls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.html.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.helm_ls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.jsonls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.jedi_language_server.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.sqlls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.terraformls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.lemminx.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.yamlls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})
		lspconfig.phpactor.setup({
			capabilities = capabilities,
			on_attach = on_attach, -- ✅ Attach navic here
		})

		vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
	end,
}
