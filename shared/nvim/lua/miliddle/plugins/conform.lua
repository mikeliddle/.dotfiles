return {
    'stevearc/conform.nvim',
    opts = {},
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "black" },
                javascript = { "prettier" },
                go = { "gofmt" },
                html = { "prettier" },
                css = { "prettier" },
                csharp = { "dotnet-format" },
                json = { "prettier" },
                markdown = { "prettier" },
            }
        })
    end
}
