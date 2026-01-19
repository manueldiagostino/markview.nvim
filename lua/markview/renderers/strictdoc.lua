local strictdoc = {}
local spec = require("markview.spec")
local utils = require("markview.utils")

strictdoc.ns = vim.api.nvim_create_namespace("markview/strictdoc")

-- -- "@string.strictdoc" è il capture standard di TS per le stringhe in strictdoc
-- vim.api.nvim_set_hl(0, "@string.strictdoc", { link = "Normal" })
--
-- -- Facciamo lo stesso per il testo semplice se il parser lo chiama in altro modo
-- vim.api.nvim_set_hl(0, "@text.strictdoc", { link = "Normal" })

vim.api.nvim_set_hl(0, "StrictdocBadgeDoc", {
	bg = "#61afef",
	fg = "#282c34",
	bold = true,
})

vim.api.nvim_set_hl(0, "StrictdocBadgeSection", {
	bg = "#c678dd",
	fg = "#282c34",
	bold = true,
})

vim.api.nvim_set_hl(0, "StrictdocBadgeSectionEnd", {
	fg = "#c678dd",
	bold = true,
})

vim.api.nvim_set_hl(0, "StrictdocBadgeComposite", {
	bg = "#e5c07b",
	fg = "#282c34",
	bold = true,
})

vim.api.nvim_set_hl(0, "StrictdocBadgeCompositeEnd", {
	fg = "#e5c07b",
	bold = true,
})

local function get_conf(key)
	local highlights = spec.get({ "strictdoc", "highlights" }, { fallback = {} })
	local icons = spec.get({ "strictdoc", "icons" }, { fallback = {} })

	local conf_key = "strictdoc_" .. key
	return highlights[conf_key], icons[conf_key]
end

strictdoc.document_title = function(buffer, item)
	local hl, icon = get_conf("document_title")
	if not hl or not icon then
		return
	end

	local range = item.range

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, range.row_start, range.col_start, {
		end_row = range.row_end,
		end_col = range.col_end,
		hl_group = utils.set_hl(hl),
		virt_text = { { icon .. " ", utils.set_hl(hl) } },
		virt_text_pos = "inline",
	})
end

strictdoc.title = function(buffer, item)
	local hl, icon = get_conf("title")
	if not hl or not icon then
		return
	end

	local range = item.range

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, range.row_start, range.col_start, {
		end_row = range.row_end,
		end_col = range.col_end,
		hl_group = utils.set_hl(hl),
		virt_text = { { icon .. " ", utils.set_hl(hl) } },
		virt_text_pos = "inline",
	})
end

strictdoc.conceal = function(buffer, item)
	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, item.range.row_start, item.range.col_start, {
		end_row = item.range.row_end,
		end_col = item.range.col_end,
		conceal = "",
	})
end

strictdoc.link = function(buffer, item)
	local hl, icon = get_conf("link")
	if not hl or not icon then
		return
	end

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, item.range.row_start, item.range.col_start, {
		end_row = item.range.row_end,
		end_col = item.range.col_end,
		conceal = "",
		virt_text = { { icon .. item.text[1], hl } },
		virt_text_pos = "inline",
	})
end

strictdoc.anchor = function(buffer, item)
	local hl, icon = get_conf("anchor")
	if not hl or not icon then
		return
	end

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, item.range.row_start, item.range.col_start, {
		end_row = item.range.row_end,
		end_col = item.range.col_end,
		conceal = "",
		virt_text = { { icon .. item.text[1], hl } },
		virt_text_pos = "inline",
	})
end

strictdoc.uid = function(buffer, item)
	local hl, _ = get_conf("uid")
	if not hl then
		return
	end

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, item.range.row_start, item.range.col_start, {
		end_row = item.range.row_end,
		end_col = item.range.col_end,
		hl_group = hl,
	})
end

strictdoc.block_marker = function(buffer, item)
	local key = "block_" .. item.type
	local hl, icon = get_conf(key)

	if not icon then
		return
	end

	hl = hl or "Comment"

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, item.range.row_start, item.range.col_start, {
		end_row = item.range.row_end,
		end_col = item.range.col_end,
		conceal = "",
		virt_text = { { icon, hl } },
		virt_text_pos = "overlay",
	})
end

strictdoc.marker = function(buffer, item)
	local markers_config = spec.get({ "strictdoc", "markers" }, { fallback = {} })
	if markers_config.enable == false then
		return
	end

	local specific_key = item.text and item.text:lower() or ""
	local conf = markers_config[specific_key]

	if not conf then
		conf = markers_config[item.type]
	end

	if not conf and item.type:match("composite") then
		local suffix = item.type:match("end") and "end" or "start"
		conf = markers_config["composite_" .. suffix]
	end

	if not conf then
		return
	end

	local icon = conf.icon or ""
	local hl = conf.hl or "Comment"

	local text = conf.text
	if item.type == "composite_start" and not markers_config[specific_key] then
		text = " " .. item.text .. " "
	else
		text = text or item.text
	end

	vim.api.nvim_buf_set_extmark(buffer, strictdoc.ns, item.range.row_start, item.range.col_start, {
		end_row = item.range.row_end,
		end_col = item.range.col_end,

		conceal = "",

		virt_text = {
			{ icon, hl },
			{ text, hl },
		},
		virt_text_pos = "inline",
	})
end

strictdoc.render = function(buffer, content)
	local custom = spec.get({ "renderers" }, { fallback = {} })
	for _, item in ipairs(content or {}) do
		local func_name = item.class:gsub("^strictdoc_", "")
		if custom[item.class] then
			pcall(custom[item.class], strictdoc.ns, buffer, item)
		elseif strictdoc[func_name] then
			local success, err = pcall(strictdoc[func_name], buffer, item)
			if not success then
				require("markview.health").print({
					kind = "ERR",
					from = "renderers/strictdoc.lua",
					message = { { tostring(err), "DiagnosticError" } },
				})
			end
		end
	end
end

strictdoc.clear = function(buffer, from, to)
	if not from then
		vim.api.nvim_buf_clear_namespace(buffer, strictdoc.ns, 0, -1)
		return
	end

	local _to = to or -1

	if _to ~= -1 and _to <= from then
		_to = from + 1
	end

	vim.api.nvim_buf_clear_namespace(buffer, strictdoc.ns, from, _to)
end

return strictdoc
