note
	description: "[
		Unicode scalar values: the code points that UTF-8 can encode (U+0000..U+D7FF and
		U+E000..U+10FFFF). A CHARACTER_32 can also hold a surrogate (U+D800..U+DFFF) or a value
		above U+10FFFF, typically from UTF-16 data decoded one code unit at a time. Such a value
		has no UTF-8 form: UTF_CONVERTER writes a surrogate as a 3-byte CESU-8 sequence, and
		terminals show one to three U+FFFD for it, so the screen and the buffer disagree on columns.

		BUFFER and TERMINAL_CELL replace each non-scalar value with U+FFFD REPLACEMENT CHARACTER
		before it reaches a cell. The replacement is measurement-neutral: a non-scalar value and
		U+FFFD are both width 1 in UNICODE_WIDTH, and neither is a control, an extending code
		point, Extended_Pictographic or a regional indicator. So text measured before replacement
		(TEXT_SPAN.width, `string_width') takes the same columns once drawn.

		Surrogate pairs are replaced one by one, not joined: a joined pair would be one wide
		character where the text was measured as two narrow ones. Decode UTF-16 data as UTF-16
		(UTF_CONVERTER), not one code unit per CHARACTER_32, before drawing it.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	UNICODE_SCALAR

feature -- Status report

	is_scalar_value (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` a Unicode scalar value (not a surrogate, not above U+10FFFF)?
		do
			Result := a_code < 0xD800 or (a_code > 0xDFFF and a_code <= 0x10FFFF)
		ensure
			instance_free: class
		end

	is_scalar_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_string` hold only Unicode scalar values?
		local
			i: INTEGER
		do
			from
				Result := True
				i := 1
			until
				not Result or i > a_string.count
			loop
				Result := is_scalar_value (a_string.code (i))
				i := i + 1
			end
		ensure
			instance_free: class
		end

feature -- Conversion

	scalar_value (a_code: NATURAL_32): NATURAL_32
			-- `a_code` if it is a scalar value, `Replacement_character` otherwise.
		do
			if is_scalar_value (a_code) then
				Result := a_code
			else
				Result := Replacement_character
			end
		ensure
			instance_free: class
			scalar: is_scalar_value (Result)
			kept: is_scalar_value (a_code) implies Result = a_code
		end

	scalar_string (a_string: READABLE_STRING_GENERAL): READABLE_STRING_GENERAL
			-- `a_string` itself if it holds only scalar values, otherwise a copy in which every
			-- non-scalar value is `Replacement_character`.
		local
			i: INTEGER
			l_copy: STRING_32
		do
			if is_scalar_string (a_string) then
				Result := a_string
			else
				create l_copy.make (a_string.count)
				from
					i := 1
				until
					i > a_string.count
				loop
					l_copy.append_code (scalar_value (a_string.code (i)))
					i := i + 1
				end
				Result := l_copy
			end
		ensure
			instance_free: class
			scalar: is_scalar_string (Result)
			same_count: Result.count = a_string.count
			unchanged_if_valid: is_scalar_string (a_string) implies Result = a_string
		end

feature -- Constants

	Replacement_character: NATURAL_32 = 0xFFFD
			-- U+FFFD REPLACEMENT CHARACTER

end
