note
	description: "[
		Converter between BSON and JSON formats.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSONJSON_CONVERTER

create
	make

feature {NONE} -- Initialization

	make
		do
			-- No initialization needed
		end

feature -- Conversion

	convert_json_to_bson (a_json: JSON_VALUE; a_doc: BSON_DOCUMENT)
			-- Convert JSON value to BSON document.
		require
			json_not_void: a_json /= Void
			document_not_void: a_doc /= Void
		do
			if a_json.is_object then
				if attached {JSON_OBJECT} a_json as obj then
					across obj as i loop
						a_doc.put (json_value_to_bson (i), (@i.key).unescaped_string_32)
					end
				end
			else

				-- Non-object JSON, wrap in a document with "value" key
				a_doc.put (json_value_to_bson (a_json), "value")
			end
		end

	convert_bson_to_json (a_doc: BSON_DOCUMENT): detachable JSON_OBJECT
			-- Convert BSON document to JSON object.
		require
			document_not_void: a_doc /= Void
		local
			v: BSON_JSON_VISITOR
			writer: JSON_STREAM_TEXT_WRITER
			s: STRING_8
			p: JSON_PARSER
		do
			create s.make_empty
			create writer.make_with_text (s)
			create v.make_with_writer (writer)
			a_doc.accept (v)
			-- This is a placeholder; the visitor should build the JSON

			create p.make
			p.parse_string (s)
			if p.is_parsed and p.is_valid then
				Result := p.parsed_json_object
			end
		end

feature {NONE} -- Implementation

	json_value_to_bson (a_val: JSON_VALUE): BSON_VALUE
			-- Convert JSON value to BSON value.
		require
			val_not_void: a_val /= Void
		local
			barr: BSON_ARRAY
			bdoc: BSON_DOCUMENT
		do
			if a_val.is_string then
				if attached {JSON_STRING} a_val as s then
					create {BSON_STRING} Result.make_from_string_general (s.unescaped_string_8)
				end
			elseif a_val.is_number then
				if attached {JSON_NUMBER} a_val as n then
					if n.item.has ('.') or n.item.has ('e') then
						create {BSON_DOUBLE} Result.make (n.item.to_real_64)
					else
						if attached n.integer_64_item as i64 then
							create {BSON_INT64} Result.make (i64)
						else
							create {BSON_DOUBLE} Result.make (n.item.to_real_64)
						end
					end
				end
			elseif a_val.is_boolean then
				if attached {JSON_BOOLEAN} a_val as b then
					create {BSON_BOOLEAN} Result.make (b.item)
				end
			elseif a_val.is_null then
				create {BSON_NULL} Result
			elseif a_val.is_array then
				if attached {JSON_ARRAY} a_val as arr then
					create barr.make_empty
					across arr as i loop
						barr.extend (json_value_to_bson (i))
					end
					Result := barr
				end
			elseif a_val.is_object then
				if attached {JSON_OBJECT} a_val as obj then
					create bdoc.make_empty
					across obj as i loop
						bdoc.put (json_value_to_bson (i), (@i.key).unescaped_string_32)
					end
					Result := bdoc
				end
			end
			if Result = Void then
				create {BSON_NULL} Result
			end
		ensure
			result_not_void: Result /= Void
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
