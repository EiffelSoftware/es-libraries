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
			create scalar.make_plain ("Hello World")
			assert ("is_scalar", scalar.is_scalar)
			assert ("value_correct", scalar.value.same_string ("Hello World"))
			assert ("style_is_plain", scalar.style = {YAML_SCALAR}.Style_plain)
		end

	test_make_null
			-- Test creating a null scalar.
		local
			scalar: YAML_SCALAR
		do
			create {YAML_NULL} scalar
			assert ("is_null", scalar.is_null)
			assert ("value_is_null", scalar.to_string_value.same_string ("null"))
		end

	test_make_boolean_true
			-- Test creating a true boolean scalar.
		local
			scalar: YAML_BOOLEAN
		do
			create scalar.make (True)
			assert ("is_boolean", scalar.is_boolean)
			assert ("to_boolean_true", scalar.value = True)
		end

	test_make_boolean_false
			-- Test creating a false boolean scalar.
		local
			scalar: YAML_BOOLEAN
		do
			create scalar.make (False)
			assert ("is_boolean", scalar.is_boolean)
			assert ("to_boolean_false", scalar.value = False)
		end

	test_make_integer
			-- Test creating an integer scalar.
		local
			scalar: YAML_SCALAR
		do
			create {YAML_INTEGER} scalar.make_integer_64 (42)
			assert ("is_integer", scalar.is_integer)
			assert ("to_integer_correct", scalar.to_integer_64 = 42)
		end

	test_make_integer_negative
			-- Test creating a negative integer scalar.
		local
			scalar: YAML_SCALAR
		do
			create {YAML_INTEGER} scalar.make_integer_64 (-100)
			assert ("is_integer", scalar.is_integer)
			assert ("to_integer_correct", scalar.to_integer_64 = -100)
		end

	test_make_real
			-- Test creating a real scalar.
		local
			scalar: YAML_SCALAR
		do
			create {YAML_REAL} scalar.make_real_64 (3.14159)
			assert ("is_real", scalar.is_real)
			assert ("to_real_correct", (scalar.to_real_64 - 3.14159).abs < 0.0001)
		end

	test_make_explicit_string
			-- Test creating an explicitly typed string.
		local
			str: YAML_STRING
		do
			create str.make_double_quoted ("123")
			assert ("is_string", str.is_string)
			assert ("value_correct", str.value.same_string ("123"))
			assert ("style_double_quoted", str.style = {YAML_SCALAR}.Style_double_quoted)
		end

	test_set_style
			-- Test changing scalar style.
		local
			scalar: YAML_STRING
		do
			create scalar.make_single_quoted ("test")
			assert ("style_single_quoted", scalar.style = {YAML_SCALAR}.Style_single_quoted)
		end

	test_representation_plain
			-- Test plain style representation.
		local
			scalar: YAML_STRING
		do
			create scalar.make_plain ("hello")
			assert ("plain_repr", scalar.representation.same_string ("hello"))
		end

	test_representation_single_quoted
			-- Test single-quoted representation.
		local
			scalar: YAML_STRING
		do
			create scalar.make_single_quoted ("hello")
			assert ("single_quoted_repr", scalar.representation.same_string ("'hello'"))
		end

	test_representation_double_quoted
			-- Test double-quoted representation.
		local
			scalar: YAML_STRING
		do
			create scalar.make_double_quoted ("hello")
			assert ("double_quoted_repr", scalar.representation.same_string ("%"hello%""))
		end

	test_anchor
			-- Test anchor setting.
		local
			scalar: YAML_STRING
		do
			create scalar.make_plain ("value")
			scalar.set_anchor ("myanchor")
			assert ("has_anchor", attached scalar.anchor as a and then a.same_string ("myanchor"))
		end

	test_tag
			-- Test tag setting.
		local
			scalar: YAML_STRING
		do
			create scalar.make_plain ("value")
			scalar.set_tag ("!!str")
			assert ("has_tag", attached scalar.tag as t and then t.same_string ("!!str"))
		end

	test_make_date_canonical
			-- Test creating a date scalar (canonical format).
		local
			scalar: YAML_DATE
		do
			create scalar.make_from_string ("2001-12-15T02:59:43.1Z")
			assert ("is_scalar", scalar.is_scalar)
			assert ("is_date", scalar.is_date)
			assert ("value_correct", scalar.to_string_value.same_string ("2001-12-15T02:59:43.1Z"))
		end

	test_make_date_only
			-- Test creating a date scalar (date-only format).
		local
			scalar: YAML_DATE
		do
			create scalar.make_from_string ("2002-12-14")
			assert ("is_date", scalar.is_date)
			assert ("value_correct", scalar.to_string_value.same_string ("2002-12-14"))
		end

	test_make_date_from_date_time
			-- Test creating a date scalar from DATE_TIME.
		local
			scalar: YAML_DATE
			dt: DATE_TIME
		do
			create dt.make (2001, 12, 15, 2, 59, 43)
			create scalar.make_from_date_time (dt)
			assert ("is_date", scalar.is_date)
			assert ("parseable", scalar.is_parseable)
		end

end
