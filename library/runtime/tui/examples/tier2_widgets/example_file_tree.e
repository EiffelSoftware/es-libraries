note
	description: "[
		Tier 2 Widget Specialist Example: File Tree (P2b R2).
		Demonstrates TUI_TREE + TREE_STATE (the first example to use them) with a TUI_BREADCRUMB
		of the selected node's path above it. The tree is a fixed, made-up project (`roots`):
		nothing is read from the file system, so every run looks the same.

		  * Tree keys: Up / Down move the selection, Home / End jump to the first / last row,
		    Right expands a folder (on an expanded folder: goes to its first child), Left
		    collapses an expanded folder (otherwise: goes to the parent), Space toggles a folder.
		  * Breadcrumb keys: Backspace goes to the parent; Alt+Left / Alt+Right move the
		    breadcrumb's selection (shown reversed); Enter goes to the selected crumb (with no
		    crumb selected, Enter toggles the folder, as Space). Any other move of the tree
		    clears the breadcrumb's selection.
		  * Mouse (left button; the others do nothing): a click on a crumb goes to that crumb;
		    a click on a tree row selects it (a second click on the selected folder toggles
		    it); the wheel moves the selection.
		  * q or Esc quits.

		"Going to" crumb i (`go_to_crumb`: a click, Enter on a selected crumb, Backspace for the
		parent) selects that ancestor in the tree and collapses it and every folder below it,
		so the tree folds up to the place shown at the end of the path.

		Mapping: the crumbs are the labels of the nodes from the root to the selected node
		(`selected_path`, found in `roots` by id each frame), so the breadcrumb always follows
		the tree's selection and its last crumb is the selected node. Crumb i has the hit id
		`Crumb_id_base + i`; tree row j (of the rows shown) has `Row_id_base + j`, registered by
		the example after the tree is drawn, since TUI_TREE registers no hit regions. A click
		is mapped back through `hit_test` in `click`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_FILE_TREE

inherit
	TUI_APPLICATION
		redefine
			make
		end

create
	make,
	make_batch,
	make_on

feature {NONE} -- Initialization

	make
			-- Initialize and launch the file tree example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_tree
			Precursor
			set_mouse_capture (True)
			create l_args
			auto_exit_frames := -1
			from i := 1 until i > l_args.argument_count loop
				if l_args.argument (i).is_equal ("-batch") then
					auto_exit_frames := 2
				end
				i := i + 1
			end
			frame_counter := 0
			run
		end

	make_batch (a_frames: INTEGER)
			-- Initialize and run for `a_frames` frames.
		do
			init_tree
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_mouse_capture (True)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

	make_on (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize on `a_terminal` without running (for snapshot tests).
		require
			terminal_attached: a_terminal /= Void
		do
			init_tree
			make_with_terminal (a_terminal)
			set_mouse_capture (True)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_tree
			-- Build the project tree and open it on "library/widgets/tree/tui_tree.e".
		do
			create tree.make_with_roots (<<new_folder ("eiffeltui", <<
				new_folder ("docs", <<new_file ("guide.md"), new_file ("api.md")>>),
				new_folder ("examples", <<
					new_folder ("tier1", <<new_file ("hello.e")>>),
					new_folder ("tier2", <<new_file ("file_tree.e"), new_file ("menu_bar.e")>>)>>),
				new_folder ("library", <<
					new_folder ("core", <<new_file ("buffer.e"), new_file ("frame.e")>>),
					new_folder ("widgets", <<
						new_folder ("breadcrumb", <<new_file ("tui_breadcrumb.e"), new_file ("breadcrumb_symbols.e")>>),
						new_folder ("tree", <<new_file ("tui_tree.e"), new_file ("tree_state.e"), new_file ("tree_node.e")>>)>>)>>),
				new_folder ("tests", <<new_file ("test_app.e")>>),
				new_file ("eiffeltui.ecf"),
				new_file ("README.md")>>)>>)
			create tree_state.make
			tree_state.expand_node ("eiffeltui")
			tree_state.expand_node ("eiffeltui/library")
			tree_state.expand_node ("eiffeltui/library/widgets")
			tree_state.expand_node ("eiffeltui/library/widgets/tree")
			tree_state.select_node ("eiffeltui/library/widgets/tree/tui_tree.e")
			create crumb_area.make (0, 0, 0, 0)
		end

	new_folder (a_name: STRING_32; a_children: ARRAY [TREE_NODE]): TREE_NODE
			-- Folder `a_name` holding `a_children`; each child's id is prefixed with "`a_name`/".
		do
			create Result.make_with_string (a_name, a_name)
			across a_children as c loop
				Result.add_child (prefixed (c, a_name))
			end
		end

	new_file (a_name: STRING_32): TREE_NODE
			-- File `a_name` (a leaf whose id is its name, until a folder prefixes it)
		do
			create Result.make_with_string (a_name, a_name)
		end

	prefixed (a_node: TREE_NODE; a_prefix: STRING_32): TREE_NODE
			-- Copy of `a_node` and its children with ids prefixed by "`a_prefix`/"
		do
			create Result.make (a_prefix + {STRING_32} "/" + a_node.id, a_node.text)
			across a_node.children as c loop
				Result.add_child (prefixed (c, a_prefix))
			end
		end

feature -- Access

	tree: TUI_TREE
			-- The project tree (its nodes: ids are paths such as "eiffeltui/docs/api.md")

	tree_state: TREE_STATE
			-- Selected node, expanded folders and scroll offset

	crumb_selected: INTEGER
			-- Crumb selected by Alt+Left / Alt+Right (0: none)

	selected_path: ARRAYED_LIST [TREE_NODE]
			-- Nodes from the root to the selected node (empty when nothing is selected)
		do
			create Result.make (8)
			if attached tree_state.selected_id as l_id then
				across tree.roots as r until not Result.is_empty loop
					if find_path (r, l_id, Result) then
							-- Found: `Result` holds the path
					end
				end
			end
		ensure
			ends_at_selection: not Result.is_empty implies
				(attached tree_state.selected_id as l_id and then Result.last.id.same_string (l_id))
		end

	crumbs: ARRAYED_LIST [STRING_32]
			-- Labels of `selected_path`, root first
		do
			create Result.make (8)
			across selected_path as n loop
				Result.extend (n.text.to_plain_string)
			end
		end

	crumb_area: RECT
			-- Row the breadcrumb was last drawn in

	Crumb_id_base: INTEGER = 100
			-- Crumb i has the hit id `Crumb_id_base` + i

	Row_id_base: INTEGER = 1000
			-- Tree row j (1 for the top row shown) has the hit id `Row_id_base` + j

feature {NONE} -- State

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw the breadcrumb on the top row, the tree in a box below it and the help
			-- line at the bottom; register each crumb and each tree row shown for clicks.
		local
			l_box, l_inner: RECT
			l_crumbs: like crumbs
			l_ids: ARRAY [WIDGET_ID]
			i, l_first, l_last: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end
				-- The tree first: drawing it may move the selection (to a visible ancestor), and
				-- the breadcrumb below must show the selection the tree shows.
			if a_frame.area.height > 3 then
					-- The tree in a box
				create l_box.make (0, 1, a_frame.area.width, a_frame.area.height - 2)
				a_frame.render_widget ((create {TUI_BLOCK}.make).with_border_type ({BORDER_TYPE}.rounded)
					.with_title (" Project "), l_box)
				l_inner := l_box.inner (1, 1)
				if not l_inner.is_empty then
					a_frame.render_stateful_widget (tree, l_inner, tree_state)
						-- One region per row shown (the scroll offset is the one just drawn)
					l_first := tree_state.scroll_offset + 1
					l_last := (tree_state.scroll_offset + l_inner.height.to_integer_32).min (tree.visible_nodes (tree_state).count)
					from i := l_first until i > l_last loop
						a_frame.register_hit (create {WIDGET_ID}.make (Row_id_base + i - tree_state.scroll_offset),
							create {RECT}.make (l_inner.x, l_inner.y + (i - l_first).to_natural_16, l_inner.width, 1))
						i := i + 1
					end
				end
				a_frame.render_widget (create {TUI_PARAGRAPH}.make_raw (Help_text),
					create {RECT}.make (0, a_frame.area.height - 1, a_frame.area.width, 1))
			end
			if a_frame.area.width > 2 and a_frame.area.height > 0 then
					-- The breadcrumb of the selected node's path, on the top row
				l_crumbs := crumbs
				create l_ids.make_filled (create {WIDGET_ID}.make (Crumb_id_base + 1), 1, l_crumbs.count)
				from i := 1 until i > l_crumbs.count loop
					l_ids [i] := create {WIDGET_ID}.make (Crumb_id_base + i)
					i := i + 1
				end
				if crumb_selected > l_crumbs.count then
					crumb_selected := 0
				end
				create crumb_area.make (1, 0, a_frame.area.width - 2, 1)
				a_frame.render_widget ((create {TUI_BREADCRUMB}.make (l_crumbs))
						.with_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan))
						.with_selected (crumb_selected)
						.with_hit_ids (l_ids),
					crumb_area)
			end
		end

	Help_text: STRING_32 = "Arrows: tree  Bksp: up  Alt+arrows, Enter: crumb  q: quit"
			-- The help line

	process (a_event: EVENT)
			-- Tree and breadcrumb keys, clicks and the wheel.
		do
			if attached {MOUSE_EVENT} a_event as m then
				if m.is_down then
					if m.button = {MOUSE_EVENT}.Button_left then
						click (hit_test (m))
					end
				elseif m.is_scroll_down then
					move_selection (True)
				elseif m.is_scroll_up then
					move_selection (False)
				end
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.modifiers.is_alt and then k.code.is_left then
					move_crumb_selection (-1)
				elseif k.modifiers.is_alt and then k.code.is_right then
					move_crumb_selection (1)
				elseif k.code.is_backspace then
					go_to_parent
				elseif k.code.is_enter then
					if crumb_selected > 0 then
						go_to_crumb (crumb_selected)
					else
						toggle_selected
					end
				elseif k.code.is_up then
					move_selection (False)
				elseif k.code.is_down then
					move_selection (True)
				elseif k.code.is_home then
					select_visible (1)
				elseif k.code.is_end then
					select_visible (tree.visible_nodes (tree_state).count)
				elseif k.code.is_right then
					expand_or_enter
				elseif k.code.is_left then
					collapse_or_leave
				elseif k.code.is_escape or else (k.code.is_char and then k.code.character = 'q') then
					stop
				elseif k.code.is_char and then k.code.character = ' ' then
					toggle_selected
				end
			end
		end

feature -- Breadcrumb navigation

	go_to_crumb (i: INTEGER)
			-- Select crumb `i`'s node in the tree and collapse it and every folder below it.
		require
			valid_crumb: i >= 1 and i <= selected_path.count
		local
			l_node: TREE_NODE
		do
			l_node := selected_path [i]
			tree_state.select_node (l_node.id)
			collapse_subtree (l_node)
			crumb_selected := 0
		ensure
			selected: attached tree_state.selected_id as l_id and then l_id.same_string (old selected_path [i].id)
			collapsed: not tree_state.is_expanded (old selected_path [i].id)
			path_cut: selected_path.count = i
			no_crumb_selected: crumb_selected = 0
		end

	go_to_parent
			-- Go to the parent crumb (Backspace); nothing at the root.
		do
			if selected_path.count > 1 then
				go_to_crumb (selected_path.count - 1)
			end
		end

	move_crumb_selection (a_step: INTEGER)
			-- Move the breadcrumb's selection by `a_step` (-1 left, +1 right) within the path;
			-- from no selection it starts at the last crumb.
		local
			l_count: INTEGER
		do
			l_count := selected_path.count
			if l_count > 0 then
				if crumb_selected = 0 then
					crumb_selected := l_count
				end
				crumb_selected := (crumb_selected + a_step).max (1).min (l_count)
			end
		ensure
			in_path: crumb_selected >= 0 and crumb_selected <= selected_path.count
		end

feature -- Tree navigation

	move_selection (a_down: BOOLEAN)
			-- Select the next (`a_down`) or previous visible node.
		do
			if a_down then
				tree.select_next (tree_state)
			else
				tree.select_previous (tree_state)
			end
			crumb_selected := 0
		end

	select_visible (j: INTEGER)
			-- Select the `j`-th visible node, if any.
		local
			l_nodes: ARRAYED_LIST [TREE_NODE]
		do
			l_nodes := tree.visible_nodes (tree_state)
			if j >= 1 and j <= l_nodes.count then
				tree_state.select_node (l_nodes [j].id)
				crumb_selected := 0
			end
		end

	expand_or_enter
			-- Expand the selected folder; on an expanded one, select its first child.
		do
			if attached selected_node as l_node and then not l_node.is_leaf then
				if tree_state.is_expanded (l_node.id) then
					tree_state.select_node (l_node.children.first.id)
				else
					tree_state.expand_node (l_node.id)
				end
				crumb_selected := 0
			end
		end

	collapse_or_leave
			-- Collapse the selected folder if it is expanded; otherwise select the parent.
		local
			l_path: like selected_path
		do
			l_path := selected_path
			if not l_path.is_empty then
				if not l_path.last.is_leaf and then tree_state.is_expanded (l_path.last.id) then
					tree_state.collapse_node (l_path.last.id)
				elseif l_path.count > 1 then
					tree_state.select_node (l_path [l_path.count - 1].id)
				end
				crumb_selected := 0
			end
		end

	toggle_selected
			-- Expand or collapse the selected folder.
		do
			if attached selected_node as l_node and then not l_node.is_leaf then
				tree_state.toggle_node (l_node.id)
				crumb_selected := 0
			end
		end

	click (a_id: detachable WIDGET_ID)
			-- A click on the region `a_id`: a crumb goes there, a tree row is selected (a click
			-- on the selected folder toggles it); anything else is ignored.
		local
			l_nodes: ARRAYED_LIST [TREE_NODE]
			j: INTEGER
		do
			if attached a_id as l_id then
				if l_id.value > Crumb_id_base and l_id.value <= Crumb_id_base + selected_path.count then
					go_to_crumb (l_id.value - Crumb_id_base)
				elseif l_id.value > Row_id_base then
					j := tree_state.scroll_offset + l_id.value - Row_id_base
					l_nodes := tree.visible_nodes (tree_state)
					if j <= l_nodes.count then
						if attached tree_state.selected_id as l_sel and then l_sel.same_string (l_nodes [j].id) then
							toggle_selected
						else
							tree_state.select_node (l_nodes [j].id)
							crumb_selected := 0
						end
					end
				end
			end
		end

feature {NONE} -- Implementation

	selected_node: detachable TREE_NODE
			-- The selected node, if any
		local
			l_path: like selected_path
		do
			l_path := selected_path
			if not l_path.is_empty then
				Result := l_path.last
			end
		end

	collapse_subtree (a_node: TREE_NODE)
			-- Collapse `a_node` and every folder below it.
		do
			if not a_node.is_leaf then
				across a_node.children as c loop
					collapse_subtree (c)
				end
				tree_state.collapse_node (a_node.id)
			end
		ensure
			collapsed: not tree_state.is_expanded (a_node.id)
		end

	find_path (a_node: TREE_NODE; a_id: READABLE_STRING_32; a_path: ARRAYED_LIST [TREE_NODE]): BOOLEAN
			-- Is `a_id` `a_node` or below it? If so, `a_path` is extended by the nodes from
			-- `a_node` down to it; otherwise `a_path` is left as it was.
		do
			a_path.extend (a_node)
			if a_node.id.same_string (a_id) then
				Result := True
			else
				across a_node.children as c until Result loop
					Result := find_path (c, a_id, a_path)
				end
				if not Result then
					a_path.finish
					a_path.remove
				end
			end
		ensure
			unchanged_if_absent: not Result implies a_path.count = old a_path.count
		end

invariant
	crumb_selection_non_negative: crumb_selected >= 0

end
