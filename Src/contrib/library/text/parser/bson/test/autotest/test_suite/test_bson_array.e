note
	description: "Tests for BSON_ARRAY class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_BSON_ARRAY

inherit
	EQA_TEST_SET

feature -- Tests

	test_empty_array
			-- Test empty array creation.
		local
			arr: BSON_ARRAY
		do
			create arr.make_empty
			assert ("is_empty", arr.is_empty)
			assert ("count_zero", arr.count = 0)
			assert ("is_array", arr.is_array)
		end

	test_array_extend
			-- Test extending array.
		local
			arr: BSON_ARRAY
		do
			create arr.make_empty

			arr.extend_string ("first")
			assert ("count_one", arr.count = 1)
			assert ("first_is_string", arr [1].is_string)

			arr.extend_int32 (42)
			assert ("count_two", arr.count = 2)
			assert ("second_is_int32", arr [2].is_int32)

			arr.extend_boolean (True)
			assert ("count_three", arr.count = 3)
			assert ("third_is_boolean", arr [3].is_boolean)
		end

	test_array_from_strings
			-- Test creating array from string list.
		local
			arr: BSON_ARRAY
			lst: ARRAYED_LIST [STRING]
		do
			create lst.make (3)
			lst.extend ("one")
			lst.extend ("two")
			lst.extend ("three")

			create arr.make_from_string_list (lst)
			assert ("count_three", arr.count = 3)
			assert ("first_is_string", arr [1].is_string)
			assert ("first_value", attached {BSON_STRING} arr [1] as s and then s.same_string ("one"))
		end

	test_array_iteration
			-- Test iterating over array.
		local
			arr: BSON_ARRAY
			count: INTEGER
		do
			create arr.make_empty
			arr.extend_int32 (1)
			arr.extend_int32 (2)
			arr.extend_int32 (3)

			count := 0
			across arr as c loop
				count := count + 1
			end
			assert ("iteration_count", count = 3)
		end

	test_array_wipe_out
			-- Test wiping out array.
		local
			arr: BSON_ARRAY
		do
			create arr.make_empty
			arr.extend_string ("value")
			assert ("not_empty", not arr.is_empty)

			arr.wipe_out
			assert ("is_empty", arr.is_empty)
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
