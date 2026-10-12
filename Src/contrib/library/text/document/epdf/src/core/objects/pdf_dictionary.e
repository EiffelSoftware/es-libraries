note
	description: "Represents a PDF dictionary object. Dictionaries are associative arrays mapping names to PDF objects."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_DICTIONARY

inherit
	PDF_OBJECT

create
	make,
	make_empty

feature -- Initialization

	make (initial_capacity: INTEGER)
			-- Create a dictionary with initial capacity.
		require
			valid_capacity: initial_capacity >= 0
		do
			create entries.make (initial_capacity)
		ensure
		end

	make_empty
			-- Create an empty dictionary.
		do
			create entries.make (0)
		ensure
			is_empty: entries.is_empty
		end

feature -- Access

	entries: HASH_TABLE [PDF_OBJECT, STRING_8]
			-- Dictionary entries (name -> object).
			-- Per ISO 32000-1:2008 §7.3.7, dictionary keys are PDF names (7-bit ASCII).

	count: INTEGER
			-- Number of entries in the dictionary
		do
			Result := entries.count
		ensure
			definition: Result = entries.count
		end

	is_empty: BOOLEAN
			-- Is the dictionary empty?
		do
			Result := entries.is_empty
		ensure
			definition: Result = entries.is_empty
		end

	has_key (a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Does the dictionary have the given key?
			-- Per ISO 32000-1:2008 §7.3.7, keys are PDF names (7-bit ASCII).
		require
			key_not_empty: not a_key.is_empty
		do
			Result := entries.has (a_key.to_string_8)
		ensure
			definition: Result = entries.has (a_key.to_string_8)
		end

	item (a_key: READABLE_STRING_GENERAL): detachable PDF_OBJECT
			-- Object associated with `a_key`, or Void if not found.
			-- Per ISO 32000-1:2008 §7.3.7, keys are PDF names (7-bit ASCII).
		require
			key_not_empty: not a_key.is_empty
		local
			key_str: STRING_8
		do
			key_str := a_key.to_string_8
			if entries.has (key_str) then
				Result := entries.item (key_str)
			end
		end

feature -- Element Change

	put (an_object: PDF_OBJECT; a_key: READABLE_STRING_GENERAL)
			-- Associate `an_object` with `a_key`.
			-- Per ISO 32000-1:2008 §7.3.7, keys are PDF names (7-bit ASCII).
		require
			key_not_empty: not a_key.is_empty
		do
			entries.force (an_object, a_key.to_string_8)
		ensure
			has_key: has_key (a_key)
			object_set: attached item (a_key) as obj implies obj = an_object
		end

	put_name (a_value: READABLE_STRING_GENERAL; a_key: READABLE_STRING_GENERAL)
			-- Associate a name object with `a_key`.
			-- Per ISO 32000-1:2008 §7.3.5, names are 7-bit ASCII.
		require
			value_not_empty: not a_value.is_empty
			key_not_empty: not a_key.is_empty
		local
			name: PDF_NAME
		do
			create name.make (a_value)
			put (name, a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_number (a_value: INTEGER; a_key: READABLE_STRING_GENERAL)
			-- Associate an integer number with `a_key`.
		require
			key_not_empty: not a_key.is_empty
		local
			number: PDF_NUMBER
		do
			create number.make_integer (a_value)
			put (number, a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_real (a_value: REAL_64; a_key: READABLE_STRING_GENERAL)
			-- Associate a real number with `a_key`.
		require
			key_not_empty: not a_key.is_empty
		local
			number: PDF_NUMBER
		do
			create number.make_real (a_value)
			put (number, a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_string (a_value: READABLE_STRING_GENERAL; a_key: READABLE_STRING_GENERAL)
			-- Associate a literal string with `a_key`.
		require
			key_not_empty: not a_key.is_empty
		local
			str: PDF_STRING
		do
			create str.make_literal (a_value)
			put (str, a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_boolean (a_value: BOOLEAN; a_key: READABLE_STRING_GENERAL)
			-- Associate a boolean value with `a_key`.
		require
			key_not_empty: not a_key.is_empty
		local
			bool: PDF_BOOLEAN
		do
			create bool.make (a_value)
			put (bool, a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_hex_string (a_value: STRING_8; a_key: READABLE_STRING_GENERAL)
			-- Associate a hexadecimal-encoded string with `a_key`.
			-- Use this for binary data like encryption U/O values.
		require
			key_not_empty: not a_key.is_empty
		local
			str: PDF_STRING
		do
			create str.make_hex (a_value)
			put (str, a_key)
		ensure
			has_key: has_key (a_key)
		end

feature {NONE} -- Implementation

	bytes_to_hex (bytes: STRING_8): STRING_8
			-- Convert byte string to hexadecimal string.
		local
			i: INTEGER
			code: NATURAL_32
			hex: STRING_8
		do
			create Result.make (bytes.count * 2)
			from i := 1 until i > bytes.count loop
				code := bytes.code (i)
				hex := code.to_hex_string
				-- hex format from NATURAL_32 is 8 characters, we need last 2
				Result.append (hex.substring (7, 8))
				i := i + 1
			end
		ensure
			correct_length: Result.count = bytes.count * 2
		end

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_dictionary (Current)
		end

invariant

end
