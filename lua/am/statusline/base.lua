local base = {
	modes = {
		["c"] = "Command",
		["cv"] = "Command",
		["ce"] = "Command",

		["r"] = "Confirm",
		["rm"] = "ConfirmMore",
		["r?"] = "ConfirmAsk",
		["x"] = "ConfirmAsk",

		["i"] = "Insert",
		["ic"] = "Insert",
		["ix"] = "Insert",

		["n"] = "Normal",
		["no"] = "Normal",
		["nov"] = "Normal",
		["noV"] = "Normal",
		["noCTRL-V"] = "Normal",
		["niI"] = "Normal",
		["niR"] = "Normal",
		["niV"] = "Normal",

		["nt"] = "NTerminal",
		["ntT"] = "NTerminal",

		["R"] = "Replace",
		["Rc"] = "Replace",
		["Rx"] = "Replace",
		["Rv"] = "Replace",
		["Rvc"] = "Replace",
		["Rvx"] = "Replace",

		["s"] = "Select",
		["S"] = "Select",
		-- [""] = "Select",

		["t"] = "Terminal",
		["!"] = "Terminal",

		["v"] = "Visual",
		["vs"] = "Visual",
		["V"] = "Visual",
		["Vs"] = "Visual",
		[""] = "Visual",
	},
}

--- Possible sides for component position
--- Values:
--- >lua
---  AMStatusline,SIDES = {
--- 	 Left = 0,
---  	 Center = 1,
--- 	 Right = 2,
---  }
--- <
---
---@enum ContextSide
---@tag AM-Statusline-context-sides
base.SIDES = {
	Left = 0,
	Center = 1,
	Right = 2,
}

function base.is_activewin()
	return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

function base.mode()
	return vim.api.nvim_get_mode().mode
end

function base.mode_norm()
  local m = base.mode() or "Empty"
  local n = base.modes[m]

  if n == nil then
    vim.notify_once("Unknown mode: " .. m)
  end

	return n or m
end

function base.stbufnr()
	return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

function base.filename()
	local path = vim.api.nvim_buf_get_name(base.stbufnr())
	local name = (path == "" and "Empty") or path:match("([^/\\]+)[/\\]*$")

	return name
end

---Resolve component just for render purposes
---@param component StatuslineComponent<string?>?
---@return StatuslineResolvedComponent<string>
function base.resolve_render(component)
	if component == nil then
		return function()
			return ""
		end
	end

	if type(component) == "function" then
		return function(ctx)
			return component(ctx) or ""
		end
	end

	if type(component) == "string" then
		return function()
			return component
		end
	end

	vim.notify("Component must be a function or string, but got: " .. type(component), vim.log.levels.WARN)

	return function()
		vim.notify_once(
			"[RENDER] Component must be a function or string, but got: " .. type(component),
			vim.log.levels.WARN
		)
		return ""
	end
end

---Resolve component just for render purposes
---@param component? StatuslineComponent
---@param config ModuleConfig
---@param ctx StatuslineContext
---@return StatuslineResolvedComponent
function base.resolve(component, config, ctx)
	if type(component) == "function" then
		return base.resolve_render(component(config, ctx))
	end

	return base.resolve_render(component)
end

---@generic T
---@param opts T?
---@param defaults T?
---@return T
function base.scoped_opts(opts, defaults)
	return vim.tbl_deep_extend("force", defaults or {}, vim.g.statusline_scope_opts or {}, opts or {})
end

---@generic OPTS
---@generic T
---@param on_start fun(opts: OPTS, config: ModuleConfig, ctx: StatuslineContext): T
---@param on_render fun(opts: T, ctx: StatuslineContext, config: ModuleConfig): string?
---@return fun(opts: OPTS, ...: StatuslineComponent[]): StatuslineComponent<string?>
function base.component(on_start, on_render)
	return function(opts, ...)
		local last_opts
		local children = { ... }

		opts = opts or {}

		return function(config, ctx)
			opts.children = children
			last_opts = on_start(opts, config, ctx)

			return function(ctx_)
				return base.resolve(on_render(last_opts, ctx_, config), config, ctx_)(ctx_)
			end
		end
	end
end

return base
