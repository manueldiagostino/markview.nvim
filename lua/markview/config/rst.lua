return {
	enable = true,

	highlights = {
		enable = true,

		default = {
			hl = "MarkviewPalette3",
		},

		inline_code = "RstInlineCode",
		bold = "RstBold",
		italic = "RstItalic",
	},

	code_blocks = {
		enable = true,
		style = "block",

		border_hl = "MarkviewCode",
		label_hl = "CursorLine",

		min_width = 80,
		pad_amount = 2,
		pad_char = " ",

		default = {
			icon = "📄",
			block_hl = "MarkviewCode",
			pad_hl = "MarkviewCode",
		},

		["diff"] = {
			block_hl = function(_, line)
				if line:match("^%+") then
					return "MarkviewPalette4"
				elseif line:match("^%-") then
					return "MarkviewPalette1"
				else
					return "MarkviewCode"
				end
			end,
		},
	},

	inline_codes = {
		enable = true,
		hl = "RstInlineCode",

		padding_left = "",
		padding_right = "",

		corner_left = "",
		corner_right = "",
	},

	inline_styles = {
		bold = {
			hl = "RstBold",
			conceal = true,
		},
		italic = {
			hl = "RstItalic",
			conceal = true,
		},
	},

	links = {
		enable = true,

		default = {
			icon = "󰌷 ",
			hl = "MarkviewHyperlink",
		},

		["github%.com/[%a%d%-%_%.]+%/?$"] = {
			icon = " ",
			hl = "MarkviewPalette0Fg",
		},
		["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/?$"] = {
			icon = " ",
			hl = "MarkviewPalette0Fg",
		},
		["stackoverflow%.com"] = {
			icon = "󰓌 ",
			hl = "MarkviewPalette2Fg",
		},
		["reddit%.com"] = {
			icon = " ",
			hl = "MarkviewPalette2Fg",
		},
		["github%.com"] = {
			icon = " ",
			hl = "MarkviewPalette6Fg",
		},
		["gitlab%.com"] = {
			icon = "󰮠 ",
			hl = "MarkviewPalette2Fg",
		},
		["wikipedia%.org"] = {
			icon = "󰖟 ",
			hl = "MarkviewPalette7Fg",
		},
		["jira%."] = {
			icon = " ",
			hl = "MarkviewPalette4Fg",
		},
	},

	headings = {
		enable = true,
		shift_width = 1,

		["="] = {
			level = 1,
			style = "icon",
			icon = "󰼏  ",
			hl = "MarkviewHeading1",
			sign = "󰌕 ",
			sign_hl = "MarkviewHeading1Sign",
		},
		["-"] = {
			level = 2,
			style = "icon",
			icon = "󰎨  ",
			hl = "MarkviewHeading2",
			sign = "󰌖 ",
			sign_hl = "MarkviewHeading2Sign",
		},
		["~"] = {
			level = 3,
			style = "icon",
			icon = "󰼑  ",
			hl = "MarkviewHeading3",
		},
		['"'] = { level = 4, icon = "󰎲  ", hl = "MarkviewHeading4" },
		["^"] = { level = 5, icon = "󰼓  ", hl = "MarkviewHeading5" },
	},

	admonitions = {
		enable = true,

		default = {
			icon = "▎",
			hl = "MarkviewBlockQuoteDefault",
			border = "▋",
		},

		["note"] = {
			icon = "󰋽",
			title = "Note",
			hl = "MarkviewBlockQuoteNote",
		},
		["tip"] = {
			icon = "",
			title = "Tip",
			hl = "MarkviewBlockQuoteOk",
		},
		["warning"] = {
			icon = "",
			title = "Warning",
			hl = "MarkviewBlockQuoteWarn",
		},
		["error"] = {
			icon = "",
			title = "Error",
			hl = "MarkviewBlockQuoteError",
		},
		["danger"] = {
			icon = "⚡",
			title = "Danger",
			hl = "MarkviewBlockQuoteError",
		},
		["attention"] = {
			icon = "",
			title = "Attention",
			hl = "MarkviewBlockQuoteWarn",
		},
	},
}
