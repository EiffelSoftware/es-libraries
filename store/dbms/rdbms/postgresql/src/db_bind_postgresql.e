note
	description: "One piece of PostgreSQL parameter bind info"
	date: "$Date$"
	revision: "$Revision$"

class
	DB_BIND_POSTGRESQL

inherit
	POSTGRESQL_EXTERNALS

create
	make

feature {NONE} -- Initialization

	make (a_value: detachable STRING; a_count: like count)
			-- Initialize with value and count
		do
			if a_value /= Void then
				value := a_value
				count := a_count
				create is_null_flag.make (1)
				is_null_flag.put_natural_8 (0, 0)
			else
				value := ""
				count := 0
				create is_null_flag.make (1)
				is_null_flag.put_natural_8 (1, 0)
			end
			create length_data.make ({PLATFORM}.integer_32_bytes)
			length_data.put_integer_32 (count, 0)
		end

feature -- Access

	value: STRING
			-- String value of the parameter

	count: INTEGER
			-- Length of the value

	length_data: MANAGED_POINTER
			-- Pointer to length data

	is_null_flag: MANAGED_POINTER
			-- Flag indicating if value is NULL

	is_null: BOOLEAN
			-- Is the value NULL?
		do
			Result := is_null_flag.read_natural_8 (0) = 1
		end

	value_pointer: POINTER
			-- Pointer to the value string
		local
			l_c_string: C_STRING
		do
			if not is_null then
				create l_c_string.make (value)
				Result := l_c_string.item
			else
				Result := default_pointer
			end
		end

	length: INTEGER
			-- Length of the data
		do
			Result := length_data.read_integer_32 (0)
		end

feature -- Element Change

	set_value (a_value: detachable STRING)
			-- Set `value' with `a_value'
		do
			if a_value /= Void then
				value := a_value
				count := a_value.count
				is_null_flag.put_natural_8 (0, 0)
			else
				value := ""
				count := 0
				is_null_flag.put_natural_8 (1, 0)
			end
			length_data.put_integer_32 (count, 0)
		ensure
			value_set: a_value /= Void implies value = a_value
			null_set: a_value = Void implies is_null
		end

note
	copyright: "Copyright (c) 1984-2025, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
