note
	description: "[
		Hierarchical node within a TUI_TREE widget. Each node contains a unique
		identifier, formatted text line, and zero or more child nodes.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TREE_NODE

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create
	make,
	make_with_string,
	make_with_children

feature {NONE} -- Initialization

	make (a_id: READABLE_STRING_GENERAL; a_text: TEXT_LINE)
			-- Initialize node with `a_id` and formatted `a_text`.
		require
			id_not_void: a_id /= Void
			text_not_void: a_text /= Void
		do
			create id.make_from_string_general (a_id)
			text := a_text
			create children.make (0)
		ensure
			id_set: id.same_string_general (a_id)
			text_set: text = a_text
			children_empty: children.is_empty
		end

	make_with_string (a_id, a_text: READABLE_STRING_GENERAL)
			-- Initialize node with `a_id` and string text.
		require
			id_not_void: a_id /= Void
			text_not_void: a_text /= Void
		do
			create id.make_from_string_general (a_id)
			create text.make_raw (a_text)
			create children.make (0)
		ensure
			id_set: id.same_string_general (a_id)
			children_empty: children.is_empty
		end

	make_with_children (a_id: READABLE_STRING_GENERAL; a_text: TEXT_LINE; a_children: ITERABLE [TREE_NODE])
			-- Initialize node with `a_id`, `a_text`, and `a_children`.
		require
			id_not_void: a_id /= Void
			text_not_void: a_text /= Void
			children_not_void: a_children /= Void
		do
			make (a_id, a_text)
			across
				a_children as c
			loop
				children.extend (c)
			end
		end

feature -- Access

	id: STRING_32
			-- Unique node identifier

	text: TEXT_LINE
			-- Formatted text line for this node

	children: ARRAYED_LIST [TREE_NODE]
			-- Child nodes

	is_leaf: BOOLEAN
			-- Does this node have no children?
		do
			Result := children.is_empty
		ensure
			matches_children: Result = children.is_empty
		end

feature -- Element Change

	set_text (a_text: TEXT_LINE)
			-- Set node text to `a_text`.
		require
			text_not_void: a_text /= Void
		do
			text := a_text
		ensure
			text_set: text = a_text
		end

	add_child (a_child: TREE_NODE)
			-- Append `a_child` to children list.
		require
			child_not_void: a_child /= Void
		do
			children.extend (a_child)
		ensure
			child_added: children.count = old children.count + 1
		end

feature -- Fluent Builders

	with_child (a_child: TREE_NODE): like Current
			-- Return a copy of Current with `a_child` appended.
		require
			child_not_void: a_child /= Void
		do
			Result := twin
			Result.add_child (a_child)
		ensure
			result_not_void: Result /= Void
			child_added: Result.children.count = children.count + 1
		end

feature -- Comparison & Duplication

	copy (other: like Current)
			-- Deep-duplicate children list.
		local
			l_new_children: ARRAYED_LIST [TREE_NODE]
		do
			if other /= Current then
				standard_copy (other)
				create l_new_children.make (other.children.count)
				across
					other.children as c
				loop
					l_new_children.extend (c.twin)
				end
				children := l_new_children
			end
		end

	is_equal (other: like Current): BOOLEAN
			-- Compare id, text, and children count.
		local
			i: INTEGER
		do
			if other = Current then
				Result := True
			elseif id.is_equal (other.id) and text.is_equal (other.text) and children.count = other.children.count then
				Result := True
				from
					i := 1
				until
					not Result or i > children.count
				loop
					Result := children.i_th (i).is_equal (other.children.i_th (i))
					i := i + 1
				end
			end
		end

invariant
	id_not_void: id /= Void
	text_not_void: text /= Void
	children_not_void: children /= Void

end
