note
	description: "[
		A message dialog (P2b U2): a box with a title, a word-wrapped message and a row of 1 to
		4 buttons, drawn over the rest of the frame while its DIALOG_STATE is open. Ratatui has
		no dialog widget; applications draw one as a `Clear`, a `Block` and their own buttons,
		which is what this widget draws, on a TUI_POPUP with TUI_BUTTONs.

		    confirm := create {DIALOG_STATE}.make_confirm
		    confirm.set_focus_manager (focus)
		    confirm.set_answered_action (agent on_confirm)
		    confirm.open
		    ...
		    frame.render_stateful_widget ((create {TUI_DIALOG}).with_title (" Confirm ")
		            .with_message (create {TEXT}.make_raw ("Delete report.txt?"))
		            .with_kind ({DIALOG_KIND}.question),
		        frame.area, confirm)

		Render it last, into the whole frame area, every frame: it draws nothing while the
		state is closed. DIALOG_STATE has the keys, the clicks and the answer.

		Layout (in the area given, normally the frame's):
		  * The message is word-wrapped (TEXT_LAYOUT, leading and trailing blanks of each row
		    trimmed) to `max_width` - 4 columns (two borders and one column of padding on each
		    side), or to the area's width - 4 when that is less. Each row is aligned by its own
		    alignment, else the TEXT's; a TEXT without one is centred.
		  * Width: the widest of the wrapped message, the button row and the title (title + 2,
		    at most `max_width`), plus 4; at most the area's width.
		  * Height: the message rows, one blank row, the button row and the two borders.
		  * The box is centred in the area.
		  * Too small an area: the message rows are cut first (the last ones go); then the box
		    is cut to the area, the blank row going before the button row, which is kept as
		    long as the box has one row inside its borders.
		  * Buttons: TUI_BUTTONs ("[ label ]", `button_style`, `focused_button_style` on the
		    focused one), each as wide as it draws, laid out with LAYOUT (FLEX_JUSTIFY.center,
		    `button_spacing` columns apart) on the last row inside the box, between the
		    paddings. A row wider than that has every label cut to the same largest width
		    that fits, per grapheme cluster, never below one cluster.
		  * Body: `with_body` puts a widget where the message goes (a prompt's TUI_TEXT_INPUT,
		    for instance), `body_height` rows high and as wide as `max_width` allows; it is
		    cut like the message. `body_area` tells a stateful body where to render:

		        frame.render_stateful_widget (dialog, frame.area, prompt)
		        frame.render_stateful_widget (create {TUI_TEXT_INPUT},
		            dialog.body_area (frame.area, prompt), name_input)

		Look: the box is a TUI_POPUP (the cells under it cleared) with all borders of
		`border_type`, `style` patched over it, the border in the kind's style (`kind_style`,
		DIALOG_KIND), the title on the top border (`title_alignment`, centred by default), and
		`shadow` (dimmed by default: DIMMED_EFFECT, the cells under it stay readable).
		`with_theme` takes `style` from the theme's base, the kinds from its `info`, `warning`,
		`error` and `primary` styles, and the focused button from its `highlight`.

		Hit regions (FRAME.render_stateful_widget registers them; the widget is a
		HIT_CONTAINER with state), while the state is open: first the state's `popup`, which is
		modal while the dialog's focus scope is open, so everything rendered before the dialog
		hits nothing and anything registered after it is clipped to the box (without a focus
		manager, the same modal is registered directly: a dialog is always modal for the
		mouse); then the body, if any; then each button drawn, under its `button_id`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_DIALOG

inherit
	STATEFUL_WIDGET [DIALOG_STATE]
		redefine
			default_create,
			is_equal
		end

	HIT_CONTAINER
		redefine
			default_create,
			is_equal,
			register_child_hits_with_state
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Dialog with no title and an empty message, an info kind, plain borders, a
			-- dimmed shadow, at most `Default_max_width` columns wide, buttons
			-- `Default_button_spacing` columns apart, the focused one reversed.
		do
			create message.make_empty
			body_height := 1
			kind := {DIALOG_KIND}.info
			border_type := {BORDER_TYPE}.plain
			title_alignment := {TEXT_ALIGNMENT}.center
			shadow := Dimmed_shadow
			max_width := Default_max_width
			button_spacing := Default_button_spacing
			create style
			create info_style.make_fg ({COLOR}.cyan)
			create warning_style.make_fg ({COLOR}.yellow)
			create error_style.make_fg ({COLOR}.red)
			create question_style.make_fg ({COLOR}.blue)
			create button_style
			focused_button_style := (create {STYLE}).with_reverse
		ensure then
			no_title: title = Void
			empty_message: message.is_empty
			no_body: body = Void
			info: kind = {DIALOG_KIND}.info
			plain: border_type = {BORDER_TYPE}.plain
			dimmed_shadow: shadow = Dimmed_shadow
			default_width: max_width = Default_max_width
			default_spacing: button_spacing = Default_button_spacing
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	title: detachable IMMUTABLE_STRING_32
			-- Text on the top border, or Void for none

	title_alignment: NATURAL_8
			-- Place of the title on the top border (TEXT_ALIGNMENT)

	message: TEXT
			-- Text shown above the buttons (word-wrapped), unless there is a `body`

	body: detachable WIDGET
			-- Widget shown instead of the message, or Void

	body_height: NATURAL_16
			-- Rows given to `body`

	kind: NATURAL_8
			-- Kind of the dialog (DIALOG_KIND), which chooses the border style

	border_type: NATURAL_8
			-- Box corners and edges (BORDER_TYPE)

	shadow: detachable SHADOW
			-- Shadow of the box, or Void for none

	max_width: NATURAL_16
			-- Width the message is wrapped for, borders and padding included

	button_spacing: NATURAL_16
			-- Columns between two buttons

	style: STYLE
			-- Style patched over the box

	info_style: STYLE
			-- Border style of an info dialog

	warning_style: STYLE
			-- Border style of a warning dialog

	error_style: STYLE
			-- Border style of an error dialog

	question_style: STYLE
			-- Border style of a question dialog

	button_style: STYLE
			-- `style` of each button

	focused_button_style: STYLE
			-- `focused_style` of each button, shown on the focused one

	kind_style (a_kind: NATURAL_8): STYLE
			-- Border style of a dialog of kind `a_kind`
		require
			valid_kind: {DIALOG_KIND}.is_valid (a_kind)
		do
			inspect a_kind
			when {DIALOG_KIND}.warning then
				Result := warning_style
			when {DIALOG_KIND}.error then
				Result := error_style
			when {DIALOG_KIND}.question then
				Result := question_style
			else
				Result := info_style
			end
		ensure
			result_not_void: Result /= Void
		end

	Default_max_width: NATURAL_16 = 60
			-- `max_width` of a new dialog

	Default_button_spacing: NATURAL_16 = 2
			-- `button_spacing` of a new dialog

	Minimum_width: NATURAL_16 = 5
			-- Narrowest `max_width`: two borders, two columns of padding and one of text

	Dimmed_shadow: SHADOW
			-- Default shadow: dims the cells under it and keeps their symbols
		once
			create Result.make_custom (create {DIMMED_EFFECT})
		ensure
			result_not_void: Result /= Void
		end

feature -- Geometry

	box_area (a_area: RECT; a_state: DIALOG_STATE): RECT
			-- Box of the dialog for `a_state` rendered into `a_area`, shadow not included
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		do
			Result := layout (a_area, a_state).box
		ensure
			result_not_void: Result /= Void
			inside: Result.is_empty or else a_area.contains_rect (Result)
		end

	body_area (a_area: RECT; a_state: DIALOG_STATE): RECT
			-- Where the message (or the body) is drawn for `a_state` rendered into `a_area`
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		do
			Result := layout (a_area, a_state).body
		ensure
			result_not_void: Result /= Void
		end

	button_areas (a_area: RECT; a_state: DIALOG_STATE): ARRAYED_LIST [RECT]
			-- Where each button of `a_state` is drawn when rendered into `a_area` (empty for a
			-- button not drawn), in button order
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		do
			Result := layout (a_area, a_state).buttons
		ensure
			result_not_void: Result /= Void
			one_per_button: Result.count = a_state.button_count
		end

	shown_labels (a_area: RECT; a_state: DIALOG_STATE): ARRAYED_LIST [STRING_32]
			-- Labels of the buttons of `a_state` as drawn into `a_area`: cut when the row is too
			-- wide (see the class note)
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		do
			Result := layout (a_area, a_state).labels
		ensure
			result_not_void: Result /= Void
			one_per_button: Result.count = a_state.button_count
			never_empty: across Result as l all not l.is_empty end
		end

feature -- Element change

	set_title (a_title: detachable READABLE_STRING_GENERAL)
			-- Show `a_title` on the top border (Void: none).
		do
			if attached a_title as t then
				create title.make_from_string_general (t)
			else
				title := Void
			end
		ensure
			title_set: attached a_title as t implies (attached title as l_t and then l_t.same_string_general (t))
			no_title: a_title = Void implies title = Void
		end

	set_title_alignment (a_alignment: NATURAL_8)
			-- Place the title by `a_alignment` (TEXT_ALIGNMENT).
		require
			valid_alignment: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		do
			title_alignment := a_alignment
		ensure
			title_alignment_set: title_alignment = a_alignment
		end

	set_message (a_message: TEXT)
			-- Show `a_message` above the buttons (and no body).
		require
			message_not_void: a_message /= Void
		do
			message := a_message
			body := Void
		ensure
			message_set: message = a_message
			no_body: body = Void
		end

	set_body (a_body: detachable WIDGET)
			-- Show `a_body` instead of the message (Void: the message again).
		do
			body := a_body
		ensure
			body_set: body = a_body
		end

	set_body_height (a_height: NATURAL_16)
			-- Give `body` `a_height` rows.
		do
			body_height := a_height
		ensure
			body_height_set: body_height = a_height
		end

	set_kind (a_kind: NATURAL_8)
			-- Make the dialog of kind `a_kind`.
		require
			valid_kind: {DIALOG_KIND}.is_valid (a_kind)
		do
			kind := a_kind
		ensure
			kind_set: kind = a_kind
		end

	set_border_type (a_type: NATURAL_8)
			-- Draw the box with `a_type` corners and edges.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			border_type := a_type
		ensure
			border_type_set: border_type = a_type
		end

	set_shadow (a_shadow: detachable SHADOW)
			-- Cast `a_shadow` (Void: none).
		do
			shadow := a_shadow
		ensure
			shadow_set: shadow = a_shadow
		end

	set_max_width (a_width: NATURAL_16)
			-- Wrap the message for a box at most `a_width` columns wide.
		require
			room_for_text: a_width >= Minimum_width
		do
			max_width := a_width
		ensure
			max_width_set: max_width = a_width
		end

	set_button_spacing (a_spacing: NATURAL_16)
			-- Put `a_spacing` columns between two buttons.
		do
			button_spacing := a_spacing
		ensure
			button_spacing_set: button_spacing = a_spacing
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over the box.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_kind_style (a_kind: NATURAL_8; a_style: STYLE)
			-- Draw the border of a dialog of kind `a_kind` in `a_style`.
		require
			valid_kind: {DIALOG_KIND}.is_valid (a_kind)
			style_not_void: a_style /= Void
		do
			inspect a_kind
			when {DIALOG_KIND}.warning then
				warning_style := a_style
			when {DIALOG_KIND}.error then
				error_style := a_style
			when {DIALOG_KIND}.question then
				question_style := a_style
			else
				info_style := a_style
			end
		ensure
			kind_style_set: kind_style (a_kind) = a_style
		end

	set_button_style (a_style: STYLE)
			-- Give each button the style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			button_style := a_style
		ensure
			button_style_set: button_style = a_style
		end

	set_focused_button_style (a_style: STYLE)
			-- Patch `a_style` over the focused button.
		require
			style_not_void: a_style /= Void
		do
			focused_button_style := a_style
		ensure
			focused_button_style_set: focused_button_style = a_style
		end

	set_theme (a_theme: TUI_THEME)
			-- Take `style` from `a_theme.base`, the kind styles from its `info`, `warning`,
			-- `error` and `primary` styles, and `focused_button_style` from its `highlight`.
		require
			theme_not_void: a_theme /= Void
		do
			style := a_theme.base
			info_style := a_theme.info
			warning_style := a_theme.warning
			error_style := a_theme.error
			question_style := a_theme.primary
			focused_button_style := a_theme.highlight
		ensure
			style_set: style = a_theme.base
			info_set: info_style = a_theme.info
			warning_set: warning_style = a_theme.warning
			error_set: error_style = a_theme.error
			question_set: question_style = a_theme.primary
			focused_set: focused_button_style = a_theme.highlight
		end

feature -- Fluent Builders

	with_title (a_title: detachable READABLE_STRING_GENERAL): like Current
			-- Copy of Current with `a_title` on the top border (Void: none).
		do
			Result := twin
			Result.set_title (a_title)
		ensure
			result_not_void: Result /= Void
			title_set: attached a_title as t implies (attached Result.title as l_t and then l_t.same_string_general (t))
		end

	with_title_alignment (a_alignment: NATURAL_8): like Current
			-- Copy of Current placing the title by `a_alignment`.
		require
			valid_alignment: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		do
			Result := twin
			Result.set_title_alignment (a_alignment)
		ensure
			result_not_void: Result /= Void
			title_alignment_set: Result.title_alignment = a_alignment
		end

	with_message (a_message: TEXT): like Current
			-- Copy of Current showing `a_message` (and no body).
		require
			message_not_void: a_message /= Void
		do
			Result := twin
			Result.set_message (a_message)
		ensure
			result_not_void: Result /= Void
			message_set: Result.message = a_message
			no_body: Result.body = Void
		end

	with_body (a_body: detachable WIDGET): like Current
			-- Copy of Current showing `a_body` instead of the message.
		do
			Result := twin
			Result.set_body (a_body)
		ensure
			result_not_void: Result /= Void
			body_set: Result.body = a_body
		end

	with_body_height (a_height: NATURAL_16): like Current
			-- Copy of Current giving the body `a_height` rows.
		do
			Result := twin
			Result.set_body_height (a_height)
		ensure
			result_not_void: Result /= Void
			body_height_set: Result.body_height = a_height
		end

	with_kind (a_kind: NATURAL_8): like Current
			-- Copy of Current of kind `a_kind`.
		require
			valid_kind: {DIALOG_KIND}.is_valid (a_kind)
		do
			Result := twin
			Result.set_kind (a_kind)
		ensure
			result_not_void: Result /= Void
			kind_set: Result.kind = a_kind
		end

	with_border_type (a_type: NATURAL_8): like Current
			-- Copy of Current drawing the box with `a_type`.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			Result := twin
			Result.set_border_type (a_type)
		ensure
			result_not_void: Result /= Void
			border_type_set: Result.border_type = a_type
		end

	with_shadow (a_shadow: detachable SHADOW): like Current
			-- Copy of Current casting `a_shadow` (Void: none).
		do
			Result := twin
			Result.set_shadow (a_shadow)
		ensure
			result_not_void: Result /= Void
			shadow_set: Result.shadow = a_shadow
		end

	with_max_width (a_width: NATURAL_16): like Current
			-- Copy of Current wrapping the message for a box at most `a_width` columns wide.
		require
			room_for_text: a_width >= Minimum_width
		do
			Result := twin
			Result.set_max_width (a_width)
		ensure
			result_not_void: Result /= Void
			max_width_set: Result.max_width = a_width
		end

	with_button_spacing (a_spacing: NATURAL_16): like Current
			-- Copy of Current with `a_spacing` columns between two buttons.
		do
			Result := twin
			Result.set_button_spacing (a_spacing)
		ensure
			result_not_void: Result /= Void
			button_spacing_set: Result.button_spacing = a_spacing
		end

	with_style (a_style: STYLE): like Current
			-- Copy of Current patching `a_style` over the box.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_kind_style (a_kind: NATURAL_8; a_style: STYLE): like Current
			-- Copy of Current drawing the border of a dialog of kind `a_kind` in `a_style`.
		require
			valid_kind: {DIALOG_KIND}.is_valid (a_kind)
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_kind_style (a_kind, a_style)
		ensure
			result_not_void: Result /= Void
			kind_style_set: Result.kind_style (a_kind) = a_style
		end

	with_button_style (a_style: STYLE): like Current
			-- Copy of Current giving each button the style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_button_style (a_style)
		ensure
			result_not_void: Result /= Void
			button_style_set: Result.button_style = a_style
		end

	with_focused_button_style (a_style: STYLE): like Current
			-- Copy of Current patching `a_style` over the focused button.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_focused_button_style (a_style)
		ensure
			result_not_void: Result /= Void
			focused_button_style_set: Result.focused_button_style = a_style
		end

	with_theme (a_theme: TUI_THEME): like Current
			-- Copy of Current with its styles from `a_theme` (see `set_theme`).
		require
			theme_not_void: a_theme /= Void
		do
			Result := twin
			Result.set_theme (a_theme)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_theme.base
			question_set: Result.question_style = a_theme.primary
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same title, message, body, sizes, kind, border, shadow and styles?
		do
			if a_other = Current then
				Result := True
			else
				Result := title ~ a_other.title
					and title_alignment = a_other.title_alignment
					and message ~ a_other.message
					and body = a_other.body
					and body_height = a_other.body_height
					and kind = a_other.kind
					and border_type = a_other.border_type
					and shadow ~ a_other.shadow
					and max_width = a_other.max_width
					and button_spacing = a_other.button_spacing
					and style.is_equal (a_other.style)
					and info_style.is_equal (a_other.info_style)
					and warning_style.is_equal (a_other.warning_style)
					and error_style.is_equal (a_other.error_style)
					and question_style.is_equal (a_other.question_style)
					and button_style.is_equal (a_other.button_style)
					and focused_button_style.is_equal (a_other.focused_button_style)
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Draw nothing: without a state there is no open dialog.
		do
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: DIALOG_STATE)
			-- Draw the dialog of `a_state`, if it is open, centred in `a_area` (see the class
			-- note).
		local
			l_layout: like layout
			l_popup: TUI_POPUP
			l_block: TUI_BLOCK
			l_clip: RECT
			l_row, l_col, i: INTEGER
			l_base: STYLE
			l_align: NATURAL_8
			l_button: TUI_BUTTON
		do
			if a_state.is_open then
				l_layout := layout (a_area, a_state)
				if not l_layout.box.is_empty then
					l_block := (create {TUI_BLOCK}.make).with_borders ({BORDERS}.all_borders)
						.with_border_type (border_type).with_style (style).with_border_style (kind_style (kind))
						.with_shadow (shadow)
					if attached title as t then
						l_block := l_block.with_title (t).with_title_alignment (title_alignment)
					end
					l_popup := (create {TUI_POPUP}.make).with_block (l_block)
					l_popup.render (l_layout.box, a_buffer)
					if not l_layout.body.is_empty then
						if attached body as b then
							b.render (l_layout.body, a_buffer)
						else
							l_clip := l_layout.body.intersection (a_buffer.area)
							if message.has_alignment then
								l_align := message.alignment
							else
								l_align := {TEXT_ALIGNMENT}.center
							end
							l_row := l_layout.body.y.to_integer_32
							across l_layout.lines as l loop
								if not l_clip.is_empty and then l_row >= l_clip.top.to_integer_32
									and then l_row < l_clip.bottom.to_integer_32
								then
									l_col := l_layout.body.x.to_integer_32 + {TEXT_LAYOUT}.aligned_offset (l.width,
										l_layout.body.width, l.resolved_alignment (l_align)).to_integer_32
									l_base := a_buffer.cell (l_row, l_clip.left.to_integer_32).style.patch (message.style)
									a_buffer.set_line_clipped (l_row, l_col, l, l_base,
										l_clip.left.to_integer_32, l_clip.right.to_integer_32)
								end
								l_row := l_row + 1
							end
						end
					end
					from i := 1 until i > a_state.button_count loop
						if not l_layout.buttons.i_th (i).is_empty then
							create l_button.make (l_layout.labels.i_th (i))
							l_button := l_button.with_style (button_style).with_focused_style (focused_button_style)
								.with_focused (i = a_state.focused_button)
							l_button.render (l_layout.buttons.i_th (i), a_buffer)
						end
						i := i + 1
					end
				end
			end
		end

feature {FRAME} -- Hit testing

	register_child_hits (a_area: RECT; a_frame: FRAME)
			-- Nothing: without a state there is no open dialog (as `render` draws none).
		do
		end

	register_child_hits_with_state (a_area: RECT; a_state: detachable WIDGET_STATE; a_frame: FRAME)
			-- While the dialog `a_state` is open: its popup (the modal), then the body, then
			-- each button drawn under its id (see the class note).
		local
			l_layout: like layout
			i: INTEGER
		do
			if attached {DIALOG_STATE} a_state as s and then s.is_open then
				l_layout := layout (a_area, s)
				if not l_layout.box.is_empty then
					if s.popup.blocks_hits then
						a_frame.register_rendered (s.popup, l_layout.box)
					elseif not a_frame.hit_map.is_overlay_open then
						a_frame.hit_map.register_modal (a_frame.area, l_layout.box)
					end
					if attached body as b and then not l_layout.body.is_empty then
						a_frame.register_rendered (b, l_layout.body)
					end
					from i := 1 until i > s.button_count loop
						if not l_layout.buttons.i_th (i).is_empty then
							a_frame.register_hit (s.button_id (i), l_layout.buttons.i_th (i))
						end
						i := i + 1
					end
				end
			end
		end

feature {NONE} -- Implementation

	Chrome_width: INTEGER = 4
			-- Columns of the box not given to the content: two borders and two of padding

	Chrome_height: INTEGER = 4
			-- Rows of the box not given to the message: two borders, the blank row and the
			-- button row

	Bracket_width: INTEGER = 4
			-- Columns of a button's default brackets, "[ " and " ]"

	layout (a_area: RECT; a_state: DIALOG_STATE): TUPLE [box, body: RECT; lines: ARRAYED_LIST [TEXT_LINE];
			buttons: ARRAYED_LIST [RECT]; labels: ARRAYED_LIST [STRING_32]]
			-- Box, message area, wrapped message rows shown, button areas and shown labels of
			-- `a_state` rendered into `a_area` (see the class note)
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_aw, l_ah, l_limit, l_wrap, l_content, l_rows, l_row_width, l_title_width: INTEGER
			l_w, l_h, l_inside, l_shown, l_x, l_y, l_cap, l_spacing, i: INTEGER
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_labels: ARRAYED_LIST [STRING_32]
			l_buttons: ARRAYED_LIST [RECT]
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_box, l_body, l_row: RECT
		do
			l_aw := a_area.width.to_integer_32
			l_ah := a_area.height.to_integer_32
			l_limit := max_width.to_integer_32.min (l_aw)
			l_wrap := (l_limit - Chrome_width).max (1)
			l_spacing := button_spacing.to_integer_32
				-- Content: the message rows (or the body) and the button row
			if body /= Void then
				create l_lines.make (0)
				l_content := l_wrap
				l_rows := body_height.to_integer_32
			else
				l_lines := {TEXT_LAYOUT}.wrap_text (message, l_wrap.to_natural_16, {TEXT_WRAP_MODE}.word, True)
				across l_lines as l loop
					l_content := l_content.max (l.width.to_integer_32)
				end
				l_rows := l_lines.count
			end
			l_labels := labels_of (a_state)
			l_row_width := row_width (l_labels, l_spacing)
			if attached title as t then
				l_title_width := ({UNICODE_WIDTH}.string_width (t).to_integer_32 + 2).min (max_width.to_integer_32)
			end
				-- Box
			l_w := ((l_content.max (l_row_width) + Chrome_width).max (l_title_width)).min (l_aw)
			l_h := (l_rows + Chrome_height).min (l_ah)
			l_inside := (l_h - 2).max (0)
			l_shown := (l_inside - 2).max (0)
			from until l_lines.count <= l_shown loop
				l_lines.finish
				l_lines.remove
			end
			l_x := a_area.x.to_integer_32 + (l_aw - l_w) // 2
			l_y := a_area.y.to_integer_32 + (l_ah - l_h) // 2
			create l_box.make (l_x.to_natural_16, l_y.to_natural_16, l_w.to_natural_16, l_h.to_natural_16)
			create l_body.make ((l_x + 2).to_natural_16, (l_y + 1).to_natural_16,
				(l_w - Chrome_width).max (0).to_natural_16, l_shown.to_natural_16)
				-- Buttons, on the last row inside the box
			create l_buttons.make (l_labels.count)
			if l_inside >= 1 and l_w > Chrome_width then
				create l_row.make ((l_x + 2).to_natural_16, (l_y + l_h - 2).to_natural_16, (l_w - Chrome_width).to_natural_16, 1)
				if l_row_width > l_row.width.to_integer_32 then
					from
						l_cap := 0
						across l_labels as l loop
							l_cap := l_cap.max ({UNICODE_WIDTH}.string_width (l).to_integer_32)
						end
					until
						l_cap <= 1 or row_width (cut_labels (a_state, l_cap), l_spacing) <= l_row.width.to_integer_32
					loop
						l_cap := l_cap - 1
					end
					l_labels := cut_labels (a_state, l_cap)
				end
				create l_constraints.make (l_labels.count)
				across l_labels as l loop
					l_constraints.extend ({CONSTRAINTS}.fixed (({UNICODE_WIDTH}.string_width (l).to_integer_32 + Bracket_width).to_natural_16))
				end
				across (create {LAYOUT}.make_horizontal (l_constraints)).with_spacing (l_spacing)
					.with_flex ({FLEX_JUSTIFY}.center).split_list (l_row) as r
				loop
					l_buttons.extend (r.intersection (l_row))
				end
			end
			from i := l_buttons.count + 1 until i > l_labels.count loop
				l_buttons.extend (create {RECT}.make (l_x.to_natural_16, l_y.to_natural_16, 0, 0))
				i := i + 1
			end
			Result := [l_box, l_body, l_lines, l_buttons, l_labels]
		ensure
			result_not_void: Result /= Void
			box_inside: Result.box.is_empty or else a_area.contains_rect (Result.box)
			one_area_per_button: Result.buttons.count = a_state.button_count
			one_label_per_button: Result.labels.count = a_state.button_count
		end

	labels_of (a_state: DIALOG_STATE): ARRAYED_LIST [STRING_32]
			-- The labels of `a_state`, whole
		require
			state_not_void: a_state /= Void
		do
			create Result.make (a_state.button_count)
			across a_state.buttons as l loop
				Result.extend (l.to_string_32)
			end
		ensure
			one_per_button: Result.count = a_state.button_count
		end

	cut_labels (a_state: DIALOG_STATE; a_cap: INTEGER): ARRAYED_LIST [STRING_32]
			-- The labels of `a_state`, each cut to its first grapheme clusters that take at most
			-- `a_cap` columns, and never to less than its first cluster
		require
			state_not_void: a_state /= Void
		local
			i, l_end, l_width, l_next: INTEGER
			l_label: IMMUTABLE_STRING_32
		do
			create Result.make (a_state.button_count)
			across a_state.buttons as l loop
				l_label := l
				l_end := {UNICODE_WIDTH}.grapheme_end (l_label, 1)
				l_width := {UNICODE_WIDTH}.string_width (l_label.substring (1, l_end)).to_integer_32
				from i := l_end + 1 until i > l_label.count loop
					l_next := {UNICODE_WIDTH}.grapheme_end (l_label, i)
					l_width := l_width + {UNICODE_WIDTH}.string_width (l_label.substring (i, l_next)).to_integer_32
					if l_width <= a_cap then
						l_end := l_next
						i := l_next + 1
					else
						i := l_label.count + 1
					end
				end
				Result.extend (l_label.substring (1, l_end).to_string_32)
			end
		ensure
			one_per_button: Result.count = a_state.button_count
			never_empty: across Result as l all not l.is_empty end
		end

	row_width (a_labels: ARRAYED_LIST [STRING_32]; a_spacing: INTEGER): INTEGER
			-- Columns of a button row with `a_labels`, `a_spacing` columns apart
		require
			labels_not_void: a_labels /= Void
		do
			across a_labels as l loop
				Result := Result + {UNICODE_WIDTH}.string_width (l).to_integer_32 + Bracket_width
			end
			Result := Result + a_spacing * (a_labels.count - 1).max (0)
		ensure
			non_negative: Result >= 0
		end

invariant
	message_not_void: message /= Void
	valid_title_alignment: {TEXT_ALIGNMENT}.is_valid (title_alignment)
	valid_kind: {DIALOG_KIND}.is_valid (kind)
	valid_border_type: {BORDER_TYPE}.is_valid (border_type)
	room_for_text: max_width >= Minimum_width
	style_not_void: style /= Void
	info_style_not_void: info_style /= Void
	warning_style_not_void: warning_style /= Void
	error_style_not_void: error_style /= Void
	question_style_not_void: question_style /= Void
	button_style_not_void: button_style /= Void
	focused_button_style_not_void: focused_button_style /= Void

end
