local strictdoc = {}

local spec = require("markview.spec")
local utils = require("markview.utils")

--- Dedicated namespace for strictdoc
---@type integer
strictdoc.ns = vim.api.nvim_create_namespace("markview/strictdoc")

-- Renders concealed text
---@param buffer integer
---@param item table
strictdoc.conceal = function(buffer, item)
	local range = item.range

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, range.row_start, range.col_start, {
		end_row = range.row_end,
		end_col = range.col_end,

		conceal = "",

		virt_text_pos = "inline",
	})
end

--- Renders the section title
---@param buffer integer
---@param item table
strictdoc.document_title = function(buffer, item)
	-- Retrieve specific configuration for titles
	-- Looks in: spec.config.strictdoc.highlights
	local main_config = spec.get({ "strictdoc", "highlights" }, { fallback = nil })
	local icons = spec.get({ "strictdoc", "icons" }, { fallback = nil })

	-- If configuration is missing, stop rendering
	if not main_config or not icons then
		return
	end

	local hl_group = main_config.strictdoc_document_title
	local icon = icons.strictdoc_document_title

	-- If specific values are missing, stop rendering
	if not hl_group or not icon then
		return
	end

	local range = item.range

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, range.row_start, range.col_start, {
		undo_restore = false,
		invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(hl_group),

		virt_text = {
			{ icon .. " ", utils.set_hl(hl_group) },
		},
		virt_text_pos = "inline",
	})
end

--- Main rendering function (Dispatcher)
---@param buffer integer
---@param content table[]
strictdoc.render = function(buffer, content)
	-- Allows user to inject custom renderers via config
	local custom = spec.get({ "renderers" }, { fallback = {} })

	for _, item in ipairs(content or {}) do
		local success, err

		-- 1. Check if there is a custom renderer for this class
		if custom[item.class] then
			success, err = pcall(custom[item.class], strictdoc.ns, buffer, item)
		else
			-- 2. Otherwise use the internal renderer
			-- Converts "strictdoc_title" -> calls strictdoc.title()
			local func_name = item.class:gsub("^strictdoc_", "")

			if strictdoc[func_name] then
				success, err = pcall(strictdoc[func_name], buffer, item)
			end
		end

		-- 3. Error handling
		if success == false then
			require("markview.health").print({
				kind = "ERR",
				from = "renderers/strictdoc.lua",
				fn = "render() -> " .. item.class,
				message = {
					{ tostring(err), "DiagnosticError" },
				},
			})
		end
	end
end

--- Clears the namespace
---@param buffer integer
---@param from integer?
---@param to integer?
strictdoc.clear = function(buffer, from, to)
	vim.api.nvim_buf_clear_namespace(buffer, strictdoc.ns, from or 0, to or -1)
end

return strictdoc
