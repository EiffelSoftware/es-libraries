note
	description: "Tests for YAML_SCALAR class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_YAML_SCALAR

inherit
	EQA_TEST_SET

feature -- Test routines

	test_make_string
			-- Test creating a string scalar.
		local
			scalar: YAML_STRING
		do
			create scalar.make ("Hello World")
			assert ("is_scalar", scalar.is_scalar)
			assert ("value_correct", scalar.value.same_string ("Hello World"))
			assert ("style_is_plain", scalar.style = {YAML_SCALAR}.Style_plain)
		end

	test_make_null
			-- Test creating a null scalar.
		local
			scalar: YAML_SCALAR
		do
			create scalar.make_null
			assert ("is_null", scalar.is_null)
			assert ("value_is_null", scalar.value.same_string ("null"))
		end

	test_make_boolean_true
			-- Test creating a true boolean scalar.
		local
			scalar: YAML_SCALAR
		do
			create scalar.make_boolean (True)
			assert ("is_boolean", scalar.is_boolean)
			assert ("to_boolean_true", scalar.to_boolean = True)
		end

	test_make_boolean_false
			-- Test creating a false boolean scalar.
		local
			scalar: YAML_SCALAR
		do
			create scalar.make_boolean (False)
			assert ("is_boolean", scalar.is_boolean)
			assert ("to_boolean_false", scalar.to_boolean = False)
		end

	test_make_integer
			-- Test creating an integer scalar.
		local
			scalar: YAML_SCALAR
		do
			create scalar.make_integer (42)
			assert ("is_integer", scalar.is_integer)
			assert ("to_integer_correct", scalar.to_integer_64 = 42)
		end

	test_make_integer_negative
			-- Test creating a negative integer scalar.
		local
			scalar: YAML_SCALAR
		do
			create scalar.make_integer (-100)
			assert ("is_integer", scalar.is_integer)
			assert ("to_integer_correct", scalar.to_integer_64 = -100)
		end

	test_make_real
			-- Test creating a real scalar.
		local
			scalar: YAML_SCALAR
		do
			create scalar.make_real (3.14159)
			assert ("is_real", scalar.is_real)
			assert ("to_real_correct", (scalar.to_real_64 - 3.14159).abs < 0.0001)
		end

	test_make_explicit_string
			-- Test creating an explicitly typed string.
		local
			str: YAML_STRING
		do
			create str.make_string ("123")
			assert ("is_string", str.is_string)
			assert ("value_correct", str.value.same_string ("123"))
			assert ("style_double_quoted", str.style = {YAML_SCALAR}.Style_double_quoted)
		end

	test_set_style
			-- Test changing scalar style.
		local
			scalar: YAML_STRING
		do
			create scalar.make ("test")
			scalar.set_style ({YAML_SCALAR}.Style_single_quoted)
			assert ("style_single_quoted", scalar.style = {YAML_SCALAR}.Style_single_quoted)
		end

	test_representation_plain
			-- Test plain style representation.
		local
			scalar: YAML_STRING
		do
			create scalar.make ("hello")
			assert ("plain_repr", scalar.representation.same_string ("hello"))
		end

	test_representation_single_quoted
			-- Test single-quoted representation.
		local
			scalar: YAML_STRING
		do
			create scalar.make ("hello")
			scalar.set_style ({YAML_SCALAR}.Style_single_quoted)
			assert ("single_quoted_repr", scalar.representation.same_string ("'hello'"))
		end

	test_representation_double_quoted
			-- Test double-quoted representation.
		local
			scalar: YAML_STRING
		do
			create scalar.make ("hello")
			scalar.set_style ({YAML_SCALAR}.Style_double_quoted)
			assert ("double_quoted_repr", scalar.representation.same_string ("%"hello%""))
		end

	test_anchor
			-- Test anchor setting.
		local
			scalar: YAML_STRING
		do
			create scalar.make ("value")
			scalar.set_anchor ("myanchor")
			assert ("has_anchor", attached scalar.anchor as a and then a.same_string ("myanchor"))
		end

	test_tag
			-- Test tag setting.
		local
			scalar: YAML_STRING
		do
			create scalar.make ("value")
			scalar.set_tag ("!!str")
			assert ("has_tag", attached scalar.tag as t and then t.same_string ("!!str"))
		end

end
