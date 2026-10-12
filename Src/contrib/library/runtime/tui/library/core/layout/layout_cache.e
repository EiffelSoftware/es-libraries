note
	description: "[
		Bounded LRU layout cache storing computed (RECT, LAYOUT) -> areas and spacers.
		Default capacity is 500 entries (matching Ratatui DEFAULT_CACHE_SIZE).
		When capacity is reached, the least recently used (LRU) entry is evicted in O(1)
		time via a doubly-linked hash map. Lookups reuse one key object and hash once, so a
		cache hit allocates nothing. Not synchronized: LAYOUT uses one instance per thread
		(`once`). Stored arrays are owned by the cache: `get`, `get_spacers` and `entry`
		return them as stored, so callers must copy before modifying (LAYOUT.split does).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LAYOUT_CACHE

inherit
	ANY
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize layout cache with default capacity 500.
		do
			make (Default_capacity)
		ensure then
			capacity_set: capacity = Default_capacity
			enabled_by_default: is_enabled
		end

	make (a_capacity: INTEGER)
			-- Initialize layout cache with `a_capacity`.
		require
			positive_capacity: a_capacity > 0
		do
			capacity := a_capacity
			create table.make (a_capacity)
			create lookup_key.make (create {RECT}, create {LAYOUT})
			is_enabled := True
		ensure
			capacity_set: capacity = a_capacity
			is_enabled: is_enabled
		end

feature -- Access

	Default_capacity: INTEGER = 500
			-- Standard cache size matching Ratatui Layout::DEFAULT_CACHE_SIZE

	capacity: INTEGER
			-- Maximum cache entries before LRU eviction

	count: INTEGER
			-- Number of cached layout solutions
		do
			Result := table.count
		ensure
			non_negative: Result >= 0
			bounded: Result <= capacity
		end

	is_enabled: BOOLEAN
			-- Is caching enabled?

	has (a_area: RECT; a_layout: LAYOUT): BOOLEAN
			-- Does cache contain a solution for (`a_area`, `a_layout`)? (Does not affect LRU order.)
		do
			if is_enabled then
				lookup_key.set (a_area, a_layout)
				Result := table.has (lookup_key)
			end
		end

	entry (a_area: RECT; a_layout: LAYOUT): detachable LAYOUT_CACHE_ENTRY
			-- Cached solution for (`a_area`, `a_layout`), promoted to most recently used;
			-- Void when absent or when caching is disabled. The entry is owned by the cache.
		do
			if is_enabled then
				lookup_key.set (a_area, a_layout)
				Result := table.item (lookup_key)
				if attached Result as l_entry and then head /= l_entry then
					detach_entry (l_entry)
					attach_to_head (l_entry)
				end
			end
		end

	get (a_area: RECT; a_layout: LAYOUT): detachable ARRAY [RECT]
			-- Cached layout rectangles if present, promoting the entry to MRU.
		do
			if attached entry (a_area, a_layout) as l_entry then
				Result := l_entry.areas
			end
		end

	get_spacers (a_area: RECT; a_layout: LAYOUT): detachable ARRAY [RECT]
			-- Cached layout spacers if present, promoting the entry to MRU.
		do
			if attached entry (a_area, a_layout) as l_entry then
				Result := l_entry.spacers
			end
		end

feature -- Element change

	put (a_results: ARRAY [RECT]; a_area: RECT; a_layout: LAYOUT)
			-- Cache `a_results` for (`a_area`, `a_layout`) with LRU tracking (no spacers).
		do
			put_with_spacers (a_results, Void, a_area, a_layout)
		end

	put_with_spacers (a_results: ARRAY [RECT]; a_spacers: detachable ARRAY [RECT]; a_area: RECT; a_layout: LAYOUT)
			-- Cache `a_results` and `a_spacers` for (`a_area`, `a_layout`) with LRU tracking.
			-- The arrays are stored as given (the cache owns them from now on).
		local
			l_key: LAYOUT_CACHE_KEY
			l_entry: LAYOUT_CACHE_ENTRY
		do
			if is_enabled then
				lookup_key.set (a_area, a_layout)
				if attached table.item (lookup_key) as l_existing then
					l_existing.set_areas (a_results)
					l_existing.set_spacers (a_spacers)
					detach_entry (l_existing)
					attach_to_head (l_existing)
				else
					if table.count >= capacity and attached tail as l_tail then
						-- LRU eviction: remove the oldest (tail) entry
						table.remove (l_tail.key)
						detach_entry (l_tail)
					end
					create l_key.make (a_area, a_layout)
					create l_entry.make (l_key, a_results, a_spacers)
					attach_to_head (l_entry)
					table.put (l_entry, l_key)
				end
			end
		ensure
			stored: is_enabled implies has (a_area, a_layout)
		end

	clear
			-- Clear all cached entries.
		do
			table.wipe_out
			head := Void
			tail := Void
		ensure
			empty: count = 0
		end

	enable
			-- Enable caching.
		do
			is_enabled := True
		ensure
			enabled: is_enabled
		end

	disable
			-- Disable caching and clear table.
		do
			is_enabled := False
			clear
		ensure
			disabled: not is_enabled
			empty: count = 0
		end

feature {NONE} -- LRU Doubly-Linked List Manipulation

	head: detachable LAYOUT_CACHE_ENTRY
			-- Most recently used entry

	tail: detachable LAYOUT_CACHE_ENTRY
			-- Least recently used entry

	detach_entry (a_entry: LAYOUT_CACHE_ENTRY)
			-- Unlink `a_entry` from the chain.
		local
			l_prev, l_next: detachable LAYOUT_CACHE_ENTRY
		do
			l_prev := a_entry.previous_entry
			l_next := a_entry.next_entry
			if attached l_prev as p then
				p.set_next_entry (l_next)
			else
				head := l_next
			end
			if attached l_next as n then
				n.set_previous_entry (l_prev)
			else
				tail := l_prev
			end
			a_entry.set_previous_entry (Void)
			a_entry.set_next_entry (Void)
		end

	attach_to_head (a_entry: LAYOUT_CACHE_ENTRY)
			-- Place `a_entry` at the head of the chain (most recently used).
		do
			a_entry.set_previous_entry (Void)
			a_entry.set_next_entry (head)
			if attached head as h then
				h.set_previous_entry (a_entry)
			else
				tail := a_entry
			end
			head := a_entry
		end

feature {NONE} -- Implementation

	table: HASH_TABLE [LAYOUT_CACHE_ENTRY, LAYOUT_CACHE_KEY]
			-- Underlying hash map

	lookup_key: LAYOUT_CACHE_KEY
			-- Reusable key for lookups (never stored in `table`)

invariant
	positive_capacity: capacity > 0
	count_within_capacity: count <= capacity

end
