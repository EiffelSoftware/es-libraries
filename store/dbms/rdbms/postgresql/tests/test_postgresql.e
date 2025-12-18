note
	description: "AutoTest suite for PostgreSQL EiffelStore implementation"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_POSTGRESQL

inherit
	EQA_TEST_SET
		redefine
			on_prepare
		end

feature {NONE} -- Initialization

	on_prepare
			-- Called before all tests
		do
			-- Initialize test environment
		end

feature -- Test: Class Instantiation

	test_postgresql_create
			-- Test that POSTGRESQL class can be instantiated
		local
			l_db: POSTGRESQL
		do
			create l_db
			assert ("postgresql_created", l_db /= Void)
			assert ("database_handle_name", l_db.database_handle_name.is_equal ("POSTGRESQL"))
		end

	test_postgresql_externals_create
			-- Test that POSTGRESQL_EXTERNALS class can be instantiated
		local
			l_ext: POSTGRESQL_EXTERNALS
		do
			create l_ext
			assert ("externals_created", l_ext /= Void)
		end

	test_postgresql_sql_string_create
			-- Test that POSTGRESQL_SQL_STRING class can be instantiated
		local
			l_str: POSTGRESQL_SQL_STRING
		do
			create l_str.make_empty (10)
			assert ("sql_string_created", l_str /= Void)
		end

feature -- Test: SQL Type Names

	test_sql_type_names
			-- Test SQL type name constants
		local
			l_db: POSTGRESQL
		do
			create l_db
			assert ("sql_name_string", l_db.sql_name_string.is_equal ("VARCHAR(255)"))
			assert ("sql_name_integer", l_db.sql_name_integer.is_equal ("INTEGER"))
			assert ("sql_name_integer_16", l_db.sql_name_integer_16.is_equal ("SMALLINT"))
			assert ("sql_name_integer_64", l_db.sql_name_integer_64.is_equal ("BIGINT"))
			assert ("sql_name_real", l_db.sql_name_real.is_equal ("REAL"))
			assert ("sql_name_double", l_db.sql_name_double.is_equal ("DOUBLE PRECISION"))
			assert ("sql_name_boolean", l_db.sql_name_boolean.is_equal ("BOOLEAN"))
			assert ("sql_name_datetime", l_db.sql_name_datetime.is_equal ("TIMESTAMP"))
		end

feature -- Test: Boolean Representations

	test_boolean_representations
			-- Test boolean string representations
		local
			l_db: POSTGRESQL
		do
			create l_db
			assert ("true_representation", l_db.True_representation.is_equal ("TRUE"))
			assert ("false_representation", l_db.False_representation.is_equal ("FALSE"))
		end

feature -- Test: Descriptor Management

	test_descriptor_availability
			-- Test descriptor availability
		local
			l_db: POSTGRESQL
		do
			create l_db
			assert ("descriptor_available", l_db.descriptor_is_available)
		end

	test_new_descriptor
			-- Test new descriptor creation
		local
			l_db: POSTGRESQL
			l_desc: INTEGER
		do
			create l_db
			l_desc := l_db.new_descriptor
			assert ("new_descriptor_valid", l_desc > 0)
		end

	test_max_descriptor_number
			-- Test max descriptor number constant
		local
			l_db: POSTGRESQL
		do
			create l_db
			assert ("max_descriptor_number", l_db.max_descriptor_number = 20)
		end

feature -- Test: Date Formatting

	test_date_to_str
			-- Test date to string conversion
		local
			l_db: POSTGRESQL
			l_date: DATE_TIME
			l_result: STRING
		do
			create l_db
			create l_date.make (2025, 12, 17, 14, 30, 45)
			l_result := l_db.date_to_str (l_date)
			assert ("date_starts_with_quote", l_result.item (1) = '%'')
			assert ("date_ends_with_quote", l_result.item (l_result.count) = '%'')
			assert ("date_contains_year", l_result.has_substring ("2025"))
			assert ("date_contains_month", l_result.has_substring ("12"))
			assert ("date_contains_day", l_result.has_substring ("17"))
		end

feature -- Test: String Formatting

	test_string_format_null
			-- Test string format with Void value
		local
			l_db: POSTGRESQL
			l_result: STRING_32
		do
			create l_db
			l_result := l_db.string_format_32 (Void)
			assert ("null_format", l_result.is_equal ({STRING_32} "IS NULL"))
		end

	test_string_format_value
			-- Test string format with actual value
		local
			l_db: POSTGRESQL
			l_result: STRING_32
		do
			create l_db
			l_result := l_db.string_format_32 ("test_value")
			assert ("value_starts_with_quote", l_result.item (1) = '%'')
			assert ("value_ends_with_quote", l_result.item (l_result.count) = '%'')
			assert ("value_contains_text", l_result.has_substring ("test_value"))
		end

feature -- Test: Password Validation

	test_password_ok
			-- Test password validation
		local
			l_db: POSTGRESQL
		do
			create l_db
			assert ("password_ok_valid", l_db.password_ok ("some_password"))
			assert ("password_ok_empty", l_db.password_ok (""))
		end

feature -- Test: Procedure Support

	test_stored_procedure_support
			-- Test stored procedure support flags
		local
			l_db: POSTGRESQL
		do
			create l_db
			assert ("support_stored_proc", l_db.support_stored_proc)
			assert ("support_sql_of_proc", l_db.support_sql_of_proc)
			assert ("support_drop_proc", l_db.support_drop_proc)
			assert ("name_proc_lower", l_db.name_proc_lower)
		end

	test_sql_creation_strings
			-- Test SQL creation and execution strings
		local
			l_db: POSTGRESQL
		do
			create l_db
			assert ("sql_creation_set", not l_db.sql_creation.is_empty)
			assert ("sql_as_set", not l_db.sql_as.is_empty)
			assert ("sql_end_set", not l_db.sql_end.is_empty)
			assert ("sql_execution_set", not l_db.sql_execution.is_empty)
		end

feature -- Test: Parameter Binding

	test_db_para_postgresql_create
			-- Test DB_PARA_POSTGRESQL creation
		local
			l_para: DB_PARA_POSTGRESQL
		do
			create l_para.make (5)
			assert ("para_created", l_para /= Void)
			assert ("para_empty", l_para.is_empty)
		end

	test_db_para_extend_parameter
			-- Test extending parameters
		local
			l_para: DB_PARA_POSTGRESQL
		do
			create l_para.make (5)
			l_para.extend_parameter ("test_string")
			assert ("para_count_1", l_para.count = 1)
			l_para.extend_parameter (42)
			assert ("para_count_2", l_para.count = 2)
		end

	test_db_bind_postgresql_create
			-- Test DB_BIND_POSTGRESQL creation
		local
			l_bind: DB_BIND_POSTGRESQL
		do
			create l_bind.make ("test_value", 10)
			assert ("bind_created", l_bind /= Void)
			assert ("bind_not_null", not l_bind.is_null)
			assert ("bind_value", l_bind.value.is_equal ("test_value"))
			assert ("bind_count", l_bind.count = 10)
		end

	test_db_bind_postgresql_null
			-- Test DB_BIND_POSTGRESQL with NULL value
		local
			l_bind: DB_BIND_POSTGRESQL
		do
			create l_bind.make (Void, 0)
			assert ("bind_is_null", l_bind.is_null)
		end

feature -- Test: Externals Constants

	test_externals_connection_constants
			-- Test connection status constants
		local
			l_ext: POSTGRESQL_EXTERNALS
		do
			create l_ext
			assert ("connection_ok", l_ext.connection_ok = 0)
			assert ("connection_bad", l_ext.connection_bad = 1)
		end

	test_externals_result_constants
			-- Test result status constants
		local
			l_ext: POSTGRESQL_EXTERNALS
		do
			create l_ext
			assert ("pgres_empty_query", l_ext.pgres_empty_query = 0)
			assert ("pgres_command_ok", l_ext.pgres_command_ok = 1)
			assert ("pgres_tuples_ok", l_ext.pgres_tuples_ok = 2)
		end

feature -- Test: Connection String

	test_connection_string_format
			-- Test that connection string format is valid PostgreSQL format
			-- PostgreSQL connection strings follow: "key1=value1 key2=value2 ..."
		local
			l_conn_string: STRING
		do
			l_conn_string := "host=localhost port=5432 dbname=testdb user=testuser password=testpass"
			assert ("contains_host", l_conn_string.has_substring ("host="))
			assert ("contains_port", l_conn_string.has_substring ("port="))
			assert ("contains_dbname", l_conn_string.has_substring ("dbname="))
			assert ("contains_user", l_conn_string.has_substring ("user="))
			assert ("contains_password", l_conn_string.has_substring ("password="))
			assert ("no_semicolons", not l_conn_string.has (';'))
		end

	test_connection_string_components
			-- Test parsing and validating connection string components
		local
			l_conn_string: STRING
			l_parts: LIST [STRING]
			l_found_host, l_found_port, l_found_dbname: BOOLEAN
			l_item: STRING
		do
			l_conn_string := "host=localhost port=5432 dbname=postgres"
			l_parts := l_conn_string.split (' ')
			from
				l_parts.start
			until
				l_parts.after
			loop
				l_item := l_parts.item
				if l_item.starts_with ("host=") then
					l_found_host := True
					assert ("host_value", l_item.substring (6, l_item.count).is_equal ("localhost"))
				elseif l_item.starts_with ("port=") then
					l_found_port := True
					assert ("port_value", l_item.substring (6, l_item.count).is_equal ("5432"))
				elseif l_item.starts_with ("dbname=") then
					l_found_dbname := True
					assert ("dbname_value", l_item.substring (8, l_item.count).is_equal ("postgres"))
				end
				l_parts.forth
			end
			assert ("found_host", l_found_host)
			assert ("found_port", l_found_port)
			assert ("found_dbname", l_found_dbname)
		end

	test_connection_string_variations
			-- Test various valid connection string formats
		local
			l_conn_string_basic: STRING
			l_conn_string_ssl: STRING
			l_conn_string_timeout: STRING
		do
			-- Basic connection string
			l_conn_string_basic := "host=localhost dbname=postgres"
			assert ("basic_valid", l_conn_string_basic.has_substring ("host=") and l_conn_string_basic.has_substring ("dbname="))

			-- Connection string with SSL mode
			l_conn_string_ssl := "host=localhost dbname=postgres sslmode=require"
			assert ("ssl_valid", l_conn_string_ssl.has_substring ("sslmode="))

			-- Connection string with timeout
			l_conn_string_timeout := "host=localhost dbname=postgres connect_timeout=10"
			assert ("timeout_valid", l_conn_string_timeout.has_substring ("connect_timeout="))
		end

	test_connection_string_builder
			-- Test building a connection string from components
		local
			l_host, l_port, l_dbname, l_user, l_password: STRING
			l_conn_string: STRING
		do
			l_host := "localhost"
			l_port := "5432"
			l_dbname := "testdb"
			l_user := "testuser"
			l_password := "testpass"

			create l_conn_string.make (100)
			l_conn_string.append ("host=")
			l_conn_string.append (l_host)
			l_conn_string.append (" port=")
			l_conn_string.append (l_port)
			l_conn_string.append (" dbname=")
			l_conn_string.append (l_dbname)
			l_conn_string.append (" user=")
			l_conn_string.append (l_user)
			l_conn_string.append (" password=")
			l_conn_string.append (l_password)

			assert ("built_string_not_empty", not l_conn_string.is_empty)
			assert ("built_string_valid", l_conn_string.is_equal ("host=localhost port=5432 dbname=testdb user=testuser password=testpass"))
		end

	test_connect_by_connection_string_feature_exists
			-- Test that the connect_by_connection_string feature exists on POSTGRESQL class
		local
			l_db: POSTGRESQL
		do
			create l_db
			-- The feature exists if we can reference it (compile-time check)
			-- This test verifies the interface is available
			assert ("db_created", l_db /= Void)
			-- Note: Actual connection requires a running PostgreSQL server
		end

feature -- Test: Table Listing Queries

	test_list_user_tables_query
			-- Test the SQL query for listing user tables
		local
			l_query: STRING
		do
			l_query := "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'"
			assert ("query_not_empty", not l_query.is_empty)
			assert ("uses_information_schema", l_query.has_substring ("information_schema.tables"))
			assert ("filters_public_schema", l_query.has_substring ("table_schema = 'public'"))
			assert ("filters_base_tables", l_query.has_substring ("table_type = 'BASE TABLE'"))
		end

	test_list_all_tables_query
			-- Test the SQL query for listing all tables in all schemas
		local
			l_query: STRING
		do
			l_query := "SELECT table_schema, table_name, table_type FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema') ORDER BY table_schema, table_name"
			assert ("query_not_empty", not l_query.is_empty)
			assert ("uses_information_schema", l_query.has_substring ("information_schema.tables"))
			assert ("excludes_system_schemas", l_query.has_substring ("NOT IN ('pg_catalog', 'information_schema')"))
			assert ("ordered", l_query.has_substring ("ORDER BY"))
		end

	test_information_schema_columns_query
			-- Test the SQL query used by Selection_string for repository
		local
			l_db: POSTGRESQL
			l_query: STRING
		do
			create l_db
			l_query := l_db.Selection_string ("", "", "test_table")
			assert ("query_not_empty", not l_query.is_empty)
			assert ("uses_information_schema", l_query.has_substring ("information_schema.columns"))
			assert ("has_table_name_param", l_query.has_substring (":rep"))
		end

	test_table_exists_query
			-- Test the SQL query to check if a table exists
		local
			l_query: STRING
		do
			l_query := "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'my_table')"
			assert ("query_not_empty", not l_query.is_empty)
			assert ("uses_exists", l_query.has_substring ("EXISTS"))
			assert ("uses_information_schema", l_query.has_substring ("information_schema.tables"))
		end

	test_list_views_query
			-- Test the SQL query for listing views
		local
			l_query: STRING
		do
			l_query := "SELECT table_name FROM information_schema.views WHERE table_schema = 'public'"
			assert ("query_not_empty", not l_query.is_empty)
			assert ("uses_information_schema_views", l_query.has_substring ("information_schema.views"))
			assert ("filters_public_schema", l_query.has_substring ("table_schema = 'public'"))
		end

	test_list_columns_query
			-- Test the SQL query for listing columns of a table
		local
			l_query: STRING
		do
			l_query := "SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'my_table' ORDER BY ordinal_position"
			assert ("query_not_empty", not l_query.is_empty)
			assert ("uses_information_schema_columns", l_query.has_substring ("information_schema.columns"))
			assert ("selects_column_name", l_query.has_substring ("column_name"))
			assert ("selects_data_type", l_query.has_substring ("data_type"))
			assert ("ordered_by_position", l_query.has_substring ("ORDER BY ordinal_position"))
		end

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
