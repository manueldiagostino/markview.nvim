local strictdoc = {}

strictdoc.content = {}
strictdoc.sorted = {}

strictdoc.insert = function(data)
	table.insert(strictdoc.content, data)
	if not strictdoc.sorted[data.class] then
		strictdoc.sorted[data.class] = {}
	end
	table.insert(strictdoc.sorted[data.class], data)
end

-- Handlers
strictdoc.document_title = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_document_title", text = text, range = range })
end

strictdoc.title = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_title", text = text, range = range })
end

strictdoc.conceal = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_conceal", range = range })
end

strictdoc.link = function(buffer, TSNode, text, range)
	-- Extract UID from [LINK: UID]
	local uid = text[1]:match("LINK:%s*([%w%-%_%.]+)") or text[1]
	strictdoc.insert({ class = "strictdoc_link", text = { uid }, range = range })
end

strictdoc.anchor = function(buffer, TSNode, text, range)
	local uid = text[1]:match("ANCHOR:%s*([%w%-%_%.]+)") or text[1]
	strictdoc.insert({ class = "strictdoc_anchor", text = { uid }, range = range })
end

strictdoc.uid = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_uid", text = text, range = range })
end

strictdoc.block_start = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_block_marker", type = "start", range = range })
end

strictdoc.block_end = function(buffer, TSNode, text, range)
	strictdoc.insert({ class = "strictdoc_block_marker", type = "end", range = range })
end

local function insert_marker(type, text, range)
	strictdoc.insert({
		class = "strictdoc_marker",
		type = type,
		text = text,
		range = range,
	})
end

strictdoc.section_start = function(buffer, item, lines, range)
	insert_marker("section_start", "SECTION", range)
end

strictdoc.section_end = function(buffer, item, lines, range)
	insert_marker("section_end", "│", range)
end

strictdoc.document_start = function(buffer, item, lines, range)
	insert_marker("document", "DOCUMENT", range)
end

strictdoc.composite_start = function(buffer, item, lines, range)
	-- Extract clean name from "[[REQUIREMENT]]" or "[[COMPOSITE]]"
	-- item is the TSNode
	local text = vim.treesitter.get_node_text(item, buffer)
	local clean_name = text:gsub("%[%[", ""):gsub("%]%]", ""):gsub("%s+", "")

	insert_marker("composite_start", clean_name, range)
end

strictdoc.composite_end = function(buffer, item, lines, range)
	insert_marker("composite_end", "│", range)
end

strictdoc.parse = function(buffer, TSTree, from, to)
	strictdoc.sorted = {}
	strictdoc.content = {}

	local query_string = [[
		(source_file title: (single_line_string) @strictdoc.document_title)
		
		(source_file 
			"TITLE" @strictdoc.conceal 
			":" @strictdoc.conceal
			" " @strictdoc.conceal
		)

		(section_body 
			"TITLE" @strictdoc.conceal 
			":" @strictdoc.conceal 
			" " @strictdoc.conceal
			title: (single_line_string) @strictdoc.title
		)

		(inline_link) @strictdoc.link
		(anchor) @strictdoc.anchor

		(multiline_opening_token) @strictdoc.block_start
		(multiline_closing_token) @strictdoc.block_end

		(sdoc_node_field_uid (uid_string) @strictdoc.uid)
		"[SECTION]" @strictdoc.section_start
		"[/SECTION]" @strictdoc.section_end
		"[DOCUMENT]" @strictdoc.document_start
		
		(sdoc_composite_node_opening) @strictdoc.composite_start
		(sdoc_composite_node_closing) @strictdoc.composite_end

		(single_line_string) @strictdoc.text
		(multi_line_string) @strictdoc.text
		(single_line_text_part) @strictdoc.text
	]]

	local scanned_queries = vim.treesitter.query.parse("strictdoc", query_string)

	for capture_id, capture_node, _, _ in scanned_queries:iter_captures(TSTree:root(), buffer, from, to) do
		local capture_name = scanned_queries.captures[capture_id]
		if not capture_name:match("^strictdoc%.") then
			goto continue
		end

		local capture_text = vim.treesitter.get_node_text(capture_node, buffer)
		local r_start, c_start, r_end, c_end = capture_node:range()

		-- Append newline if missing for text processing
		if not capture_text:match("\n$") then
			capture_text = capture_text .. "\n"
		end

		local lines = {}
		for line in capture_text:gmatch("(.-)\n") do
			table.insert(lines, line)
		end

		local func_name = capture_name:gsub("^strictdoc%.", "")
		local success, err = pcall(strictdoc[func_name], buffer, capture_node, lines, {
			row_start = r_start,
			col_start = c_start,
			row_end = r_end,
			col_end = c_end,
		})

		if not success then
			require("markview.health").print({
				kind = "ERR",
				from = "parsers/strictdoc.lua",
				message = { { tostring(err), "DiagnosticError" } },
			})
		end
		::continue::
	end

	return strictdoc.content, strictdoc.sorted
end

return strictdoc
