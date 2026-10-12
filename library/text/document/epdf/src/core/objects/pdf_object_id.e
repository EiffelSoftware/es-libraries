note
	description: "Represents a PDF object identifier (object number, generation number pair)."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_OBJECT_ID

inherit
	ANY
		redefine
			is_equal
		end

create
	make

feature -- Initialization

	make (an_object_number: INTEGER; a_generation: INTEGER)
			-- Create object ID with given object and generation numbers.
		require
			valid_object_number: an_object_number > 0
			valid_generation: a_generation >= 0
		do
			object_number := an_object_number
			generation := a_generation
		ensure
			object_number_set: object_number = an_object_number
			generation_set: generation = a_generation
		end

feature -- Access

	object_number: INTEGER
			-- The object number

	generation: INTEGER
			-- The generation number

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Is this ID equal to `other`?
		do
			Result := object_number = other.object_number and generation = other.generation
		end

feature -- Conversion

	to_reference_string: STRING_8
			-- Convert to PDF indirect reference format (e.g., "1 0 R").
			-- Per ISO 32000-1:2008 §7.3.10, indirect references are 7-bit ASCII.
		do
			create Result.make (20)
			Result.append (object_number.out)
			Result.append_character (' ')
			Result.append (generation.out)
			Result.append (" R")
		ensure
			result_not_empty: not Result.is_empty
		end

	to_object_header_string: STRING_8
			-- Convert to PDF object header format (e.g., "1 0 obj").
			-- Per ISO 32000-1:2008 §7.3.10, object headers are 7-bit ASCII.
		do
			create Result.make (20)
			Result.append (object_number.out)
			Result.append_character (' ')
			Result.append (generation.out)
			Result.append (" obj")
		ensure
			result_not_empty: not Result.is_empty
		end

invariant
	valid_object_number: object_number > 0
	valid_generation: generation >= 0

end
