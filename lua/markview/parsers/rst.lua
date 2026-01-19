local rst = {}

rst.content = {}
rst.sorted = {}

rst.insert = function(data)
	table.insert(rst.content, data)
	if not rst.sorted[data.class] then
		rst.sorted[data.class] = {}
	end
	table.insert(rst.sorted[data.class], data)
end

rst.process_list = function(buffer, TSNode, type_hint)
	for child in TSNode:iter_children() do
		if child:named() then
			local marker_node = child:field("bullet")[1] or child:field("enumerator")[1]

			if not marker_node then
				local first = child:child(0)
				if first then
					local f_type = first:type()

					if
						type_hint == "number"
						or f_type:match("bullet")
						or f_type:match("enumerator")
						or f_type == "text"
					then
						marker_node = first
					end
				end
			end

			if marker_node then
				local marker_text = vim.treesitter.get_node_text(marker_node, buffer)

				local is_valid = false
				if type_hint == "bullet" and marker_text:match("^[%*%-+•]$") then
					is_valid = true
				elseif type_hint == "number" and marker_text:match("^[(%w]") then
					is_valid = true
				elseif not type_hint then
					is_valid = true
				end

				if is_valid then
					local r_start, c_start, _, c_end = marker_node:range()
					local range = { child:range() }

					local type = type_hint or "bullet"
					if not type_hint and (marker_text:match("^%d") or marker_text:match("^%(")) then
						type = "number"
					end

					rst.insert({
						class = "rst_list_item",
						type = type,
						marker = marker_text,
						range = {
							row_start = range[1],
							col_start = range[2],
							row_end = range[3],
							col_end = range[4],
						},
						marker_row = r_start,
						marker_col_start = c_start,
						marker_col_end = c_end,
					})
				end
			end
		end
	end
end

rst.strong = function(buffer, TSNode, text, range)
	rst.insert({ class = "rst_strong", text = text, range = range })
end

rst.emphasis = function(buffer, TSNode, text, range)
	rst.insert({ class = "rst_emphasis", text = text, range = range })
end

rst.link = function(buffer, TSNode, text, range)
	rst.insert({ class = "rst_link", text = text, range = range, node_type = TSNode:type() })
end

rst.inline_code = function(buffer, TSNode, text, range)
	rst.insert({ class = "rst_inline_code", text = text, range = range })
end

rst.code_block = function(buffer, TSNode, text, range)
	local name_node = TSNode:field("name")[1]
	local body_node = TSNode:field("body")[1]

	if name_node then
		local name = vim.treesitter.get_node_text(name_node, buffer)
		if name ~= "code-block" and name ~= "sourcecode" then
			return
		end
	end

	local language = "text"
	local header_end_row = range.row_end

	if body_node then
		for child in body_node:iter_children() do
			local type = child:type()
			if type == "arguments" then
				language = vim.treesitter.get_node_text(child, buffer):gsub("^%s*", ""):gsub("%s*$", "")
			elseif type == "content" then
				local start_row, _, _, _ = child:range()
				header_end_row = start_row
			end
		end
	end

	rst.insert({
		class = "rst_code_block",
		language = language,
		text = text,
		range = range,
		header_row_end = header_end_row,
	})
end

-- These act as entry points for the container query
rst.bullet_list = function(buffer, TSNode, _, _)
	rst.process_list(buffer, TSNode, "bullet")
end

rst.enumerated_list = function(buffer, TSNode, _, _)
	rst.process_list(buffer, TSNode, "number")
end

rst.parse = function(buffer, TSTree, from, to)
	rst.sorted = {}
	rst.content = {}

	-- Updated query: Capture PARENTS (bullet_list) instead of children (list_item)
	-- This works even if the child node name is "item" or something else.
	local query_string = [[
 		(strong) @rst.strong
 		(emphasis) @rst.emphasis
 		(literal) @rst.inline_code
 		(directive) @rst.code_block
		(reference) @rst.link
		(standalone_hyperlink) @rst.link
		
		(bullet_list) @rst.bullet_list
		(enumerated_list) @rst.enumerated_list
 	]]

	local success, scanned_queries = pcall(vim.treesitter.query.parse, "rst", query_string)
	if not success then
		return {}, {}
	end

	for capture_id, capture_node, _, _ in scanned_queries:iter_captures(TSTree:root(), buffer, from, to) do
		local capture_name = scanned_queries.captures[capture_id]
		if capture_name:match("^rst%.") then
			local func_name = capture_name:gsub("^rst%.", "")

			if rst[func_name] then
				local r_start, c_start, r_end, c_end = capture_node:range()
				local text = vim.treesitter.get_node_text(capture_node, buffer)

				-- We pass the node directly so process_list can iterate children
				pcall(rst[func_name], buffer, capture_node, text, {
					row_start = r_start,
					col_start = c_start,
					row_end = r_end,
					col_end = c_end,
				})
			end
		end
	end

	return rst.content, rst.sorted
end

return rst
