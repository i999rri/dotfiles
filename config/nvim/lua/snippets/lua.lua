local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node

return {
    s("doc", {
        f(function()
            require("neogen").generate()
            return ""
        end, {}),
    }),
}
