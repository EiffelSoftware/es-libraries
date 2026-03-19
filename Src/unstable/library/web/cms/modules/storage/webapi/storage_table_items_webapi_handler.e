note
	description: "WebAPI handler for listing table items (rows)."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	STORAGE_TABLE_ITEMS_WEBAPI_HANDLER

inherit
	STORAGE_WEBAPI_HANDLER

create
	make

feature {NONE} -- Router setup

	setup_router (a_router: WSF_ROUTER)
		do
			a_router.handle (versioned_base_uri_template + "storage/tables/{table_name}/items", Current, a_router.methods_get)
		end

feature -- Execution

	execute (a_version: READABLE_STRING_GENERAL; req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			rep: HM_WEBAPI_RESPONSE
			jarr: JSON_ARRAY
			jobj: JSON_OBJECT
			table_name: detachable READABLE_STRING_GENERAL
			rows: detachable LIST [STRING_TABLE [detachable ANY]]
			l_row: STRING_TABLE [detachable ANY]
			k: READABLE_STRING_GENERAL
			offset, count: INTEGER
			limit: INTEGER
			sql_query: STRING_8
			l_storage: detachable CMS_STORAGE_SQL_I
			l_is_sqlite3: BOOLEAN
		do
			rep := new_response (req, res)

				-- Get table name from path
			if attached {WSF_STRING} req.path_parameter ("table_name") as p_table_name then
				table_name := p_table_name.value

					-- Get pagination parameters
				if attached req.query_parameter ("offset") as p_offset and then attached p_offset.string_representation as s then
					if s.is_integer_64 then
						offset := s.to_integer_32
					end
				end
				if attached req.query_parameter ("count") as p_count and then attached p_count.string_representation as s then
					if s.is_integer_64 then
						count := s.to_integer_32
					end
				end

					-- Default values
				if count <= 0 then
					count := 100  -- Default page size
				end
				limit := count

					-- Check permission
				if not api.has_permission ({STORAGE_MODULE}.Permission_query_storage) then
					rep.add_boolean_field ("error", True)
					rep.add_string_field ("message", "Permission denied: query storage permission required")
					rep.execute
				else
						-- Build SQL query
					l_storage := storage_api.sql_storage
					if l_storage /= Void then
						l_is_sqlite3 := l_storage.generator.ends_with ("SQLITE3")

							-- Sanitize table name (basic check - only allow alphanumeric, underscore, and dash)
						if attached table_name as tname and then is_valid_table_name (tname.to_string_8) then
							create sql_query.make_from_string ("SELECT * FROM ")
							sql_query.append (tname.to_string_8)

								-- Add LIMIT and OFFSET for pagination
							if l_is_sqlite3 then
								sql_query.append (" LIMIT ")
								sql_query.append (limit.out)
								if offset > 0 then
									sql_query.append (" OFFSET ")
									sql_query.append (offset.out)
								end
							else
									-- MySQL/MariaDB syntax
								sql_query.append (" LIMIT ")
								sql_query.append (limit.out)
								if offset > 0 then
									sql_query.append (" OFFSET ")
									sql_query.append (offset.out)
								end
							end

								-- Execute query
							if attached storage_api.execute_query (sql_query, Void, 0) as lst then
								rows := lst
								create jarr.make (rows.count)
								across
									rows as r
								loop
									l_row := r
									create jobj.make
									across
										l_row as entry
									loop
										k := @entry.key
										if attached entry as val then
											if attached {READABLE_STRING_GENERAL} val as s then
												jobj.put_string (s, k)
											elseif attached {INTEGER_64} val as i then
												jobj.put_integer (i, k)
											elseif attached {INTEGER_32} val as i32 then
												jobj.put_integer (i32.to_integer_64, k)
											elseif attached {REAL_64} val as r64 then
												jobj.put_real (r64, k)
											elseif attached {REAL_32} val as r32 then
												jobj.put_real (r32, k)
											elseif attached {DECIMAL} val as dec then
												jobj.put_string (dec.to_scientific_string, k)
											elseif attached {BOOLEAN} val as b then
												jobj.put_boolean (b, k)
											else
												jobj.put_string (val.out, k)
											end
										else
											jobj.put (Void, k)
										end
									end
									jarr.extend (jobj)
								end
								if attached {JSON_WEBAPI_RESPONSE} rep as jrep then
									jrep.resource.put (jarr, "rows")
								end
								rep.add_string_field ("table_name", tname.to_string_8)
								rep.add_integer_64_field ("count", rows.count)
								rep.add_integer_64_field ("offset", offset)
								rep.add_integer_64_field ("limit", limit)

									-- Indicate if there might be more rows
								if rows.count = limit then
									rep.add_boolean_field ("has_more", True)
								else
									rep.add_boolean_field ("has_more", False)
								end
							else
								rep.add_boolean_field ("error", True)
								rep.add_string_field ("message", "Query execution failed or table not found: " + tname.to_string_8)
							end
						else
							rep.add_boolean_field ("error", True)
							rep.add_string_field ("message", "Invalid table name")
						end
					else
						rep.add_boolean_field ("error", True)
						rep.add_string_field ("message", "Unable to access SQL storage")
					end
					rep.execute
				end
			else
				rep.add_boolean_field ("error", True)
				rep.add_string_field ("message", "Missing table_name parameter")
				rep.execute
			end
		end

feature {NONE} -- Validation

	is_valid_table_name (a_name: STRING_8): BOOLEAN
			-- Check if table name is valid (contains only alphanumeric, underscore, dash characters).
			-- This is a basic security check to prevent SQL injection.
		local
			i: INTEGER
			c: CHARACTER_8
		do
			Result := not a_name.is_empty
			if Result then
				from
					i := 1
				until
					i > a_name.count or not Result
				loop
					c := a_name [i]
					Result := c.is_alpha_numeric or c = '_' or c = '-'
					i := i + 1
				end
			end
		end

note
	copyright: "2011-2025, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end

