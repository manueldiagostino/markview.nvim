local strictdoc = {}

--- Queried contents
---@type table[]
strictdoc.content = {}

--- Queried contents, but sorted
---@type { [string]: table[] }
strictdoc.sorted = {}

--- Custom `table.insert()` function.
---@param data any
strictdoc.insert = function(data)
	table.insert(strictdoc.content, data)

	if not strictdoc.sorted[data.class] then
		strictdoc.sorted[data.class] = {}
	end

	table.insert(strictdoc.sorted[data.class], data)
end

strictdoc.conceal = function(buffer, TSNode, text, range)
	strictdoc.insert({
		class = "strictdoc_conceal",
		range = range,
	})
end

--- StrictDoc document title parser
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range markview.parsed.range
strictdoc.document_title = function(buffer, TSNode, text, range)
	strictdoc.insert({
		class = "strictdoc_document_title",
		text = text,
		range = range,
	})
end

strictdoc.link = function(buffer, TSNode, text, range)
	local uid = text[1]:match("LINK:%s*([%w%-%_%.]+)") or text[1]

	strictdoc.insert({
		class = "strictdoc_link",
		text = { uid },
		range = range,
	})
end

strictdoc.anchor = function(buffer, TSNode, text, range)
	local uid = text[1]:match("ANCHOR:%s*([%w%-%_%.]+)") or text[1]
	strictdoc.insert({
		class = "strictdoc_anchor",
		text = { uid },
		range = range,
	})
end

strictdoc.block_start = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_block_marker", type = "start", range = range })
end

strictdoc.block_end = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_block_marker", type = "end", range = range })
end

strictdoc.uid = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_uid", text = text, range = range })
end

--- StrictDoc parser function.
---@param buffer integer
---@param TSTree table
---@param from integer?
---@param to integer?
---@return markview.parsed.strictdoc[]
---@return markview.parsed.strictdoc_sorted
strictdoc.parse = function(buffer, TSTree, from, to)
	--- Clear the previous contents
	strictdoc.sorted = {}
	strictdoc.content = {}

	local scanned_queries = vim.treesitter.query.parse(
		"strictdoc",
		[[
		(source_file
			"TITLE" @strictdoc.conceal
			":" @strictdoc.conceal
			title: (single_line_string) @strictdoc.document_title
		)
        (inline_link) @strictdoc.link
        (anchor) @strictdoc.anchor

        (multiline_opening_token) @strictdoc.block_start
        (multiline_closing_token) @strictdoc.block_end

        (sdoc_node_field_uid (uid_string) @strictdoc.uid)
		]]
	)

	for capture_id, capture_node, _, _ in scanned_queries:iter_captures(TSTree:root(), buffer, from, to) do
		---@type string
		local capture_name = scanned_queries.captures[capture_id]

		if not capture_name:match("^strictdoc%.") then
			goto continue
		end

		---@type string?
		local capture_text = vim.treesitter.get_node_text(capture_node, buffer)
		local r_start, c_start, r_end, c_end = capture_node:range()

		if capture_text == nil then
			goto continue
		end

		--- If a node doesn't end with \n, Add it.
		if not capture_text:match("\n$") then
			capture_text = capture_text .. "\n"
		end

		--- Turn the texts into list of lines.
		---@type string[]
		local lines = {}

		for line in capture_text:gmatch("(.-)\n") do
			table.insert(lines, line)
		end

		---@type boolean, string
		local success, err = pcall(strictdoc[capture_name:gsub("^strictdoc%.", "")], buffer, capture_node, lines, {
			row_start = r_start,
			col_start = c_start,

			row_end = r_end,
			col_end = c_end,
		})

		if success == false then
			require("markview.health").print({
				kind = "ERR",

				from = "parsers/strictdoc.lua",
				fn = "parse()",

				message = {
					{ tostring(err), "DiagnosticError" },
				},
			})
		end

		::continue::
	end

	return strictdoc.content, strictdoc.sorted
end

return strictdoc
