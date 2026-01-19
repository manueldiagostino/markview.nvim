local rst = {}
rst.ns = vim.api.nvim_create_namespace("markview/rst")

local spec = require("markview.spec")
local utils = require("markview.utils")
local filetypes = require("markview.filetypes")

vim.api.nvim_set_hl(0, "RstInlineCode", {
	bg = "#3E4145",
	fg = "#D19A66",
	italic = true,
	default = true,
})

vim.api.nvim_set_hl(0, "RstBold", {
	bold = true,
	fg = "#f06e5e",
	default = true,
})

vim.api.nvim_set_hl(0, "RstItalic", {
	italic = true,
	fg = "#C6789D",
	default = true,
})

local function get_component_config(component_name, fallback_table)
	local rst_conf = spec.get({ "rst", component_name }, { fallback = nil })
	if rst_conf then
		return rst_conf
	end

	if fallback_table then
		return spec.get(fallback_table, { fallback = nil })
	end
	return nil
end

local function get_target_width(buffer, pad_amount)
	local win = utils.buf_getwin(buffer)
	if not win then
		return 80
	end

	local cc = vim.wo[win].colorcolumn
	if cc and cc ~= "" then
		local first_cc = vim.split(cc, ",")[1]
		if first_cc:match("^[+-]") then
			local tw = vim.bo[buffer].textwidth
			if tw > 0 then
				return tw + tonumber(first_cc)
			end
		elseif tonumber(first_cc) then
			return tonumber(first_cc)
		end
	end

	local tw = vim.bo[buffer].textwidth
	if tw and tw > 0 then
		return tw
	end

	local win_width = vim.api.nvim_win_get_width(win)
	local textoff = vim.fn.getwininfo(win)[1].textoff
	return math.max(20, win_width - textoff - (pad_amount or 0))
end

local function render_inline(buffer, item, hl_conf_key, default_hl, delim_len, decorations)
	local range = item.range
	local hl_group = spec.get({ "rst", "highlights", hl_conf_key }, { fallback = default_hl })

	vim.api.nvim_buf_set_extmark(buffer, rst.ns, range.row_start, range.col_start, {
		end_row = range.row_end,
		end_col = range.col_end,
		hl_group = hl_group,
		priority = 200,
	})

	local left_virt = nil
	if decorations then
		local text = (decorations.corner_left or "") .. (decorations.padding_left or "")
		if text ~= "" then
			left_virt = { { text, hl_group } }
		end
	end

	vim.api.nvim_buf_set_extmark(buffer, rst.ns, range.row_start, range.col_start, {
		end_row = range.row_start,
		end_col = range.col_start + delim_len,
		conceal = "",
		virt_text = left_virt,
		virt_text_pos = "inline",
	})

	local right_virt = nil
	if decorations then
		local text = (decorations.padding_right or "") .. (decorations.corner_right or "")
		if text ~= "" then
			right_virt = { { text, hl_group } }
		end
	end

	vim.api.nvim_buf_set_extmark(buffer, rst.ns, range.row_end, range.col_end - delim_len, {
		end_row = range.row_end,
		end_col = range.col_end,
		conceal = "",
		virt_text = right_virt,
		virt_text_pos = "inline",
	})
end

rst.inline_code = function(buffer, item)
	local config = spec.get({ "rst", "inline_codes" }, { fallback = {} })
	local hl = config.hl or "RstInlineCode"

	render_inline(buffer, item, "inline_code", hl, 2, config)
end

rst.strong = function(buffer, item)
	render_inline(buffer, item, "bold", "MarkviewStrong", 2, nil)
end

rst.emphasis = function(buffer, item)
	render_inline(buffer, item, "italic", "MarkviewEmphasis", 1, nil)
end

rst.link = function(buffer, item)
	local config = spec.get({ "rst", "links" }, { fallback = {} })
	if config.enable == false then
		return
	end

	local raw_text = type(item.text) == "table" and table.concat(item.text, "") or item.text or ""

	local text_content = raw_text:gsub("\n", " "):gsub("%s+", " ")

	local label, url

	if item.node_type == "standalone_hyperlink" then
		label = text_content
		url = text_content
	else
		local l_match, u_match = text_content:match("^`(.+)%s+<(.+)>`_?_?$")

		if l_match and u_match then
			label = l_match
			url = u_match
		else
			return
		end
	end

	local icon = config.default and config.default.icon or "󰌷 "
	local hl = config.default and config.default.hl or "MarkviewHyperlink"

	for pattern, conf in pairs(config) do
		if pattern ~= "enable" and pattern ~= "default" and url:match(pattern) then
			icon = conf.icon or icon
			hl = conf.hl or hl
			break
		end
	end

	vim.api.nvim_buf_set_extmark(buffer, rst.ns, item.range.row_start, item.range.col_start, {
		end_row = item.range.row_end,
		end_col = item.range.col_end,
		conceal = "",
		virt_text = {
			{ icon, hl },
			{ label, hl },
		},
		virt_text_pos = "inline",
	})
end

rst.code_block = function(buffer, item)
	local config = get_component_config("code_blocks", { "markdown", "code_blocks" })

	if not config or config.enable == false then
		return
	end

	local decorations = filetypes.get(item.language)
	local icon = decorations.icon or "📄"
	local name = decorations.name or item.language
	local label_text = string.format(" %s %s ", icon, name)
	local label_hl = config.label_hl or "CursorLine"

	local code_start_row = item.header_row_end
	local range = item.range

	vim.api.nvim_buf_set_extmark(buffer, rst.ns, range.row_start, range.col_start, {
		end_row = code_start_row,
		end_col = 0,
		conceal = "",
	})

	local function get_line_config(line)
		return utils.match(config, item.language, {
			eval_args = { buffer, line },
			def_fallback = { block_hl = config.border_hl, pad_hl = config.border_hl },
			fallback = { block_hl = config.border_hl, pad_hl = config.border_hl },
		})
	end

	local pad_amount = config.pad_amount or 2
	local target_width = get_target_width(buffer, pad_amount)

	if config.style == "block" then
		local pad_char = config.pad_char or " "

		for l = code_start_row, range.row_end do
			local line_text = vim.api.nvim_buf_get_lines(buffer, l, l + 1, false)[1]
			if not line_text then
				break
			end

			local line_conf = get_line_config(line_text)
			local width = vim.fn.strdisplaywidth(line_text)
			local fill_space = math.max(0, target_width - width - (pad_amount * 2))
			local virt_elements = {}

			if l == code_start_row then
				local badge_width = vim.fn.strdisplaywidth(label_text)
				local total_right_space = fill_space + pad_amount
				local space_before_badge = math.max(0, total_right_space - badge_width)

				table.insert(
					virt_elements,
					{ string.rep(pad_char, space_before_badge), utils.set_hl(line_conf.block_hl) }
				)
				table.insert(virt_elements, { label_text, label_hl })
			else
				table.insert(virt_elements, { string.rep(pad_char, fill_space), utils.set_hl(line_conf.block_hl) })
				table.insert(virt_elements, { string.rep(pad_char, pad_amount), utils.set_hl(line_conf.pad_hl) })
			end

			vim.api.nvim_buf_set_extmark(buffer, rst.ns, l, #line_text, {
				virt_text_pos = "inline",
				virt_text = virt_elements,
				hl_mode = "combine",
			})

			vim.api.nvim_buf_set_extmark(buffer, rst.ns, l, 0, {
				end_row = l + 1,
				hl_group = utils.set_hl(line_conf.block_hl),
			})
		end
	elseif config.style == "simple" then
		for l = code_start_row, range.row_end do
			local line_text = vim.api.nvim_buf_get_lines(buffer, l, l + 1, false)[1]
			if not line_text then
				break
			end
			local line_conf = get_line_config(line_text)
			vim.api.nvim_buf_set_extmark(buffer, rst.ns, l, 0, {
				line_hl_group = utils.set_hl(line_conf.block_hl),
			})
		end
	end
end

rst.list_item = function(buffer, item)
	local config = spec.get({ "rst", "list_items" }, { fallback = {} })
	if config.enable == false then
		return
	end

	local bullet_icon = config.marker_bullet or "•"
	local bullet_hl = config.marker_bullet_hl or "MarkviewPalette4Fg"
	local number_hl = config.marker_number_hl or "MarkviewPalette5Fg"

	local symbol = ""
	local hl_group = ""

	if item.type == "bullet" then
		if type(bullet_icon) == "table" then
			symbol = bullet_icon[item.marker] or bullet_icon.default or "•"
		else
			symbol = bullet_icon
		end
		hl_group = bullet_hl
	elseif item.type == "number" then
		symbol = item.marker
		hl_group = number_hl
	end

	vim.api.nvim_buf_set_extmark(buffer, rst.ns, item.marker_row, item.marker_col_start, {
		end_row = item.marker_row,
		end_col = item.marker_col_end,
		conceal = "",
		virt_text = { { symbol, hl_group } },
		virt_text_pos = "inline",
	})
end

rst.render = function(buffer, content)
	for _, item in ipairs(content or {}) do
		local func_name = item.class:gsub("^rst_", "")
		if rst[func_name] then
			pcall(rst[func_name], buffer, item)
		end
	end
end

rst.clear = function(buffer, from, to)
	vim.api.nvim_buf_clear_namespace(buffer, rst.ns, from or 0, to or -1)
end

return rst
