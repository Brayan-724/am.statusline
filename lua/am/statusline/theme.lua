local theme = {}
local H = {}

--- Set nvim highlights
---
---@param hl table<string, table>
---
---@usage >lua
---  theme.set_highlights({
---    CustomHighlight = { fg = "white", bg = "black", bold = true }
---  })
--- >
function theme.set_highlights(hl)
	for k, v in pairs(hl) do
		vim.api.nvim_set_hl(0, k, v)
	end
end

theme.minimal = {
	StatuslineEmpty = { fg = "none", bg = "none" },
}

---@param name string
---@param accent string
---@param base string
---@param bg string
---@return table
function theme.create_cell(name, accent, base, bg)
	local prefix = "Statusline" .. name

	return {
		[prefix .. "SepLeft"] = {
			fg = accent,
			bg = bg,
		},

		[prefix .. "Icon"] = {
			fg = base,
			bg = accent,
			bold = true,
		},

		[prefix .. "Label"] = {
			fg = accent,
			bg = base,
			bold = true,
		},

		[prefix .. "SepRight"] = {
			fg = base,
			bg = bg,
		},
	}
end

function theme.create_mode(name, accent, fg, bg)
	local prefix = "StatuslineMode" .. name

	return {
		[prefix .. "Sep"] = {
			fg = accent,
			bg = bg,
		},

		[prefix] = {
			fg = fg,
			bg = accent,
			bold = true,
		},
	}
end

function H.set_mode_theme(mode_theme)
	local global_mode_bg = mode_theme.bg
	local global_mode_fg = mode_theme.fg

	for mode, spec in pairs(mode_theme) do
		if mode == "fg" or mode == "bg" then
		-- CONTINUE
		elseif type(spec) == "string" then
			theme.set_highlights(theme.create_mode(mode, spec, global_mode_fg, global_mode_bg))
		elseif type(spec) == "table" then
			vim.notify("TODO: Mode theme table spec", vim.log.levels.WARN)
		else
			vim.notify("Mode spec should be string or table, got " .. type(spec), vim.log.levels.ERROR)
		end
	end
end

---@param spec string|table
function theme.set_theme(spec)
	if type(spec) == "string" then
		return theme.set_theme(theme[spec])
	end

	if type(spec) ~= "table" then
		return
	end

	theme.set_highlights({
		StatuslineEmpty = spec.empty,
	})

	if type(spec.mode) == "table" then
		H.set_mode_theme(spec.mode)
	end

	if type(spec.transparent) == "table" then
		local level = spec.transparent
		theme.set_highlights(theme.create_cell("Transparent", level.accent, level.base, level.bg))
	end

	if type(spec.transparent) == "string" then
		theme.set_highlights(theme.create_cell("Transparent", spec.transparent, "none", "none"))
	end

	if type(spec.lsp) == "table" then
		for name, level in pairs(spec.lsp) do
			theme.set_highlights(theme.create_cell("Lsp" .. name, level, "none", "none"))
		end
	end

	if type(spec.levels) == "table" then
		for i, level in ipairs(spec.levels) do
			theme.set_highlights(theme.create_cell("Level" .. i, level.accent, level.base, level.bg))
		end
	end
end

local apika_colors = {
	black = "#1e222a",
	light_grey = "#6f737b",
	white = "#abb2bf",

	blue = "#61afef",
	cyan = "#aaffe4",
	darkgreen = "#62d196",
	dark_purple = "#c882e7",
	green = "#a1efd3",
	orange = "#fca2aa",
  purple = "#d4bfff",
	red = "#f48fb1",
	yellow = "#ffe9aa",
}

theme.apika = {
	empty = { fg = "none", bg = "none" },

	mode = {
		bg = "none",
		fg = apika_colors["black"],

		Confirm = apika_colors["teal"],
		Command = apika_colors["green"],
		Insert = apika_colors["dark_purple"],
		Normal = apika_colors["blue"],
		Nterminal = apika_colors["yellow"],
		Replace = apika_colors["orange"],
		Select = apika_colors["blue"],
		Terminal = apika_colors["green"],
		Visual = apika_colors["cyan"],
	},

	transparent = apika_colors["white"],

	lsp = {
		Error = apika_colors["red"],
		Warn = apika_colors["yellow"],
		Hint = apika_colors["purple"],
		Info = apika_colors["green"],
	},

	levels = {
		{
			accent = apika_colors["yellow"],
			base = apika_colors["black"],
			bg = "none",
		},
		{
			accent = apika_colors["red"],
			base = apika_colors["black"],
			bg = "none",
		},
		{
			accent = apika_colors["green"],
			base = apika_colors["black"],
			bg = "none",
		},
	},
}

--
-- -- add block highlights for minimal theme
-- local function gen_hl(name, col)
-- 	M.minimal["St_" .. name .. "_bg"] = {
-- 		fg = colors.space0,
-- 		bg = colors[col],
-- 	}
--
-- 	M.minimal["St_" .. name .. "_txt"] = {
-- 		fg = colors[col],
-- 		bg = colors.black,
-- 	}
--
-- 	M.minimal["St_" .. name .. "_sep"] = {
-- 		fg = colors[col],
-- 		bg = colors.space0,
-- 	}
-- end
--
-- gen_hl("file", "red")
-- gen_hl("Pos", "yellow")
-- gen_hl("cwd", "orange")
-- gen_hl("lsp", "green")

return theme
