note
	description: "[
		Spacing specification between segments in a layout (mirroring Ratatui Spacing).
		Can represent positive spacing (Space) or negative spacing / overlapping (Overlap).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SPACING

inherit
	HASHABLE
		redefine
			default_create,
			is_equal,
			out
		end

create
	default_create,
	make_space,
	make_overlap,
	make_from_integer

feature {NONE} -- Initialization

	default_create
			-- Initialize as zero spacing (Space (0)).
		do
			value := 0
			is_overlap := False
		ensure then
			is_space: not is_overlap
			zero_value: value = 0
		end

	make_space (a_value: NATURAL_16)
			-- Positive gap of `a_value` cells between segments.
		do
			value := a_value
			is_overlap := False
		ensure
			is_space: not is_overlap
			value_set: value = a_value
		end

	make_overlap (a_value: NATURAL_16)
			-- Negative spacing / overlap of `a_value` cells between segments.
		do
			value := a_value
			is_overlap := True
		ensure
			is_overlap: is_overlap
			value_set: value = a_value
		end

	make_from_integer (a_int: INTEGER)
			-- Initialize from signed integer (negative becomes Overlap, non-negative becomes Space).
		do
			if a_int < 0 then
				make_overlap ((-a_int).to_natural_16)
			else
				make_space (a_int.to_natural_16)
			end
		ensure
			overlap_if_negative: a_int < 0 implies is_overlap
			space_if_non_negative: a_int >= 0 implies not is_overlap
		end

feature -- Access

	value: NATURAL_16
			-- Magnitude in cells

	is_overlap: BOOLEAN
			-- Is this an overlapping spacing?

	is_space: BOOLEAN
			-- Is this a positive/zero gap spacing?
		do
			Result := not is_overlap
		end

	effective_spacing: INTEGER
			-- Signed spacing value (negative for overlap, positive or zero for space)
		do
			if is_overlap then
				Result := - (value.to_integer_32)
			else
				Result := value.to_integer_32
			end
		end

feature -- Factory (Class Features)

	space (a_val: NATURAL_16): SPACING
			-- Spacing representing a positive gap of `a_val` cells.
		do
			create Result.make_space (a_val)
		ensure
			instance_free: class
			result_attached: Result /= Void
			is_space: Result.is_space
			value_set: Result.value = a_val
		end

	overlap (a_val: NATURAL_16): SPACING
			-- Spacing representing an overlap of `a_val` cells.
		do
			create Result.make_overlap (a_val)
		ensure
			instance_free: class
			result_attached: Result /= Void
			is_overlap: Result.is_overlap
			value_set: Result.value = a_val
		end

feature -- Measurement

	hash_code: INTEGER
			-- Hash code for hash table lookup
		do
			if is_overlap then
				Result := -(value.to_integer_32 + 1)
			else
				Result := value.to_integer_32
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := is_overlap = a_other.is_overlap and value = a_other.value
		end

feature -- Output

	out: STRING_8
			-- String representation
		do
			if is_overlap then
				Result := "Overlap(" + value.out + ")"
			else
				Result := "Space(" + value.out + ")"
			end
		end

end
