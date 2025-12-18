note
	description: "PostgreSQL database specification"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	POSTGRESQL

inherit
	DATABASE
		redefine
			default_create,
			parse,
			bind_arguments,
			convert_string_type,
			no_args,
			is_affected_row_count_supported,
			affected_row_count,
			result_order,
			sensitive_mixed
		end

	STRING_HANDLER
		redefine
			default_create
		end

	GLOBAL_SETTINGS
		export
			{NONE} all
		redefine
			default_create
		end

	POSTGRESQL_EXTERNALS
		export
			{NONE} all
		redefine
			default_create
		end

	DB_CONSTANT
		export
			{NONE} all
		redefine
			default_create
		end

feature {NONE} -- Initialization

	default_create
			-- Initialize Current
		do
			create descriptors.make_filled (Void, 1, max_descriptor_number)
			create result_pointers.make_filled (default_pointer, 1, max_descriptor_number)
			create arguments.make_filled (Void, 1, max_descriptor_number)
			create row_indices.make_filled (0, 1, max_descriptor_number)
			create prepared_stmt_names.make_filled (Void, 1, max_descriptor_number)
			create last_date_data.make (0)
			create date_buffer.make (date_length)
			create string_buffer.make (selection_string_size)
			last_descriptor := 0
			stmt_counter := 0
		end

feature -- Constants

	database_handle_name: STRING = "POSTGRESQL"

feature -- For DATABASE_STATUS

	is_error_updated: BOOLEAN
			-- Has a PostgreSQL function been called since the last update which may
			-- have caused an update to error code, error message, or warning message?

	is_warning_updated: BOOLEAN
			-- Has a database function been called since last update which may have warnings?

	found: BOOLEAN
			-- Is there any record matching the last selection condition used?

	clear_error
			-- Reset database error status
		do
				-- Don't need to do anything in database
			internal_error_code := 0
			is_error_updated := True
			is_warning_updated := True
		end

	insert_auto_identity_column: BOOLEAN = False
			-- For INSERTs and UPDATEs should record auto-increment identity
			-- columns be explicitly included in the statement?
			-- PostgreSQL uses SERIAL types which auto-generate values

feature -- For DATABASE_CHANGE

	descriptor_is_available: BOOLEAN
			-- Is a descriptor available?
		local
			l_descriptor_index: INTEGER
		do
			from
				Result := False
				l_descriptor_index := 1
			until
				Result or else l_descriptor_index > max_descriptor_number
			loop
				if descriptors.item (l_descriptor_index) = Void then
					Result := True
				else
					l_descriptor_index := l_descriptor_index + 1
				end
			end
		end

	affected_row_count: INTEGER
			-- Number of rows affected by last statement
		do
			-- PostgreSQL returns affected rows via PQcmdTuples
			if last_result_pointer /= default_pointer then
				Result := pq_cmd_tuples (last_result_pointer)
			end
		end

	max_descriptor_number: INTEGER = 20
			-- Max number of descriptors

	No_more_descriptor: INTEGER = -1
			-- Error code indicating no more descriptors available

	is_affected_row_count_supported: BOOLEAN = True
			-- <Precursor>

feature -- For DATABASE_FORMAT

	date_to_str (object: DATE_TIME): STRING
			-- String representation in PostgreSQL of `object'
		do
			create Result.make (21)
			Result.append_character ('%'')
			Result.append (object.formatted_out ("yyyy-[0]mm-[0]dd [0]hh:[0]mi:[0]ss"))
			Result.append_character ('%'')
		end

	string_format (object: detachable STRING): STRING
			-- String representation in SQL of `object'.
		obsolete
			"Use `string_format_32' instead [2017-11-30]."
		do
			Result := string_format_32 (object).as_string_8_conversion
		end

	string_format_32 (object: detachable READABLE_STRING_GENERAL): STRING_32
			-- String representation in PostgreSQL of `object'
		do
			if object = Void then
				Result := once {STRING_32} "IS NULL"
			else
				Result := escaped_sql_string (object)
				Result.prepend_character ({CHARACTER_32} '%'')
				Result.append_character ({CHARACTER_32} '%'')
			end
		end

	True_representation: STRING = "TRUE"
			-- String representation in PostgreSQL for the boolean 'true' value

	False_representation: STRING = "FALSE"
			-- String representation in PostgreSQL for the boolean 'false' value

feature -- For DATABASE_SELECTION, DATABASE_CHANGE

	normal_parse: BOOLEAN
			-- Should the SQL string be parsed normally using SQL_SCAN?
		do
			Result := False
		end

	parse (descriptor: INTEGER; uht: detachable DB_STRING_HASH_TABLE [detachable ANY]; ht_order: detachable ARRAYED_LIST [READABLE_STRING_GENERAL]; uhandle: HANDLE; sql: READABLE_STRING_GENERAL; dynamic: BOOLEAN): BOOLEAN
			-- Parse and prepare a dynamic statement.
		local
			l_result: POINTER
			l_c_string: C_STRING
			l_stmt_name: STRING
			l_converted_sql: STRING
		do
			if dynamic then
				-- Generate unique statement name
				stmt_counter := stmt_counter + 1
				l_stmt_name := "stmt_" + stmt_counter.out

				-- Convert parameter syntax from :name to $1, $2, etc.
				l_converted_sql := convert_parameters (sql, ht_order)

				descriptors.put (sql, descriptor)
				prepared_stmt_names.put (l_stmt_name, descriptor)

				create l_c_string.make (l_stmt_name)
				if attached uht as l_ht and then attached ht_order as l_order then
					l_result := pq_prepare (postgresql_pointer, l_c_string.item,
						(create {C_STRING}.make (l_converted_sql)).item, l_order.count)
					if pq_result_status (l_result) = pgres_command_ok then
						bind_arguments (descriptor, l_ht, l_order)
						Result := True
					end
					pq_clear (l_result)
				else
					l_result := pq_prepare (postgresql_pointer, l_c_string.item,
						(create {C_STRING}.make (l_converted_sql)).item, 0)
					if pq_result_status (l_result) = pgres_command_ok then
						Result := True
					end
					pq_clear (l_result)
				end
				is_error_updated := False
			end
		end

	bind_arguments (descriptor: INTEGER_32; uht: DB_STRING_HASH_TABLE [detachable ANY]; ht_order: detachable ARRAYED_LIST [READABLE_STRING_GENERAL])
			-- Bind arguments
		local
			l_args: DB_PARA_POSTGRESQL
			i: INTEGER
		do
			if uht.count > 0 and then ht_order /= Void then
				if attached arguments.item (descriptor) as l_arg then
					l_args := l_arg
				else
					create l_args.make (uht.count)
					arguments.put (l_args, descriptor)
				end
				from
					ht_order.start
					i := 1
				until
					ht_order.after
				loop
					if i <= l_args.count then
						l_args.replace_parameter (i, uht.item (ht_order.item))
					end
					l_args.extend_parameter (uht.item (ht_order.item))
					ht_order.forth
					i := i + 1
				end
				l_args.set_parameter_count (i - 1)
				is_error_updated := False
			end
		end

feature -- DATABASE_STRING

	sql_name_string: STRING
			-- The name of the PostgreSQL type that represents a string
		do
			Result := "VARCHAR(255)"
		end

	map_var_name_32 (a_para: READABLE_STRING_GENERAL): STRING_32
			-- Map `a_para' to the PostgreSQL statement parameter representation
		do
			create Result.make (a_para.count + 1)
			Result.append ({STRING_32} ":")
			Result.append_string_general (a_para)
		end

feature -- DECIMAL

	sql_name_decimal: STRING
			-- SQL type name for decimal
		once
			Result := "NUMERIC"
		end

feature -- DATABASE_REAL

	sql_name_real: STRING = "REAL"

feature -- DATABASE_DATETIME

	sql_name_datetime: STRING = "TIMESTAMP"

feature -- DATABASE_DOUBLE

	sql_name_double: STRING = "DOUBLE PRECISION"

feature -- DATABASE_CHARACTER

	sql_name_character: STRING = "CHAR"

feature -- DATABASE_INTEGER

	sql_name_integer: STRING = "INTEGER"

	sql_name_integer_16: STRING = "SMALLINT"

	sql_name_integer_64: STRING = "BIGINT"

feature -- DATABASE_BOOLEAN

	sql_name_boolean: STRING = "BOOLEAN"

feature -- LOGIN and DATABASE_APPL only for password_ok

	password_ok (upassword: STRING): BOOLEAN
			-- Is the given `upassword' correct?
		do
				-- Password can be empty in PostgreSQL
			Result := upassword /= Void
		end

	password_ensure (name, password, uname, upassword: STRING): BOOLEAN
			-- Make sure `name' equals `uname' and `password' equals `upassword'
		do
			Result := True
		end

feature -- For database types

	convert_string_type (r_any: ANY; field_name, class_name: STRING): ANY
			-- Convert `r_any' to the expected object.
		local
			data_type: INTEGER_REF
		do
			if field_name.is_equal ("data_type") then
				if class_name.is_equal (("").generator) then
					create data_type
					if r_any.is_equal ("character varying") or else r_any.is_equal ("varchar") or else r_any.is_equal ("char") then
						data_type.set_item ({DB_TYPES}.string_type)
					elseif r_any.is_equal ("text") then
						data_type.set_item ({DB_TYPES}.string_32_type)
					elseif r_any.is_equal ("double precision") or else r_any.is_equal ("float8") then
						data_type.set_item ({DB_TYPES}.real_64_type)
					elseif r_any.is_equal ("numeric") or else r_any.is_equal ("decimal") then
						data_type.set_item ({DB_TYPES}.decimal_type)
					elseif r_any.is_equal ("real") or else r_any.is_equal ("float4") then
						data_type.set_item ({DB_TYPES}.real_32_type)
					elseif r_any.is_equal ("integer") or else r_any.is_equal ("int4") then
						if not use_extended_types then
							data_type.set_item ({DB_TYPES}.integer_32_type)
						else
							data_type.set_item ({DB_TYPES}.integer_32_type)
						end
					elseif r_any.is_equal ("smallint") or else r_any.is_equal ("int2") then
						data_type.set_item ({DB_TYPES}.integer_16_type)
					elseif r_any.is_equal ("bigint") or else r_any.is_equal ("int8") then
						data_type.set_item ({DB_TYPES}.integer_64_type)
					elseif r_any.is_equal ("timestamp") or else r_any.is_equal ("timestamp without time zone") or else
					   r_any.is_equal ("timestamp with time zone") or else r_any.is_equal ("date") then
						data_type.set_item ({DB_TYPES}.date_type)
					elseif r_any.is_equal ("boolean") or else r_any.is_equal ("bool") then
						data_type.set_item ({DB_TYPES}.boolean_type)
					elseif r_any.is_equal ("bytea") then
						-- Binary data type
						data_type.set_item ({DB_TYPES}.string_type)
					elseif r_any.is_equal ("") then
						-- Empty type string - default to string
						data_type.set_item ({DB_TYPES}.string_type)
					else
						io.error.putstring ("Unknown data type '")
						print (r_any)
						io.error.putstring ("'%N")
						-- Default to string type for unknown types
						data_type.set_item ({DB_TYPES}.string_type)
					end
					Result := data_type
				else
					Result := r_any
				end
			else
				Result := r_any
			end
		end

feature -- For DATABASE_PROC

	support_sql_of_proc: BOOLEAN = True

	support_stored_proc: BOOLEAN = True

	sql_as: STRING = " AS $$ BEGIN "

	sql_end: STRING = "; END; $$ LANGUAGE plpgsql;"

	sql_execution: STRING = "SELECT "

	sql_creation: STRING = "CREATE OR REPLACE FUNCTION "

	sql_after_exec: STRING = ""

	support_drop_proc: BOOLEAN = True

	name_proc_lower: BOOLEAN = True

	map_var_between: STRING = ""

	no_args: STRING = "()"

	Select_text_32 (proc_name: READABLE_STRING_GENERAL): STRING_32
		do
			Result := {STRING_32} "SELECT routine_definition %
				%FROM information_schema.routines %
				%WHERE routine_name = :name AND %
				%routine_type = 'FUNCTION'"
		end

	Select_exists_32 (proc_name: READABLE_STRING_GENERAL): STRING_32
		do
			Result := {STRING_32} "SELECT count(*) FROM information_schema.routines %
				%WHERE routine_type = 'FUNCTION' AND %
				%routine_name = :name"
		end

feature -- For DATABASE_REPOSITORY

	Selection_string (rep_qualifier, rep_owner, rep_name: STRING): STRING
		do
			repository_name := rep_name
			Result := "SELECT table_catalog, table_schema, table_name, %
				%column_name, ordinal_position as column_id, %
				%column_default as data_default, is_nullable as nullable, %
				%data_type, character_maximum_length as column_size, %
				%character_octet_length, numeric_precision as data_precision, %
				%numeric_scale as scale %
				%FROM information_schema.columns WHERE table_name = :rep"
		end

	sql_string: STRING = "VARCHAR("

	sql_string2 (int: INTEGER): STRING
		do
			Result := "VARCHAR("
			Result.append (int.out)
			Result.append_character (')')
		end

	sql_wstring: STRING = "VARCHAR("

	sql_wstring2 (int: INTEGER): STRING
		do
			Result := "VARCHAR("
			Result.append (int.out)
			Result.append (")")
		end

	sensitive_mixed: BOOLEAN = False
			-- PostgreSQL converts unquoted identifiers to lowercase,
			-- so repository names need to be converted to lowercase
			-- for correct matching with information_schema tables

feature -- External features

	get_error_message: POINTER
			-- The error message as returned by the RDBMS after the last action.
		do
			Result := pq_get_error_message (postgresql_pointer)
			is_error_updated := True
		end

	get_error_message_string: STRING_32
		local
			l_ptr: POINTER
			l_s: STRING_8
		do
			l_ptr := pq_get_error_message (postgresql_pointer)
			if l_ptr /= default_pointer then
				create l_s.make_from_c (l_ptr)
				if l_s.is_empty then
					if last_result_pointer /= default_pointer then
						l_ptr := pq_get_result_error (last_result_pointer)
						if l_ptr /= default_pointer then
							create l_s.make_from_c (l_ptr)
						end
					end
				end
				Result := utf8_to_utf32 (l_s)
			else
				create Result.make_empty
			end
			is_error_updated := True
		end

	get_error_code: INTEGER
			-- The error code as returned by the RDBMS after the last action.
		local
			l_status: INTEGER
		do
			if internal_error_code /= 0 then
				Result := internal_error_code
			elseif last_result_pointer /= default_pointer then
				l_status := pq_result_status (last_result_pointer)
				if l_status = pgres_tuples_ok or l_status = pgres_command_ok or l_status = pgres_empty_query then
					Result := 0
				else
					Result := l_status
				end
			else
				Result := pq_get_error_code (postgresql_pointer)
			end
			is_error_updated := True
		end

	get_warn_message: POINTER
			-- The warning message as returned by the RDBMS after the last action.
		do
			Result := pq_get_error_message (postgresql_pointer)
			is_warning_updated := True
		end

	get_warn_message_string: STRING_32
			-- The warning message as returned by the RDBMS after the last action.
		local
			l_s: POSTGRESQL_SQL_STRING
		do
			create l_s.make_by_pointer (get_warn_message)
			Result := l_s.string
		end

	new_descriptor: INTEGER
			-- Create a new descriptor under which queries can and will be executed
		local
			l_descriptor_index: INTEGER
		do
			from
				Result := 0
				l_descriptor_index := 1
			until
				Result > 0 or else l_descriptor_index > max_descriptor_number
			loop
				if descriptors.item (l_descriptor_index) = Void then
					Result := l_descriptor_index
				else
					l_descriptor_index := l_descriptor_index + 1
				end
			end
		end

	init_order (no_descriptor: INTEGER; command: READABLE_STRING_GENERAL)
		do
			if no_descriptor > 0 and no_descriptor <= max_descriptor_number then
				descriptors.put (command, no_descriptor)
				prepared_stmt_names.put (Void, no_descriptor)
			else
				-- No descriptors available, set internal error
				internal_error_code := No_more_descriptor
				is_error_updated := False
			end
		end

	start_order (no_descriptor: INTEGER)
		local
			l_c_string: C_STRING
			l_db_result: POINTER
			l_args: detachable DB_PARA_POSTGRESQL
			l_status: INTEGER
		do
			if attached prepared_stmt_names.item (no_descriptor) as l_stmt_name then
				-- Execute prepared statement
				l_args := arguments.item (no_descriptor)
				if l_args /= Void and then l_args.parameter_count > 0 then
					create l_c_string.make (l_stmt_name)
					l_db_result := pq_exec_prepared (postgresql_pointer, l_c_string.item,
						l_args.parameter_count,
						l_args.param_values_pointer,
						l_args.param_lengths_pointer,
						l_args.param_formats_pointer)
				else
					create l_c_string.make (l_stmt_name)
					l_db_result := pq_exec_prepared (postgresql_pointer, l_c_string.item,
						0, default_pointer, default_pointer, default_pointer)
				end
			else
				-- Execute simple query
				if attached descriptors.item (no_descriptor) as l_descriptor then
					create l_c_string.make (utf32_to_utf8 (l_descriptor.as_string_32))
					l_db_result := pq_exec (postgresql_pointer, l_c_string.item)
				end
			end
			result_pointers.put (l_db_result, no_descriptor)
			row_indices.put (0, no_descriptor)
			last_result_pointer := l_db_result
			if l_db_result /= default_pointer then
				l_status := pq_result_status (l_db_result)
				if l_status = pgres_fatal_error or l_status = pgres_bad_response then
					internal_error_code := l_status
				else
					internal_error_code := 0
				end
			end
			is_error_updated := False
		end

	result_order (no_descriptor: INTEGER)
			-- Store results (PostgreSQL stores automatically)
		do
			-- PostgreSQL automatically stores results, nothing needed here
			is_error_updated := False
		end

	next_row (no_descriptor: INTEGER)
			-- Fetch the next row from the result set
		local
			l_result_pointer: POINTER
			l_row_index, l_total_rows: INTEGER
		do
			l_result_pointer := result_pointers.item (no_descriptor)
			if l_result_pointer /= default_pointer then
				l_row_index := row_indices.item (no_descriptor)
				l_total_rows := pq_ntuples (l_result_pointer)
				if l_row_index < l_total_rows then
					found := True
					row_indices.put (l_row_index + 1, no_descriptor)
				else
					found := False
				end
			else
				found := False
			end
		end

	terminate_order (no_descriptor: INTEGER)
		do
			if result_pointers.item (no_descriptor) = last_result_pointer then
				last_result_pointer := default_pointer
			end
			pq_clear (result_pointers.item (no_descriptor))
			result_pointers.put (default_pointer, no_descriptor)
			descriptors.put (Void, no_descriptor)
			prepared_stmt_names.put (Void, no_descriptor)
			row_indices.put (0, no_descriptor)
			is_error_updated := False
			is_warning_updated := False
		end

	close_cursor (no_descriptor: INTEGER)
			-- Close cursor (no-op for PostgreSQL)
		do
		end

	exec_immediate (no_descriptor: INTEGER; command: READABLE_STRING_GENERAL)
		do
		end

	put_col_name (no_descriptor: INTEGER; index: INTEGER; ar: STRING; max_len: INTEGER): INTEGER
			-- Put the column name of field `index' into `ar'
		local
			l_area: MANAGED_POINTER
			i: INTEGER
		do
			l_area := string_buffer
			l_area.resize (max_len)
			Result := pq_column_name (result_pointers.item (no_descriptor), index - 1, l_area.item, max_len)
			check
				Result <= max_len
			end
			ar.set_count (Result)
			from
				i := 1
			until
				i > Result
			loop
				ar.put (l_area.read_integer_8 (i - 1).to_character_8, i)
				i := i + 1
			end
		end

	put_data (no_descriptor: INTEGER; index: INTEGER; ar: STRING; max_len: INTEGER): INTEGER
			-- Put the data of field `index' into `ar'
		local
			l_area: MANAGED_POINTER
			l_length: INTEGER
			i: INTEGER
			l_row_index: INTEGER
		do
			l_area := string_buffer
			l_row_index := row_indices.item (no_descriptor) - 1
			l_length := pq_data_length (result_pointers.item (no_descriptor), l_row_index, index - 1)
			if l_length >= l_area.count then
				l_area.resize (l_length + 1)
			end
			Result := pq_column_data (result_pointers.item (no_descriptor), l_row_index, index - 1, l_area.item, l_length + 1)
			ar.set_count (Result)
			from
				i := 1
			until
				i > Result
			loop
				ar.put (l_area.read_integer_8 (i - 1).to_character_8, i)
				i := i + 1
			end
		end

	put_data_32 (no_descriptor: INTEGER; index: INTEGER; ar: STRING_32; max_len: INTEGER): INTEGER
			-- Put the data of field `index' into `ar' as UTF-32
		local
			l_area: MANAGED_POINTER
			l_length: INTEGER
			i: INTEGER
			l_str: STRING
			l_str32: STRING_32
			l_row_index: INTEGER
		do
			l_area := string_buffer
			l_row_index := row_indices.item (no_descriptor) - 1
			l_length := pq_data_length (result_pointers.item (no_descriptor), l_row_index, index - 1)
			if l_length >= l_area.count then
				l_area.resize (l_length + 1)
			end
			Result := pq_column_data (result_pointers.item (no_descriptor), l_row_index, index - 1, l_area.item, l_length + 1)

			create l_str.make (Result)
			l_str.set_count (Result)
			from
				i := 1
			until
				i > Result
			loop
				l_str.put (l_area.read_integer_8 (i - 1).to_character_8, i)
				i := i + 1
			end
			l_str32 := utf8_to_utf32 (l_str)
			ar.wipe_out
			ar.append (l_str32)
			Result := l_str32.count
		end

	conv_type (indicator: INTEGER; index: INTEGER): INTEGER
		do
			Result := index
		end

	get_count (no_descriptor: INTEGER): INTEGER
			-- The number of columns in a result
		do
			Result := pq_nfields (result_pointers.item (no_descriptor))
		end

	get_data_len (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- The length of the data in field `ind'
		local
			l_row_index: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			Result := pq_data_length (result_pointers.item (no_descriptor), l_row_index, ind - 1)
		end

	get_col_len (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- The length of column `ind' as defined by table definition
		do
			-- PostgreSQL doesn't expose this directly via libpq result
			-- Return a reasonable default
			Result := 255
		end

	get_col_type (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- The column type of column `ind'
		do
			Result := pq_column_type (result_pointers.item (no_descriptor), ind - 1)
		end

	get_integer_data (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- Get the integer for field `ind'
		local
			l_row_index: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			Result := pq_integer_data (result_pointers.item (no_descriptor), l_row_index, ind - 1)
		end

	get_integer_16_data (no_descriptor: INTEGER; ind: INTEGER): INTEGER_16
			-- Get the 16-bit integer for field `ind'
		local
			l_row_index: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			Result := pq_integer_16_data (result_pointers.item (no_descriptor), l_row_index, ind - 1)
		end

	get_integer_64_data (no_descriptor: INTEGER; ind: INTEGER): INTEGER_64
			-- Get the 64-bit integer for field `ind'
		local
			l_row_index: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			Result := pq_integer_64_data (result_pointers.item (no_descriptor), l_row_index, ind - 1).as_integer_64
		end

	get_float_data (no_descriptor: INTEGER; ind: INTEGER): DOUBLE
			-- Get the float for field `ind'
		local
			l_row_index: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			Result := pq_float_data (result_pointers.item (no_descriptor), l_row_index, ind - 1)
		end

	get_real_data (no_descriptor: INTEGER; ind: INTEGER): REAL
			-- Get the real for field `ind'
		local
			l_row_index: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			Result := pq_real_data (result_pointers.item (no_descriptor), l_row_index, ind - 1)
		end

	get_boolean_data (no_descriptor: INTEGER; ind: INTEGER): BOOLEAN
			-- Get the boolean for field `ind'
		local
			l_row_index: INTEGER
			l_str: STRING
			l_area: MANAGED_POINTER
			l_length: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			l_area := string_buffer
			l_length := pq_data_length (result_pointers.item (no_descriptor), l_row_index, ind - 1)
			if l_length > 0 then
				if l_length >= l_area.count then
					l_area.resize (l_length + 1)
				end
				l_length := pq_column_data (result_pointers.item (no_descriptor), l_row_index, ind - 1, l_area.item, l_length + 1)
				create l_str.make (l_length)
				l_str.set_count (l_length)
				if l_length > 0 then
					l_str.put (l_area.read_integer_8 (0).to_character_8, 1)
				end
				Result := l_str.is_equal ("t") or else l_str.is_equal ("1") or else l_str.is_case_insensitive_equal ("true")
			end
		end

	get_date_data (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- Get date data for field `ind' (Return 1 on success)
		local
			l_row_index: INTEGER
			l_length: INTEGER
			l_area: MANAGED_POINTER
			i, l_res: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			l_area := date_buffer
			l_length := pq_data_length (result_pointers.item (no_descriptor), l_row_index, ind - 1)
			if l_length > 0 then
				if l_length >= l_area.count then
					l_area.resize (l_length + 1)
				end
				l_res := pq_column_data (result_pointers.item (no_descriptor), l_row_index, ind - 1, l_area.item, l_length + 1)
				if l_res > 0 then
					Result := 1
					last_date_data_descriptor := no_descriptor
					last_date_data_ind := ind
					last_date_data.wipe_out
					from
						i := 1
					until
						i > l_res
					loop
						last_date_data.append_character (l_area.read_integer_8 (i - 1).to_character_8)
						i := i + 1
					end
				end
			end
		end



	is_null_data (no_descriptor: INTEGER; ind: INTEGER): BOOLEAN
			-- Is the data at field `ind' NULL?
		local
			l_row_index: INTEGER
		do
			l_row_index := row_indices.item (no_descriptor) - 1
			Result := pq_is_null_data (result_pointers.item (no_descriptor), l_row_index, ind - 1) = 1
		end

	get_hour (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- Return the integer hour for the date from row set `no_descriptor' and field `ind'
		do
			if
				no_descriptor = last_date_data_descriptor and
				ind = last_date_data_ind and
				last_date_data.count >= 13
			then
				Result := last_date_data.substring (12, 13).to_integer
			end
		end

	get_sec (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- Return the integer second for the date from row set `no_descriptor' and field `ind'
		do
			if
				no_descriptor = last_date_data_descriptor and
				ind = last_date_data_ind and
				last_date_data.count >= 19
			then
				Result := last_date_data.substring (18, 19).to_integer
			end
		end

	get_min (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- Return the integer minute for the date from row set `no_descriptor' and field `ind'
		do
			if
				no_descriptor = last_date_data_descriptor and
				ind = last_date_data_ind and
				last_date_data.count >= 16
			then
				Result := last_date_data.substring (15, 16).to_integer
			end
		end

	get_year (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- Return the integer year for the date from row set `no_descriptor' and field `ind'
		do
			if
				no_descriptor = last_date_data_descriptor and
				ind = last_date_data_ind and
				last_date_data.count >= 4
			then
				Result := last_date_data.substring (1, 4).to_integer
			end
		end

	get_day (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- Return the integer day for the date from row set `no_descriptor' and field `ind'
		do
			if
				no_descriptor = last_date_data_descriptor and
				ind = last_date_data_ind and
				last_date_data.count >= 10
			then
				Result := last_date_data.substring (9, 10).to_integer
				if Result = 0 then
					Result := 1
				end
			end
		end

	get_month (no_descriptor: INTEGER; ind: INTEGER): INTEGER
			-- Return the integer month for the date from row set `no_descriptor' and field `ind'
		do
			if
				no_descriptor = last_date_data_descriptor and
				ind = last_date_data_ind and
				last_date_data.count >= 7
			then
				Result := last_date_data.substring (6, 7).to_integer
				if Result = 0 then
					Result := 1
				end
			end
		end

	get_decimal (no_descriptor: INTEGER; ind: INTEGER): detachable TUPLE [digits: STRING_8; sign, precision, scale: INTEGER]
			-- Function used to get decimal info
		local
			l_area: MANAGED_POINTER
			l_length: INTEGER
			l_row_index: INTEGER
			l_str: STRING
			i: INTEGER
			l_sign, l_scale, l_pt: INTEGER
		do
			if is_null_data (no_descriptor, ind) then
				Result := Void
			else
				l_row_index := row_indices.item (no_descriptor) - 1
				l_area := string_buffer
				l_length := pq_data_length (result_pointers.item (no_descriptor), l_row_index, ind - 1)
				if l_length > 0 then
					if l_length >= l_area.count then
						l_area.resize (l_length + 1)
					end
					l_length := pq_column_data (result_pointers.item (no_descriptor), l_row_index, ind - 1, l_area.item, l_length + 1)
					create l_str.make (l_length)
					l_str.set_count (l_length)
					from
						i := 1
					until
						i > l_length
					loop
						l_str.put (l_area.read_integer_8 (i - 1).to_character_8, i)
						i := i + 1
					end

					l_str.left_adjust
					l_str.right_adjust
					if l_str.starts_with ("-") then
						l_sign := 0
						l_str.remove_head (1)
					else
						l_sign := 1
					end
					l_pt := l_str.index_of ('.', 1)
					if l_pt = 0 then
						l_scale := 0
					else
						l_scale := l_str.count - l_pt
						l_str.remove (l_pt)
					end
					Result := [l_str, l_sign, l_str.count, l_scale]
				end
			end
		end

	database_make (i: INTEGER)
		do
		end

	connect (user_name, user_passwd, data_source, application, hostname, role_id: STRING; role_passwd: detachable STRING; group_id: STRING)
			-- Connect to PostgreSQL database
		local
			l_c_user, l_c_passwd, l_c_host, l_c_db: C_STRING
			l_port: INTEGER
		do
			create l_c_user.make (user_name)
			create l_c_passwd.make (user_passwd)
			if hostname /= Void and then not hostname.is_empty then
				create l_c_host.make (hostname)
			else
				create l_c_host.make ("localhost")
			end
			create l_c_db.make (data_source)
			l_port := 5432 -- Default PostgreSQL port
			postgresql_pointer := pq_connect (l_c_user.item, l_c_passwd.item, l_c_host.item, l_port, l_c_db.item)
			is_error_updated := False
		end

	connect_by_connection_string (a_connection_string: STRING)
			-- Connect using a PostgreSQL connection string
			-- Format: "host=hostname port=5432 dbname=database user=username password=pass"
			-- See: https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING
		local
			l_c_string: C_STRING
		do
			create l_c_string.make (a_connection_string)
			postgresql_pointer := pq_connect_string (l_c_string.item)
			is_error_updated := False
		ensure then
			connected: postgresql_pointer /= default_pointer implies is_connected
		end

	is_connected: BOOLEAN
			-- Is database connected?
		do
			Result := postgresql_pointer /= default_pointer and then
					  pq_status (postgresql_pointer) = connection_ok
		end

	disconnect
			-- Disconnect from PostgreSQL database
		do
			pq_disconnect (postgresql_pointer)
			postgresql_pointer := default_pointer
		end

	commit
			-- Commit current transaction
		local
			l_res: INTEGER
		do
			l_res := pq_commit (postgresql_pointer)
			is_error_updated := False
		end

	rollback
			-- Rollback current transaction
		local
			l_res: INTEGER
		do
			l_res := pq_rollback (postgresql_pointer)
			is_error_updated := False
		end

	trancount: INTEGER
			-- Transaction count (not directly supported in PostgreSQL)
		do
			Result := 0
		end

	begin
			-- Begin a new transaction
		local
			l_res: INTEGER
		do
			l_res := pq_begin (postgresql_pointer)
			is_error_updated := False
		end

feature {NONE} -- Implementation

	postgresql_pointer: POINTER
			-- Pointer to PGconn structure

	last_result_pointer: POINTER
			-- Last result pointer for affected row count

	descriptors: ARRAY [detachable READABLE_STRING_GENERAL]
			-- Descriptor list

	result_pointers: ARRAY [POINTER]
			-- Result set pointers

	arguments: ARRAY [detachable DB_PARA_POSTGRESQL]
			-- Arguments for prepared statements

	row_indices: ARRAY [INTEGER]
			-- Current row index for each descriptor

	prepared_stmt_names: ARRAY [detachable STRING]
			-- Prepared statement names

	last_descriptor: INTEGER
			-- Last used descriptor

	stmt_counter: INTEGER
			-- Counter for generating unique statement names

	last_date_data: STRING
			-- Last date data retrieved

	last_date_data_descriptor: INTEGER
			-- Descriptor used to retrieve `last_date_data'

	last_date_data_ind: INTEGER
			-- Column index used to retrieve `last_date_data'

	date_buffer: MANAGED_POINTER
			-- Buffer for date data

	string_buffer: MANAGED_POINTER
			-- Buffer for string data

	repository_name: detachable STRING
			-- Current repository name

	internal_error_code: INTEGER
			-- Internal error code for EiffelStore-level errors (e.g., no more descriptors)

	date_length: INTEGER = 32
			-- Maximum length of date string

	convert_parameters (sql: READABLE_STRING_GENERAL; ht_order: detachable ARRAYED_LIST [READABLE_STRING_GENERAL]): STRING
			-- Convert parameter syntax from :name to $1, $2, etc.
		local
			l_param_index: INTEGER
			l_result: STRING_32
			l_sql32: STRING_32
			i: INTEGER
			c: CHARACTER_32
		do
			l_sql32 := sql.as_string_32
			create l_result.make (l_sql32.count)
			l_param_index := 0
			from
				i := 1
			until
				i > l_sql32.count
			loop
				c := l_sql32.item (i)
				if c = ':' and then i < l_sql32.count and then l_sql32.item (i + 1).is_alpha then
					-- Start of parameter
					l_param_index := l_param_index + 1
					l_result.append_character ('$')
					l_result.append (l_param_index.out)
					-- Skip parameter name
					from
						i := i + 1
					until
						i > l_sql32.count or else not (l_sql32.item (i).is_alpha_numeric or else l_sql32.item (i) = '_')
					loop
						i := i + 1
					end
				else
					l_result.append_character (c)
					i := i + 1
				end
			end
			Result := l_result.to_string_8
		end

	escaped_sql_string (a_string: READABLE_STRING_GENERAL): STRING_32
			-- Escape special characters in SQL string
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count * 2)
			from
				i := 1
			until
				i > a_string.count
			loop
				c := a_string.item (i)
				if c = '%'' then
					Result.append_character ('%'')
					Result.append_character ('%'')
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

note
	copyright: "Copyright (c) 1984-2025, Eiffel Software and others"
	license: "The specified license contains syntax errors!"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
