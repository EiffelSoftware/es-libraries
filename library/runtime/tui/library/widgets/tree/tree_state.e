note
	description: "[
		Mutable state for TUI_TREE widget tracking selected node id,
		expanded node ids, and vertical scroll offset.
		Expanded ids are kept in a hash set (`is_expanded` is O(1)).
		TUI_TREE records the ids of the selected node's ancestors (`selected_ancestor_ids`)
		whenever it renders or moves the selection, so that `collapse_node` can move the
		selection to the collapsed node when the selected node disappears under it.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TREE_STATE

inherit
	WIDGET_STATE
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize with no selection and empty expanded set.
		do
			create expanded_set.make (8)
			create selected_ancestors.make (0)
			scroll_offset := 0
		ensure then
			no_selection: selected_id = Void
			expanded_empty: expanded_count = 0
			scroll_at_zero: scroll_offset = 0
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	selected_id: detachable STRING_32
			-- ID of currently selected tree node

	expanded_ids: ARRAYED_LIST [STRING_32]
			-- IDs of expanded parent nodes (a fresh list; change them with the commands below)
		do
			create Result.make (expanded_set.count)
			across expanded_set as e loop
				Result.extend (@e.key)
			end
		ensure
			count_matches: Result.count = expanded_count
		end

	expanded_count: INTEGER
			-- Number of expanded nodes
		do
			Result := expanded_set.count
		end

	selected_ancestor_ids: ARRAYED_LIST [STRING_32]
			-- IDs of the ancestors of the selected node, root first, as last recorded by TUI_TREE
			-- (empty when unknown)
		do
			Result := selected_ancestors.twin
		end

	scroll_offset: INTEGER
			-- Number of visible lines scrolled vertically from top

feature -- Query

	is_expanded (a_id: READABLE_STRING_GENERAL): BOOLEAN
			-- Is the node with `a_id` expanded?
		require
			id_not_void: a_id /= Void
		do
			if attached {STRING_32} a_id as l_s then
				Result := expanded_set.has (l_s)
			else
				Result := expanded_set.has (create {STRING_32}.make_from_string_general (a_id))
			end
		end

feature -- Element Change

	select_node (a_id: detachable READABLE_STRING_GENERAL)
			-- Select node with `a_id` (or deselect if Void). The recorded ancestors are cleared.
		do
			if attached a_id as l_id then
				create selected_id.make_from_string_general (l_id)
			else
				selected_id := Void
			end
			selected_ancestors.wipe_out
		ensure
			ancestors_unknown: selected_ancestor_ids.is_empty
		end

	expand_node (a_id: READABLE_STRING_GENERAL)
			-- Mark node `a_id` as expanded.
		require
			id_not_void: a_id /= Void
		local
			l_s: STRING_32
		do
			create l_s.make_from_string_general (a_id)
			expanded_set.put (l_s, l_s)
		ensure
			node_expanded: is_expanded (a_id)
		end

	collapse_node (a_id: READABLE_STRING_GENERAL)
			-- Mark node `a_id` as collapsed. If the selected node is a recorded descendant of
			-- `a_id`, select `a_id` instead (the selected node is no longer visible).
		require
			id_not_void: a_id /= Void
		local
			l_s: STRING_32
			l_path: ARRAYED_LIST [STRING_32]
			i: INTEGER
		do
			create l_s.make_from_string_general (a_id)
			expanded_set.remove (l_s)
			from
				i := 1
			until
				i > selected_ancestors.count or else selected_ancestors [i].same_string (l_s)
			loop
				i := i + 1
			end
			if i <= selected_ancestors.count then
				l_path := selected_ancestors.twin
				select_node (l_s)
				from until l_path.count < i loop
					l_path.finish
					l_path.remove
				end
				record_selected_ancestors (l_path)
			end
		ensure
			collapsed: not is_expanded (a_id)
		end

	toggle_node (a_id: READABLE_STRING_GENERAL)
			-- Toggle expansion state of node `a_id`.
		require
			id_not_void: a_id /= Void
		do
			if is_expanded (a_id) then
				collapse_node (a_id)
			else
				expand_node (a_id)
			end
		end

	set_scroll_offset (a_offset: INTEGER)
			-- Set vertical scroll offset.
		do
			scroll_offset := a_offset.max (0)
		ensure
			scroll_valid: scroll_offset >= 0
		end

	scroll_up (a_lines: INTEGER)
			-- Scroll up by `a_lines`.
		do
			scroll_offset := (scroll_offset - a_lines).max (0)
		end

	scroll_down (a_lines: INTEGER)
			-- Scroll down by `a_lines`.
		do
			scroll_offset := scroll_offset + a_lines
		end

feature {TUI_TREE, TREE_STATE} -- Selection path

	record_selected_ancestors (a_ids: ITERABLE [READABLE_STRING_32])
			-- Record `a_ids` (root first) as the ancestors of the selected node.
		do
			selected_ancestors.wipe_out
			across a_ids as l_id loop
				selected_ancestors.extend (create {STRING_32}.make_from_string (l_id))
			end
		end

feature {NONE} -- Implementation

	expanded_set: HASH_TABLE [STRING_32, STRING_32]
			-- Expanded node ids (key = item)

	selected_ancestors: ARRAYED_LIST [STRING_32]
			-- Recorded ancestors of the selected node, root first

invariant
	expanded_set_not_void: expanded_set /= Void
	selected_ancestors_not_void: selected_ancestors /= Void
	scroll_non_negative: scroll_offset >= 0

end
