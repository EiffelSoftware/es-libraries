note
	description: "PostgreSQL external C functions"
	date: "$Date$"
	revision: "$Revision$"

class
	POSTGRESQL_EXTERNALS

feature -- Connection Management

	pq_connect (a_user, a_password, a_host: POINTER; a_port: INTEGER; a_db: POINTER): POINTER
			-- PGconn *eif_pq_connect(const char *user, const char *pass, const char *host, int port, const char *dbname)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_connect((const char *)$a_user, (const char *)$a_password, (const char *)$a_host, $a_port, (const char *)$a_db)"
		end

	pq_connect_string (a_conninfo: POINTER): POINTER
			-- PGconn *eif_pq_connect_string(const char *conninfo)
			-- Connect using a PostgreSQL connection string
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_connect_string((const char *)$a_conninfo)"
		end

	pq_disconnect (a_conn: POINTER)
			-- void eif_pq_disconnect(PGconn *conn)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_disconnect((PGconn *)$a_conn)"
		end

	pq_status (a_conn: POINTER): INTEGER
			-- int eif_pq_status(PGconn *conn)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_status((PGconn *)$a_conn)"
		end

feature -- Query Execution

	pq_prepare (a_conn, a_stmt_name, a_query: POINTER; a_n_params: INTEGER): POINTER
			-- PGresult *eif_pq_prepare(PGconn *conn, const char *stmt_name, const char *query, int n_params)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_prepare((PGconn *)$a_conn, (const char *)$a_stmt_name, (const char *)$a_query, $a_n_params)"
		end

	pq_exec_prepared (a_conn, a_stmt_name: POINTER; a_n_params: INTEGER;
						a_param_values, a_param_lengths, a_param_formats: POINTER): POINTER
			-- PGresult *eif_pq_exec_prepared(PGconn *conn, const char *stmt_name, int n_params,
			--     const char * const *param_values, const int *param_lengths, const int *param_formats)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_exec_prepared((PGconn *)$a_conn, (const char *)$a_stmt_name, $a_n_params, (const char * const *)$a_param_values, (const int *)$a_param_lengths, (const int *)$a_param_formats)"
		end

	pq_exec (a_conn, a_command: POINTER): POINTER
			-- PGresult *eif_pq_exec(PGconn *conn, const char *command)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_exec((PGconn *)$a_conn, (const char *)$a_command)"
		end

	pq_clear (a_result: POINTER)
			-- void eif_pq_clear(PGresult *res)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_clear((PGresult *)$a_result)"
		end

feature -- Result Processing

	pq_result_status (a_result: POINTER): INTEGER
			-- int eif_pq_result_status(PGresult *res)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_result_status((PGresult *)$a_result)"
		end

	pq_cmd_tuples (a_result: POINTER): INTEGER
			-- int eif_pq_cmd_tuples(PGresult *res)
			-- Get number of rows affected by INSERT, UPDATE, DELETE, etc.
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_cmd_tuples((PGresult *)$a_result)"
		end

	pq_ntuples (a_result: POINTER): INTEGER
			-- int eif_pq_ntuples(PGresult *res)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_ntuples((PGresult *)$a_result)"
		end

	pq_nfields (a_result: POINTER): INTEGER
			-- int eif_pq_nfields(PGresult *res)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_nfields((PGresult *)$a_result)"
		end

	pq_column_name (a_result: POINTER; a_column: INTEGER; a_buffer: POINTER; a_buffer_size: INTEGER): INTEGER
			-- int eif_pq_column_name(PGresult *res, int column_number, char *buffer, int buffer_size)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_column_name((PGresult *)$a_result, $a_column, (char *)$a_buffer, $a_buffer_size)"
		end

	pq_column_type (a_result: POINTER; a_column: INTEGER): INTEGER
			-- int eif_pq_column_type(PGresult *res, int column_number)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_column_type((PGresult *)$a_result, $a_column)"
		end

	pq_column_data (a_result: POINTER; a_row, a_column: INTEGER; a_buffer: POINTER; a_buffer_size: INTEGER): INTEGER
			-- int eif_pq_column_data(PGresult *res, int row, int column, char *buffer, int buffer_size)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_column_data((PGresult *)$a_result, $a_row, $a_column, (char *)$a_buffer, $a_buffer_size)"
		end

	pq_is_null_data (a_result: POINTER; a_row, a_column: INTEGER): INTEGER
			-- int eif_pq_is_null_data(PGresult *res, int row, int column)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_is_null_data((PGresult *)$a_result, $a_row, $a_column)"
		end

	pq_data_length (a_result: POINTER; a_row, a_column: INTEGER): INTEGER
			-- int eif_pq_data_length(PGresult *res, int row, int column)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_data_length((PGresult *)$a_result, $a_row, $a_column)"
		end

feature -- Data Extraction

	pq_integer_data (a_result: POINTER; a_row, a_column: INTEGER): INTEGER
			-- long eif_pq_integer_data(PGresult *res, int row, int column)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_integer_data((PGresult *)$a_result, $a_row, $a_column)"
		end

	pq_integer_16_data (a_result: POINTER; a_row, a_column: INTEGER): INTEGER_16
			-- int eif_pq_integer_16_data(PGresult *res, int row, int column)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_integer_16_data((PGresult *)$a_result, $a_row, $a_column)"
		end

	pq_integer_64_data (a_result: POINTER; a_row, a_column: INTEGER): NATURAL_64
			-- EIF_NATURAL_64 eif_pq_integer_64_data(PGresult *res, int row, int column)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_integer_64_data((PGresult *)$a_result, $a_row, $a_column)"
		end

	pq_real_data (a_result: POINTER; a_row, a_column: INTEGER): REAL
			-- float eif_pq_real_data(PGresult *res, int row, int column)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_real_data((PGresult *)$a_result, $a_row, $a_column)"
		end

	pq_float_data (a_result: POINTER; a_row, a_column: INTEGER): DOUBLE
			-- double eif_pq_float_data(PGresult *res, int row, int column)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_float_data((PGresult *)$a_result, $a_row, $a_column)"
		end

feature -- Error Handling

	pq_get_error_message (a_conn: POINTER): POINTER
			-- char *eif_pq_get_error_message(PGconn *conn)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_get_error_message((PGconn *)$a_conn)"
		end

	pq_get_result_error (a_result: POINTER): POINTER
			-- char *eif_pq_get_result_error(PGresult *res)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_get_result_error((PGresult *)$a_result)"
		end

	pq_get_error_code (a_conn: POINTER): INTEGER
			-- int eif_pq_get_error_code(PGconn *conn)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_get_error_code((PGconn *)$a_conn)"
		end

feature -- Transaction Management

	pq_begin (a_conn: POINTER): INTEGER
			-- int eif_pq_begin(PGconn *conn)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_begin((PGconn *)$a_conn)"
		end

	pq_commit (a_conn: POINTER): INTEGER
			-- int eif_pq_commit(PGconn *conn)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_commit((PGconn *)$a_conn)"
		end

	pq_rollback (a_conn: POINTER): INTEGER
			-- int eif_pq_rollback(PGconn *conn)
		external
			"C inline use %"eif_postgresql.h%""
		alias
			"eif_pq_rollback((PGconn *)$a_conn)"
		end

feature -- PostgreSQL Status Constants

	connection_ok: INTEGER = 0
			-- CONNECTION_OK constant from libpq

	connection_bad: INTEGER = 1
			-- CONNECTION_BAD constant from libpq

	pgres_empty_query: INTEGER = 0
			-- PGRES_EMPTY_QUERY

	pgres_command_ok: INTEGER = 1
			-- PGRES_COMMAND_OK

	pgres_tuples_ok: INTEGER = 2
			-- PGRES_TUPLES_OK

	pgres_copy_out: INTEGER = 3
			-- PGRES_COPY_OUT

	pgres_copy_in: INTEGER = 4
			-- PGRES_COPY_IN

	pgres_bad_response: INTEGER = 5
			-- PGRES_BAD_RESPONSE

	pgres_nonfatal_error: INTEGER = 6
			-- PGRES_NONFATAL_ERROR

	pgres_fatal_error: INTEGER = 7
			-- PGRES_FATAL_ERROR

note
	copyright: "Copyright (c) 1984-2025, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
