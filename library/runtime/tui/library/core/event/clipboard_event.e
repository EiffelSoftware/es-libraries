note
	description: "[
		The answer to a clipboard read: the terminal's OSC 52 reply
		`ESC ] 52 ; <selection> ; <base64> (BEL | ESC \)`, decoded by ANSI_INPUT_PARSER.
		`selection` is the first character of the reply's selection field (`c` the clipboard,
		`p` the primary selection; `c` when the field is empty). `status` says what `text` is:
		- `Status_text`: the clipboard's text, its base64 decoded and read as UTF-8 (each
		  invalid sequence is U+FFFD). An empty clipboard, and a reply whose data is `?`
		  (some terminals echo the query), give empty text: the protocol has no refusal.
		- `Status_unavailable`: no answer (the terminal does not support or allow the read).
		- `Status_too_large`: the reply was longer than the parser's `max_osc_size`; its data
		  was dropped.
		- `Status_invalid`: the data was not strict base64, or the reply had no data field.
		`text` is empty unless the status is `Status_text`. It is not sanitised: control
		characters are kept, as in PASTE_EVENT; removing them is the widget's job.
		The parser sends one event per reply, whether or not a read was asked for.
		On Windows the answer comes from the system clipboard instead
		({WIN32_CONSOLE_DRIVER}.read_clipboard_text, P2b K4): the same event, with
		`Status_text` (an empty clipboard, or one with no text, gives empty text),
		`Status_unavailable` (the clipboard could not be opened) or `Status_too_large`
		(more than `max_osc_size` UTF-16 code units); line breaks are passed on as read (CR LF).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CLIPBOARD_EVENT

inherit
	EVENT
		redefine
			is_clipboard
		end

create
	make, make_text

create {ANSI_INPUT_PARSER, CONSOLE_DRIVER}
	make_owned_text

feature {NONE} -- Initialization

	make (a_selection: CHARACTER_32; a_status: INTEGER)
			-- Initialize an answer without text for `a_selection`, with `a_status`.
		require
			valid_status: is_valid_status (a_status)
		do
			selection := a_selection
			status := a_status
			create text.make_empty
		ensure
			selection_set: selection = a_selection
			status_set: status = a_status
			no_text: text.is_empty
		end

	make_text (a_selection: CHARACTER_32; a_text: READABLE_STRING_GENERAL)
			-- Initialize an answer with `Status_text` holding a copy of `a_text` for `a_selection`.
		require
			text_attached: a_text /= Void
		do
			selection := a_selection
			status := Status_text
			text := a_text.as_string_32.twin
		ensure
			selection_set: selection = a_selection
			has_text: status = Status_text
			text_set: text.same_string_general (a_text)
		end

	make_owned_text (a_selection: CHARACTER_32; a_text: STRING_32)
			-- Initialize an answer with `Status_text` holding `a_text` itself (not a copy) for
			-- `a_selection`. The caller gives up `a_text` and must not change it later.
		require
			text_attached: a_text /= Void
		do
			selection := a_selection
			status := Status_text
			text := a_text
		ensure
			selection_set: selection = a_selection
			has_text: status = Status_text
			text_set: text = a_text
		end

feature -- Access

	selection: CHARACTER_32
			-- Selection the answer is for: `c` the clipboard, `p` the primary selection

	status: INTEGER
			-- What `text` is: one of `Status_text`, `Status_unavailable`, `Status_too_large`,
			-- `Status_invalid`

	text: STRING_32
			-- Decoded clipboard text (empty unless `status = Status_text`); not sanitised

feature -- Status report

	is_clipboard: BOOLEAN = True

	has_text: BOOLEAN
			-- Did the terminal send the clipboard's text (possibly empty)?
		do
			Result := status = Status_text
		ensure
			definition: Result = (status = Status_text)
		end

	is_valid_status (a_status: INTEGER): BOOLEAN
			-- Is `a_status` one of the status constants?
		do
			Result := a_status = Status_text or a_status = Status_unavailable
				or a_status = Status_too_large or a_status = Status_invalid
		ensure
			instance_free: class
		end

feature -- Constants

	Status_text: INTEGER = 1
			-- The reply held the clipboard's text

	Status_unavailable: INTEGER = 2
			-- No reply (the read is not supported or not allowed)

	Status_too_large: INTEGER = 3
			-- The reply was longer than the parser's `max_osc_size` (or the native clipboard's
			-- text, on Windows)

	Status_invalid: INTEGER = 4
			-- The reply's data was not valid base64, or it had no data field

invariant
	valid_status: is_valid_status (status)
	text_attached: text /= Void
	text_only_with_status_text: status /= Status_text implies text.is_empty

end
