note
	description: "Collection of helper routines to access WSF_REQUEST."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_REQUEST_UTILITIES

feature -- Helpers	

	json_value_from_request (req: WSF_REQUEST): detachable JSON_VALUE
		local
			l_payload: STRING_8
			jp: JSON_PARSER
		do
			if attached req.content_type as ct and then ct.same_simple_type ({HTTP_MIME_TYPES}.application_json) then
				create l_payload.make (req.content_length_value.as_integer_32)
				req.read_input_data_into (l_payload)
				create jp.make
				jp.parse_string (l_payload)
				if jp.is_parsed and jp.is_valid then
					Result := jp.parsed_json_value
				end
			else
				-- Do not try to get json from non json content type.
			end
		ensure
			class
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
