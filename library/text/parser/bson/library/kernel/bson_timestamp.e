note
	description: "[
		BSON_TIMESTAMP represents a special timestamp used internally by MongoDB.
		
		In BSON, timestamp is serialized as uint64:
		- First 4 bytes: increment
		- Second 4 bytes: timestamp (seconds since Unix epoch)
		
		Note: This is different from BSON_DATETIME and is primarily used
		for MongoDB replication and sharding.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_TIMESTAMP

inherit
	BSON_VALUE
		redefine
			is_timestamp
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make,
	make_from_raw

feature {NONE} -- Initialization

	make (a_timestamp: NATURAL_32; an_increment: NATURAL_32)
			-- Initialize with timestamp and increment.
		do
			timestamp := a_timestamp
			increment := an_increment
		ensure
			timestamp_set: timestamp = a_timestamp
			increment_set: increment = an_increment
		end

	make_from_raw (a_raw: NATURAL_64)
			-- Initialize from raw uint64 value.
		do
			increment := (a_raw & 0xFFFFFFFF).to_natural_32
			timestamp := ((a_raw |>> 32) & 0xFFFFFFFF).to_natural_32
		end

feature -- Status report

	is_timestamp: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_timestamp
		end

	timestamp: NATURAL_32
			-- Unix timestamp (seconds since epoch).

	increment: NATURAL_32
			-- Ordinal increment.

	to_raw: NATURAL_64
			-- Raw uint64 representation.
		do
			Result := (timestamp.to_natural_64 |<< 32) + increment.to_natural_64
		end

	seconds: NATURAL_32
		do
			-- FIXME
			Result := timestamp
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_timestamp (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := to_raw.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			Result := "Timestamp(" + timestamp.out + ", " + increment.out + ")"
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
