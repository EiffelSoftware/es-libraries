note
	description: "Summary description for {CMS_MODULE_WITH_SQL_STORAGE}."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CMS_MODULE_WITH_SQL_STORAGE

inherit
	CMS_MODULE
		redefine
			install, uninstall,
			update
		end

feature {CMS_API} -- SQL queries

	sql_storage (api: CMS_API): detachable CMS_STORAGE_SQL_I
		do
			Result := api.storage.as_sql_storage
		end

	has_sql_table (a_table_name: READABLE_STRING_8; api: CMS_API): BOOLEAN
		do
			if attached sql_storage (api) as l_sql_storage then
				Result := l_sql_storage.sql_table_exists (a_table_name)
			end
		end

feature {CMS_API} -- Module management

	install (api: CMS_API)
		local
			p, l_script_location: PATH
			fut: FILE_UTILITIES
		do
				-- Schema
			if attached sql_storage (api) as l_sql_storage then
				p := (create {PATH}.make_from_string ("scripts")).extended (name).appended_with_extension ("sql")
				l_script_location := api.module_resource_location (Current, p)
				if not fut.file_path_exists (l_script_location) then
					p := (create {PATH}.make_from_string ("scripts")).extended ("install.sql")
					l_script_location := api.module_resource_location (Current, p)
				end
				l_sql_storage.sql_execute_file_script (l_script_location, Void)
				if l_sql_storage.has_error then
					api.logger.put_error ("Could not install database for module [" + name + "]: " + utf_8_encoded (l_sql_storage.error_handler.as_string_representation), generating_type)
				else
					Precursor {CMS_MODULE} (api)
				end
			end
		end

	uninstall (api: CMS_API)
			-- (export status {CMS_API})
		do
			if attached sql_storage (api) as l_sql_storage then
				l_sql_storage.sql_execute_file_script (api.module_resource_location (Current, (create {PATH}.make_from_string ("scripts")).extended ("uninstall").appended_with_extension ("sql")), Void)
				if l_sql_storage.has_error then
					api.logger.put_error ("Could not uninstall database for module [" + name + "]: " + utf_8_encoded (l_sql_storage.error_handler.as_string_representation), generating_type)
				end
			end
			Precursor (api)
		end

	update (a_installed_version: READABLE_STRING_GENERAL; api: CMS_API)
			-- Update module from version `a_installed_version` to current `version`.
		local
			done: BOOLEAN
			l_module_version, v, prev_v: like version_details
		do
			if attached sql_storage (api) as l_sql_storage then
					-- TODO: documentate this global update facility for SQL storage.
				from
					l_module_version := version_details (version)
					v :=  version_details (a_installed_version)
					prev_v := v
					done := False
				until
					done
				loop
					if attached update_details_for_version (v, l_module_version, api) as l_up_details then
						prev_v := v
						v := l_up_details.target_version
						if
							version_compared_to (v, prev_v, 4) >= 0 and -- greater or equal to the installed version (or previous updated version)
							version_compared_to (v, l_module_version, 4) <= 0 -- Lower or equal to the target version
						then
							l_sql_storage.sql_execute_file_script (l_up_details.location, Void)
						else
							done := True
						end
					else
						done := True
					end
				end

				if l_sql_storage.has_error then
					api.log_error (name, "Could not update database for module [" + name + "]: " + utf_8_encoded (l_sql_storage.error_handler.as_string_representation), Void)
				else
					Precursor (a_installed_version, api)
				end
			else
				Precursor (a_installed_version, api)
			end
		end

feature {NONE} -- Implementation

	version_details (v: READABLE_STRING_GENERAL): TUPLE [major, minor: INTEGER; built: INTEGER; tag: detachable READABLE_STRING_GENERAL]
		local
			i,j: INTEGER
			maj,min, bui: INTEGER
			s: READABLE_STRING_GENERAL
		do
				-- TODO: add a VERSION class to manipulate such version values.
			i := 1
			j := v.index_of ('.', i)
			if j > i then
					-- major.
				maj := v.substring (i, j - 1).to_integer
				i := j + 1
				j := v.index_of ('.', i)
				if j > i then
						-- major.minor.
					min := v.substring (i, j - 1).to_integer
					i := j + 1
					j := v.index_of ('.', i)
					if j > i then
							-- major.minor.built.tag
						s := v.substring (i, j - 1)
						if s.is_integer then
							bui := s.to_integer
						else
							s := v.substring (i, v.count)
						end
					else
						s := v.substring (i, v.count)
						if s.is_integer then
							bui := s.to_integer
						end
					end
				else
						-- major.minor
					min := v.substring (i, v.count).to_integer
				end
			end
			if s /= Void and then s.is_whitespace then
				s := Void
			end
			Result := [maj, min, bui, s]
		end

	version_compared_to (v1, v2: like version_details; a_level: INTEGER): INTEGER
			-- smaller=-1 equal=0 greater=1.
			-- take into account version data until level `a_level`,
			-- level  = 1: major
			-- level  = 2: major + minor
			-- level >= 3: major + minor + build
		require
			a_level >= 1
		do
			if v1.major = v2.major then
				if a_level >= 2 then
					if v1.minor = v2.minor then
						if a_level >= 3 then
							if v1.built = v2.built then
								Result := 0
							elseif v1.built <= v2.built then
								Result := -1
							else
								Result := +1
							end
						else
							Result := 0
						end
					else
						if v1.minor <= v2.minor then
							Result := -1
						else
							Result := +1
						end
					end
				else
					Result := 0
				end
			else
				if v1.major <= v2.major then
					Result := -1
				else
					Result := +1
				end
			end
		end

	sort_versioned_data_by_source (lst: LIST [attached like update_details_for_version])
		local
			l_sorter: QUICK_SORTER [attached like update_details_for_version]
		do
			create l_sorter.make (create {AGENT_EQUALITY_TESTER [attached like update_details_for_version]}.make (
					agent (t1, t2: attached like update_details_for_version): BOOLEAN
						local
							d: INTEGER
						do
							d := version_compared_to (t1.from_version, t2.from_version, 4)
							if d = 0 then
								d := version_compared_to (t1.target_version, t2.target_version, 4)
								Result := d >= 0
							else
								Result := d < 0
							end
						end
					))
			l_sorter.sort (lst)
		end

	update_details_for_version (v, max_v: like version_details; api: CMS_API): detachable TUPLE [location: PATH; from_version, target_version: attached like version_details]
		local
			v_from, v_src, v_to: STRING_32
			v_from_details, v_to_details: like version_details
			p: PATH
			l_names: LIST [READABLE_STRING_32]
			l_choices: ARRAYED_LIST [TUPLE [location: PATH; from_version, target_version: attached like version_details]]
			fut: FILE_UTILITIES
			l_pref: STRING_32
			i, lev: INTEGER
		do
			create p.make_from_string ("scripts")
			p := p.extended ("update")
			if fut.directory_path_exists (api.module_resource_location (Current, p)) then
				p := api.module_resource_location (Current, p)
				l_names := fut.file_names (p.name)
				l_pref := name + "-"
			else
				create p.make_from_string ("scripts")
				p := api.module_resource_location (Current, p)
				l_names := fut.file_names (p.name)
				l_pref := "update-"
			end
			if l_names /= Void then
				from
					l_names.start
				until
					l_names.off
				loop
					if l_names.item.starts_with (l_pref) and then l_names.item.ends_with (".sql") then
						l_names.forth
					else
						l_names.remove
					end
				end
				if l_names.is_empty then
					l_names := Void
				end
			end

			if l_names /= Void then
				create l_choices.make (0)
				from
					lev := 3 -- 3: built, 2: minor, 1: major
				until
					l_choices.count > 0 or lev < 1
				loop
					if lev >= 3 then
						v_from := v.major.out + "_" + v.minor.out + "_" + v.built.out
						lev := 2 -- minor
					elseif lev >= 2 then
						v_from := v.major.out + "_" + v.minor.out
						lev := 1 -- major						
					elseif lev >= 1 then
						v_from := v.major.out
						lev := 0 -- exit
					else
						v_from := Void
						lev := lev - 1
					end
					if v_from /= Void then
						v_from := l_pref + v_from
						across
							l_names as fn
						loop
							if fn.starts_with (v_from) then
								i := fn.index_of ('-', v_from.count)
								if i > 0 then
									v_src := fn.substring (l_pref.count + 1, i - 1)
									v_to := fn.substring (i + 1, fn.count)
									i := v_to.last_index_of ('.', v_to.count)
									if i > 0 then
										v_to.keep_head (i - 1)
									end
									v_src.replace_substring_all ("_", ".")
									v_to.replace_substring_all ("_", ".")

									v_from_details := version_details (v_src)
									v_to_details := version_details (v_to)
									if
											-- Between `v_lev` and `max_v`
										version_compared_to (v_from_details, v, lev + 1) >= 0 and
										version_compared_to (v_to_details, max_v, lev + 1) <= 0
									then
										l_choices.force ([p.extended (fn), version_details (v_src), v_to_details])
									end
								end
							end
						end
					end
				end
				if l_choices.count > 0 then
					sort_versioned_data_by_source (l_choices)
					Result := l_choices.first
				end
			end
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
