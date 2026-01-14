note
	description: "Parameter collection for PostgreSQL dynamic calls"
	date: "$Date$"
	revision: "$Revision$"

class
	DB_PARA_POSTGRESQL

inherit
	ARRAYED_LIST [DB_BIND_POSTGRESQL]
		redefine
			make
		end

	GLOBAL_SETTINGS
		undefine
			is_equal,
			copy
		end

	POSTGRESQL_EXTERNALS
		export
			{NONE} all
		undefine
			is_equal,
			copy
		end

create
	make

feature {NONE} -- Initialization

	make (n: INTEGER)
			-- Initialization with capacity `n'
		do
			Precursor (n)
		end

feature -- Access

	parameter_count: INTEGER
			-- Number of parameters currently in use

	param_values_pointer: POINTER
			-- Pointer to array of parameter value pointers
		local
			l_managed: MANAGED_POINTER
			l_item: DB_BIND_POSTGRESQL
			i: INTEGER
		do
			if parameter_count > 0 then
				if attached internal_param_values as l_p then
					l_managed := l_p
				else
					create l_managed.make ({PLATFORM}.pointer_bytes * parameter_count)
					internal_param_values := l_managed
				end
				from
					i := 1
				until
					i > parameter_count
				loop
					l_item := i_th (i)
					l_managed.put_pointer (l_item.value_pointer, (i - 1) * {PLATFORM}.pointer_bytes)
					i := i + 1
				end
				Result := l_managed.item
			end
		end

	param_lengths_pointer: POINTER
			-- Pointer to array of parameter lengths
		local
			l_managed: MANAGED_POINTER
			l_item: DB_BIND_POSTGRESQL
			i: INTEGER
		do
			if parameter_count > 0 then
				if attached internal_param_lengths as l_p then
					l_managed := l_p
				else
					create l_managed.make ({PLATFORM}.integer_32_bytes * parameter_count)
					internal_param_lengths := l_managed
				end
				from
					i := 1
				until
					i > parameter_count
				loop
					l_item := i_th (i)
					l_managed.put_integer_32 (l_item.count, (i - 1) * {PLATFORM}.integer_32_bytes)
					i := i + 1
				end
				Result := l_managed.item
			end
		end

	param_formats_pointer: POINTER
			-- Pointer to array of parameter formats (0 = text format)
		local
			l_managed: MANAGED_POINTER
			i: INTEGER
		do
			if parameter_count > 0 then
				if attached internal_param_formats as l_p then
					l_managed := l_p
				else
					create l_managed.make ({PLATFORM}.integer_32_bytes * parameter_count)
					internal_param_formats := l_managed
					-- Set all to 0 (text format)
					from
						i := 0
					until
						i >= parameter_count
					loop
						l_managed.put_integer_32 (0, i * {PLATFORM}.integer_32_bytes)
						i := i + 1
					end
				end
				Result := l_managed.item
			end
		end

feature -- Element Change

	extend_parameter (a_object: detachable ANY)
			-- Add parameter converted from Eiffel object
		do
			if attached object_to_bind (a_object) as l_bind then
				extend (l_bind)
			else
				extend (create {DB_BIND_POSTGRESQL}.make (Void, 0))
			end
		end

	replace_parameter (i: INTEGER; a_object: detachable ANY)
			-- Replace parameter at position `i'
		require
			i_valid: valid_index (i)
		do
			if attached object_to_bind (a_object) as l_bind then
				put_i_th (l_bind, i)
			else
				put_i_th (create {DB_BIND_POSTGRESQL}.make (Void, 0), i)
			end
		end

	set_parameter_count (a_count: INTEGER)
			-- Set number of parameters to use
		require
			a_count_valid: a_count >= 0 and then a_count <= count
		do
			parameter_count := a_count
		ensure
			parameter_count_set: parameter_count = a_count
		end

feature -- Action

	release
			-- Release all parameters
		do
			wipe_out
		end

feature {NONE} -- Implementation

	object_to_bind (a_obj: detachable ANY): detachable DB_BIND_POSTGRESQL
			-- Convert Eiffel object to bind parameter
		local
			l_string: STRING
			u: UTF_CONVERTER
		do
			if a_obj = Void then
				create Result.make (Void, 0)
			elseif attached {READABLE_STRING_8} a_obj as l_val_string then
				create Result.make (l_val_string.to_string_8, l_val_string.count)
			elseif attached {READABLE_STRING_32} a_obj as l_string_32 then
				l_string := u.utf_32_string_to_utf_8_string_8 (l_string_32)
				create Result.make (l_string, l_string.count)
			elseif attached {INTEGER_REF} a_obj as l_val_int then
				l_string := l_val_int.item.out
				create Result.make (l_string, l_string.count)
			elseif attached {INTEGER_16_REF} a_obj as l_val_int16 then
				l_string := l_val_int16.item.out
				create Result.make (l_string, l_string.count)
			elseif attached {INTEGER_64_REF} a_obj as l_val_int64 then
				l_string := l_val_int64.item.out
				create Result.make (l_string, l_string.count)
			elseif attached {DATE_TIME} a_obj as l_tmp_date then
				-- PostgreSQL timestamp format: YYYY-MM-DD HH:MM:SS
				create l_string.make (19)
				l_string.append (l_tmp_date.year.out)
				l_string.append_character ('-')
				if l_tmp_date.month < 10 then
					l_string.append_character ('0')
				end
				l_string.append (l_tmp_date.month.out)
				l_string.append_character ('-')
				if l_tmp_date.day < 10 then
					l_string.append_character ('0')
				end
				l_string.append (l_tmp_date.day.out)
				l_string.append_character (' ')
				if l_tmp_date.hour < 10 then
					l_string.append_character ('0')
				end
				l_string.append (l_tmp_date.hour.out)
				l_string.append_character (':')
				if l_tmp_date.minute < 10 then
					l_string.append_character ('0')
				end
				l_string.append (l_tmp_date.minute.out)
				l_string.append_character (':')
				if l_tmp_date.second < 10 then
					l_string.append_character ('0')
				end
				l_string.append (l_tmp_date.second.out)
				create Result.make (l_string, l_string.count)
			elseif attached {DOUBLE_REF} a_obj as l_val_double then
				l_string := l_val_double.item.out
				create Result.make (l_string, l_string.count)
			elseif attached {REAL_REF} a_obj as l_val_real then
				l_string := l_val_real.item.out
				create Result.make (l_string, l_string.count)
			elseif attached {CHARACTER_REF} a_obj as l_val_char then
				create l_string.make (1)
				l_string.append_character (l_val_char.item)
				create Result.make (l_string, 1)
			elseif attached {BOOLEAN_REF} a_obj as l_val_bool then
				if l_val_bool.item then
					create Result.make ("TRUE", 4)
				else
					create Result.make ("FALSE", 5)
				end
			else
				create Result.make (Void, 0)
			end
		end

	internal_param_values: detachable MANAGED_POINTER
			-- Managed pointer for parameter values array

	internal_param_lengths: detachable MANAGED_POINTER
			-- Managed pointer for parameter lengths array

	internal_param_formats: detachable MANAGED_POINTER
			-- Managed pointer for parameter formats array


;note
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
