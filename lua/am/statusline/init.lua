--- *am.statusline* Plugin manager
--- *AMStatusline*
---
--- MIT License Copyright (c) 2024 Apika Luca
---
--- ==============================================================================

---# Plugin Specification ~
---@class ModeHighlights
---@field Command string
---@field Confirm string
---@field ConfirmMore string
---@field ConfirmAsk string
---@field Insert string
---@field Normal string
---@field NTerminal string
---@field Replace string
---@field Select string
---@field Terminal string
---@field Visual string
---
---@alias StatuslineComponent string|fun(config: ModuleConfig, ctx: StatuslineContext): StatuslineResolvedComponent
---@alias StatuslineResolvedComponent fun(ctx: StatuslineContext): string?
---
---@class StatuslineContext
---@field mode string
---@field level number
---@field side ContextSide
---@tag AM-Statusline-plugin-specification

local ui = require("am.statusline.ui")
local ui_apika = require("am.statusline.ui.apika")
local base = require("am.statusline.base")

local AMStatusline = {}

--- Module Config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---
---@class ModuleConfig
AMStatusline.config = {
	transparent = true,

	---@type string|table
	theme = "apika",

	colors = {
		Command = { fg = "" },
	},

	separators = { left = "", right = "" },

	icons = {
		Command = "",
		Confirm = "󰛔",
		ConfirmMore = "MORE",
		ConfirmAsk = "",
		Insert = "󰏫",
		Normal = "󰋜",
		NTerminal = "",
		Replace = "",
		Select = "󰏫",
		Terminal = "",
		Visual = "󰈈",
	},

	gap = 1,
	sections = {
		left = {
			ui_apika.mode({
				icon = false,
			}),
			ui_apika.filename(),
			ui_apika.git({ transparent = true }),
		},
		center = {
      ui.text("Apika Luca")()
    },
		right = {
			ui_apika.cursor_position(),
			ui_apika.cwd(),
			ui_apika.lsp_server(),
			ui_apika.lsp_diagnostics({ transparent = true }),
		},
	},
}

--- Create a table with all
---@param prefix? string
---@param suffix? string
---@return ModeHighlights highlights_maps
function AMStatusline.create_mode_highlights(prefix, suffix)
	prefix = prefix or ""
	suffix = suffix or ""

	return {
		Command = prefix .. "Command" .. suffix,
		Confirm = prefix .. "Confirm" .. suffix,
		ConfirmMore = prefix .. "ConfirmMore" .. suffix,
		ConfirmAsk = prefix .. "ConfirmAsk" .. suffix,
		Insert = prefix .. "Insert" .. suffix,
		Normal = prefix .. "Normal" .. suffix,
		NTerminal = prefix .. "NTerminal" .. suffix,
		Replace = prefix .. "Replace" .. suffix,
		Select = prefix .. "Select" .. suffix,
		Terminal = prefix .. "Terminal" .. suffix,
		Visual = prefix .. "Visual" .. suffix,
	}
end

-- M.fileInfo = function()
-- 	local icon = "󰈚"
-- 	local path = vim.api.nvim_buf_get_name(stbufnr())
-- 	local name = (path == "" and "Empty ") or path:match("([^/\\]+)[/\\]*$")
--
-- 	if name ~= "Empty" then
-- 		local devicons_present, devicons = pcall(require, "nvim-web-devicons")
--
-- 		if devicons_present then
-- 			local ft_icon = devicons.get_icon(name)
-- 			icon = (ft_icon ~= nil and ft_icon) or icon
-- 		end
-- 	end
--
-- 	return gen_block(icon, name, "%#St_file_sep#", "%#St_file_bg#", "%#St_file_txt#")
-- end
--
-- M.LSP_Diagnostics = function()
-- end
--
-- M.file_encoding = function()
-- 	local encode = vim.bo[stbufnr()].fileencoding
-- 	return string.upper(encode) == "" and "" or string.upper(encode) .. "  "
-- end

AMStatusline.cache = {
	---@type StatuslineResolvedComponent
	left = nil,
	---@type StatuslineResolvedComponent
	center = nil,
	---@type StatuslineResolvedComponent
	right = nil,
}

AMStatusline.run = function()
	local mode = base.mode_norm()

	vim.g.statusline_scope_opts = {
		gap = AMStatusline.config.gap or 0,
	}

	return ""
		.. AMStatusline.cache.left({
			mode = mode,
			level = 1,
			side = base.SIDES.Left,
		})
		.. "%="
		.. AMStatusline.cache.center({
			mode = mode,
			level = 1,
			side = base.SIDES.Center,
		})
		.. "%="
		.. AMStatusline.cache.right({
			mode = mode,
			level = 1,
			side = base.SIDES.Right,
		})
end

---@param opts ModuleConfig
function AMStatusline.setup(opts)
	AMStatusline.config = vim.tbl_deep_extend("force", AMStatusline.config, opts)

	AMStatusline.config.sections.left = AMStatusline.config.sections.left or {}
	AMStatusline.config.sections.center = AMStatusline.config.sections.center or {}
	AMStatusline.config.sections.right = AMStatusline.config.sections.right or {}

	require("am.statusline.theme").set_theme(AMStatusline.config.theme)

	local mode = base.mode_norm() or "Normal"

	vim.g.statusline_scope_opts = {
		gap = AMStatusline.config.gap or 0,
	}

	AMStatusline.cache.left = ui.section({}, unpack(AMStatusline.config.sections.left))(AMStatusline.config, {
		mode = mode,
		level = 1,
		side = base.SIDES.Left,
	})

	AMStatusline.cache.center = ui.section({}, unpack(AMStatusline.config.sections.center))(AMStatusline.config, {
		mode = mode,
		level = 1,
		side = base.SIDES.Center,
	})

	AMStatusline.cache.right = ui.section({}, unpack(AMStatusline.config.sections.right))(AMStatusline.config, {
		mode = mode,
		level = 1,
		side = base.SIDES.Right,
	})

	vim.opt.statusline = "%!v:lua.require('am.statusline').run()"
end

return AMStatusline
