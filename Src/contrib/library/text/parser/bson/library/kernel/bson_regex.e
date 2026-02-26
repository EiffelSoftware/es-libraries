note
	description: "[
		BSON_REGEX represents a regular expression in BSON.
		
		In BSON, regex is serialized as:
		cstring cstring
		- First cstring: the regex pattern
		- Second cstring: the options (characters in alphabetical order)
		
		Options:
		- 'i' for case insensitive matching
		- 'm' for multiline matching
		- 's' for dotall mode (. matches everything)
		- 'x' for verbose mode
		- 'u' for unicode matching
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_REGEX

inherit
	BSON_VALUE
		redefine
			is_regex
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make,
	make_with_options

feature {NONE} -- Initialization

	make (a_pattern: READABLE_STRING_GENERAL)
			-- Initialize with pattern only.
		require
			a_pattern_not_void: a_pattern /= Void
		do
			create pattern.make_from_string_general (a_pattern)
			create options.make_empty
		ensure
			pattern_set: pattern.same_string (a_pattern)
			no_options: options.is_empty
		end

	make_with_options (a_pattern: READABLE_STRING_GENERAL; a_options: READABLE_STRING_8)
			-- Initialize with pattern and options.
		require
			a_pattern_not_void: a_pattern /= Void
			a_options_not_void: a_options /= Void
		do
			create pattern.make_from_string_general (a_pattern)
			options := sorted_options (a_options)
		ensure
			pattern_set: pattern.same_string (a_pattern)
		end

feature -- Status report

	is_regex: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_regex
		end

	pattern: STRING_32
			-- Regex pattern.

	options: STRING_8
			-- Regex options (alphabetically sorted).

feature -- Status report

	is_case_insensitive: BOOLEAN
			-- Is matching case insensitive?
		do
			Result := options.has ('i')
		end

	is_multiline: BOOLEAN
			-- Is multiline matching enabled?
		do
			Result := options.has ('m')
		end

	is_dotall: BOOLEAN
			-- Does dot match everything (including newline)?
		do
			Result := options.has ('s')
		end

	is_verbose: BOOLEAN
			-- Is verbose mode enabled?
		do
			Result := options.has ('x')
		end

	is_unicode: BOOLEAN
			-- Is unicode matching enabled?
		do
			Result := options.has ('u')
		end

feature -- Element change

	set_case_insensitive (a_value: BOOLEAN)
			-- Set case insensitive option.
		do
			set_option ('i', a_value)
		ensure
			option_set: is_case_insensitive = a_value
		end

	set_multiline (a_value: BOOLEAN)
			-- Set multiline option.
		do
			set_option ('m', a_value)
		ensure
			option_set: is_multiline = a_value
		end

	set_dotall (a_value: BOOLEAN)
			-- Set dotall option.
		do
			set_option ('s', a_value)
		ensure
			option_set: is_dotall = a_value
		end

	set_verbose (a_value: BOOLEAN)
			-- Set verbose option.
		do
			set_option ('x', a_value)
		ensure
			option_set: is_verbose = a_value
		end

	set_unicode (a_value: BOOLEAN)
			-- Set unicode option.
		do
			set_option ('u', a_value)
		ensure
			option_set: is_unicode = a_value
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_regex (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := pattern.hash_code + options.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			Result := "/" + pattern.to_string_8 + "/" + options
		end

feature {NONE} -- Implementation

	set_option (c: CHARACTER_8; a_value: BOOLEAN)
			-- Set or unset option character.
		local
			l_pos: INTEGER
		do
			l_pos := options.index_of (c, 1)
			if a_value and l_pos = 0 then
				options.append_character (c)
				options := sorted_options (options)
			elseif not a_value and l_pos > 0 then
				options.remove (l_pos)
			end
		end

	sorted_options (a_options: READABLE_STRING_8): STRING_8
			-- Return options sorted alphabetically.
		local
			l_list: ARRAYED_LIST [CHARACTER_8]
			i: INTEGER
		do
			create l_list.make (a_options.count)
			from
				i := 1
			until
				i > a_options.count
			loop
				l_list.extend (a_options.item (i))
				i := i + 1
			end
			create Result.make (l_list.count)
			across l_list as c loop
				Result.append_character (c)
			end
		end

invariant
	pattern_not_void: pattern /= Void
	options_not_void: options /= Void

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
