note
	description: "Parser for S3 ListBucketResult XML response."

class
	S3_LIST_RESPONSE_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser.
		do
		end

feature -- Parsing

	parse_list_response (a_xml_content: READABLE_STRING_8): detachable LIST [S3_OBJECT]
			-- Parse S3 ListBucketResult XML from `a_xml_content`.
			-- Returns list of S3 objects or Void if parsing failed.
		require
			content_not_empty: a_xml_content /= Void and then not a_xml_content.is_empty
		local
			parser: XML_STANDARD_PARSER
			callbacks: XML_CALLBACKS_DOCUMENT
			doc: XML_DOCUMENT
			root: XML_ELEMENT
			objects: ARRAYED_LIST [S3_OBJECT]
		do
			create callbacks.make_null
			create parser.make;
			parser.set_callbacks (callbacks);
			parser.parse_from_string_8 (a_xml_content)
			if parser.is_correct then
				doc := callbacks.document
				if doc /= Void and then attached doc.root_element as root_elem then
					root := root_elem
					create objects.make (10)
					parse_objects (root, objects)
					Result := objects
				end
			end
		end

	parse_list_common_prefixes_response (a_xml_content: READABLE_STRING_8): detachable LIST [READABLE_STRING_32]
			-- Parse S3 ListBucketResult XML from `a_xml_content`.
			-- Returns list of CommonPrefixes.prefix or Void if parsing failed.
		require
			content_not_empty: a_xml_content /= Void and then not a_xml_content.is_empty
		local
			parser: XML_STANDARD_PARSER
			callbacks: XML_CALLBACKS_DOCUMENT
			doc: XML_DOCUMENT
			root: XML_ELEMENT
			lst: ARRAYED_LIST [READABLE_STRING_32]
		do
			create callbacks.make_null
			create parser.make;
			parser.set_callbacks (callbacks);
			parser.parse_from_string_8 (a_xml_content)
			if parser.is_correct then
				doc := callbacks.document
				if doc /= Void and then attached doc.root_element as root_elem then
					root := root_elem
					create lst.make (10)
					parse_common_prefixes (root, lst)
					Result := lst
				end
			end
		end

feature {NONE} -- Implementation

	parse_objects (a_root: XML_ELEMENT; a_objects: LIST [S3_OBJECT])
			-- Parse objects from `a_root` element and add to `a_objects`.
		require
			root_not_void: a_root /= Void
			objects_not_void: a_objects /= Void
		local
			key_str, size_str, last_modified_str: detachable STRING_8
			size_val: INTEGER_32
			parsed_data: TUPLE [key: detachable STRING_8; size: detachable STRING_8; last_modified: detachable STRING_8]
		do
			across
				a_root as child
			loop
				if attached {XML_ELEMENT} child as elem then
					if elem.name.same_string_general ("Contents") then
						parsed_data := parse_contents_element (elem)
						key_str := parsed_data.key
						size_str := parsed_data.size
						last_modified_str := parsed_data.last_modified
						if key_str /= Void and then size_str /= Void then
							if size_str.is_integer then
								size_val := size_str.to_integer
							else
								size_val := 0
							end;
							a_objects.force (create {S3_OBJECT}.make (key_str, size_val, last_modified_str))
						end
					end
				end
			end
		end

	parse_common_prefixes (a_root: XML_ELEMENT; a_list: LIST [READABLE_STRING_32])
			-- Parse CommonPrefixes.prefix from `a_root` element and add to `a_list`.
		require
			root_not_void: a_root /= Void
			a_list_not_void: a_list /= Void
		do
			across
				a_root as child
			loop
				if attached {XML_ELEMENT} child as elem then
					if elem.name.same_string_general ("CommonPrefixes") then
						if
							attached {XML_ELEMENT} elem.element_by_name ("Prefix") as x_prefix and then
							attached extract_text (x_prefix) as s
						then
							a_list.force (s)
						end
					end
				end
			end
		end

	parse_contents_element (a_elem: XML_ELEMENT): TUPLE [key: detachable STRING_8; size: detachable STRING_8; last_modified: detachable STRING_8]
			-- Parse Contents element and extract key, size, and last modified.
		require
			element_not_void: a_elem /= Void
		local
			key_str, size_str, last_modified_str: detachable STRING_8
		do
			across
				a_elem as child
			loop
				if attached {XML_ELEMENT} child as child_elem then
					if child_elem.name.same_string ("Key") then
						key_str := extract_text (child_elem)
					elseif child_elem.name.same_string ("Size") then
						size_str := extract_text (child_elem)
					elseif child_elem.name.same_string ("LastModified") then
						last_modified_str := extract_text (child_elem)
					end
				end
			end
			Result := [key_str, size_str, last_modified_str]
		end

	extract_text (a_element: XML_ELEMENT): detachable STRING_8
			-- Extract text content from `a_element`.
		require
			element_not_void: a_element /= Void
		local
			text_parts: ARRAYED_LIST [STRING_8]
		do
			create text_parts.make (1)
			across
				a_element as child
			loop
				if attached {XML_CHARACTER_DATA} child as char_data then
					text_parts.force (char_data.content.to_string_8)
				end
			end
			if not text_parts.is_empty then
				create Result.make_empty
				across
					text_parts as part
				loop
					Result.append (part)
				end
			end
		end

note
	copyright: "2025-2026, Jocelyn Fiat, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end -- class S3_LIST_RESPONSE_PARSER


