note
	description: "Summary description for {BSON_PARSER_DEBUG}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_PARSER_DEBUG

inherit
	BSON_PARSER
		redefine
			make,
			parse_Boolean,
			parse_string,
			parse_int32,
			parse_int64,
			parse_double,
			read_key,
			parse_elements_into,
			parse_elements_into_array,
			parse_document,
			parse_array,
			parse_null,
			parse_value
		end

create
	make

feature -- Initialization

	make
		do
			Precursor
			create indentation.make (0)
		end

feature -- Debug

	tab: STRING_8 = "  "

	indent
		do
			indentation.append (tab)
			need_indentation := True
		end

	exdent
		do
			indentation.remove_tail (tab.count)
		end

	indentation: STRING_8

	need_indentation: BOOLEAN

	output (m: READABLE_STRING_GENERAL)
		do
			if need_indentation then
				io.error.put_string (indentation)
			end
			io.error.put_string_general (m)
			if m.ends_with ("%N") then
				need_indentation := True
--				io.error.put_new_line
			else
				need_indentation := False
			end
		end

feature {NONE} -- Implementation

	last_key: detachable READABLE_STRING_32

	read_key: detachable READABLE_STRING_32
		do
			Result := Precursor
			last_key := Result
--			if Result /= Void then
--				output ({STRING_32} "@" + Result + ": " )
--			end
		end

	parse_value (a_type: INTEGER_8): detachable BSON_VALUE
		local
			k: like last_key
		do
			k := last_key
			if k /= Void then
				output ({STRING_32} "<@" + k + ">" )
			end
			Result := Precursor (a_type)
			if k /= Void then
				output ({STRING_32} "</@" + k + ">" )
			end
		end

	parse_elements_into (a_container: BSON_DOCUMENT; a_end_index: INTEGER)
		do
			indent
			Precursor (a_container, a_end_index)
			exdent
		end

	parse_elements_into_array (a_container: BSON_ARRAY; a_end_index: INTEGER)
		do
			indent
			Precursor (a_container, a_end_index)
			exdent
		end

	parse_document: detachable BSON_DOCUMENT
		do
			output ("<Document>%N")
			Result := Precursor
			output ("</Document>%N")
		end

	parse_array: detachable BSON_ARRAY
		do
			output ("<Array>%N")
			Result := Precursor
			output ("</Array>%N")
		end

	parse_null: BSON_NULL
		do
			output ("<NULL/>")
			Result := Precursor
			output ("%N")
		end

	parse_string: detachable BSON_STRING
		do
			output ("<STRING>")
			Result := Precursor
			output ("</STRING>%N")
		end

	parse_double: detachable BSON_DOUBLE
		do
			output ("<DOUBLE>")
			Result := Precursor
			if Result /= Void then
				output (Result.debug_output)
			end
			output ("</DOUBLE>%N")
		end

	parse_int32: detachable BSON_INT32
		do
			output ("<INT32>")
			Result := Precursor
			if Result /= Void then
				output (Result.debug_output)
			end
			output ("</INT32>%N")
		end

	parse_int64: detachable BSON_INT64
		do
			output ("<INT64>")
			Result := Precursor
			if Result /= Void then
				output (Result.debug_output)
			end
			output ("</INT64>%N")
		end

	parse_boolean: detachable BSON_BOOLEAN
		do
			output ("<BOOL>")
			Result := Precursor
			if Result /= Void then
				output (Result.debug_output)
			end
			output ("</BOOL>%N")
		end

end
