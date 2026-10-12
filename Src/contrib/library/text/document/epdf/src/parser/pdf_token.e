note
	description: "[
		Represents a lexical token in a PDF file.
		Tokens are the atomic units produced by the lexer (PDF_LEXER).
		Each token has a type and optional value.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_TOKEN

create
	make

feature -- Initialization

	make (a_type: INTEGER; a_value: STRING_8)
			-- Create token with given type and value.
		require
			valid_type: is_valid_type (a_type)
		do
			token_type := a_type
			value := a_value
		ensure
			type_set: token_type = a_type
			value_set: value = a_value
		end

feature -- Access

	token_type: INTEGER
			-- Type of this token.

	value: STRING_8
			-- String value of this token.

feature -- Token Types

	type_eof: INTEGER = 0
			-- End of file.

	type_null: INTEGER = 1
			-- Null keyword.

	type_boolean: INTEGER = 2
			-- Boolean (true/false).

	type_number: INTEGER = 3
			-- Numeric literal (integer or real).

	type_string: INTEGER = 4
			-- String literal ((...) or <...>).

	type_name: INTEGER = 5
			-- Name object (/Name).

	type_array_start: INTEGER = 6
			-- Array start ([).

	type_array_end: INTEGER = 7
			-- Array end (]).

	type_dict_start: INTEGER = 8
			-- Dictionary start (<<).

	type_dict_end: INTEGER = 9
			-- Dictionary end (>>).

	type_stream_start: INTEGER = 10
			-- Stream keyword.

	type_stream_end: INTEGER = 11
			-- Endstream keyword.

	type_obj_start: INTEGER = 12
			-- Obj keyword.

	type_obj_end: INTEGER = 13
			-- Endobj keyword.

	type_ref: INTEGER = 14
			-- Reference (R keyword).

	type_xref: INTEGER = 15
			-- Xref keyword.

	type_trailer: INTEGER = 16
			-- Trailer keyword.

	type_startxref: INTEGER = 17
			-- Startxref keyword.

	type_hex_string: INTEGER = 18
			-- Hexadecimal string literal (<...>).

feature -- Status Report

	is_valid_type (a_type: INTEGER): BOOLEAN
			-- Is the given type valid?
		do
			Result := a_type >= type_eof and a_type <= type_hex_string
		end

	is_eof: BOOLEAN
			-- Is this an EOF token?
		do
			Result := token_type = type_eof
		end


	is_keyword (a_keyword: STRING_8): BOOLEAN
			-- Does this token match the given keyword?
			-- Uses STRING_8 as PDF keywords are ASCII byte sequences.
		do
			Result := value.is_equal (a_keyword)
		end

end
