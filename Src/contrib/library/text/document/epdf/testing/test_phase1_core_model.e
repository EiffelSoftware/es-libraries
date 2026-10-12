note
	description: "[
		Tests for Phase 1 Core Model components:
		- PDF_NULL
		- PDF_LAZY_OBJECT
		- PDF_OBJECT_CACHE
		- PDF_VALIDATOR
		- PDF_BYTE_SOURCE implementations
		- PDF_ERROR_POLICY
	]"
	author: "EiffelStudio test wizard"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_PHASE1_CORE_MODEL

inherit
	EQA_TEST_SET

feature -- Test routines: PDF_NULL

	test_pdf_null_creation
			-- Test: Create and use PDF null object.
		note
			testing: "covers/{PDF_NULL}.make"
		local
			null_obj: PDF_NULL
			serializer: PDF_SERIALIZER
		do
			create null_obj.make
			assert ("null_created", null_obj /= Void)
			assert ("null_to_string", null_obj.to_pdf_string.is_equal ("null"))

				-- Test serialization
			create serializer.make
			null_obj.accept (serializer)
			assert ("null_serializes_correctly", serializer.last_output.is_equal ("null"))
		end

feature -- Test routines: PDF_OBJECT_CACHE

	test_object_cache_basic
			-- Test: Basic object cache operations.
		note
			testing: "covers/{PDF_OBJECT_CACHE}.put"
			testing: "covers/{PDF_OBJECT_CACHE}.object"
			testing: "covers/{PDF_OBJECT_CACHE}.has"
		local
			cache: PDF_OBJECT_CACHE
			id1, id2: PDF_OBJECT_ID
			obj1, obj2: PDF_NUMBER
			retrieved: detachable PDF_OBJECT
		do
			create cache.make
			assert ("cache_created", cache /= Void)
			assert ("cache_initially_empty", cache.count = 0)

			create id1.make (1, 0)
			create id2.make (2, 0)
			create obj1.make_integer (42)
			create obj2.make_integer (99)

				-- Put objects in cache
			cache.put (id1, obj1)
			assert ("has_obj1", cache.has (id1))
			assert ("count_is_1", cache.count = 1)

			cache.put (id2, obj2)
			assert ("has_obj2", cache.has (id2))
			assert ("count_is_2", cache.count = 2)

				-- Retrieve objects
			retrieved := cache.object (id1)
			assert ("retrieved_obj1", retrieved = obj1)

			retrieved := cache.object (id2)
			assert ("retrieved_obj2", retrieved = obj2)
		end

	test_object_cache_identity
			-- Test: Cache ensures object identity.
		note
			testing: "covers/{PDF_OBJECT_CACHE}.put"
		local
			cache: PDF_OBJECT_CACHE
			id: PDF_OBJECT_ID
			obj1, obj2: PDF_NUMBER
			retrieved1, retrieved2: detachable PDF_OBJECT
		do
			create cache.make
			create id.make (1, 0)
			create obj1.make_integer (42)
			create obj2.make_integer (99)

				-- Put first object
			cache.put (id, obj1)
			retrieved1 := cache.object (id)

				-- Replace with second object
			cache.put (id, obj2)
			retrieved2 := cache.object (id)

				-- Should get the second object (replacement)
			assert ("replaced_object", retrieved2 = obj2)
			assert ("different_objects", retrieved1 /= retrieved2)
		end

feature -- Test routines: PDF_BYTE_SOURCE

	test_string_byte_source
			-- Test: String byte source operations.
		note
			testing: "covers/{PDF_STRING_BYTE_SOURCE}.make"
		local
			source: PDF_STRING_BYTE_SOURCE
			content: STRING
			byte: NATURAL_8
		do
			content := "Hello PDF"
			create source.make (content)

			assert ("source_valid", source.is_valid)
			assert ("correct_count", source.byte_count = 9)
			assert ("position_at_start", source.position = 0)
			assert ("not_at_end", not source.end_of_source)

				-- Read first byte ('H' = 72)
			byte := source.read_byte
			assert ("first_byte_is_H", byte = 72)
			assert ("position_advanced", source.position = 1)

				-- Peek at next byte ('e' = 101)
			byte := source.peek_byte
			assert ("peek_is_e", byte = 101)
			assert ("position_unchanged", source.position = 1)

				-- Set position
			source.set_position (6)
			assert ("position_set_to_6", source.position = 6)

			byte := source.read_byte
			assert ("byte_at_6_is_P", byte = 80) -- 'P'
		end

feature -- Test routines: PDF_ERROR_POLICY

	test_error_policy_modes
			-- Test: Error policy strict and permissive modes.
		note
			testing: "covers/{PDF_ERROR_POLICY}.make_permissive"
			testing: "covers/{PDF_ERROR_POLICY}.make_strict"
		local
			permissive, strict: PDF_ERROR_POLICY
		do
			create permissive.make_permissive
			assert ("permissive_not_strict", not permissive.strict_mode)
			assert ("permissive_allows_violations", not permissive.should_reject_minor_violation)

			create strict.make_strict
			assert ("strict_is_strict", strict.strict_mode)
			assert ("strict_rejects_violations", strict.should_reject_minor_violation)
		end

feature -- Test routines: PDF_VALIDATOR

	test_validator_basic
			-- Test: Basic validator operations.
		note
			testing: "covers/{PDF_VALIDATOR}.make"
		local
			validator: PDF_VALIDATOR
			name: PDF_NAME
			dict: PDF_DICTIONARY
		do
			create validator.make
			assert ("validator_created", validator /= Void)
			assert ("initially_valid", validator.is_valid_result)
			assert ("no_errors", validator.errors.is_empty)

				-- Test valid name
			create name.make ("Type")
			validator.reset
			name.accept (validator)
			assert ("valid_name_passes", validator.is_valid_result)

				-- Test valid dictionary
			create dict.make_empty
			dict.put_name ("Type", "Page")
			validator.reset
			dict.accept (validator)
			assert ("valid_dict_passes", validator.is_valid_result)
		end

	test_validator_detects_errors
			-- Test: Validator detects structural errors.
			-- Tests stream missing required /Length entry.
		note
			testing: "covers/{PDF_VALIDATOR}.visit_stream"
		local
			validator: PDF_VALIDATOR
			policy: PDF_ERROR_POLICY
			stream: PDF_STREAM
		do
				-- Create permissive validator to avoid exceptions
			create policy.make_permissive
			create validator.make_with_policy (policy)

				-- Create stream with content
			create stream.make ("test content")

				-- Remove /Length entry to create invalid stream
			stream.stream_dictionary.entries.remove ("Length")

				-- Validate - should detect missing /Length
			validator.reset
			stream.accept (validator)
			assert ("missing_length_fails", not validator.is_valid_result)
			assert ("error_recorded", not validator.errors.is_empty)
		end

feature -- Test routines: PDF_LAZY_OBJECT

	test_lazy_object_deferred_loading
			-- Test: Lazy object defers loading until access.
		note
			testing: "covers/{PDF_LAZY_OBJECT}.make"
			testing: "covers/{PDF_LAZY_OBJECT}.resolved"
		local
			lazy: PDF_LAZY_OBJECT
			loader: FUNCTION [PDF_OBJECT]
			resolved: PDF_OBJECT
		do
				-- Create loader that creates a number object
			loader := agent: PDF_OBJECT
				local
					num: PDF_NUMBER
				do
					create num.make_integer (42)
					Result := num
				end

			create lazy.make (loader)
			assert ("lazy_created", lazy /= Void)
			assert ("not_loaded_initially", not lazy.is_loaded)

				-- Access resolved object
			resolved := lazy.resolved
			assert ("now_loaded", lazy.is_loaded)

				-- Access again should return cached (same object)
			resolved := lazy.resolved
			assert ("still_loaded", lazy.is_loaded)
		end

end
