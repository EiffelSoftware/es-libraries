note
	description: "Tests for YAML_DOCUMENT class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_YAML_DOCUMENT

inherit
	EQA_TEST_SET

feature -- Test routines

	test_make_with_root
			-- Test creating document with root.
		local
			doc: YAML_DOCUMENT
			root: YAML_STRING
		do
			create root.make ("hello")
			create doc.make (root)
			assert ("has_root", doc.has_root)
			assert ("root_correct", doc.root = root)
		end

	test_make_empty
			-- Test creating empty document.
		local
			doc: YAML_DOCUMENT
		do
			create doc.make_empty
			assert ("no_root", not doc.has_root)
		end

	test_set_root
			-- Test setting root value.
		local
			doc: YAML_DOCUMENT
			root: YAML_MAPPING
		do
			create doc.make_empty
			create root.make
			root.put_string ("value", "key")
			doc.set_root (root)
			assert ("now_has_root", doc.has_root)
			assert ("root_correct", doc.root = root)
		end

	test_yaml_version
			-- Test YAML version.
		local
			doc: YAML_DOCUMENT
		do
			create doc.make_empty
			assert ("default_version", doc.yaml_version.same_string ("1.2"))
			doc.set_yaml_version ("1.1")
			assert ("version_changed", doc.yaml_version.same_string ("1.1"))
		end

	test_tag_directives
			-- Test adding tag directives.
		local
			doc: YAML_DOCUMENT
		do
			create doc.make_empty
			doc.add_tag_directive ("!mytag!", "tag:example.com,2024:")
			assert ("has_directive", doc.tag_directives.has ("!mytag!"))
		end

	test_representation
			-- Test document representation.
		local
			doc: YAML_DOCUMENT
			root: YAML_STRING
			repr: STRING_32
		do
			create root.make ("hello")
			create doc.make (root)
			repr := doc.representation
			assert ("has_doc_start", repr.has_substring ("---"))
			assert ("has_content", repr.has_substring ("hello"))
		end

	test_representation_with_directives
			-- Test representation with tag directives.
		local
			doc: YAML_DOCUMENT
			root: YAML_STRING
			repr: STRING_32
		do
			create root.make ("hello")
			create doc.make (root)
			doc.add_tag_directive ("!", "tag:example.com:")
			repr := doc.representation
			assert ("has_yaml_directive", repr.has_substring ("%%YAML"))
			assert ("has_tag_directive", repr.has_substring ("%%TAG"))
		end

end
