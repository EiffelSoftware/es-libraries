note
	description: "Summary description for {CMS_STORAGE_STORE_ODBC}."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_STORAGE_STORE_ODBC

inherit
	CMS_STORAGE_STORE_SQL
		redefine
			make
		end

	CMS_CORE_STORAGE_SQL_I

	CMS_USER_STORAGE_SQL_I

	REFACTORING_HELPER

create
	make,
	make_with_driver

feature {NONE} -- Initialization

	make (a_connection: DATABASE_CONNECTION)
			-- <Precursor>
		do
			create odbc_driver.make_from_string_general ("odbc")
			create driver.make_from_string ("odbc")

			Precursor (a_connection)
		end

	make_with_driver (a_connection: DATABASE_CONNECTION; a_driver: detachable READABLE_STRING_GENERAL)
		require
			is_connected: a_connection.is_connected
		do
			make (a_connection)
			if a_driver /= Void then
				create odbc_driver.make_from_string_general (a_driver)
				if a_driver.is_valid_as_string_8 then
					create driver.make_from_string (a_driver.to_string_8)
				end
			end
		end

feature -- Status report

	driver: IMMUTABLE_STRING_8

	odbc_driver: IMMUTABLE_STRING_32
			-- Database's driver name.
			--  sqlite, mysql, ...

	is_initialized: BOOLEAN
			-- Is storage initialized?
		do
			Result := table_count > 0
		end

	table_count: INTEGER
			-- Column of tables.
		local
			sql: STRING_8
		do
			sql := "SELECT COUNT(*) AS table_count FROM INFORMATION_SCHEMA.TABLES;"
			sql_query (sql, Void)
			if not has_error and then not sql_after then
				Result := sql_read_integer_32 (1).to_integer_32
				sql_forth
				check one_row: sql_after end
			end
			sql_finalize_query (sql)
		end

	table_column_count (a_table_name: READABLE_STRING_8): INTEGER
			-- Column count for table `a_table_name`
		local
			sql: STRING_8
			l_parameters: STRING_TABLE [detachable ANY]
		do
			create l_parameters.make (1)
			sql := "SELECT COUNT(*) as column_count FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :table_name ;"
			l_parameters.put (a_table_name, "table_name")
			sql_query (sql, l_parameters)
			if not has_error and then not sql_after then
				Result := sql_read_integer_32 (1).to_integer_32
				sql_forth
				check one_row: sql_after end
			end
			sql_finalize_query (sql)
		end

feature -- Conversion

	sql_statement (a_statement: STRING): STRING
			-- <Precursor>.
		local
			i: INTEGER
		do
			Result := a_statement
			if odbc_driver.same_caseless_characters_general ("sqlite3", 1, 5, 1) then
				from
					i := 1
				until
					i = 0
				loop
					i := a_statement.substring_index ("AUTO_INCREMENT", i)
					if i > 0 then
						if Result = a_statement then
							create Result.make_from_string (a_statement)
						end
						Result.remove (i + 4)
						i := i + 14
					end
				end
			end
		end

end
