note
	description: "Tests for YAML_MAPPING class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_YAML_MAPPING

inherit
	EQA_TEST_SET

feature -- Test routines

	test_make_empty
			-- Test creating an empty mapping.
		local
			mapping: YAML_MAPPING
		do
			create mapping.make
			assert ("is_mapping", mapping.is_mapping)
			assert ("is_empty", mapping.is_empty)
			assert ("count_zero", mapping.count = 0)
		end

	test_put_and_value_at
			-- Test putting and retrieving values.
		local
			mapping: YAML_MAPPING
			key: YAML_STRING
			value: YAML_STRING
		do
			create mapping.make
			create key.make ("name")
			create value.make ("John")
			mapping.put (value, key)
			assert ("count_one", mapping.count = 1)
			assert ("has_key", mapping.has_key ("name"))
			assert ("value_correct", attached mapping.value_at ("name") as v and then attached {YAML_SCALAR} v as s and then s.value.same_string ("John"))
		end

	test_put_string
			-- Test put_string convenience method.
		local
			mapping: YAML_MAPPING
		do
			create mapping.make
			mapping.put (create {YAML_SCALAR}.make_integer (30), "age")
			assert ("has_age", mapping.has_key ("age"))
		end

	test_replace_value
			-- Test replacing a value for an existing key.
		local
			mapping: YAML_MAPPING
			v1, v2: YAML_STRING
		do
			create mapping.make
			create v1.make ("original")
			create v2.make ("replacement")
			mapping.put (v1, "key")
			mapping.put (v2, "key")
			assert ("count_still_one", mapping.count = 1)
			assert ("value_replaced", attached mapping.value_at ("key") as v and then v = v2)
		end

	test_remove
			-- Test removing an entry.
		local
			mapping: YAML_MAPPING
		do
			create mapping.make
			mapping.put_string ("value1", "key1")
			mapping.put_string ("value2", "key2")
			mapping.remove ("key1")
			assert ("count_one", mapping.count = 1)
			assert ("key1_removed", not mapping.has_key ("key1"))
			assert ("key2_exists", mapping.has_key ("key2"))
		end

	test_wipe_out
			-- Test clearing a mapping.
		local
			mapping: YAML_MAPPING
		do
			create mapping.make
			mapping.put_string ("1", "a")
			mapping.put_string ("2", "b")
			mapping.wipe_out
			assert ("empty_after_wipe_out", mapping.is_empty)
		end

	test_key_at_and_value_at_index
			-- Test accessing by index.
		local
			mapping: YAML_MAPPING
		do
			create mapping.make
			mapping.put_string ("1", "first")
			mapping.put_string ("2", "second")
			assert ("key_1", attached {YAML_SCALAR} mapping.key_at (1) as k and then k.value.same_string ("first"))
			assert ("value_1", attached {YAML_SCALAR} mapping.value_at_index (1) as v and then v.value.same_string ("1"))
		end

	test_flow_style
			-- Test flow style setting.
		local
			mapping: YAML_MAPPING
		do
			create mapping.make
			assert ("default_block", not mapping.is_flow_style)
			mapping.set_flow_style (True)
			assert ("now_flow", mapping.is_flow_style)
		end

	test_iteration
			-- Test iterating over mapping.
		local
			mapping: YAML_MAPPING
			count: INTEGER
		do
			create mapping.make
			mapping.put_string ("1", "a")
			mapping.put_string ("2", "b")
			mapping.put_string ("3", "c")
			across mapping as ic loop
				count := count + 1
			end
			assert ("iterated_all", count = 3)
		end

	test_nested_mapping
			-- Test mapping containing another mapping.
		local
			outer, inner: YAML_MAPPING
		do
			create outer.make
			create inner.make
			inner.put_string ("nested_value", "nested_key")
			outer.put (inner, "inner")
			assert ("outer_count", outer.count = 1)
			assert ("inner_is_mapping", attached outer.value_at ("inner") as v and then v.is_mapping)
		end

	test_representation_block
			-- Test block style representation.
		local
			mapping: YAML_MAPPING
			repr: STRING_32
		do
			create mapping.make
			mapping.put_string ("value", "key")
			repr := mapping.representation
			assert ("has_colon", repr.has_substring (": "))
		end

	test_representation_flow
			-- Test flow style representation.
		local
			mapping: YAML_MAPPING
			repr: STRING_32
		do
			create mapping.make
			mapping.set_flow_style (True)
			mapping.put_string ("1", "a")
			repr := mapping.representation
			assert ("starts_brace", repr.starts_with ("{"))
			assert ("ends_brace", repr.ends_with ("}"))
		end

	test_value_at_missing
			-- Test value_at for missing key returns Void.
		local
			mapping: YAML_MAPPING
		do
			create mapping.make
			mapping.put_string ("value", "existing")
			assert ("missing_is_void", mapping.value_at ("nonexistent") = Void)
		end

end
