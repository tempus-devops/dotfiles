return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "dockerls",
          "docker_compose_language_service",
          "bashls",
          "html",
          "helm_ls",
          "jsonls",
          "jedi_language_server",
          "sqlls",
          "terraformls",
          "tflint",
          "lemminx",
          "yamlls",
          "phpactor",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
        vim.notify("This config requires Neovim >= 0.11.3", vim.log.levels.ERROR)
        return
      end

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local servers = {
        "lua_ls",
        "dockerls",
        "docker_compose_language_service",
        "bashls",
        "html",
        "helm_ls",
        "jsonls",
        "jedi_language_server",
        "sqlls",
        "terraformls",
        "tflint",
        "lemminx",
        "yamlls",
        "phpactor",
      }

      for _, name in ipairs(servers) do
        vim.lsp.config(name, {
          capabilities = capabilities,
        })
        vim.lsp.enable(name)
      end

      -- Keymaps
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover" })
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP Goto Definition" })
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP Code Action" })
    end,
  },
}
