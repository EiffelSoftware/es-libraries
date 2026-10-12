note
	description: "[
		Tier 5 Container Widget: Heterogeneous Widget Stack Container.
		Holds a collection of polymorphic WIDGET instances with associated layout
		constraints and renders them sequentially in vertical or horizontal orientation.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	STACK_CONTAINER

inherit
	WIDGET

create
	make_vertical,
	make_horizontal

feature {NONE} -- Initialization

	make_vertical
			-- Initialize vertical stack container.
		do
			is_vertical := True
			create items.make (10)
		ensure
			vertical: is_vertical
			empty: items.is_empty
		end

	make_horizontal
			-- Initialize horizontal stack container.
		do
			is_vertical := False
			create items.make (10)
		ensure
			horizontal: not is_vertical
			empty: items.is_empty
		end

feature -- Access

	is_vertical: BOOLEAN
			-- Is layout vertical?

	items: ARRAYED_LIST [TUPLE [widget: WIDGET; constraint: CONSTRAINT]]
			-- List of child widgets with their respective layout constraints

feature -- Element Change

	extend (a_widget: WIDGET; a_constraint: CONSTRAINT)
			-- Add child `a_widget` with layout `a_constraint`.
		require
			widget_not_void: a_widget /= Void
			constraint_not_void: a_constraint /= Void
		do
			items.extend ([a_widget, a_constraint])
		ensure
			one_more: items.count = old items.count + 1
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render all child widgets polymorphically according to layout constraints.
		local
			l_layout: LAYOUT
			l_constraints: ARRAY [CONSTRAINT]
			l_chunks: ARRAY [RECT]
			i: INTEGER
		do
			if not items.is_empty and not a_area.is_empty then
				-- Gather constraints
				create l_constraints.make_empty
				from i := 1 until i > items.count loop
					l_constraints.force (items [i].constraint, i)
					i := i + 1
				end

				-- Create layout
				if is_vertical then
					create l_layout.make_vertical (l_constraints)
				else
					create l_layout.make_horizontal (l_constraints)
				end

				l_chunks := l_layout.split (a_area)

				-- Render each child widget
				from i := 1 until i > items.count or i > l_chunks.count loop
					items [i].widget.render (l_chunks [i], a_buffer)
					i := i + 1
				end
			end
		end

end
