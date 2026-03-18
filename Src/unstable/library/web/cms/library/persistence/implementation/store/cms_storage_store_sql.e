note
	description: "Storage based on Eiffel Store component."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CMS_STORAGE_STORE_SQL

inherit
	CMS_STORAGE_SQL

	GLOBAL_SETTINGS

	DECIMAL_ACCESS

feature {NONE} -- Initialization

	make (a_connection: DATABASE_CONNECTION)
			--
		require
			is_connected: a_connection.is_connected
		do
			connection := a_connection
			debug ("cms_debug")
--				write_information_log (generator + ".make - is database connected?  "+ a_connection.is_connected.out )
			end
			create {DATABASE_HANDLER_IMPL} db_handler.make (a_connection)
			create error_handler.make

			set_decimal_functions (agent create_decimal, agent is_decimal, agent decimal_factors, agent decimal_output)
			set_default_decimal_scale (2)
			set_is_decimal_used (True)

		end

feature -- Status report

	is_available: BOOLEAN
			-- Is storage available?
		do
			Result := connection.is_connected
		end

feature -- Basic operation

	close
			-- <Precursor>
			-- Disconnect from SQL database.
		do
			connection.disconnect
		end

feature {NONE} -- Implementation	

	db_handler: DATABASE_HANDLER

	connection: DATABASE_CONNECTION
			-- Current database connection.	

feature -- Decimal Callbacks

	create_decimal (a_digits: STRING_8; a_sign, a_precision, a_scale: INTEGER): ANY
			-- Create decimal
		local
			l_d: DECIMAL
			l_s: STRING_8
		do
			create l_s.make (a_precision + 2)
			if a_sign = 0 then
				l_s.append_character ('-')
			end

			if a_scale = 0 then
				l_s.append (a_digits)
			elseif a_scale > 0 then
				if a_scale < a_digits.count then
						-- 1.234
					l_s.append (a_digits.substring (1, a_digits.count - a_scale))
					l_s.append_character ('.')
					l_s.append (a_digits.substring (a_digits.count - a_scale + 1, a_digits.count))
				else
						-- 0.1234
					l_s.append ("0.")
					append_characters (l_s, '0', (a_scale - a_digits.count))
					l_s.append (a_digits)
				end
			else
				l_s.append (a_digits)
				append_characters (l_s, '0', (-a_scale))
			end
			create l_d.make_from_string (l_s)
			Result := l_d
		end

	append_characters (a_str: STRING_8; a_c: CHARACTER; a_n: INTEGER)
			-- Append `a_n' `a_c' into `a_str'.
		local
			i: INTEGER
		do
			from
				i := 0
			until
				i = a_n
			loop
				a_str.append_character (a_c)
				i := i + 1
			end
		end

	is_decimal (a_obj: ANY): BOOLEAN
			-- Is decimal?
		do
			Result := attached {DECIMAL} a_obj
		end

	decimal_factors (a_obj: ANY): TUPLE [digits: STRING_8; sign, precision, scale: INTEGER]
			-- Decimal factors
		local
			l_sign: INTEGER
		do
			if attached {DECIMAL} a_obj as l_d then
				if l_d.is_negative then
					l_sign := 0
				else
					l_sign := 1
				end
				Result := [l_d.coefficient.out, l_sign, l_d.count, -l_d.exponent]
			else
				Result := ["0", 1, 1, 0]
			end
		end

	decimal_output (a_obj: ANY): STRING_8
			-- Decimal output
		do
			if attached {DECIMAL} a_obj as l_d then
				Result := l_d.to_engineering_string
			else
				Result := "0"
			end
		end

feature -- Query

	sql_post_execution
			-- Post database execution.
		do
			error_handler.append (db_handler.database_error_handler)
			if error_handler.has_error then
				debug ("cms_error")
--					write_critical_log (generator + ".post_execution " +  error_handler.as_string_representation)
				end
			end
		end

	sql_begin_transaction
			-- <Precursor>
		do
			connection.begin_transaction
		end

	sql_rollback_transaction
			-- <Precursor>
		do
			connection.rollback
		end

	sql_commit_transaction
			-- <Precursor>
		do
			connection.commit
		end

	sql_query (a_sql_statement: READABLE_STRING_8; a_params: detachable STRING_TABLE [detachable ANY])
			-- Execute an sql query `a_sql_statement' with the params `a_params'.
		do
			check_sql_query_validity (a_sql_statement, a_params)
			db_handler.set_query (create {DATABASE_QUERY}.data_reader (a_sql_statement, a_params))
			db_handler.execute_query
			sql_post_execution
		end

	sql_finalize
			-- <Precursor>
		do
			-- N/A
		end

	sql_insert (a_sql_statement: READABLE_STRING_8; a_params: detachable STRING_TABLE [detachable ANY])
			-- <Precursor>
		do
			check_sql_query_validity (a_sql_statement, a_params)
			db_handler.set_query (create {DATABASE_QUERY}.data_reader (a_sql_statement, a_params))
			db_handler.execute_change
			sql_post_execution
		end

	sql_modify (a_sql_statement: READABLE_STRING_8; a_params: detachable STRING_TABLE [detachable ANY])
			-- <Precursor>
		do
			check_sql_query_validity (a_sql_statement, a_params)
			db_handler.set_query (create {DATABASE_QUERY}.data_reader (a_sql_statement, a_params))
			db_handler.execute_change
			sql_post_execution
		end

	sql_delete (a_sql_statement: READABLE_STRING_8; a_params: detachable STRING_TABLE [detachable ANY])
			-- <Precursor>
		do
			sql_modify (a_sql_statement, a_params)
		end

	sql_rows_count: INTEGER
			-- Number of rows for last sql execution.	
		do
			Result := db_handler.count
		end

	sql_start
			-- Set the cursor on first element.
		do
			db_handler.start
		end

	sql_after: BOOLEAN
			-- Are there no more items to iterate over?	
		do
			Result := db_handler.after
		end

	sql_forth
			-- Fetch next row from last sql execution, if any.
		do
			db_handler.forth
		end

	sql_valid_item_index (a_index: INTEGER): BOOLEAN
		do
			Result := attached {DB_TUPLE} db_handler.item as l_item and then l_item.valid_index (a_index)
		end

	sql_columns_count: INTEGER
		do
			if attached {DB_TUPLE} db_handler.item as l_item then
				Result := l_item.count
			else
				check has_row: False end
			end
		end

	sql_column_name (a_index: INTEGER): detachable READABLE_STRING_8
		do
			if attached {DB_TUPLE} db_handler.item as l_item then
				Result := l_item.column_name (a_index)
			end
		end

	sql_item (a_index: INTEGER): detachable ANY
		do
			if attached {DB_TUPLE} db_handler.item as l_item and then l_item.count >= a_index then
				Result := l_item.item (a_index)
			else
				check has_item_at_index: False end
			end
		end

	sql_read_integer_32 (a_index: INTEGER): INTEGER_32
			-- Retrieved value at `a_index' position in `item'.
		local
			l_item: like sql_item
			i64: INTEGER_64
		do
			l_item := sql_item (a_index)
			if attached {INTEGER_32} l_item as i then
				Result := i
			elseif attached {INTEGER_32_REF} l_item as l_value then
				Result := l_value.item
			else
				if attached {INTEGER_64} l_item as i then
					i64 := i
				elseif attached {INTEGER_64_REF} l_item as l_value then
					i64 := l_value.item
				else
					check is_integer_32: False end
				end
				if i64 <= {INTEGER_32}.max_value then
					Result := i64.to_integer_32
				else
					check is_integer_32: False end
				end
			end
		end

	sql_read_real_32 (a_index: INTEGER): REAL_32
			-- Retrieved value at `a_index' position in `item'.
		local
			l_item: like sql_item
			r64: REAL_64
		do
			l_item := sql_item (a_index)
			if attached {REAL_32} l_item as r then
				Result := r
			elseif attached {REAL_32_REF} l_item as l_value then
				Result := l_value.item
			else
				if attached {REAL_64} l_item as r then
					r64 := r
				elseif attached {REAL_64_REF} l_item as l_value then
					r64 := l_value.item
				else
					check is_real_32: False end
				end
				if r64 <= {REAL_32}.max_value then
					Result := r64.truncated_to_real
				else
					check is_real_32: False end
				end
			end
		end

	sql_read_date_time (a_index: INTEGER): detachable DATE_TIME
			-- Retrieved value at `a_index' position in `item'.
		local
			l_item: like sql_item
		do
			l_item := sql_item (a_index)
			if attached {DATE_TIME} l_item as dt then
				Result := dt
			elseif attached {DATE} l_item as d then
				create Result.make_by_date (d)
			else
				check is_date_time_or_null: l_item = Void end
			end
		end

	sql_read_date (a_index: INTEGER): detachable DATE
			-- Retrieved value at `a_index' position in `item'.
		local
			l_item: like sql_item
		do
			l_item := sql_item (a_index)
			if attached {DATE} l_item as d then
				Result := d
			elseif attached {DATE_TIME} l_item as dt then
				Result := dt.date
			else
				check is_date_or_null: l_item = Void end
			end
		end

end
