note
	description: "Testing of various conversion of the UTF_CONVERTER class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_UTF_CONVERTER

inherit
	EQA_TEST_SET

feature -- Testing UTF-16

	test_utf_16_roundtrip
		local
			s: STRING_32
			u: UTF_CONVERTER
			l_upper: CELL [INTEGER_32]
			q: MANAGED_POINTER
			l_spec16: SPECIAL [NATURAL_16]
		do
			s := {STRING_32} "Manu"
			create q.make (s.count * 2 + 2)
			create l_upper.put (0)
			u.escaped_utf_32_substring_into_utf_16_0_pointer (s, 1, s.count, q, 0, l_upper)
			assert ("test_utf_16_roundtrip - 1", u.utf_16_0_pointer_to_escaped_string_32 (q).same_string (s))
			assert ("test_utf_16_roundtrip - 2", u.utf_16_0_subpointer_to_string_32 (q, 0, (l_upper.item // 2) - 1, False).same_string (s))

			l_spec16 := u.string_32_to_utf_16 (s)
			if
				not (l_spec16.item (0).to_character_8 = 'M' and l_spec16.item (1).to_character_8 = 'a' and
				l_spec16.item (2).to_character_8 = 'n' and l_spec16.item (3).to_character_8 = 'u')
			then
				assert ("test_utf_16_roundtrip - 3", False)
			end

			create s.make (10)
			s.append_code (66186)
			create q.make (s.count * 2 + 2)
			u.escaped_utf_32_substring_into_utf_16_0_pointer (s, 1, s.count, q, 0, Void)
			assert ("test_utf_16_roundtrip - 4", u.utf_16_0_pointer_to_escaped_string_32 (q).same_string (s))
		end

	test_utf_16_d834_dd1e
		local
			u: UTF_CONVERTER
			p, q: MANAGED_POINTER
			l_str: STRING_32
			l_ref: STRING_32
			l_utf16le: STRING_8
		do
				-- Let's create a valid Surrogate pair
			create p.make (6)
			p.put_natural_16 (0xD834, 0)
			p.put_natural_16 (0xDD1E, 2)
			p.put_natural_16 (0x0, 4)
			create l_utf16le.make (6)
			l_utf16le.append_character ('%/0x34/')
			l_utf16le.append_character ('%/0xD8/')
			l_utf16le.append_character ('%/0x1E/')
			l_utf16le.append_character ('%/0xDD/')

			create l_ref.make (1)
			l_ref.append_character ('%/119070/')

			l_str := u.utf_16_0_pointer_to_string_32 (p)
			assert ("test_utf_16_d834_dd1e - 1", l_str.same_string (l_ref))

			l_str := u.utf_16le_string_8_to_string_32 (l_utf16le)
			assert ("test_utf_16_d834_dd1e - 2", l_str.same_string (l_ref))

			l_str := u.utf_16_0_pointer_to_escaped_string_32 (p)
			assert ("test_utf_16_d834_dd1e - 3", l_str.same_string (l_ref))

			l_str := u.utf_16le_string_8_to_escaped_string_32 (l_utf16le)
			assert ("test_utf_16_d834_dd1e - 4", l_str.same_string (l_ref))

				-- Now let's check that we roundtrip properly
				-- We preallocate a buffer for UTF-16 encoding that includes also the null character.
			create q.make ((l_ref.count + 1) * 2)
			u.escaped_utf_32_substring_into_utf_16_0_pointer (l_ref, 1, l_ref.count, q, 0, Void)
			assert ("test_utf_16_d834_dd1e - 5", q ~ p)

			create q.make ((l_ref.count + 1) * 2)
			u.utf_32_substring_into_utf_16_0_pointer (l_ref, 1, l_ref.count, q, 0, Void)
			assert ("test_utf_16_d834_dd1e - 6", q ~ p)
		end

	test_utf_16_d834_d000
		local
			u: UTF_CONVERTER
			p, q: MANAGED_POINTER
			l_str: STRING_32
			l_ref: STRING_32
			l_utf16le: STRING_8
		do
				-- Let's create an invalid valid Surrogate pair
			create p.make (6)
			p.put_natural_16 (0xD834, 0)
			p.put_natural_16 (0xD000, 2)
			p.put_natural_16 (0x0, 4)
			create l_utf16le.make (6)
			l_utf16le.append_character ('%/0x34/')
			l_utf16le.append_character ('%/0xD8/')
			l_utf16le.append_character ('%/0x00/')
			l_utf16le.append_character ('%/0xD0/')

			create l_ref.make (1)
			l_ref.append_character ('%/115712/')

			l_str := u.utf_16_0_pointer_to_string_32 (p)
			assert ("test_utf_16_d834_d000 - 1", l_str.same_string (l_ref))

			l_str := u.utf_16le_string_8_to_string_32 (l_utf16le)
			assert ("test_utf_16_d834_d000 - 2", l_str.same_string (l_ref))

				-- Now check with escape.
			create l_ref.make (7)
			l_ref.append_character ('%/65533/')
			l_ref.append_string_general ("uD834")
			l_ref.append_character ('%/53248/')

			l_str := u.utf_16_0_pointer_to_escaped_string_32 (p)
			assert ("test_utf_16_d834_d000 - 3", l_str.same_string (l_ref))

			l_str := u.utf_16le_string_8_to_escaped_string_32 (l_utf16le)
			assert ("test_utf_16_d834_d000 - 4", l_str.same_string (l_ref))

				-- Now let's check that we roundtrip properly
				-- We preallocate a buffer for UTF-16 encoding that includes also the null character.
			create q.make (2)
			u.escaped_utf_32_substring_into_utf_16_0_pointer (l_ref, 1, l_ref.count, q, 0, Void)
			assert ("test_utf_16_d834_d000 - 5", q ~ p)
		end

	test_utf_16_dc01_d834
		local
			u: UTF_CONVERTER
			p, q: MANAGED_POINTER
			l_str: STRING_32
			l_ref: STRING_32
			l_utf16le: STRING_8
		do
				-- Let's create an invalid valid Surrogate pair
			create p.make (6)
			p.put_natural_16 (0xDC01, 0)
			p.put_natural_16 (0xD834, 2)
			p.put_natural_16 (0x0, 4)
			create l_utf16le.make (6)
			l_utf16le.append_character ('%/0x01/')
			l_utf16le.append_character ('%/0xDC/')
			l_utf16le.append_character ('%/0x34/')
			l_utf16le.append_character ('%/0xD8/')

			create l_ref.make (1)
			l_ref.append_character ('%/1114164/')

			l_str := u.utf_16_0_pointer_to_string_32 (p)
			assert ("test_utf_16_dc01_d834 - 1", l_str.same_string (l_ref))

			l_str := u.utf_16le_string_8_to_string_32 (l_utf16le)
			assert ("test_utf_16_dc01_d834 - 2", l_str.same_string (l_ref))

			create l_ref.make (7)
			l_ref.append_character ('%/65533/')
			l_ref.append_string_general ("uDC01")
			l_ref.append_character ('%/65533/')
			l_ref.append_string_general ("uD834")

			l_str := u.utf_16_0_pointer_to_escaped_string_32 (p)
			assert ("test_utf_16_dc01_d834 - 3", l_str.same_string (l_ref))

			l_str := u.utf_16le_string_8_to_escaped_string_32 (l_utf16le)
			assert ("test_utf_16_dc01_d834 - 4", l_str.same_string (l_ref))

				-- Now let's check that we roundtrip properly
				-- We preallocate a buffer for UTF-16 encoding that includes also the null character.
			create q.make (2)
			u.escaped_utf_32_substring_into_utf_16_0_pointer (l_ref, 1, l_ref.count, q, 0, Void)
			assert ("test_utf_16_dc01_d834 - 5", q ~ p)
		end

	test_invalid_utf_16
			-- Test whenever we have an escape character if roundtrip works properly or not.
		local
			l_ptr: MANAGED_POINTER
			l_str32: STRING_32
			l_expected: STRING_32
			u: UTF_CONVERTER
		do
			create l_ptr.make (6)
			l_ptr.put_natural_16 (0xDC00, 0)
			l_ptr.put_natural_16 (0xDC00, 2)
			l_ptr.put_natural_16 (0x0, 4)

			create l_expected.make (6)
			l_expected.append_character ({UTF_CONVERTER}.escape_character)
			l_expected.append ("uDC00")
			l_expected.append_character ({UTF_CONVERTER}.escape_character)
			l_expected.append ("uDC00")

			l_str32 := u.utf_16_0_subpointer_to_escaped_string_32 (l_ptr, 0, 2, True)
			assert ("test_invalid_utf_16 - 1", l_str32 ~ l_expected)

				-- Slight variation, we replace the second 0xDC00 by 0xD800
			l_ptr.put_natural_16 (0xD800, 2)
			l_expected.put ('8', 10)

			l_str32 := u.utf_16_0_subpointer_to_escaped_string_32 (l_ptr, 0, 2, True)
			assert ("test_invalid_utf_16 - 2", l_str32 ~ l_expected)

				-- Mixed valid and invalid content
			create l_ptr.make (14)
			l_ptr.put_natural_16 (0xD800, 0)
			l_ptr.put_natural_16 (97, 2)
			l_ptr.put_natural_16 (0xDBFF, 4)
			l_ptr.put_natural_16 (98, 6)
			l_ptr.put_natural_16 (0xD800, 8)
			l_ptr.put_natural_16 (0xDC00, 10)
			l_ptr.put_natural_16 (0, 12)

			create l_expected.make (15)
			l_expected.append_character ({UTF_CONVERTER}.escape_character)
			l_expected.append ("uD800a")
			l_expected.append_character ({UTF_CONVERTER}.escape_character)
			l_expected.append ("uDBFFb")
			l_expected.append_character ('%/0x10000/')

			l_str32 := u.utf_16_0_subpointer_to_escaped_string_32 (l_ptr, 0, 6, True)
			assert ("test_invalid_utf_16", l_str32 ~ l_expected)
		end

	test_utf_16_with_escape_character
			-- Case where UTF-16 stream contains some escaped characters.
			-- It should not prevent any roundtrip between the UTF-32 representation
			-- and the UTF-16 one.
		local
			l_ptr: MANAGED_POINTER
			l_str32: STRING_32
			l_expected: STRING_32
			u: UTF_CONVERTER
			l_spec: SPECIAL [NATURAL_16]
		do
			create l_ptr.make (6)
			l_ptr.put_natural_16 (0xFFFD, 0)
			l_ptr.put_natural_16 (97, 2)
			l_ptr.put_natural_16 (0, 4)

			create l_expected.make (6)
			l_expected.append_character ({UTF_CONVERTER}.escape_character)
			l_expected.append ("a")

				-- Reading with or without escape should produce the same result.
			l_str32 := u.utf_16_0_subpointer_to_string_32 (l_ptr, 0, 2, True)
			assert ("test_utf_16_with_escape - 1", l_str32 ~ l_expected)
			l_str32 := u.utf_16_0_subpointer_to_escaped_string_32 (l_ptr, 0, 2, True)
			assert ("test_utf_16_with_escape - 2", l_str32 ~ l_expected)

				-- Converting the UTF-32 as with or without escaping should
				-- produce the same original UTF-16.
			l_spec := u.utf_32_string_to_utf_16 (l_str32)
			assert ("test_utf_16_with_escape - 3", l_spec.count = 2 and then l_spec.item (0) = 0xFFFD and then l_spec.item (1) = 97)
			u.escaped_utf_32_substring_into_utf_16_0_pointer (l_str32, 1, 2, l_ptr, 0, Void)
			assert ("test_utf_16_with_escape - 3", l_ptr.count = 6 and then l_ptr.read_natural_16 (0) = 0xFFFD and then l_ptr.read_natural_16 (2) = 97)
		end

	test_utf_32_with_escape_character_for_utf_16
			-- Assuming that the input STRING_32 has some escape characters, we check
			-- that converting it to a UTF-16 sequence will always yield the expected
			-- results.
		local
			l_str32: STRING_32
			l_result: STRING_32
			u: UTF_CONVERTER
			l_ptr: MANAGED_POINTER
			l_cell: detachable like upper
			l_str8: STRING_8
			i: INTEGER
		do
				-- We do the test twice. The first time without providing `upper',
				-- and the second with.
			from
				i := 0
			until
				i > 1
			loop
					-- I -Let's escape with what would be an invalid UTF-16 character.
				create l_str32.make (10)
				l_str32.append_character ({UTF_CONVERTER}.escape_character)
				l_str32.append ("uDC00")

				create l_ptr.make (2)
				u.escaped_utf_32_substring_into_utf_16_0_pointer (l_str32, 1, 6, l_ptr, 0, l_cell)
				assert ("test_utf_32_with_escape_character_for_utf_16 - 1", l_ptr.count >= 4 and l_ptr.read_natural_16 (0) = 0xDC00)

					-- Roundtrip to see if it is the same as the original
				l_result := u.utf_16_0_pointer_to_escaped_string_32 (l_ptr)
				assert ("test_utf_32_with_escape_character_for_utf_16 - 2", l_result ~ l_str32)

					-- Same but with STRING_8 output
				l_str8 := u.escaped_utf_32_string_to_utf_16le_string_8 (l_str32)
				assert ("test_utf_32_with_escape_character_for_utf_16 - 1_bis", l_str8.count = 2 and l_str8 ~ "%U%/220/")
					-- Roundtrip
				l_result := u.utf_16le_string_8_to_escaped_string_32 (l_str8)
				assert ("test_utf_32_with_escape_character_for_utf_16 - 2bis", l_result ~ l_str32)

					-- II - Let's escape with what would be a valid UTF-16 character.
				create l_str32.make (10)
				l_str32.append_character ({UTF_CONVERTER}.escape_character)
				l_str32.append ("u0061")

				create l_ptr.make (2)
				u.escaped_utf_32_substring_into_utf_16_0_pointer (l_str32, 1, 6, l_ptr, 0, l_cell)
				if l_cell /= Void then
					assert ("test_uft_32_with_escape - 3", l_cell.item <= l_ptr.count)
				else
					assert ("test_uft_32_with_escape - 4", l_ptr.count >= 14)
				end
				assert ("test_utf_32_with_escape_character_for_utf_16 - 5",
					(l_ptr.read_natural_16 (0) = 0xFFFD and -- '?'
					l_ptr.read_natural_16 (2) = 0x75 and -- 'u'
					l_ptr.read_natural_16 (4) = 0x30 and -- '0'
					l_ptr.read_natural_16 (6) = 0x30 and -- '0'
					l_ptr.read_natural_16 (8) = 0x36 and -- '6'
					l_ptr.read_natural_16 (10) = 0x31 and -- '1'
					l_ptr.read_natural_16 (12) = 0x0))

					-- Roundtrip to see if it is the same as the original
				l_result := u.utf_16_0_pointer_to_escaped_string_32 (l_ptr)
				assert ("test_utf_32_with_escape_character_for_utf_16 - 6", l_result ~ l_str32)

					-- Same but with STRING_8 output
				l_str8 := u.escaped_utf_32_string_to_utf_16le_string_8 (l_str32)
				assert ("test_utf_32_with_escape_character_for_utf_16 - 5bis", l_str8 ~ "%/253/%/255/u%U0%U0%U6%U1%U")
					-- Roundtrip
				l_result := u.utf_16le_string_8_to_escaped_string_32 (l_str8)
				assert ("test_utf_32_with_escape_character_for_utf_16 - 6bis", l_result ~ l_str32)
				l_cell := upper
				i := i + 1
			end
		end

	test_utf_16_multiline
		local
			str: STRING_32
			u: UTF_CONVERTER
			l_ptr: MANAGED_POINTER
		do
			create str.make (20)
			str.append_character ('a')
			str.append_code (66185)
			str.append_code (66186)
			str.append_code (66300)
			str.append_code (66301)
			str.append_code (66302)
			str.append_code (66303)
			str.append_code (66304)
			str.append ("%N")
			str.append_code (65530)
			str.append_code (65531)
			str.append_code (65532)
			str.append_code (65533)
			str.append ("%NS")

			create l_ptr.make (34)
				-- We are testing that
			u.escaped_utf_32_substring_into_utf_16_0_pointer (str, 10, 13, l_ptr, 34, Void)

			assert ("Proper retrieve", u.utf_16_0_subpointer_to_escaped_string_32 (l_ptr, 17, 20, False).same_string (str.substring (10, 13)))
		end

	test_utf_16_postconditions
			-- Regression: postconditions of the UTF-16 conversion routines
			-- (string_32_to_utf_16, utf_16_0_pointer_to_string_32 and
			-- utf_16_0_subpointer_to_string_32 with `start_pos' = 1) used to be wrong
			-- or to fail when the input contained a BMP character such as U+20AC.
		local
			u: UTF_CONVERTER
			r: SPECIAL [NATURAL_16]
		do
			r := u.string_32_to_utf_16 ({STRING_32} "%/0x20AC/a")
			assert ("test_utf_16_postconditions - 1", r.count = 2 and r [0] = 0x20AC and r [1] = 0x61)

			assert ("test_utf_16_postconditions - 2",
				u.utf_16_0_pointer_to_string_32 (units (<<0x20AC, 0x61, 0>>)).same_string ({STRING_32} "%/0x20AC/a"))

			assert ("test_utf_16_postconditions - 3",
				u.utf_16_0_subpointer_to_string_32 (units (<<0x78, 0x20AC, 0x61>>), 1, 2, False).same_string ({STRING_32} "%/0x20AC/a"))
		end

	test_utf_32_substring_into_utf_16_pointer_upper
			-- Regression: `a_new_upper' of `utf_32_substring_into_utf_16_pointer' was
			-- 2 bytes too small when `p' had to be resized, losing the last code unit.
		local
			u: UTF_CONVERTER
			p: MANAGED_POINTER
			l_upper: CELL [INTEGER]
		do
			create p.make (0)
			create l_upper.put (0)
			u.utf_32_substring_into_utf_16_pointer ({STRING_32} "a%/0x1F600/", 1, 2, p, 0, l_upper)
			assert ("test_utf_32_substring_into_utf_16_pointer_upper - 1", l_upper.item = 6)
			assert ("test_utf_32_substring_into_utf_16_pointer_upper - 2", p.count = 6)
			assert ("test_utf_32_substring_into_utf_16_pointer_upper - 3", p.read_natural_16 (2) = 0xD83D)
			assert ("test_utf_32_substring_into_utf_16_pointer_upper - 4", p.read_natural_16 (4) = 0xDE00)
		end

	test_escaped_utf_32_substring_with_offset_utf_16
			-- Regression: `escaped_utf_32_substring_into_utf_16_0_pointer' did not
			-- handle an escape sequence in a substring starting at `start_pos' > 1.
		local
			u: UTF_CONVERTER
			p: MANAGED_POINTER
			l_upper: CELL [INTEGER]
		do
			create p.make (32)
			create l_upper.put (0)
			u.escaped_utf_32_substring_into_utf_16_0_pointer ({STRING_32} "xx%/0xFFFD/uD800", 3, 8, p, 0, l_upper)
			assert ("test_escaped_utf_32_substring_with_offset_utf_16 - 1", l_upper.item = 2)
			assert ("test_escaped_utf_32_substring_with_offset_utf_16 - 2", p.read_natural_16 (0) = 0xD800)
			assert ("test_escaped_utf_32_substring_with_offset_utf_16 - 3", p.read_natural_16 (2) = 0)
		end

	test_utf_16_escaped_roundtrips
			-- Escaped UTF-32 to UTF-16 and back must be the identity,
			-- including for strings containing escape sequences and U+10FFFF.
		local
			u: UTF_CONVERTER
			p: MANAGED_POINTER
			s32: STRING_32
		do
			across samples_32 as c loop
				create p.make (0)
				u.escaped_utf_32_substring_into_utf_16_0_pointer (c, 1, c.count, p, 0, Void)
				s32 := u.utf_16_0_pointer_to_escaped_string_32 (p)
				assert ("test_utf_16_escaped_roundtrips - " + @ c.target_index.out, s32.same_string (c))
			end
		end

feature -- Status report

	test_is_valid_utf_16
			-- Regression: `is_valid_utf_16le_string_8', `is_valid_utf_16' and
			-- `is_valid_utf_16_subpointer' used to reject valid surrogate pairs
			-- or to accept a lone lead surrogate.
		local
			u: UTF_CONVERTER
			s: SPECIAL [NATURAL_16]
		do
			assert ("test_is_valid_utf_16 - 1", u.is_valid_utf_16le_string_8 ("a%U%/61/%/216/%U%/222/"))
			assert ("test_is_valid_utf_16 - 2", not u.is_valid_utf_16le_string_8 ("%/61/%/216/a%U"))

			create s.make_filled (0, 2)
			s [0] := 0xD83D
			s [1] := 0xDE00
			assert ("test_is_valid_utf_16 - 3", u.is_valid_utf_16 (s))

			assert ("test_is_valid_utf_16 - 4", u.is_valid_utf_16_subpointer (units (<<0x61, 0xD83D, 0xDE00>>), 0, 2, False))
			assert ("test_is_valid_utf_16 - 5", not u.is_valid_utf_16_subpointer (units (<<0x61, 0xD83D, 0x62>>), 0, 2, False))
		end

feature -- Measurement

	test_utf_16_characters_count
			-- `utf_16_characters_count_form_pointer' must count a surrogate
			-- pair as one character (here: 'a', U+1F600 and U+20AC, so 3).
		local
			u: UTF_CONVERTER
		do
			assert ("test_utf_16_characters_count - 1",
				u.utf_16_characters_count_form_pointer (units (<<0x61, 0xD83D, 0xDE00, 0x20AC, 0>>), 0, 8) = 3)
		end

feature -- UTF-8

	test_utf_8_roundtrip
		local
			s: STRING_32
			l_utf8: STRING_8
			u: UTF_CONVERTER
			l_upper: CELL [INTEGER_32]
			q: MANAGED_POINTER
			l_spec8: SPECIAL [NATURAL_8]
		do
			create s.make (2)
			s.append_character ('%/112900/')
			s.append_character ('%U')
			s.append_character ('a')
			s.append_character ('%/119070/')

			l_utf8 := u.escaped_utf_32_string_to_utf_8_string_8 (s)
			assert ("test_utf_8_roundtrip - 1", l_utf8.same_string ("%/240/%/155/%/164/%/132/%Ua%/240/%/157/%/132/%/158/"))

				-- Various conversion using different initial size for `q' that will trigger
				-- some kind of resizing.
			create q.make (s.count + 1)
			create l_upper.put (0)
			u.escaped_utf_32_substring_into_utf_8_0_pointer (s, 1, s.count, q, 0, l_upper)
			assert ("test_utf_8_roundtrip - 2", u.utf_8_0_subpointer_to_escaped_string_32 (q, 0, l_upper.item - 1, False).same_string (s))

			create q.make (s.count + 10)
			create l_upper.put (0)
			u.escaped_utf_32_substring_into_utf_8_0_pointer (s, 1, s.count, q, 0, l_upper)
			assert ("test_utf_8_roundtrip - 3", u.utf_8_0_subpointer_to_escaped_string_32 (q, 0, l_upper.item - 1, False).same_string (s))

			create q.make (1)
			create l_upper.put (0)
			u.escaped_utf_32_substring_into_utf_8_0_pointer (s, 1, s.count, q, 0, l_upper)
			assert ("test_utf_8_roundtrip - 4", u.utf_8_0_subpointer_to_escaped_string_32 (q, 0, l_upper.item - 1, False).same_string (s))


			create s.make (2)
			s.append_character ('%/112900/')
			s.append_character ('a')
			s.append_character ('%/119070/')
			create q.make (1)
			create l_upper.put (0)
			u.utf_32_string_into_utf_8_0_pointer (s, q, 0, l_upper)
			assert ("test_utf_8_roundtrip - 5", u.utf_8_0_pointer_to_escaped_string_32 (q).same_string (s))

			s := {STRING_32} "Manu"
			l_spec8 := u.utf_32_string_to_utf_8 (s)
			if
				not (l_spec8.item (0).to_character_8 = 'M' and l_spec8.item (1).to_character_8 = 'a' and
				l_spec8.item (2).to_character_8 = 'n' and l_spec8.item (3).to_character_8 = 'u')
			then
				assert ("test_utf_8_roundtrip - 6", False)
			end
		end

	test_invalid_utf_8
			-- Test whenever we have an escape character if roundtrip works properly or not.
		local
			l_str8: STRING_8
			l_str32: STRING_32
			l_expected: STRING_32
			u: UTF_CONVERTER
		do
			create l_str8.make (10)
			l_str8.append_character ('%/0x8F/')
			l_str8.append_character ('%/0x8F/')

			create l_expected.make (6)
			l_expected.append_character ({UTF_CONVERTER}.escape_character)
			l_expected.append ("8F")
			l_expected.append_character ({UTF_CONVERTER}.escape_character)
			l_expected.append ("8F")

			l_str32 := u.utf_8_string_8_to_escaped_string_32 (l_str8)

			assert ("test_invalid_utf_8", l_str32 ~ l_expected)
		end

	test_utf_32_with_escape_character_for_utf_8
			-- Assuming that the input STRING_32 has some escape characters, we check
			-- that converting it to a UTF-8 sequence will always yield the expected
			-- results.
		local
			l_str32: STRING_32
			l_result: STRING_32
			u: UTF_CONVERTER
			l_ptr: MANAGED_POINTER
			l_cell: detachable like upper
			l_str8: STRING_8
			i: INTEGER
		do
				-- We do the test twice. The first time without providing `upper',
				-- and the second with.
			from
				i := 0
			until
				i > 1
			loop
					-- I - Let's escape with what would be an invalid UTF-8 character.
				create l_str32.make (10)
				l_str32.append_character ({UTF_CONVERTER}.escape_character)
				l_str32.append ("8F")

				create l_ptr.make (2)
				u.escaped_utf_32_substring_into_utf_8_0_pointer(l_str32, 1, 3, l_ptr, 0, l_cell)
				assert ("test_utf_32_with_escape_character_for_utf_8 - 1", l_ptr.count >= 2 and l_ptr.read_natural_8 (0) = 0x8F)

					-- Roundtrip to see if it is the same as the original
				l_result := u.utf_8_0_pointer_to_escaped_string_32 (l_ptr)
				assert ("test_utf_32_with_escape_character_for_utf_8 - 2", l_result ~ l_str32)

					-- Same but to a STRING_8 output
				l_str8 := u.escaped_utf_32_string_to_utf_8_string_8 (l_str32)
				assert ("test_utf_32_with_escape_character_for_utf_8 - 1bis", l_str8.count = 1 and l_str8.code (1) = 0x8F)
					-- Roundtrip testing
				l_result := u.utf_8_string_8_to_escaped_string_32 (l_str8)
				assert ("test_utf_32_with_escape_character_for_utf_8 - 2bis", l_result ~ l_str32)


					-- II - Let's escape with what would be a valid UTF-8 character.
				create l_str32.make (10)
				l_str32.append_character ({UTF_CONVERTER}.escape_character)
				l_str32.append ("61")

				create l_ptr.make (2)
				u.escaped_utf_32_substring_into_utf_8_0_pointer (l_str32, 1, 3, l_ptr, 0, l_cell)
				if l_cell /= Void then
					assert ("test_utf_32_with_escape - 3", l_cell.item <= l_ptr.count)
				else
					assert ("test_uft_32_with_escape - 4", l_ptr.count >= 6)
				end
				assert ("test_utf_32_with_escape_character_for_utf_8 - 5",
					(l_ptr.read_natural_8 (0) = 0xEF and l_ptr.read_natural_8 (1) = 0xBF and l_ptr.read_natural_8 (2) = 0xBD and -- '?'
					l_ptr.read_natural_8 (3) = 0x36 and -- '6'
					l_ptr.read_natural_8 (4) = 0x31 and -- '1'
					l_ptr.read_natural_8 (5) = 0x0))

					-- Roundtrip to see if it is the same as the original
				l_result := u.utf_8_0_pointer_to_escaped_string_32 (l_ptr)
				assert ("test_utf_32_with_escape_character_for_utf_8 - 6", l_result ~ l_str32)

					-- Same but to a STRING_8 output
				l_str8 := u.escaped_utf_32_string_to_utf_8_string_8 (l_str32)
				assert ("test_utf_32_with_escape_character_for_utf_8 - 5bis", l_str8 ~ "%/239/%/191/%/189/61")
					-- Roundtrip testing
				l_result := u.utf_8_string_8_to_escaped_string_32 (l_str8)
				assert ("test_utf_32_with_escape_character_for_utf_8 - 6bis", l_result ~ l_str32)
				l_cell := upper
				i := i + 1
			end
		end

	test_utf_8_overlong
			-- Regression: the escaped UTF-8 decoders accepted overlong encodings
			-- (C0 AF, E0 80 AF) instead of escaping each byte, and must
			-- still decode valid text properly.
		local
			u: UTF_CONVERTER
			s: STRING_8
			p: MANAGED_POINTER
		do
			assert ("test_utf_8_overlong - 1",
				u.utf_8_string_8_to_escaped_string_32 ("%/192/%/175/").same_string ({STRING_32} "%/0xFFFD/C0%/0xFFFD/AF"))

			create p.make (4)
			p.put_natural_8 (0xE0, 0)
			p.put_natural_8 (0x80, 1)
			p.put_natural_8 (0xAF, 2)
			p.put_natural_8 (0, 3)
			assert ("test_utf_8_overlong - 2",
				u.utf_8_0_pointer_to_escaped_string_32 (p).same_string ({STRING_32} "%/0xFFFD/E0%/0xFFFD/80%/0xFFFD/AF"))

				-- Valid text of 1 to 4 bytes, including the lowest 3 and 4-byte characters.
			s := "a%/195/%/169/%/226/%/130/%/172/%/240/%/159/%/152/%/128/%/224/%/160/%/128/%/240/%/144/%/128/%/128/"
			create p.make (s.count + 1)
			across s as c loop
				p.put_natural_8 (c.code.to_natural_8, @ c.target_index - 1)
			end
			p.put_natural_8 (0, s.count)
			assert ("test_utf_8_overlong - 3", u.utf_8_string_8_to_escaped_string_32 (s).same_string (expected_valid_text))
			assert ("test_utf_8_overlong - 4", u.utf_8_0_pointer_to_escaped_string_32 (p).same_string (expected_valid_text))
		end

	test_escaped_utf_32_substring_with_offset_utf_8
			-- Regression: `escaped_utf_32_substring_into_utf_8_0_pointer' did not
			-- handle an escape sequence in a substring starting at `start_pos' > 1.
		local
			u: UTF_CONVERTER
			p: MANAGED_POINTER
			l_upper: CELL [INTEGER]
		do
			create p.make (16)
			create l_upper.put (0)
			u.escaped_utf_32_substring_into_utf_8_0_pointer ({STRING_32} "xx%/0xFFFD/8F", 3, 5, p, 0, l_upper)
			assert ("test_escaped_utf_32_substring_with_offset_utf_8 - 1", l_upper.item = 1)
			assert ("test_escaped_utf_32_substring_with_offset_utf_8 - 2", p.read_natural_8 (0) = 0x8F)
			assert ("test_escaped_utf_32_substring_with_offset_utf_8 - 3", p.read_natural_8 (1) = 0)
		end

	test_utf_8_escaped_roundtrips
			-- Regression: escaped UTF-8 to UTF-32 and back must be the identity,
			-- including for invalid, overlong and truncated sequences.
		local
			u: UTF_CONVERTER
			s32: STRING_32
		do
			across samples_8 as c loop
				s32 := u.utf_8_string_8_to_escaped_string_32 (c)
				assert ("test_utf_8_escaped_roundtrips - " + @ c.target_index.out, u.escaped_utf_32_string_to_utf_8_string_8 (s32).same_string (c))
			end
		end

feature -- Status report (UTF-8)

	test_is_valid_utf_8_string_8
			-- Regression: `is_valid_utf_8_string_8' accepted overlong encodings, UTF-16
			-- surrogates and code points above U+10FFFF, or rejected valid boundary values.
		local
			u: UTF_CONVERTER
		do
				-- Valid: 1, 2, 3, 4-byte characters, U+10FFFF, U+D7FF and U+E000.
			assert ("test_is_valid_utf_8_string_8 - 1",
				u.is_valid_utf_8_string_8 ("a%/195/%/169/%/226/%/130/%/172/%/240/%/159/%/152/%/128/%/244/%/143/%/191/%/191/%/237/%/159/%/191/%/238/%/128/%/128/"))

				-- Invalid: overlong 2, 2, 3 and 4-byte, surrogate, > U+10FFFF, invalid lead 0xF5.
			assert ("test_is_valid_utf_8_string_8 - 2", not u.is_valid_utf_8_string_8 ("%/192/%/175/"))
			assert ("test_is_valid_utf_8_string_8 - 3", not u.is_valid_utf_8_string_8 ("%/193/%/191/"))
			assert ("test_is_valid_utf_8_string_8 - 4", not u.is_valid_utf_8_string_8 ("%/224/%/128/%/175/"))
			assert ("test_is_valid_utf_8_string_8 - 5", not u.is_valid_utf_8_string_8 ("%/240/%/128/%/128/%/175/"))
			assert ("test_is_valid_utf_8_string_8 - 6", not u.is_valid_utf_8_string_8 ("%/237/%/160/%/128/"))
			assert ("test_is_valid_utf_8_string_8 - 7", not u.is_valid_utf_8_string_8 ("%/244/%/144/%/128/%/128/"))
			assert ("test_is_valid_utf_8_string_8 - 8", not u.is_valid_utf_8_string_8 ("%/245/%/128/%/128/%/128/"))
		end

feature -- Measurement (UTF-8)

	test_utf_8_to_string_32_count
			-- Regression: `utf_8_to_string_32_count' miscounted when a multi-byte
			-- character ended exactly at `end_pos', must agree with the decoder
			-- `utf_8_string_8_to_string_32', and used to loop forever on an invalid lead byte.
		local
			u: UTF_CONVERTER
			s: STRING_8
		do
			s := "%/194/%/169/"
			assert ("test_utf_8_to_string_32_count - 1", u.utf_8_to_string_32_count (s.area, 0, 1) = 1)

			s := "a%/226/%/130/%/172/"
			assert ("test_utf_8_to_string_32_count - 2", u.utf_8_to_string_32_count (s.area, 0, 3) = 2)

			s := "%/240/%/159/%/152/%/128/"
			assert ("test_utf_8_to_string_32_count - 3", u.utf_8_to_string_32_count (s.area, 0, 3) = 1)

				-- Consistency with the decoder.
			across samples_8 as c loop
				s := c
				if s.count > 0 then
					assert ("test_utf_8_to_string_32_count - 4 (sample " + @ c.target_index.out + ")",
						u.utf_8_to_string_32_count (s.area, 0, s.count - 1) = u.utf_8_string_8_to_string_32 (s).count)
				end
			end

				-- Invalid lead byte 0xF8 used to hang forever.
			s := "%/248/a"
			assert ("test_utf_8_to_string_32_count - 5", u.utf_8_to_string_32_count (s.area, 0, 1) = 1)
		end

feature {NONE} -- Implementation

	upper: CELL [INTEGER]
		once
			create Result.put (0)
		end

	expected_valid_text: STRING_32
			-- Expected decoding of the valid text used in `test_utf_8_overlong'.
		once
			Result := {STRING_32} "a%/0xE9/%/0x20AC/%/0x1F600/%/0x800/%/0x10000/"
		end

	samples_8: ARRAY [STRING_8]
			-- UTF-8 samples, valid and invalid.
		once
			Result := <<"", "abc", "%/195/%/169/", "%/226/%/130/%/172/", "%/240/%/159/%/152/%/128/",
				"%/192/%/175/", "%/224/%/128/%/175/", "%/240/%/128/%/128/%/175/", "%/237/%/160/%/128/",
				"%/143/%/143/", "%/195/", "a%/226/%/130/", "%/255/%/254/x", "x%/248/%/136/%/128/%/128/%/128/">>
		end

	samples_32: ARRAY [STRING_32]
			-- UTF-32 samples, some with escape sequences.
		once
			Result := <<{STRING_32} "", {STRING_32} "abc", {STRING_32} "%/0xE9/%/0x20AC/%/0x1F600/",
				{STRING_32} "x%/0xFFFD/uD800y", {STRING_32} "%/0x10FFFF/z">>
		end

	units (a: ARRAY [INTEGER]): MANAGED_POINTER
			-- Buffer holding the 16-bit code units `a'.
		do
			create Result.make (a.count * 2)
			across a as c loop
				Result.put_natural_16 (c.to_natural_16, (@ c.target_index - a.lower) * 2)
			end
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
