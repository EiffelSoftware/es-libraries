note
	description: "Messages for BSON parsing and processing errors."
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=BSON Specification", "protocol=URI", "src=https://bsonspec.org/spec.html"

class BSON_MESSAGES

feature -- Messages

	document_length_invalid: STRING = "Document length invalid or out of bounds"
	key_invalid: STRING = "Invalid document key"
	cstring_unterminated: STRING = "Unterminated C string"

	type_unsupported (a_type: INTEGER): STRING
		do
			create Result.make_from_string ("Unsupported BSON type: " + a_type.out)
		ensure
			class
		end

	parser_configuration_error: STRING = "BSON parser configuration error"

feature -- Messages end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
