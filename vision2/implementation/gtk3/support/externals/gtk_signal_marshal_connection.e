note
	description: "Summary description for {GTK_SIGNAL_CONNECTION}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GTK_SIGNAL_MARSHAL_CONNECTION

inherit
	DISPOSABLE

create
	make

feature {NONE} -- Intialization

	make (a_c_object: POINTER; a_conn_id: like connection_id)
		do
			c_object := a_c_object
			connection_id := a_conn_id
			is_connected := a_conn_id /= 0
		end

feature -- Access

	c_object: POINTER

	connection_id: INTEGER_32

feature -- Basic operation

	close
			-- Close connection `connection_id` for object `c_object`.
			--
			--| Only safe while `c_object' is known to be alive, which is why this is
			--| called from `destroy' and never from `dispose'. There is deliberately no
			--| `gtk_is_widget' guard: that macro dereferences the pointer it is meant to
			--| validate -- `((GTypeInstance*) obj)->g_class->g_type' -- so on a freed
			--| widget it reads freed memory. Worse, once the block is reused the macro
			--| answers True for the new occupant and the disconnect below is applied to
			--| an unrelated object, which is what produced
			--| "instance '0x...' has no handler with id '...'" followed by a segfault.
		do
			if
				is_connected and then
				not c_object.is_default_pointer
			then
				{GOBJECT}.signal_disconnect (c_object, connection_id)
			end
			is_connected := False
		end

feature -- Status

	is_connected: BOOLEAN

feature -- Disposal

	dispose
			-- Called by the Eiffel GC when `Current' is destroyed.
			--
			--| Deliberately does nothing. Disconnecting from here is not safe: `c_object'
			--| is a bare pointer that nothing keeps alive, so by the time the GC reclaims
			--| `Current' the GTK instance may be long gone, and there is no way to test
			--| that without dereferencing it. Leaving the connection in place keeps the
			--| connected agent rooted for as long as `c_object' lives, which is a leak --
			--| but a bounded one, and far preferable to corrupting the heap.
			--| Close connections explicitly through `destroy' instead.
		do
		end

note
	copyright: "Copyright (c) 1984-2024, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
