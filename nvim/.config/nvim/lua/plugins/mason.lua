return {
    "williamboman/mason.nvim",
    lazy = false, -- ⬅️ Force load at startup
    config = function()
        require("mason").setup()
    end,
}
