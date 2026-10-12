note
	description: "[
		Greeting widget demonstrating custom WIDGET implementation for container nesting.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	GREETING_WIDGET

inherit
	WIDGET

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- Initialize greeting with `a_name`.
		do
			name := a_name.as_string_32
		ensure
			name_set: name.same_string_general (a_name)
		end

feature -- Access

	name: STRING_32

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render bordered greeting.
		local
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_border_style, l_text_style: STYLE
		do
			create l_border_style.make_fg ({COLOR}.Green)
			create l_text_style.make_fg ({COLOR}.Bright_green)
			l_text_style := l_text_style.with_bold

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_border_style).
				with_title (" Greeting Widget ")

			create l_para.make (create {TEXT}.make_styled ({STRING_32} "Hello, " + name + {STRING_32} "! Welcome to polymorphic EiffelTUI!", l_text_style))
			l_para := l_para.with_block (l_block).with_alignment ({TEXT_ALIGNMENT}.center)

			l_para.render (a_area, a_buffer)
		end

end
