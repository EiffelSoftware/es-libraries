note
	description: "Tests for YAML_SEQUENCE class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_YAML_SEQUENCE

inherit
	EQA_TEST_SET

feature -- Test routines

	test_make_empty
			-- Test creating an empty sequence.
		local
			seq: YAML_SEQUENCE
		do
			create seq.make
			assert ("is_sequence", seq.is_sequence)
			assert ("is_empty", seq.is_empty)
			assert ("count_zero", seq.count = 0)
		end

	test_extend
			-- Test extending a sequence.
		local
			seq: YAML_SEQUENCE
			scalar: YAML_STRING
		do
			create seq.make
			create scalar.make_plain ("item1")
			seq.extend (scalar)
			assert ("count_one", seq.count = 1)
			assert ("first_correct", seq.first = scalar)
		end

	test_multiple_items
			-- Test sequence with multiple items.
		local
			seq: YAML_SEQUENCE
			s1, s2, s3: YAML_STRING
		do
			create seq.make
			create s1.make_plain ("first")
			create s2.make_plain ("second")
			create s3.make_plain ("third")
			seq.extend (s1)
			seq.extend (s2)
			seq.extend (s3)
			assert ("count_three", seq.count = 3)
			assert ("item_1", seq [1] = s1)
			assert ("item_2", seq [2] = s2)
			assert ("item_3", seq [3] = s3)
			assert ("first", seq.first = s1)
			assert ("last", seq.last = s3)
		end

	test_put
			-- Test replacing an item.
		local
			seq: YAML_SEQUENCE
			s1, s2, replacement: YAML_STRING
		do
			create seq.make
			create s1.make_plain ("first")
			create s2.make_plain ("second")
			create replacement.make_plain ("replaced")
			seq.extend (s1)
			seq.extend (s2)
			seq.put (replacement, 1)
			assert ("replaced", seq [1] = replacement)
		end

	test_remove
			-- Test removing an item.
		local
			seq: YAML_SEQUENCE
			s1, s2: YAML_STRING
		do
			create seq.make
			create s1.make_plain ("first")
			create s2.make_plain ("second")
			seq.extend (s1)
			seq.extend (s2)
			seq.remove (1)
			assert ("count_one", seq.count = 1)
			assert ("remaining_is_s2", seq [1] = s2)
		end

	test_wipe_out
			-- Test clearing a sequence.
		local
			seq: YAML_SEQUENCE
		do
			create seq.make
			seq.extend (create {YAML_STRING}.make_plain ("item"))
			seq.extend (create {YAML_STRING}.make_plain ("item2"))
			seq.wipe_out
			assert ("empty_after_wipe_out", seq.is_empty)
		end

	test_flow_style
			-- Test flow style setting.
		local
			seq: YAML_SEQUENCE
		do
			create seq.make
			assert ("default_block", not seq.is_flow_style)
			seq.set_flow_style (True)
			assert ("now_flow", seq.is_flow_style)
		end

	test_iteration
			-- Test iterating over sequence.
		local
			seq: YAML_SEQUENCE
			count: INTEGER
		do
			create seq.make
			seq.extend (create {YAML_STRING}.make_plain ("a"))
			seq.extend (create {YAML_STRING}.make_plain ("b"))
			seq.extend (create {YAML_STRING}.make_plain ("c"))
			across seq as ic loop
				count := count + 1
			end
			assert ("iterated_all", count = 3)
		end

	test_nested_sequence
			-- Test sequence containing another sequence.
		local
			outer, inner: YAML_SEQUENCE
		do
			create outer.make
			create inner.make
			inner.extend (create {YAML_STRING}.make_plain ("nested"))
			outer.extend (inner)
			assert ("outer_count", outer.count = 1)
			assert ("inner_is_sequence", outer.first.is_sequence)
		end

	test_representation_block
			-- Test block style representation.
		local
			seq: YAML_SEQUENCE
			repr: STRING_32
		do
			create seq.make
			seq.extend (create {YAML_STRING}.make_plain ("item1"))
			seq.extend (create {YAML_STRING}.make_plain ("item2"))
			repr := seq.representation
			assert ("has_dash", repr.has_substring ("- "))
		end

	test_representation_flow
			-- Test flow style representation.
		local
			seq: YAML_SEQUENCE
			repr: STRING_32
		do
			create seq.make
			seq.set_flow_style (True)
			seq.extend (create {YAML_STRING}.make_plain ("a"))
			seq.extend (create {YAML_STRING}.make_plain ("b"))
			repr := seq.representation
			assert ("starts_bracket", repr.starts_with ("["))
			assert ("ends_bracket", repr.ends_with ("]"))
		end

end
