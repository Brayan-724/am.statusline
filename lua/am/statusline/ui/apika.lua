local base = require("am.statusline.base")

local ui_apika = {}

---@class StatuslineUICell
---@field icon? StatuslineComponent<string?>
---@field txt StatuslineComponent<string?>
---@field sep_left StatuslineComponent<string?>
---@field sep_right StatuslineComponent<string?>

ui_apika.cell = base.component(
	---@param opts StatuslineUICell
	---@param config ModuleConfig
	function(opts, config, ctx)
		return {
			icon = base.resolve(opts.icon, config, ctx),
			txt = base.resolve(opts.txt, config, ctx),
			sep_left = base.resolve(opts.sep_left, config, ctx),
			sep_right = base.resolve(opts.sep_right, config, ctx),
		}
	end,
	function(opts, ctx)
		local sep_l = opts.sep_left(ctx)
		local icon = opts.icon(ctx)
		local txt = opts.txt(ctx)
		local sep_r = opts.sep_right(ctx)

		return sep_l .. icon .. txt .. sep_r
	end
)

ui_apika.cell_component = function(opts)
	local solid_hl = function(ctx, config)
		local prefix = "%#StatuslineLevel" .. ctx.level
		local icon_hl = prefix .. "Icon#"
		local text_hl = prefix .. "Label#"
		local sep_l = { config.separators.left, prefix .. "SepLeft#" }
		local sep_r = { config.separators.right, prefix .. "SepRight#" }

		return icon_hl, text_hl, sep_l, sep_r
	end

	local transparent_hl = function(_, config)
		local prefix = "%#StatuslineTransparent"
		local icon_hl = prefix .. "Icon#"
		local text_hl = prefix .. "Label#"
		local sep_l = { config.separators.transparent_left or "", prefix .. "SepLeft#" }
		local sep_r = { config.separators.transparent_left or "", prefix .. "SepRight#" }

		return icon_hl, text_hl, sep_l, sep_r
	end

	local transparent = false

	local function hl(ctx, config)
		if transparent then
			return transparent_hl(ctx, config)
		end

		return solid_hl(ctx, config)
	end

	local on_render = opts.on_render or function(_, _, _)
		return opts.icon, opts.text
	end

	return base.component(function(o)
		transparent = o.transparent or false
		return opts.on_start and opts.on_start(o) or o
	end, function(o, ctx, config)
		local icon_hl, text_hl, sep_l, sep_r = hl(ctx, config)

		local icon, text = on_render(o, ctx, config)

		if icon == nil and text == nil then
			return ""
		end

		if icon == nil then
			sep_l[2] = sep_r[2]
		elseif text == nil then
			sep_r[2] = sep_l[2]
		else
			icon = icon .. " "
			text = " " .. text
		end

		return ui_apika.cell({
			icon = icon and icon_hl .. icon,
			txt = text and text_hl .. text,
			sep_left = sep_l[2] .. sep_l[1],
			sep_right = sep_r[2] .. sep_r[1],
		})
	end)
end

---@class StatuslineUISolidCell
---@field txt StatuslineComponent<string?>
---@field sep_left StatuslineComponent<string?>
---@field sep_right StatuslineComponent<string?>

ui_apika.solid_cell = base.component(
	---@param opts StatuslineUISolidCell
	---@param config ModuleConfig
	function(opts, config, ctx)
		return {
			txt = base.resolve(opts.txt, config, ctx),
			sep_left = base.resolve(opts.sep_left, config, ctx),
			sep_right = base.resolve(opts.sep_right, config, ctx),
		}
	end,
	function(opts, ctx)
		local sep_l = opts.sep_left(ctx) or ""
		local txt = opts.txt(ctx) or ""
		local sep_r = opts.sep_right(ctx) or ""

		return sep_l .. txt .. sep_r
	end
)

ui_apika.mode = base.component(function(opts, config)
	return vim.tbl_deep_extend("force", {
		icon = function(ctx)
			return config.icons[ctx.mode]
		end,

		sep = {
			function(ctx)
				return { config.separators.left, "%#StatuslineMode" .. ctx.mode .. "Sep#" }
			end,
			function(ctx)
				return { config.separators.right, "%#StatuslineMode" .. ctx.mode .. "Sep#" }
			end,
		},
		hl = function(ctx)
			return "%#StatuslineMode" .. ctx.mode .. "#"
		end,
	}, opts)
end, function(opts, ctx)
	if not base.is_activewin() then
		return ""
	end

	local hl = opts.hl(ctx)
	local icon = opts.icon and opts.icon(ctx) or ""

	local sep_l = opts.sep[1](ctx)
	local sep_r = opts.sep[2](ctx)

	return ui_apika.solid_cell({
		txt = hl .. icon,
		sep_left = sep_l[2] .. sep_l[1],
		sep_right = sep_r[2] .. sep_r[1],
	})
end)

ui_apika.filename = ui_apika.cell_component({
	on_render = function()
		local icon = "󰈚"
		local name = base.filename()

		if name ~= "Empty" then
			local devicons_present, devicons = pcall(require, "nvim-web-devicons")

			if devicons_present then
				local ft_icon = devicons.get_icon(name)
				icon = (ft_icon ~= nil and ft_icon) or icon
			end
		end

		return icon, name
	end,
})

ui_apika.cursor_position = ui_apika.cell_component({
	icon = "",
	text = "%l/%c",
})

ui_apika.cwd = ui_apika.cell_component({
	on_render = function()
		if vim.o.columns < 85 then
			return
		end

		return "", vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	end,
})

ui_apika.lsp_server = ui_apika.cell_component({
	on_render = function()
		if not rawget(vim, "lsp") then
			return
		end

		for _, client in ipairs(vim.lsp.get_active_clients()) do
			if client.attached_buffers[base.stbufnr()] and client.name ~= "null-ls" then
				if vim.o.columns <= 100 then
					return "", "LSP"
				end

				return "", client.name
			end
		end
	end,
})

ui_apika.git = ui_apika.cell_component({
	on_render = function(opts)
		local b = vim.b[base.stbufnr()]
		if not b or not b.gitsigns_head or b.gitsigns_git_status then
			return
		end

		local git_status = b.gitsigns_status_dict

		local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
		local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
		local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
		local branch_name = " " .. git_status.head

		return not opts.transparent and "" or nil, branch_name .. added .. changed .. removed
	end,
})

ui_apika.lsp_diagnostics = ui_apika.cell_component({
	on_render = function()
		if not rawget(vim, "lsp") then
			return
		end

		local function resolve(name, icon)
			local severity = vim.diagnostic.severity[name:upper()]

			local n = #vim.diagnostic.get(base.stbufnr(), { severity = severity })

			if not n or n <= 0 then
				return ""
			end

			return "%#StatuslineLsp" .. name .. "Label#" .. icon .. " " .. n .. " "
		end

    local errors = resolve("Error", "")
    local warnings = resolve("Warn", "")
    local hints = resolve("Hint", "󰛩")
    local info = resolve("Info", "󰋼")

		return nil, errors .. warnings .. hints .. info
	end,
})

return ui_apika
