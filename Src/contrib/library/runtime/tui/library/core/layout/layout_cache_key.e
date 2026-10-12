note
	description: "[
		Hashable compound key for caching layout results, keyed by (RECT, LAYOUT).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LAYOUT_CACHE_KEY

inherit
	HASHABLE
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_area: RECT; a_layout: LAYOUT)
			-- Initialize cache key with `a_area` and `a_layout`.
		require
			area_attached: a_area /= Void
			layout_attached: a_layout /= Void
		do
			area := a_area
			layout := a_layout
		ensure
			area_set: area = a_area
			layout_set: layout = a_layout
		end

feature {LAYOUT_CACHE} -- Element change

	set (a_area: RECT; a_layout: LAYOUT)
			-- Reuse `Current` as a lookup key for (`a_area`, `a_layout`).
		do
			area := a_area
			layout := a_layout
		ensure
			area_set: area = a_area
			layout_set: layout = a_layout
		end

feature -- Access

	area: RECT
			-- Layout target area

	layout: LAYOUT
			-- Layout specification

feature -- Measurement

	hash_code: INTEGER
			-- Hash code for hash table lookup
		local
			h: INTEGER_64
			i: INTEGER
		do
			h := area.x.to_integer_64
			h := (h * 31) + area.y.to_integer_64
			h := (h * 31) + area.width.to_integer_64
			h := (h * 31) + area.height.to_integer_64
			h := (h * 31) + (if layout.direction.is_horizontal then 1 else 2 end)
			h := (h * 31) + layout.margin.horizontal.to_integer_64
			h := (h * 31) + layout.margin.vertical.to_integer_64
			h := (h * 31) + layout.spacing.to_integer_64
			h := (h * 31) + layout.flex.value.to_integer_64
			from
				i := 1
			until
				i > layout.constraint_count
			loop
				h := ((h * 31) + constraint_hash (layout.constraint (i))) \\ 2147483647
				i := i + 1
			end
			Result := (h \\ 2147483647).to_integer_32.abs
		end

feature {NONE} -- Implementation

	constraint_hash (a_constraint: CONSTRAINT): INTEGER_64
			-- Hash of the kind and value of `a_constraint`
		do
			if attached {CONSTRAINT_FIXED} a_constraint as c then
				Result := 1000003 + c.value.to_integer_64
			elseif attached {CONSTRAINT_PERCENTAGE} a_constraint as c then
				Result := 2000003 + c.percent_value.to_integer_64
			elseif attached {CONSTRAINT_RATIO} a_constraint as c then
				Result := 3000017 + c.numerator.to_integer_64 * 131 + c.denominator.to_integer_64
			elseif attached {CONSTRAINT_MIN} a_constraint as c then
				Result := 4000037 + c.min_value.to_integer_64
			elseif attached {CONSTRAINT_MAX} a_constraint as c then
				Result := 5000011 + c.max_value.to_integer_64
			elseif attached {CONSTRAINT_FLEX} a_constraint as c then
				Result := 6000011 + c.weight.to_integer_64
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := area.is_equal (a_other.area) and layout.is_equal (a_other.layout)
		end

end
