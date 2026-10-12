note
	description: "[
		Hierarchical tree widget supporting collapsible/expandable nodes,
		depth indentation, selection highlighting, and scrolling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TREE

inherit
	STATEFUL_WIDGET [TREE_STATE]
		redefine
			default_create,
			copy,
			is_equal
		end
	BLOCK_CONTAINER
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make,
	make_with_roots

feature {NONE} -- Initialization

	default_create
			-- Initialize with empty roots, default styling, and tree symbols.
		do
			create root_store.make (4)
			create style.default_create
			create highlight_style.default_create
			highlight_style := highlight_style.with_reverse
			create highlight_symbol.make_from_string (">> ")
			create expanded_symbol.make_from_string ("v ")
			create collapsed_symbol.make_from_string ("> ")
			create leaf_symbol.make_from_string ("  ")
			indent_size := 2
		ensure then
			roots_empty: roots.is_empty
			indent_valid: indent_size = 2
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

	make_with_roots (a_roots: ITERABLE [TREE_NODE])
			-- Initialize tree with `a_roots`.
		require
			roots_not_void: a_roots /= Void
		do
			default_create
			across
				a_roots as r
			loop
				roots.extend (r)
			end
		end

feature {TUI_TREE} -- Copy on write

	root_store: ARRAYED_LIST [TREE_NODE]
			-- Root nodes, possibly shared with copies of `Current` (see `roots_shared`)

	roots_shared: BOOLEAN
			-- Is `root_store` shared with another object?

	mark_roots_shared
			-- Record that `root_store` is now shared with a copy.
		do
			roots_shared := True
		ensure
			shared: roots_shared
		end

	own_roots
			-- Give `Current` its own copy of the root nodes if they are shared.
		do
			if roots_shared then
				root_store := copied_roots (root_store)
				roots_shared := False
			end
		ensure
			not_shared: not roots_shared
		end

feature {NONE} -- Copy on write

	copied_roots (a_list: ARRAYED_LIST [TREE_NODE]): ARRAYED_LIST [TREE_NODE]
			-- Copy of `a_list` holding copies of its elements
		do
			create Result.make (a_list.count)
			across a_list as e loop
				Result.extend (e.twin)
			end
		end

feature -- Access

	roots: ARRAYED_LIST [TREE_NODE]
			-- Top-level tree nodes (owned by `Current`: content still shared with a copy is copied first)
		do
			own_roots
			Result := root_store
		ensure
			owned: not roots_shared
		end

	style: STYLE
			-- Base style for tree lines

	highlight_style: STYLE
			-- Style applied to selected node

	highlight_symbol: STRING_32
			-- Prefix symbol rendered before selected node

	expanded_symbol: STRING_32
			-- Icon displayed for expanded parent nodes

	collapsed_symbol: STRING_32
			-- Icon displayed for collapsed parent nodes

	leaf_symbol: STRING_32
			-- Icon displayed for leaf nodes

	indent_size: INTEGER
			-- Number of columns indented per tree level

feature -- Element Change

	set_style (a_style: STYLE)
			-- Set base style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_highlight_style (a_style: STYLE)
			-- Set highlight style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			highlight_style := a_style
		ensure
			highlight_style_set: highlight_style = a_style
		end

	set_highlight_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set selection prefix symbol to `a_symbol`.
		require
			symbol_not_void: a_symbol /= Void
		do
			create highlight_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: highlight_symbol.same_string_general (a_symbol)
		end

	set_expanded_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set icon for expanded nodes to `a_symbol`.
		require
			symbol_not_void: a_symbol /= Void
		do
			create expanded_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: expanded_symbol.same_string_general (a_symbol)
		end

	set_collapsed_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set icon for collapsed nodes to `a_symbol`.
		require
			symbol_not_void: a_symbol /= Void
		do
			create collapsed_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: collapsed_symbol.same_string_general (a_symbol)
		end

	set_leaf_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set icon for leaf nodes to `a_symbol`.
		require
			symbol_not_void: a_symbol /= Void
		do
			create leaf_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: leaf_symbol.same_string_general (a_symbol)
		end

	set_indent_size (a_indent: INTEGER)
			-- Set column indentation per hierarchy level.
		require
			indent_non_negative: a_indent >= 0
		do
			indent_size := a_indent
		ensure
			indent_set: indent_size = a_indent
		end

	add_root (a_node: TREE_NODE)
			-- Add a root node.
		require
			node_not_void: a_node /= Void
		do
			roots.extend (a_node)
		ensure
			root_added: roots.count = old roots.count + 1
		end

feature -- Fluent Builders

	with_style (a_style: STYLE): like Current
			-- Return a copy of Current with `style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_highlight_style (a_style: STYLE): like Current
			-- Return a copy of Current with `highlight_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_highlight_style (a_style)
		ensure
			result_not_void: Result /= Void
			highlight_style_set: Result.highlight_style = a_style
		end

	with_highlight_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `highlight_symbol` set.
		require
			symbol_not_void: a_symbol /= Void
		do
			Result := twin
			Result.set_highlight_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_expanded_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `expanded_symbol` set.
		require
			symbol_not_void: a_symbol /= Void
		do
			Result := twin
			Result.set_expanded_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_collapsed_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `collapsed_symbol` set.
		require
			symbol_not_void: a_symbol /= Void
		do
			Result := twin
			Result.set_collapsed_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_leaf_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `leaf_symbol` set.
		require
			symbol_not_void: a_symbol /= Void
		do
			Result := twin
			Result.set_leaf_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_indent_size (a_indent: INTEGER): like Current
			-- Return a copy of Current with `indent_size` set.
		require
			indent_non_negative: a_indent >= 0
		do
			Result := twin
			Result.set_indent_size (a_indent)
		ensure
			result_not_void: Result /= Void
			indent_set: Result.indent_size = a_indent
		end

	with_root (a_node: TREE_NODE): like Current
			-- Return a copy of Current with a copy of `a_node` added to roots
			-- (changing `a_node` afterwards does not affect the result).
		require
			node_not_void: a_node /= Void
		do
			Result := twin
			Result.add_root (a_node.twin)
		ensure
			result_not_void: Result /= Void
			root_added: Result.roots.count = roots.count + 1
		end

feature -- Comparison & Duplication

	copy (other: like Current)
			-- Copy `other`; the node tree is copied on write (see `roots`), and rendering
			-- never copies it.
		do
			if other /= Current then
				standard_copy (other)
				roots_shared := True
				other.mark_roots_shared
			end
		end

	is_equal (other: like Current): BOOLEAN
			-- Compare roots, styles, and symbols.
		local
			i: INTEGER
		do
			if other = Current then
				Result := True
			elseif root_store.count = other.root_store.count
				and then style.is_equal (other.style)
				and then highlight_style.is_equal (other.highlight_style)
				and then highlight_symbol.is_equal (other.highlight_symbol)
				and then expanded_symbol.is_equal (other.expanded_symbol)
				and then collapsed_symbol.is_equal (other.collapsed_symbol)
				and then leaf_symbol.is_equal (other.leaf_symbol)
				and then indent_size = other.indent_size
				and then same_block (other)
			then
				Result := True
				from
					i := 1
				until
					not Result or i > root_store.count
				loop
					Result := root_store.i_th (i).is_equal (other.root_store.i_th (i))
					i := i + 1
				end
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Stateless rendering using a default empty TREE_STATE.
		local
			l_state: TREE_STATE
		do
			create l_state.default_create
			render_stateful (a_area, a_buffer, l_state)
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: TREE_STATE)
			-- Render tree hierarchy using `a_state` within `a_area` on `a_buffer`.
			-- Every write is clipped to the inner area and the buffer; the scroll offset keeps
			-- the selected node visible.
		local
			l_target: RECT
			l_items: ARRAYED_LIST [TUPLE [node: TREE_NODE; depth: INTEGER; is_expanded: BOOLEAN]]
			l_h, l_start, l_end, l_row, l_col, l_left, l_right, l_sel_index, i: INTEGER
			l_item: TUPLE [node: TREE_NODE; depth: INTEGER; is_expanded: BOOLEAN]
			l_node: TREE_NODE
			l_is_sel: BOOLEAN
			l_line_style: STYLE
			l_sym: STRING_32
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty then
					a_buffer.set_style (l_target, style)
					l_items := flatten_visible (a_state)

					if not l_items.is_empty then
						l_h := l_target.height.to_integer_32
						l_sel_index := visible_index (l_items, a_state.selected_id)
						if l_sel_index = 0 and attached a_state.selected_id as l_sel_id then
							if attached deepest_visible_ancestor (l_sel_id, l_items) as l_anc then
								a_state.select_node (l_anc.id)
								l_sel_index := visible_index (l_items, a_state.selected_id)
							end
						end
						if l_sel_index > 0 then
							record_ancestors (a_state, l_items, l_sel_index)
							if l_sel_index <= a_state.scroll_offset then
								a_state.set_scroll_offset (l_sel_index - 1)
							elseif l_sel_index > a_state.scroll_offset + l_h then
								a_state.set_scroll_offset (l_sel_index - l_h)
							end
						end
						if a_state.scroll_offset > (l_items.count - l_h).max (0) then
							a_state.set_scroll_offset ((l_items.count - l_h).max (0))
						end

						l_start := a_state.scroll_offset + 1
						l_end := (a_state.scroll_offset + l_h).min (l_items.count)
						l_left := l_target.x.to_integer_32
						l_right := l_target.right.to_integer_32

						from
							i := l_start
						until
							i > l_end
						loop
							l_row := l_target.y.to_integer_32 + (i - l_start)
							if l_row < a_buffer.height then
								l_item := l_items.i_th (i)
								l_node := l_item.node
								l_is_sel := i = l_sel_index

								if l_is_sel then
									l_line_style := style.patch (highlight_style)
									a_buffer.set_style (create {RECT}.make (l_target.x, l_row.to_natural_16, l_target.width, 1), highlight_style)
								else
									l_line_style := style
								end

								l_col := l_left

								-- Highlight symbol column (blank when not selected)
								if not highlight_symbol.is_empty then
									if l_is_sel then
										a_buffer.set_string_clipped (l_row, l_col, highlight_symbol, l_left, l_right, l_line_style)
									end
									l_col := l_col + {UNICODE_WIDTH}.string_width (highlight_symbol).to_integer_32
								end

								-- Indentation
								l_col := l_col + (l_item.depth * indent_size)

								-- Node expansion/leaf symbol
								if l_node.is_leaf then
									l_sym := leaf_symbol
								elseif l_item.is_expanded then
									l_sym := expanded_symbol
								else
									l_sym := collapsed_symbol
								end
								if not l_sym.is_empty and l_col < l_right then
									a_buffer.set_string_clipped (l_row, l_col, l_sym, l_left, l_right, l_line_style)
									l_col := l_col + {UNICODE_WIDTH}.string_width (l_sym).to_integer_32
								end

								-- Node text
								if l_col < l_right then
									a_buffer.set_line_clipped (l_row, l_col, l_node.text, l_line_style, l_left, l_right)
								end
							end
							i := i + 1
						end
					end
				end
			end
		end

feature -- Navigation

	visible_nodes (a_state: TREE_STATE): ARRAYED_LIST [TREE_NODE]
			-- Nodes shown with the expansion state of `a_state`, top to bottom
		require
			state_not_void: a_state /= Void
		do
			create Result.make (root_store.count * 2)
			across flatten_visible (a_state) as it loop
				Result.extend (it.node)
			end
		end

	collapse_node (a_state: TREE_STATE; a_id: READABLE_STRING_GENERAL)
			-- Collapse node `a_id` in `a_state`, and if the currently selected node
			-- is a descendant of `a_id`, select `a_id` (or the nearest visible ancestor).
		require
			state_not_void: a_state /= Void
			id_not_void: a_id /= Void
		do
			a_state.collapse_node (a_id)
			adjust_selection_to_visible (a_state)
		end

	adjust_selection_to_visible (a_state: TREE_STATE)
			-- If `a_state.selected_id` is hidden under a collapsed ancestor,
			-- re-select the deepest visible ancestor.
		require
			state_not_void: a_state /= Void
		local
			l_items: like flatten_visible
		do
			if attached a_state.selected_id as l_sel_id then
				l_items := flatten_visible (a_state)
				if visible_index (l_items, l_sel_id) = 0 then
					if attached deepest_visible_ancestor (l_sel_id, l_items) as l_anc then
						a_state.select_node (l_anc.id)
						record_ancestors (a_state, l_items, visible_index (l_items, l_anc.id))
					end
				end
			end
		end

	select_next (a_state: TREE_STATE)
			-- Select the visible node after the selected one (the first if none is visible).
		require
			state_not_void: a_state /= Void
		local
			l_items: like flatten_visible
			l_index: INTEGER
		do
			l_items := flatten_visible (a_state)
			if not l_items.is_empty then
				l_index := visible_index (l_items, a_state.selected_id)
				if l_index = 0 and attached a_state.selected_id as l_sel_id then
					if attached deepest_visible_ancestor (l_sel_id, l_items) as l_anc then
						a_state.select_node (l_anc.id)
						l_index := visible_index (l_items, a_state.selected_id)
					end
				end
				l_index := (l_index + 1).min (l_items.count)
				a_state.select_node (l_items.i_th (l_index).node.id)
				record_ancestors (a_state, l_items, l_index)
			end
		end

	select_previous (a_state: TREE_STATE)
			-- Select the visible node before the selected one (the first if none is visible).
		require
			state_not_void: a_state /= Void
		local
			l_items: like flatten_visible
			l_index: INTEGER
		do
			l_items := flatten_visible (a_state)
			if not l_items.is_empty then
				l_index := visible_index (l_items, a_state.selected_id)
				if l_index = 0 and attached a_state.selected_id as l_sel_id then
					if attached deepest_visible_ancestor (l_sel_id, l_items) as l_anc then
						a_state.select_node (l_anc.id)
						l_index := visible_index (l_items, a_state.selected_id)
					end
				end
				l_index := (l_index - 1).max (1)
				a_state.select_node (l_items.i_th (l_index).node.id)
				record_ancestors (a_state, l_items, l_index)
			end
		end

feature {NONE} -- Helpers

	record_ancestors (a_state: TREE_STATE; a_items: like flatten_visible; a_index: INTEGER)
			-- Record in `a_state` the ids of the ancestors of the visible node at `a_index`.
		require
			valid_index: a_index >= 1 and a_index <= a_items.count
		local
			l_path: ARRAYED_LIST [STRING_32]
			l_depth, j: INTEGER
		do
			create l_path.make (a_items [a_index].depth)
			from
				l_depth := a_items [a_index].depth
				j := a_index - 1
			until
				l_depth = 0 or j < 1
			loop
				if a_items [j].depth < l_depth then
					l_path.put_front (a_items [j].node.id)
					l_depth := a_items [j].depth
				end
				j := j - 1
			end
			a_state.record_selected_ancestors (l_path)
		end

	visible_index (a_items: like flatten_visible; a_id: detachable READABLE_STRING_32): INTEGER
			-- Index in `a_items` of the first node with id `a_id`, 0 if none is visible
		local
			i: INTEGER
		do
			if attached a_id as l_id then
				from
					i := 1
				until
					Result > 0 or i > a_items.count
				loop
					if a_items.i_th (i).node.id.same_string (l_id) then
						Result := i
					end
					i := i + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= a_items.count
		end

	flatten_visible (a_state: TREE_STATE): ARRAYED_LIST [TUPLE [node: TREE_NODE; depth: INTEGER; is_expanded: BOOLEAN]]
			-- Return flattened list of visible nodes given expansion state in `a_state`.
		do
			create Result.make (root_store.count * 2)
			across
				root_store as r
			loop
				append_node_visible (r, 0, a_state, Result)
			end
		ensure
			result_not_void: Result /= Void
		end

	append_node_visible (a_node: TREE_NODE; a_depth: INTEGER; a_state: TREE_STATE; a_out: ARRAYED_LIST [TUPLE [node: TREE_NODE; depth: INTEGER; is_expanded: BOOLEAN]])
			-- Recursively append `a_node` and its expanded descendants to `a_out`.
		local
			l_exp: BOOLEAN
		do
			l_exp := a_state.is_expanded (a_node.id)
			a_out.extend ([a_node, a_depth, l_exp])
			if l_exp and not a_node.is_leaf then
				across
					a_node.children as c
				loop
					append_node_visible (c, a_depth + 1, a_state, a_out)
				end
			end
		end

	deepest_visible_ancestor (a_id: READABLE_STRING_GENERAL; a_items: like flatten_visible): detachable TREE_NODE
			-- The deepest node in `a_items` that is an ancestor of `a_id` (or `a_id` itself if visible).
		local
			l_path: ARRAYED_LIST [TREE_NODE]
			i: INTEGER
		do
			create l_path.make (8)
			across root_store as r loop
				if l_path.is_empty then
					if find_path (r, a_id, l_path) then
						-- Found target in tree path
					end
				end
			end
			from
				i := l_path.count
			until
				Result /= Void or i < 1
			loop
				if visible_index (a_items, l_path [i].id) > 0 then
					Result := l_path [i]
				end
				i := i - 1
			end
		end

	find_path (a_current: TREE_NODE; a_target_id: READABLE_STRING_GENERAL; a_path: ARRAYED_LIST [TREE_NODE]): BOOLEAN
			-- Search `a_current` and descendants for `a_target_id`, filling `a_path` if found.
		do
			a_path.extend (a_current)
			if a_current.id.same_string_general (a_target_id) then
				Result := True
			else
				across a_current.children as c loop
					if not Result then
						Result := find_path (c, a_target_id, a_path)
					end
				end
				if not Result then
					a_path.finish
					a_path.remove
				end
			end
		end

invariant
	roots_not_void: root_store /= Void
	style_not_void: style /= Void
	highlight_style_not_void: highlight_style /= Void
	highlight_symbol_not_void: highlight_symbol /= Void
	expanded_symbol_not_void: expanded_symbol /= Void
	collapsed_symbol_not_void: collapsed_symbol /= Void
	leaf_symbol_not_void: leaf_symbol /= Void
	indent_non_negative: indent_size >= 0

end
