note
	description: "[
		Farewell widget demonstrating custom WIDGET implementation for container nesting.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FAREWELL_WIDGET

inherit
	WIDGET

create
	make

feature {NONE} -- Initialization

	make (a_message: READABLE_STRING_GENERAL)
			-- Initialize farewell with `a_message`.
		do
			message := a_message.as_string_32
		ensure
			message_set: message.same_string_general (a_message)
		end

feature -- Access

	message: STRING_32

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render bordered farewell.
		local
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_border_style, l_text_style: STYLE
		do
			create l_border_style.make_fg ({COLOR}.Magenta)
			create l_text_style.make_fg ({COLOR}.Bright_magenta)
			l_text_style := l_text_style.with_bold

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_border_style).
				with_title (" Farewell Widget ")

			create l_para.make (create {TEXT}.make_styled (message, l_text_style))
			l_para := l_para.with_block (l_block).with_alignment ({TEXT_ALIGNMENT}.center)

			l_para.render (a_area, a_buffer)
		end

end
