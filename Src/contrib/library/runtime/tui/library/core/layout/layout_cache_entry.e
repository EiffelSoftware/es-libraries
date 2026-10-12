note
	description: "[
		Node in the doubly-linked list used by LAYOUT_CACHE for O(1) LRU eviction tracking.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LAYOUT_CACHE_ENTRY

create
	make

feature {NONE} -- Initialization

	make (a_key: LAYOUT_CACHE_KEY; a_areas: ARRAY [RECT]; a_spacers: detachable ARRAY [RECT])
			-- Initialize node with `a_key`, `a_areas`, and optional `a_spacers`.
		require
			key_attached: a_key /= Void
			areas_attached: a_areas /= Void
		do
			key := a_key
			areas := a_areas
			spacers := a_spacers
		ensure
			key_set: key = a_key
			areas_set: areas = a_areas
			spacers_set: spacers = a_spacers
		end

feature -- Access

	key: LAYOUT_CACHE_KEY
			-- Cache lookup key

	areas: ARRAY [RECT]
			-- Computed layout chunks

	spacers: detachable ARRAY [RECT]
			-- Optional computed spacers between and around chunks

	previous_entry: detachable LAYOUT_CACHE_ENTRY
			-- Previous node (closer to MRU head)

	next_entry: detachable LAYOUT_CACHE_ENTRY
			-- Next node (closer to LRU tail)

feature {LAYOUT_CACHE} -- Element change

	set_areas (a_areas: ARRAY [RECT])
			-- Set cached `areas`.
		require
			areas_attached: a_areas /= Void
		do
			areas := a_areas
		ensure
			areas_set: areas = a_areas
		end

	set_spacers (a_spacers: detachable ARRAY [RECT])
			-- Set cached `spacers`.
		do
			spacers := a_spacers
		ensure
			spacers_set: spacers = a_spacers
		end

	set_previous_entry (a_entry: detachable LAYOUT_CACHE_ENTRY)
			-- Set `previous_entry` link.
		do
			previous_entry := a_entry
		ensure
			previous_set: previous_entry = a_entry
		end

	set_next_entry (a_entry: detachable LAYOUT_CACHE_ENTRY)
			-- Set `next_entry` link.
		do
			next_entry := a_entry
		ensure
			next_set: next_entry = a_entry
		end

invariant
	key_attached: key /= Void
	areas_attached: areas /= Void

end
