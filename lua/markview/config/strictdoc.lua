return {
	highlights = {
		strictdoc_document_title = "RenderMarkdownH1",
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
