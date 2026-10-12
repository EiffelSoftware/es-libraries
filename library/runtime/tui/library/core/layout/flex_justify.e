note
	description: "[
		Flex justification strategies for aligning and distributing child chunks
		when total allocated constraint space does not fill available layout area.
		Supports Start, End, Center, SpaceBetween, SpaceAround, SpaceEvenly, and Legacy.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FLEX_JUSTIFY

inherit
	ANY
		redefine
			default_create,
			is_equal,
			out
		end

create
	default_create,
	make_start,
	make_end,
	make_center,
	make_space_between,
	make_space_around,
	make_space_evenly,
	make_legacy,
	make_from_integer

feature {NONE} -- Initialization

	default_create
			-- Initialize with `Start` justification strategy by default.
		do
			value := Id_start
		ensure then
			default_is_start: is_start
		end

	make_start
			-- Pack child chunks toward the start (top or left).
		do
			value := Id_start
		ensure
			is_start: is_start
		end

	make_end
			-- Pack child chunks toward the end (bottom or right).
		do
			value := Id_end
		ensure
			is_end: is_end
		end

	make_center
			-- Center child chunks within the available space.
		do
			value := Id_center
		ensure
			is_center: is_center
		end

	make_space_between
			-- Distribute remaining space evenly between child chunks.
		do
			value := Id_space_between
		ensure
			is_space_between: is_space_between
		end

	make_space_around
			-- Distribute remaining space evenly before, between, and after child chunks.
		do
			value := Id_space_around
		ensure
			is_space_around: is_space_around
		end

	make_space_evenly
			-- Distribute remaining space evenly between chunks and before/after edges.
		do
			value := Id_space_evenly
		ensure
			is_space_evenly: is_space_evenly
		end

	make_legacy
			-- Fills available space putting excess into the last element (Ratatui legacy mode).
		do
			value := Id_legacy
		ensure
			is_legacy: is_legacy
		end

	make_from_integer (a_code: INTEGER)
			-- Initialize from integer code `a_code`.
		require
			valid_code: is_valid_code (a_code)
		do
			value := a_code
		ensure
			value_set: value = a_code
		end

feature -- Access

	value: INTEGER
			-- Numeric identifier for justification strategy

feature -- Status Report

	is_start: BOOLEAN
			-- Is chunks packed toward start?
		do
			Result := value = Id_start
		end

	is_end: BOOLEAN
			-- Is chunks packed toward end?
		do
			Result := value = Id_end
		end

	is_center: BOOLEAN
			-- Is chunks centered?
		do
			Result := value = Id_center
		end

	is_space_between: BOOLEAN
			-- Is remaining space distributed between chunks?
		do
			Result := value = Id_space_between
		end

	is_space_around: BOOLEAN
			-- Is remaining space distributed around chunks?
		do
			Result := value = Id_space_around
		end

	is_space_evenly: BOOLEAN
			-- Is remaining space distributed evenly before, between, and after chunks?
		do
			Result := value = Id_space_evenly
		end

	is_legacy: BOOLEAN
			-- Is legacy space distribution (stretch last element)?
		do
			Result := value = Id_legacy
		end

feature -- Identification Constants

	Id_start: INTEGER = 1
			-- Code for Start alignment

	Id_end: INTEGER = 2
			-- Code for End alignment

	Id_center: INTEGER = 3
			-- Code for Center alignment

	Id_space_between: INTEGER = 4
			-- Code for SpaceBetween alignment

	Id_space_around: INTEGER = 5
			-- Code for SpaceAround alignment

	Id_space_evenly: INTEGER = 6
			-- Code for SpaceEvenly alignment

	Id_legacy: INTEGER = 7
			-- Code for Legacy alignment

feature -- Named Instances (Class features)

	start_align: FLEX_JUSTIFY
			-- Pack child chunks toward the start (top or left).
		once
			create Result.make_start
		ensure
			instance_free: class
			is_start: Result.is_start
		end

	start: FLEX_JUSTIFY
			-- Pack child chunks toward the start (top or left).
		once
			create Result.make_start
		ensure
			instance_free: class
			is_start: Result.is_start
		end

	end_align: FLEX_JUSTIFY
			-- Pack child chunks toward the end (bottom or right).
		once
			create Result.make_end
		ensure
			instance_free: class
			is_end: Result.is_end
		end

	end_justify: FLEX_JUSTIFY
			-- Pack child chunks toward the end (bottom or right).
		once
			create Result.make_end
		ensure
			instance_free: class
			is_end: Result.is_end
		end

	center_align: FLEX_JUSTIFY
			-- Center child chunks within the available space.
		once
			create Result.make_center
		ensure
			instance_free: class
			is_center: Result.is_center
		end

	center: FLEX_JUSTIFY
			-- Center child chunks within the available space.
		once
			create Result.make_center
		ensure
			instance_free: class
			is_center: Result.is_center
		end

	space_between: FLEX_JUSTIFY
			-- Distribute remaining space evenly between child chunks.
		once
			create Result.make_space_between
		ensure
			instance_free: class
			is_space_between: Result.is_space_between
		end

	space_around: FLEX_JUSTIFY
			-- Distribute remaining space evenly before, between, and after child chunks.
		once
			create Result.make_space_around
		ensure
			instance_free: class
			is_space_around: Result.is_space_around
		end

	space_evenly: FLEX_JUSTIFY
			-- Distribute remaining space evenly between chunks and before/after edges.
		once
			create Result.make_space_evenly
		ensure
			instance_free: class
			is_space_evenly: Result.is_space_evenly
		end

	legacy: FLEX_JUSTIFY
			-- Legacy Ratatui layout behavior: stretch last element to fill available space.
		once
			create Result.make_legacy
		ensure
			instance_free: class
			is_legacy: Result.is_legacy
		end

feature -- Query

	is_valid (a_justify: INTEGER): BOOLEAN
			-- Is `a_justify` a recognized justification strategy code?
		do
			Result := is_valid_code (a_justify)
		ensure
			instance_free: class
		end

	is_valid_code (a_code: INTEGER): BOOLEAN
			-- Is `a_code` a valid strategy code in 1..7?
		do
			Result := a_code >= Id_start and a_code <= Id_legacy
		ensure
			instance_free: class
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := value = a_other.value
		end

feature -- Output

	out: STRING_8
			-- String representation
		do
			inspect value
			when Id_start then
				Result := "Start"
			when Id_end then
				Result := "End"
			when Id_center then
				Result := "Center"
			when Id_space_between then
				Result := "SpaceBetween"
			when Id_space_around then
				Result := "SpaceAround"
			when Id_space_evenly then
				Result := "SpaceEvenly"
			when Id_legacy then
				Result := "Legacy"
			else
				Result := "Unknown"
			end
		end

invariant
	valid_value: is_valid_code (value)

end
