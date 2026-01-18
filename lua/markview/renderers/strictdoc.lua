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

strictdoc.document_title = function(buffer, item)
	local main_config = spec.get({ "strictdoc", "highlights" }, { fallback = nil })
	local icons = spec.get({ "strictdoc", "icons" }, { fallback = nil })

	if not main_config or not icons then
		return
	end

	local hl_group = main_config.strictdoc_document_title
	local icon = icons.strictdoc_document_title

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

strictdoc.link = function(buffer, item)
	local config = spec.get({ "strictdoc", "highlights" }, { fallback = {} })
	local hl = config.strictdoc_link or "Underlined"
	local range = item.range

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, range.row_start, range.col_start, {
		end_row = range.row_end,
		end_col = range.col_end,
		conceal = "",
		virt_text = { { "🔗 " .. item.text[1], hl } },
		virt_text_pos = "inline",
	})
end

strictdoc.anchor = function(buffer, item)
	local config = spec.get({ "strictdoc", "highlights" }, { fallback = {} })
	local hl = config.strictdoc_anchor or "Special"
	local range = item.range

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, range.row_start, range.col_start, {
		end_row = range.row_end,
		end_col = range.col_end,
		conceal = "",
		virt_text = { { "⚓ " .. item.text[1], hl } },
		virt_text_pos = "inline",
	})
end

strictdoc.uid = function(buffer, item)
	local config = spec.get({ "strictdoc", "highlights" }, { fallback = {} })
	local hl = config.strictdoc_uid or "Constant"

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, item.range.row_start, item.range.col_start, {
		end_row = item.range.row_end,
		end_col = item.range.col_end,
		hl_group = hl,
	})
end

strictdoc.block_marker = function(buffer, item)
	local range = item.range
	local symbol = item.type == "start" and "❝" or "❞"

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, range.row_start, range.col_start, {
		end_row = range.row_end,
		end_col = range.col_end,
		conceal = "",
		virt_text = { { symbol, "Comment" } },
		virt_text_pos = "overlay",
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
