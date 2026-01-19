local strictdoc = {}

strictdoc.markers = {
	enable = true,

	document = {
		text = " DOCUMENT ",
		icon = " ",
		hl = "StrictdocBadgeDoc",
	},

	section_start = {
		text = " SECTION ",
		icon = " ",
		hl = "StrictdocBadgeSection",
	},
	section_end = {
		text = "───────",
		icon = "└",
		hl = "StrictdocBadgeSectionEnd",
	},

	composite_start = {
		text = " REQ ",
		icon = "󰆧 ",
		hl = "StrictdocBadgeComposite",
	},
	composite_end = {
		text = "───────",
		icon = "└",
		hl = "StrictdocBadgeCompositeEnd",
	},
}

strictdoc.markers = {
	enable = true,

	document = {
		text = "DOCUMENT",
		icon = " ",
		hl = "MarkviewPalette1",
	},

	section_start = {
		text = "SECTION",
		icon = " ",
		hl = "MarkviewPalette2",
	},
	section_end = {
		text = "│",
		icon = " ",
		hl = "MarkviewPalette2Fg",
	},

	composite_start = {
		text = "COMPOSITE",
		icon = "󰆧 ",
		hl = "MarkviewPalette4",
	},
	composite_end = {
		text = "│",
		icon = "󰆧 ",
		hl = "MarkviewPalette4Fg",
	},
}

strictdoc.highlights = {
	strictdoc_document_title = "RenderMarkdownH1",
	strictdoc_title = "Title",
	strictdoc_link = "Label",
	strictdoc_anchor = "Special",
	strictdoc_uid = "Constant",

	strictdoc_block_start = "Comment",
	strictdoc_block_end = "Comment",
	strictdoc_inline_code = "StrictDocCode",
}

strictdoc.icons = {
	strictdoc_document_title = "📋",
	strictdoc_title = "📝",

	strictdoc_link = "🔗 ",
	strictdoc_anchor = "⚓ ",

	strictdoc_block_start = "❝",
	strictdoc_block_end = "❞",
}

return strictdoc
