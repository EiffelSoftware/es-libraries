note
	description: "[
		Cache ensuring object identity: for each (object_number, generation) pair,
		exactly one in-memory PDF_OBJECT exists.
		This is critical for maintaining object identity during parsing and modification.
		See plan.md Section 4.1: Canonical Object Rule.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_OBJECT_CACHE

create
	make

feature -- Initialization

	make
			-- Create an empty object cache.
		do
			create cache.make (100)
		ensure
			cache_empty: cache.is_empty
		end

feature -- Access

	object (id: PDF_OBJECT_ID): detachable PDF_OBJECT
			-- Get object with given ID, or Void if not cached.
		local
			key: STRING_8
		do
			key := make_key (id)
			if cache.has (key) then
				Result := cache.item (key)
			end
		end

	count: INTEGER
			-- Number of cached objects.
		do
			Result := cache.count
		ensure
			non_negative: Result >= 0
		end

feature -- Status Report

	has (id: PDF_OBJECT_ID): BOOLEAN
			-- Is an object with given ID cached?
		local
			key: STRING_8
		do
			key := make_key (id)
			Result := cache.has (key)
		end

feature -- Element Change

	put (id: PDF_OBJECT_ID; obj: PDF_OBJECT)
			-- Cache object with given ID.
			-- Replaces any existing object with same ID.
		local
			key: STRING_8
		do
			key := make_key (id)
			cache.force (obj, key)
		ensure
			object_cached: has (id)
			same_object: object (id) = obj
		end

	remove (id: PDF_OBJECT_ID)
			-- Remove object with given ID from cache.
		local
			key: STRING_8
		do
			key := make_key (id)
			if cache.has (key) then
				cache.remove (key)
			end
		ensure
			object_removed: not has (id)
		end

	clear
			-- Remove all objects from cache.
		do
			cache.wipe_out
		ensure
			cache_empty: cache.is_empty
		end

feature {NONE} -- Implementation

	cache: HASH_TABLE [PDF_OBJECT, STRING_8]
			-- Internal cache mapping ID keys to objects.
			-- Keys are ASCII strings (object_number:generation).

	make_key (id: PDF_OBJECT_ID): STRING_8
			-- Create cache key from object ID.
			-- Keys are ASCII strings (object_number:generation).
		do
			create Result.make (20)
			Result.append (id.object_number.out)
			Result.append_character (':')
			Result.append (id.generation.out)
		ensure
			result_not_empty: not Result.is_empty
			-- Same key for equal IDs (deterministic)
		end

invariant

end
