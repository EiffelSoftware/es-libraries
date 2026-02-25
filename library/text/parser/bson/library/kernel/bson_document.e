note
	description: "[
		BSON_DOCUMENT represents a document in BSON.
		A document is an ordered set of key/value pairs where keys are strings.
		
		In BSON, a document is serialized as:
		int32 e_list unsigned_byte(0)
		where int32 is the total size including itself and the terminating null.
	]"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=BSON Specification", "protocol=URI", "src=https://bsonspec.org/spec.html"

class
	BSON_DOCUMENT

inherit
	BSON_VALUE
		redefine
			is_document
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

	TABLE_ITERABLE [BSON_VALUE, READABLE_STRING_GENERAL]
		undefine
			is_equal
		end

	DEBUG_OUTPUT
		undefine
			is_equal
		end

create
	make_empty,
	make_with_capacity,
	make

feature {NONE} -- Initialization

	make_with_capacity (nb: INTEGER)
			-- Initialize with a capacity of `nb' items.
		do
			create items.make (nb)
--			items.compare_objects
		ensure
			items_created: items /= Void
		end

	make_empty
			-- Initialize as empty document.
		do
			make_with_capacity (0)
		ensure
			is_empty: is_empty
		end

	make
			-- Initialize with default capacity.
		do
			make_with_capacity (10)
		end

feature -- Status report

	is_document: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_document
		end

	item alias "[]" (a_key: READABLE_STRING_GENERAL): detachable BSON_VALUE
			-- The BSON value associated with `a_key'.
		do
			Result := items.item (a_key)
		end

	string_item (a_key: READABLE_STRING_GENERAL): detachable BSON_STRING
			-- BSON string at `a_key' if any.
		do
			if attached {BSON_STRING} item (a_key) as bs then
				Result := bs
			end
		end

	int32_item (a_key: READABLE_STRING_GENERAL): detachable BSON_INT32
			-- BSON int32 at `a_key' if any.
		do
			if attached {BSON_INT32} item (a_key) as bi then
				Result := bi
			end
		end

	int64_item (a_key: READABLE_STRING_GENERAL): detachable BSON_INT64
			-- BSON int64 at `a_key' if any.
		do
			if attached {BSON_INT64} item (a_key) as bi then
				Result := bi
			end
		end

	double_item (a_key: READABLE_STRING_GENERAL): detachable BSON_DOUBLE
			-- BSON double at `a_key' if any.
		do
			if attached {BSON_DOUBLE} item (a_key) as bd then
				Result := bd
			end
		end

	boolean_item (a_key: READABLE_STRING_GENERAL): detachable BSON_BOOLEAN
			-- BSON boolean at `a_key' if any.
		do
			if attached {BSON_BOOLEAN} item (a_key) as bb then
				Result := bb
			end
		end

	document_item (a_key: READABLE_STRING_GENERAL): detachable BSON_DOCUMENT
			-- BSON document at `a_key' if any.
		do
			if attached {BSON_DOCUMENT} item (a_key) as bd then
				Result := bd
			end
		end

	array_item (a_key: READABLE_STRING_GENERAL): detachable BSON_ARRAY
			-- BSON array at `a_key' if any.
		do
			if attached {BSON_ARRAY} item (a_key) as ba then
				Result := ba
			end
		end

	binary_item (a_key: READABLE_STRING_GENERAL): detachable BSON_BINARY
			-- BSON binary at `a_key' if any.
		do
			if attached {BSON_BINARY} item (a_key) as bb then
				Result := bb
			end
		end

	object_id_item (a_key: READABLE_STRING_GENERAL): detachable BSON_OBJECT_ID
			-- BSON ObjectId at `a_key' if any.
		do
			if attached {BSON_OBJECT_ID} item (a_key) as bo then
				Result := bo
			end
		end

	datetime_item (a_key: READABLE_STRING_GENERAL): detachable BSON_DATETIME
			-- BSON datetime at `a_key' if any.
		do
			if attached {BSON_DATETIME} item (a_key) as bd then
				Result := bd
			end
		end

feature -- Access: basic values

	string_value (a_key: READABLE_STRING_GENERAL): detachable STRING_32
			-- String value at `a_key' if any.
		do
			if attached string_item (a_key) as bs then
				Result := bs.value
			end
		end

	int32_value (a_key: READABLE_STRING_GENERAL): INTEGER_32
			-- Integer 32 value at `a_key'.
		require
			has_int32: attached int32_item (a_key)
		do
			if attached int32_item (a_key) as bi then
				Result := bi.value
			end
		end

	int64_value (a_key: READABLE_STRING_GENERAL): INTEGER_64
			-- Integer 64 value at `a_key'.
		require
			has_int64: attached int64_item (a_key)
		do
			if attached int64_item (a_key) as bi then
				Result := bi.value
			end
		end

	double_value (a_key: READABLE_STRING_GENERAL): REAL_64
			-- Double value at `a_key'.
		require
			has_double: attached double_item (a_key)
		do
			if attached double_item (a_key) as bd then
				Result := bd.value
			end
		end

	boolean_value (a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Boolean value at `a_key'.
		require
			has_boolean: attached boolean_item (a_key)
		do
			if attached boolean_item (a_key) as bb then
				Result := bb.value
			end
		end

feature -- Measurement

	count: INTEGER
			-- Number of fields.
		do
			Result := items.count
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is empty document?
		do
			Result := items.is_empty
		end

	has_key (a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Has the document a key `a_key'?
		do
			Result := items.has_key (a_key)
		end

	has_item (a_value: BSON_VALUE): BOOLEAN
			-- Has the document an item `a_value'?
		do
			Result := items.has_item (a_value)
		end

feature -- Element change

	put (a_value: detachable BSON_VALUE; a_key: READABLE_STRING_GENERAL)
			-- Assuming there is no item of key `a_key',
			-- insert `a_value' with `a_key'.
		require
			a_key_not_present: not has_key (a_key)
		do
			if a_value = Void then
				put_null (a_key)
			else
				items.extend (a_value, a_key)
			end
		ensure
			has_key: has_key (a_key)
		end

	replace (a_value: detachable BSON_VALUE; a_key: READABLE_STRING_GENERAL)
			-- Associate `a_value' with `a_key'.
			-- Replace existing value if any.
		do
			if a_value = Void then
				replace_with_null (a_key)
			else
				items.force (a_value, a_key)
			end
		ensure
			has_key: has_key (a_key)
		end

	remove (a_key: READABLE_STRING_GENERAL)
			-- Remove item indexed by `a_key' if any.
		do
			items.remove (a_key)
		ensure
			removed: not has_key (a_key)
		end

	wipe_out
			-- Reset all items.
		do
			items.wipe_out
		ensure
			is_empty: is_empty
		end

feature -- Helpers

	put_string (a_value: READABLE_STRING_GENERAL; a_key: READABLE_STRING_GENERAL)
			-- Insert string `a_value' with `a_key'.
		require
			key_not_present: not has_key (a_key)
		do
			put (create {BSON_STRING}.make_from_string_general (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_int32 (a_value: INTEGER_32; a_key: READABLE_STRING_GENERAL)
			-- Insert int32 `a_value' with `a_key'.
		require
			key_not_present: not has_key (a_key)
		do
			put (create {BSON_INT32}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_int64 (a_value: INTEGER_64; a_key: READABLE_STRING_GENERAL)
			-- Insert int64 `a_value' with `a_key'.
		require
			key_not_present: not has_key (a_key)
		do
			put (create {BSON_INT64}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_double (a_value: REAL_64; a_key: READABLE_STRING_GENERAL)
			-- Insert double `a_value' with `a_key'.
		require
			key_not_present: not has_key (a_key)
		do
			put (create {BSON_DOUBLE}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_boolean (a_value: BOOLEAN; a_key: READABLE_STRING_GENERAL)
			-- Insert boolean `a_value' with `a_key'.
		require
			key_not_present: not has_key (a_key)
		do
			put (create {BSON_BOOLEAN}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_null (a_key: READABLE_STRING_GENERAL)
			-- Insert null with `a_key'.
		require
			key_not_present: not has_key (a_key)
		do
			put (create {BSON_NULL}, a_key)
		ensure
			has_key: has_key (a_key)
		end

	replace_with_string (a_value: READABLE_STRING_GENERAL; a_key: READABLE_STRING_GENERAL)
			-- Replace or insert string `a_value' with `a_key'.
		do
			replace (create {BSON_STRING}.make_from_string_general (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	replace_with_int32 (a_value: INTEGER_32; a_key: READABLE_STRING_GENERAL)
			-- Replace or insert int32 `a_value' with `a_key'.
		do
			replace (create {BSON_INT32}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	replace_with_int64 (a_value: INTEGER_64; a_key: READABLE_STRING_GENERAL)
			-- Replace or insert int64 `a_value' with `a_key'.
		do
			replace (create {BSON_INT64}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	replace_with_double (a_value: REAL_64; a_key: READABLE_STRING_GENERAL)
			-- Replace or insert double `a_value' with `a_key'.
		do
			replace (create {BSON_DOUBLE}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	replace_with_boolean (a_value: BOOLEAN; a_key: READABLE_STRING_GENERAL)
			-- Replace or insert boolean `a_value' with `a_key'.
		do
			replace (create {BSON_BOOLEAN}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	replace_with_null (a_key: READABLE_STRING_GENERAL)
			-- Replace or insert null with `a_key'.
		do
			replace (create {BSON_NULL}, a_key)
		ensure
			has_key: has_key (a_key)
		end

feature -- Access

	new_cursor: TABLE_ITERATION_CURSOR [BSON_VALUE, READABLE_STRING_GENERAL]
			-- Fresh cursor associated with current structure.
		do
			Result := items.new_cursor
		end

	current_keys: ARRAY [READABLE_STRING_GENERAL]
			-- Array containing actually used keys.
		do
			Result := items.current_keys
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_document (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			from
				items.start
				Result := items.out.hash_code
			until
				items.off
			loop
				Result := ((Result \\ 8388593) |<< 8) + items.item_for_iteration.hash_code
				items.forth
			end
			Result := Result.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			create Result.make (10)
			Result.append_integer (count)
			Result.append (" item")
			if count > 1 then
				Result.append_character ('s')
			end
		end

feature {NONE} -- Implementation

	items: STRING_TABLE [BSON_VALUE]
			-- Value container.

invariant
	items_not_void: items /= Void

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
