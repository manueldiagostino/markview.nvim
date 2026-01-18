return {
	highlights = {
		strictdoc_document_title = "RenderMarkdownH1",
		strictdoc_title = "Title",
		strictdoc_link = "Label",
		strictdoc_anchor = "Function",
		strictdoc_uid = "Constant",
	},

	icons = {
		strictdoc_document_title = "📝",
	},

	callbacks = {
		on_enable = function(_, win)
			vim.wo[win].conceallevel = 2
		end,
	},
}
