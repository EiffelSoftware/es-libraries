note
	description: "[
		Data item model for EXAMPLE_TABLE representing a contact entry.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONTACT_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_name, a_address, a_email: READABLE_STRING_GENERAL)
			-- Initialize contact with `a_name`, `a_address` and `a_email`.
		require
			name_not_void: a_name /= Void
			address_not_void: a_address /= Void
			email_not_void: a_email /= Void
		do
			create name.make_from_string_general (a_name)
			create address.make_from_string_general (a_address)
			create email.make_from_string_general (a_email)
		ensure
			name_set: name.same_string_general (a_name)
			address_set: address.same_string_general (a_address)
			email_set: email.same_string_general (a_email)
		end

feature -- Access

	name: STRING_32
			-- Contact full name

	address: STRING_32
			-- Contact location or address

	email: STRING_32
			-- Contact email address

end
