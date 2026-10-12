note
	description: "[
		Deferred base class for widgets that can be enclosed in an optional TUI_BLOCK.
		Provides unified block composition, inner area calculation, and block rendering.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BLOCK_CONTAINER

inherit
	WIDGET

feature -- Access

	block: detachable TUI_BLOCK
			-- Optional decorative or structural block container.

feature -- Element change

	set_block (a_block: detachable TUI_BLOCK)
			-- Set enclosing container block to `a_block`.
		do
			block := a_block
		ensure
			block_set: block = a_block
		end

feature -- Fluent Builders

	with_block (a_block: detachable TUI_BLOCK): like Current
			-- Return a copy of Current with container block set to `a_block`.
		do
			Result := twin
			Result.set_block (a_block)
		ensure
			block_set: Result.block = a_block
			result_not_void: Result /= Void
		end

feature -- Comparison

	same_block (a_other: BLOCK_CONTAINER): BOOLEAN
			-- Does `a_other` have an equivalent block container to `Current`?
		require
			other_not_void: a_other /= Void
		do
			if block = Void and a_other.block = Void then
				Result := True
			elseif attached block as b1 and attached a_other.block as b2 then
				Result := b1.is_equal (b2)
			end
		end

feature -- Helpers

	inner_area (a_area: RECT): RECT
			-- Calculate drawing area inside `block` if present, otherwise `a_area`.
		require
			area_not_void: a_area /= Void
		do
			if attached block as l_block then
				Result := l_block.inner (a_area)
			else
				Result := a_area
			end
		ensure
			result_not_void: Result /= Void
		end

	render_block (a_area: RECT; a_buffer: BUFFER)
			-- Render enclosing container block if present.
		require
			area_not_void: a_area /= Void
			buffer_not_void: a_buffer /= Void
		do
			if attached block as l_block then
				l_block.render (a_area, a_buffer)
			end
		end

end
