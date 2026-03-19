note
	description: "Storage API for browsing internal SQL storage."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	STORAGE_API

inherit
	CMS_MODULE_API
		rename
			make as make_api
		redefine
			initialize
		end

	REFACTORING_HELPER

	SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialization

	make (a_module: STORAGE_MODULE; a_api: CMS_API)
		do
			module := a_module
			cms_api := a_api
			initialize
		end

	initialize
			-- <Precursor>
		do
			Precursor
		end

feature -- Access

	module: STORAGE_MODULE

feature -- SQL Storage Access

	sql_storage: detachable CMS_STORAGE_SQL_I
			-- Access to SQL storage if available.
		do
			if attached cms_api.storage.as_sql_storage as l_storage_sql then
				Result := l_storage_sql
			end
		end

feature -- Tables

	tables: detachable LIST [READABLE_STRING_8]
			-- List of all table names in the database.
		local
			l_storage: like sql_storage
			sql: STRING_8
			l_is_sqlite3: BOOLEAN
		do
			l_storage := sql_storage
			if l_storage /= Void then
				l_is_sqlite3 := l_storage.generator.ends_with ("SQLITE3")
				if l_is_sqlite3 then
						-- SQLite3
					sql := "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
				else
						-- MySQL/MariaDB
					sql := "SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE() ORDER BY table_name;"
				end
				Result := execute_query_for_string_list (sql, Void, 1)
			end
		end

	table_schema (a_table_name: READABLE_STRING_8): detachable LIST [TUPLE [name: STRING_8; type: STRING_8; nullable: BOOLEAN]]
			-- Schema information for table `a_table_name`.
			-- Returns list of column information tuples: [name, type, nullable].
		local
			l_storage: like sql_storage
			sql: STRING_8
			l_is_sqlite3: BOOLEAN
			l_parameters: STRING_TABLE [detachable ANY]
		do
			l_storage := sql_storage
			if l_storage /= Void then
				l_is_sqlite3 := l_storage.generator.ends_with ("SQLITE3")
				if l_is_sqlite3 then
						-- SQLite3
					sql := "PRAGMA table_info(" + a_table_name + ");"
				else
						-- MySQL/MariaDB
					sql := "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = :table_name ORDER BY ordinal_position;"
				end
				create l_parameters.make (1)
				if not l_is_sqlite3 then
					l_parameters.put (a_table_name, "table_name")
				end
				Result := execute_query_for_table_schema (sql, l_parameters, l_is_sqlite3)
			end
		end

feature -- Query Execution

	execute_query (a_query: READABLE_STRING_8; a_parameters: detachable STRING_TABLE [detachable ANY]; a_limit: INTEGER): detachable LIST [STRING_TABLE [detachable ANY]]
			-- Execute SQL query `a_query` with optional parameters `a_parameters`.
			-- Returns list of rows, each row is a STRING_TABLE mapping column names to values.
			-- Limited to `a_limit` rows (0 = no limit).
		local
			l_storage: like sql_storage
		do
			l_storage := sql_storage
			if l_storage /= Void then
				Result := execute_query_internal (a_query, a_parameters, a_limit, l_storage)
			end
		end

feature {NONE} -- Query Execution

	execute_query_for_string_list (a_query: READABLE_STRING_8; a_parameters: detachable STRING_TABLE [detachable ANY]; a_column_index: INTEGER): detachable ARRAYED_LIST [STRING_8]
		local
			l_storage: like sql_storage
			l_rows: like execute_query
			l_row: STRING_TABLE [detachable ANY]
		do
			l_storage := sql_storage
			if l_storage /= Void then
				l_rows := execute_query_internal (a_query, a_parameters, 0, l_storage)
				if l_rows /= Void then
					create Result.make (l_rows.count)
					across
						l_rows as r
					loop
						l_row := r
						across
							l_row as l_item
						loop
							if attached {READABLE_STRING_GENERAL} l_item as s then
								Result.force (s.to_string_8)
							end
						end
--						if attached l_row.item (a_column_index.out) as val then
--							if attached {READABLE_STRING_GENERAL} val as s then
--								Result.force (s.to_string_8)
--							end
--						end
					end
				end
			end
		end

	execute_query_for_table_schema (a_query: READABLE_STRING_8; a_parameters: detachable STRING_TABLE [detachable ANY]; a_is_sqlite3: BOOLEAN): detachable ARRAYED_LIST [TUPLE [name: STRING_8; type: STRING_8; nullable: BOOLEAN]]
		local
			l_storage: like sql_storage
			l_rows: like execute_query
			l_row: STRING_TABLE [detachable ANY]
			l_name, l_type: STRING_8
			l_nullable: BOOLEAN
		do
			l_storage := sql_storage
			if l_storage /= Void then
				l_rows := execute_query_internal (a_query, a_parameters, 0, l_storage)
				if l_rows /= Void then
					create Result.make (l_rows.count)
					across
						l_rows as r
					loop
						l_row := r
						if a_is_sqlite3 then
								-- SQLite3 PRAGMA table_info returns: cid, name, type, notnull, dflt_value, pk
							if attached l_row.item ("name") as n and then attached {READABLE_STRING_GENERAL} n as ns then
								l_name := ns.to_string_8
							end
							if attached l_row.item ("type") as t and then attached {READABLE_STRING_GENERAL} t as ts then
								l_type := ts.to_string_8
							end
							if attached l_row.item ("notnull") as nn then
								if attached {INTEGER_32} nn as i then
									l_nullable := i = 0
								elseif attached {BOOLEAN} nn as b then
									l_nullable := not b
								end
							end
						else
								-- MySQL information_schema returns: column_name, data_type, is_nullable
							if attached l_row.item ("column_name") as n and then attached {READABLE_STRING_GENERAL} n as ns then
								l_name := ns.to_string_8
							end
							if attached l_row.item ("data_type") as t and then attached {READABLE_STRING_GENERAL} t as ts then
								l_type := ts.to_string_8
							end
							if attached l_row.item ("is_nullable") as nn and then attached {READABLE_STRING_GENERAL} nn as nns then
								l_nullable := nns.is_case_insensitive_equal ("YES")
							end
						end
						if l_name /= Void and l_type /= Void then
							Result.force ([l_name, l_type, l_nullable])
						end
					end
				end
			end
		end

	execute_query_internal (a_query: READABLE_STRING_8; a_parameters: detachable STRING_TABLE [detachable ANY]; a_limit: INTEGER; a_storage: CMS_STORAGE_SQL_I): detachable ARRAYED_LIST [STRING_TABLE [detachable ANY]]
		local
			l_parameters: STRING_TABLE [detachable ANY]
			l_query: READABLE_STRING_8
			l_row: STRING_TABLE [detachable ANY]
			l_col_count: INTEGER
			l_col_name: READABLE_STRING_GENERAL
			i: INTEGER
		do
				-- Safety check: only allow SELECT queries
			if not a_query.starts_with ("SELECT") and not a_query.starts_with ("PRAGMA") and not a_query.starts_with ("select") and not a_query.starts_with ("pragma") then
					-- Reject non-SELECT queries for security
				check is_select_query: False end
			else
				if a_limit > 0 then
					if a_query.ends_with (";") then
						l_query := a_query.substring (1, a_query.count - 1)
					else
						l_query := a_query
					end
					if a_storage.generator.ends_with ("SQLITE3") then
						l_query := l_query + " LIMIT " + a_limit.out + ";"
					else
						l_query := l_query + " LIMIT " + a_limit.out + ";"
					end
				else
					l_query := a_query
					if not l_query.ends_with (";") then
						l_query := l_query + ";"
					end
				end

				l_parameters := a_parameters

				if attached a_storage as proxy then -- {CMS_PROXY_STORAGE_SQL}
						-- Use the proxy's SQL execution methods
					proxy.sql_query (l_query, l_parameters)
					if not proxy.has_error then
						create Result.make (100)
						from
							proxy.sql_start
							l_col_count := proxy.sql_columns_count
						until
							proxy.sql_after or proxy.has_error
						loop
							create l_row.make_equal_caseless (l_col_count)
							from
								i := 1
							until
								i > l_col_count
							loop
								l_col_name := proxy.sql_column_name (i)
								if l_col_name = Void then
									l_col_name := "col#" + i.out
								end
								if attached proxy.sql_item (i) as v then
									l_row [l_col_name] := v
								else
										-- Try to read as string as fallback
									if attached proxy.sql_read_string_8 (i) as val then
										l_row [l_col_name] := val
									end
								end
								i := i + 1
							end
							Result.force (l_row)
							proxy.sql_forth
						end
					end
					proxy.sql_finalize_query (l_query)
				end
			end
		end

feature -- Settings

	module_version: READABLE_STRING_8
		do
			Result := module.version
		end

note
	copyright: "2011-2025, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end

