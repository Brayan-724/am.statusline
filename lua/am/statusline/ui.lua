local base = require("am.statusline.base")

local ui = {}

ui.section = base.component(function(opts, config, ctx)
	local scoped_opts = vim.tbl_deep_extend("force", vim.g.statusline_scope_opts or {}, opts)
	local gap = scoped_opts.gap or 0

	---@type StatuslineResolvedComponent[]
	local children = {}
	for _, child in ipairs(opts.children) do
		local child_ = base.resolve(child, config, ctx)

		table.insert(children, child_)

		ctx.level = ctx.level + 1
	end

	return {
		scoped_opts = scoped_opts,
		gap = gap,
		children = children,
	}
end, function(opts, ctx)
	local old_opts = vim.g.statusline_scope_opts or {}
	vim.g.statusline_scope_opts = opts

	local out = ""
	local gap = string.rep(" ", opts.gap)
	for _, child in ipairs(opts.children) do
		local rendered = child(ctx) or ""

		if ctx.side == base.SIDES.Right then
			out = rendered .. "%#StatuslineEmpty#" .. gap .. out
		else
			out = out .. rendered .. "%#StatuslineEmpty#" .. gap
		end

		ctx.level = ctx.level + 1
	end

	vim.g.statusline_scope_opts = old_opts
	return out
end)

ui.text = function(txt)
	return base.component(function(opts, _, _)
		return vim.tbl_deep_extend("force", { transparent = true }, opts)
	end, function(opts, _, _)
		local hl = opts.transparent and "%#StatuslineTransparentLabel#" or ""
		return hl .. txt
	end)
end

return ui
