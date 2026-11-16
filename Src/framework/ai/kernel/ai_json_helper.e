note
	description: "Helpers to read and write JSON values."
	date: "$Date$"
	revision: "$Revision$"

class
	AI_JSON_HELPER

feature -- Parsing

	parsed_json (s: READABLE_STRING_8): detachable JSON_VALUE
			-- JSON value of text `s' (UTF-8), if valid
		local
			p: JSON_PARSER
		do
			create p.make_with_string (s)
			p.parse_content
			if p.is_valid then
				Result := p.parsed_json_value
			end
		end

	parsed_json_object (s: READABLE_STRING_8): detachable JSON_OBJECT
			-- JSON object of text `s' (UTF-8), if it is one
		do
			if attached {JSON_OBJECT} parsed_json (s) as o then
				Result := o
			end
		end

feature -- Access

	string_item (o: detachable JSON_VALUE; a_key: READABLE_STRING_8): detachable STRING_32
			-- String of key `a_key' of object `o', if any
		do
			if attached {JSON_OBJECT} o as l_object and then attached {JSON_STRING} l_object.item (create {JSON_STRING}.make_from_string (a_key)) as s then
				Result := s.unescaped_string_32
			end
		end

	integer_item (o: detachable JSON_VALUE; a_key: READABLE_STRING_8): INTEGER
			-- Integer of key `a_key' of object `o' (0 if none)
		do
			if attached {JSON_OBJECT} o as l_object and then attached {JSON_NUMBER} l_object.item (create {JSON_STRING}.make_from_string (a_key)) as n and then n.is_integer then
				Result := n.integer_64_item.min ({INTEGER}.max_value).to_integer
			end
		end

	boolean_item (o: detachable JSON_VALUE; a_key: READABLE_STRING_8): BOOLEAN
			-- Boolean of key `a_key' of object `o' (False if none)
		do
			if attached {JSON_OBJECT} o as l_object and then attached {JSON_BOOLEAN} l_object.item (create {JSON_STRING}.make_from_string (a_key)) as b then
				Result := b.item
			end
		end

	object_item (o: detachable JSON_VALUE; a_key: READABLE_STRING_8): detachable JSON_OBJECT
			-- Object of key `a_key' of object `o', if any
		do
			if attached {JSON_OBJECT} o as l_object and then attached {JSON_OBJECT} l_object.item (create {JSON_STRING}.make_from_string (a_key)) as v then
				Result := v
			end
		end

	array_item (o: detachable JSON_VALUE; a_key: READABLE_STRING_8): detachable JSON_ARRAY
			-- Array of key `a_key' of object `o', if any
		do
			if attached {JSON_OBJECT} o as l_object and then attached {JSON_ARRAY} l_object.item (create {JSON_STRING}.make_from_string (a_key)) as v then
				Result := v
			end
		end

feature -- Conversion

	utf_8 (s: READABLE_STRING_GENERAL): STRING_8
			-- `s' encoded in UTF-8
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (s)
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
