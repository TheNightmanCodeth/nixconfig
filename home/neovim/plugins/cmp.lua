local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup {
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ["<CR>"] = cmp.mapping.confirm({ select = true })
	    ["<tab>"] = cmp.mapping(function(original)
			if cmp.visible() then
			    cmp.select_next_item() -- run completion selection if completing
			elseif luasnip.expand_or_jumpable() then
			    luasnip.expand_or_jump() -- expand snippets
			else
			    original() -- run the original behavior if not completing
			end
		end, {"i", "s"}),
		["<S-tab>"] = cmp.mapping(function(original)
		    if cmp.visible() then
			    cmp.select_prev_item() -- run previous completion option if completing
			elseif luasnip.expand_or_jumpable() then
			    luasnip.jump(-1) -- expand prev snippet
			else
			    original() -- run the original behavior if not completing
			end
		end, {"i", "s"}), -- idk what i and s are
	}),
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    },
}
