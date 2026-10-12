# Writing Your First EiffelTUI Application

Welcome to **EiffelTUI**, a pure Eiffel terminal user interface library inspired by Rust's Ratatui. EiffelTUI delivers immediate-mode differential terminal rendering, responsive flex layouts, rich widgets, and robust ANSI/POSIX/Win32 console drivers—all governed by Eiffel's Design by Contract (DbC) and Void Safety.

---

## 1. Core Architecture Concepts

An EiffelTUI application revolves around three foundational components:

1. **`TUI_APPLICATION`**: The application lifecycle controller. It owns the background event polling thread, the terminal driver, and the tick/draw event loop. You implement two hooks, `process (EVENT)` and `render (FRAME)`, and call `stop` to leave `run`. The terminal is restored even when an exception escapes (the exception is re-raised afterwards).
2. **`FRAME`**: Passed to `render` on every frame. You inspect `frame.area`, split areas with `LAYOUT`, and render widgets with `frame.render_widget` or `frame.render_stateful_widget`.
3. **Command-Query Separation (CQS) & Immutability**:
   - Widget configuration is side-effect free: methods like `with_block`, `with_style`, `with_borders` return fresh copies (`twin`), preserving original objects. A copy is independent: it has its own lists and its own copies of the elements in them (list items, text lines, rows, titles, bars), so changing a copy never affects the original. Content (items, rows, text, tree nodes, datasets, shapes) is copied on write, so chaining builders every frame is cheap: nothing is copied until you access the content of one of the copies. Fetch elements (for example `l.items.first`) again after a `with_*` call instead of keeping references from before it.
   - `STYLE` is immutable; style modifications (`with_fg`, `with_bg`, `with_bold`, `patch`) return new values.
   - Stateful widgets cleanly decouple immutable presentation from mutable state (`STATEFUL_WIDGET [S -> WIDGET_STATE]`). Calling `render_stateful` directly is type-checked by the compiler; `frame.render_stateful_widget` checks the state type with a precondition (`accepts_state`).

---

## 2. A Minimal Application

Here is a complete, minimal interactive application:

```eiffel
note
	description: "Minimal EiffelTUI application."

class
	MY_FIRST_APP

inherit
	TUI_APPLICATION
		redefine
			make
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			Precursor
			run
		end

feature {NONE} -- Application hooks

	render (a_frame: FRAME)
			-- Draw the UI; called after every batch of events and every tick.
		local
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).with_title (" Hello EiffelTUI ")

			create l_para.make_raw ("Press 'q' or Esc to exit.%NWelcome to Eiffel terminal user interfaces!")
			l_para := l_para.with_block (l_block)

			a_frame.render_widget (l_para, a_frame.area)
		end

	process (a_event: EVENT)
			-- React to one keyboard, mouse, resize or tick event.
		do
			if attached {KEY_EVENT} a_event as k then
				if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
					stop
				end
			end
		end

end
```

---

## 3. Screen Layouts

EiffelTUI provides a deterministic layout solver (not Cassowary; the algorithm is documented in `LAYOUT_SOLVER`) supporting `Fixed` (Ratatui `Length`), `Percentage`, `Ratio`, `Min`, `Max` and `Flex` (Ratatui `Fill`) constraints. A `LAYOUT` is an immutable value: build it once (for example in `make`) and split areas with it on every frame.

```eiffel
local
	l_chunks: ARRAY [RECT]
	l_layout: LAYOUT
do
	-- Split the screen into a top header (3 rows) and flexible main area
	create l_layout.make ({SPLIT_DIRECTION}.vertical, <<{CONSTRAINTS}.fixed (3), {CONSTRAINTS}.flex (1)>>)
	-- Optional: l_layout := l_layout.with_margin (...).with_spacing (1).with_flex ({FLEX_JUSTIFY}.center)

	l_chunks := l_layout.split (a_frame.area)
	-- l_chunks [1] -> Header area
	-- l_chunks [2] -> Body area
end
```

---

## 4. Working with Widgets

### Enclosing Widgets with `BLOCK_CONTAINER`
All EiffelTUI container widgets (`TUI_PARAGRAPH`, `TUI_LIST`, `TUI_TABLE`, `TUI_TEXT_INPUT`, `TUI_TREE`, etc.) inherit `BLOCK_CONTAINER`. You can enclose them with styled borders, padding, and titles:

```eiffel
l_widget := l_widget.with_block (
	(create {TUI_BLOCK}.make)
		.with_borders ({BORDERS}.all_borders)
		.with_border_style ((create {STYLE}).with_fg ({COLOR}.cyan))
		.with_title (" Section Title ")
)
```

### Text Input (`TUI_TEXT_INPUT` & `TEXT_INPUT_STATE`)
```eiffel
-- In your application state:
input_state: TEXT_INPUT_STATE

-- In drawing:
local
	l_input: TUI_TEXT_INPUT
do
	create l_input.make
	l_input := l_input.with_placeholder ("Enter command...")
	a_frame.render_stateful_widget (l_input, l_rect, input_state)
	-- Show the terminal's own cursor at the insertion point (optional):
	if attached l_input.cursor_screen_position (l_rect, input_state) as p then
		a_frame.set_cursor_position (p.col, p.row)
	end
end

-- In process:
if attached {KEY_EVENT} a_event as k then
	if k.code.is_char then
		input_state.insert_character (k.code.character)
	elseif k.code.is_backspace then
		input_state.delete_backward
	elseif k.code.is_left then
		input_state.move_cursor_left
	elseif k.code.is_right then
		input_state.move_cursor_right
	end
end
```

Editing works on grapheme clusters (a letter with its combining accents, an emoji sequence) and the view scrolls by display column, so wide CJK characters and emoji behave as expected.

### Popups & Modals (`TUI_POPUP`)
```eiffel
local
	l_popup: TUI_POPUP
	l_dialog_rect: RECT
do
	create l_popup.make
	l_dialog_rect := l_popup.centered_rect (60, 40, a_frame.area)
	l_popup := l_popup
		.with_inner_widget (dialog_content_widget)
		.with_block ((create {TUI_BLOCK}.make).with_borders ({BORDERS}.all_borders).with_title (" Alert "))
		.with_clear_background (True)
	a_frame.render_widget (l_popup, l_dialog_rect)
end
```

### Collapsible Trees (`TUI_TREE` & `TREE_STATE`)
```eiffel
local
	l_tree: TUI_TREE
	l_root, l_c1: TREE_NODE
do
	create l_root.make_with_string ("root", "Project")
	create l_c1.make_with_string ("src", "source/")
	l_root.add_child (l_c1)

	create l_tree.make
	l_tree.add_root (l_root)
	a_frame.render_stateful_widget (l_tree, l_area, tree_state)
end
```

Expand and collapse nodes with `tree_state.toggle_node (id)`, and move the selection with `l_tree.select_next (tree_state)` / `select_previous`; the view scrolls to keep the selected node visible.

### Calendar (`TUI_CALENDAR` & `CALENDAR_STATE`)
```eiffel
local
	l_cal: TUI_CALENDAR
do
	create l_cal.make
	a_frame.render_stateful_widget (l_cal, l_area, calendar_state)
end
```

---

## 5. Theming with `TUI_THEME`

EiffelTUI includes built-in semantic themes (`dark`, `light`, `nord`, `dracula`):

```eiffel
local
	l_theme: TUI_THEME
do
	l_theme := {TUI_THEME}.nord
	-- Access semantic styles:
	-- l_theme.base, l_theme.primary, l_theme.secondary, l_theme.highlight, l_theme.selection, l_theme.border
end
```

---

## 6. Compiling and Running

Compile using the Eiffel Studio CLI:
```bash
ec -config eiffeltui.ecf -target eiffeltui_demo -c_compile -batch
```
And run the generated executable (`EIFGENs/eiffeltui_demo/W_code/hello_tui`) from your terminal console. For your own application, add `eiffeltui.ecf` as a library in your ECF (`<library name="eiffeltui" location="path/to/eiffeltui.ecf"/>`) with thread concurrency and full void safety enabled.
