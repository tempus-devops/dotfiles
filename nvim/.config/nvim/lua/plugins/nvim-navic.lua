return {
    {
        "SmiteshP/nvim-navic",
        dependencies = "neovim/nvim-lspconfig", -- Ensure LSP is installed
        config = function()
            require("nvim-navic").setup({
                highlight = true, -- Enable highlights
                separator = " > ", -- Breadcrumbs separator
                depth_limit = 5, -- Limit depth of breadcrumbs
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
