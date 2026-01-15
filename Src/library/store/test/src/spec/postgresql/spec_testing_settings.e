note
	description: "PostgreSQL-specific testing settings"
	date: "$Date$"
	revision: "$Revision$"

class
	SPEC_TESTING_SETTINGS

inherit
	TESTING_SETTINGS

feature -- Storage

	host: STRING
		once
			if attached json_configuration.item ("database.postgresql.host") as l_host and then not l_host.is_empty then
				Result := l_host
			else
				Result := "localhost"
			end
		end

	database_name: STRING
		once
			if attached json_configuration.item ("database.postgresql.name") as l_name and then not l_name.is_empty then
				Result := l_name
			else
				Result := "postgres"
			end
		end

	user_login: STRING
		once
			if attached json_configuration.item ("database.postgresql.administrative_user") as l_user and then not l_user.is_empty then
				Result := l_user
			else
				Result := "postgres"
			end
		end

	user_password: STRING
		once
			if attached json_configuration.item ("database.postgresql.administrative_user_passwd") as l_p and then not l_p.is_empty then
				Result := l_p
			else
				Result := "test"
			end
		end

feature -- Query

	is_mysql: BOOLEAN = False
	is_odbc: BOOLEAN = False
	is_oracle: BOOLEAN = False
	is_sybase: BOOLEAN = False
	is_postgresql: BOOLEAN = True

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
