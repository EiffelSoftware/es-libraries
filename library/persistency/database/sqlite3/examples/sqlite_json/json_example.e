note
	description: "[
		Example of using SQLite with JSON operations.
		Demonstrates CREATE TABLE with JSON column, INSERT with JSON data,
		and SELECT with json_extract function.
	]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	JSON_EXAMPLE

inherit
	SQLITE_SHARED_API

create
	make

feature {NONE} -- Initialization

	make
			-- JSON operations with SQLite.
		local
			l_db: SQLITE_DATABASE
			l_modify: SQLITE_MODIFY_STATEMENT
			l_insert: SQLITE_INSERT_STATEMENT
			l_query: SQLITE_QUERY_STATEMENT
		do
			print ("%NOpening In-Memory Database...%N")

				-- Open an in-memory SQLite database
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write

			print ("Creating table with JSON column...%N")

				-- Create table with JSON column
			create l_modify.make ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, profile JSON);", l_db)
			l_modify.execute

			print ("Inserting JSON data...%N")

				-- Insert JSON data
			create l_insert.make ("INSERT INTO users (name, profile) VALUES (?1, ?2);", l_db)

			l_insert.execute_with_arguments ([
				"Alice",
				"{%"age%": 30, %"location%": {%"city%": %"New York%"}}"
			])
			l_insert.execute_with_arguments ([
				"Bob",
				"{%"age%": 25, %"location%": {%"city%": %"Chicago%"}}"
			])

			print ("Querying with json_extract...%N")

				-- Query using json_extract
			create l_query.make ("SELECT name, json_extract(profile, '$.location.city') AS city FROM users;", l_db)

			print ("Name%TCity%N")
			print ("----%T-----%N")

			across l_query.execute_new as l_cursor loop
				print (l_cursor.item.string_value (1) + "%T" + l_cursor.item.string_value (2) + "%N")
			end

			print ("%NClosing Database...%N")

			l_db.close
		end

note
	copyright: "Copyright (c) 1984-2009, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
