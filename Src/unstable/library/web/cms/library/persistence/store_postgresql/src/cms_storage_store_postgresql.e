note
	description: "Summary description for {CMS_STORAGE_STORE_POSTGRESQL}."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_STORAGE_STORE_POSTGRESQL

inherit
	CMS_STORAGE_STORE_SQL

	CMS_CORE_STORAGE_SQL_I

	CMS_USER_STORAGE_SQL_I

	REFACTORING_HELPER

create
	make

feature -- Properties

	driver: IMMUTABLE_STRING_8 = "postgresql"

feature -- Status report

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
			sql := "SELECT COUNT(*) as column_count FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = :table_name ;"
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

	sql_statement (a_statement: READABLE_STRING_8): READABLE_STRING_8
			-- <Precursor>
		local
			-- sql: STRING_8
			conv: SQL_CONVERTER
		do
			-- create sql.make_from_string (a_statement)
			-- sql.replace_substring_all ("`" , "%"")
			-- sql.replace_substring_all ("INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL", "SERIAL PRIMARY KEY")
			-- sql.replace_substring_all ("DATETIME", "TIMESTAMP")
			-- Result := sql

			create conv
			Result := conv.convert_to_postgresql (a_statement)
		end

end
