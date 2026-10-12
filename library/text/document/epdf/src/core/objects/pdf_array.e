note
	description: "Represents a PDF array object. Arrays are ordered collections of PDF objects."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_ARRAY

inherit
	PDF_OBJECT

create
	make,
	make_empty,
	make_with_integers

feature -- Initialization

	make (initial_capacity: INTEGER)
			-- Create an array with initial capacity.
		require
			valid_capacity: initial_capacity >= 0
		do
			create items.make (initial_capacity)
		ensure
		end

	make_empty
			-- Create an empty array.
		do
			create items.make (0)
		ensure
			is_empty: items.is_empty
		end

	make_with_integers (integers: ARRAY [INTEGER])
			-- Create an array from integer values.
		local
			i: INTEGER
			number: PDF_NUMBER
		do
			create items.make (integers.count)
			from
				i := integers.lower
			until
				i > integers.upper
			loop
				create number.make_integer (integers [i])
				items.extend (number)
				i := i + 1
			end
		ensure
			correct_count: count = integers.count
		end

feature -- Access

	items: ARRAYED_LIST [PDF_OBJECT]
			-- The array items

	count: INTEGER
			-- Number of items in the array
		do
			Result := items.count
		ensure
			definition: Result = items.count
		end

	is_empty: BOOLEAN
			-- Is the array empty?
		do
			Result := items.is_empty
		ensure
			definition: Result = items.is_empty
		end

	item (i: INTEGER): PDF_OBJECT
			-- Item at position `i`
		require
			valid_index: i >= 1 and i <= count
		do
			Result := items [i]
		end

feature -- Element Change

	add (an_object: PDF_OBJECT)
			-- Add an object to the end of array.
		do
			items.extend (an_object)
		ensure
			count_increased: count = old count + 1
		end

	add_at_first (an_object: PDF_OBJECT)
			-- Add an object at the beginning of the array.
			-- Used when footer must be drawn before original content to avoid clipping.
		do
			items.put_front (an_object)
		ensure
			count_increased: count = old count + 1
			first_is_object: items.first = an_object
		end

	insert_after (an_object: PDF_OBJECT; a_index: INTEGER)
			-- Insert `an_object` after position `a_index` (1-indexed).
		require
			valid_index: a_index >= 1 and a_index <= count
		do
			items.go_i_th (a_index)
			items.put_right (an_object)
		ensure
			count_increased: count = old count + 1
		end

	add_name (a_name: READABLE_STRING_GENERAL)
			-- Add a name object to the array.
			-- Per ISO 32000-1:2008 §7.3.5, names are 7-bit ASCII.
		require
			name_not_empty: not a_name.is_empty
		local
			name: PDF_NAME
		do
			create name.make (a_name)
			add (name)
		ensure
			count_increased: count = old count + 1
		end

	add_number (a_number: INTEGER)
			-- Add an integer number to the array.
		local
			number: PDF_NUMBER
		do
			create number.make_integer (a_number)
			add (number)
		ensure
			count_increased: count = old count + 1
		end

	add_real (a_real: REAL_64)
			-- Add a real number to the array.
		local
			number: PDF_NUMBER
		do
			create number.make_real (a_real)
			add (number)
		ensure
			count_increased: count = old count + 1
		end

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_array (Current)
		end

invariant

end
