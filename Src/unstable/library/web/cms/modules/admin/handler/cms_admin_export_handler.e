note
	description: "[
			Administrate export functionality.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_ADMIN_EXPORT_HANDLER

inherit
	CMS_HANDLER_ON_ROUTER

	WSF_URI_HANDLER
		rename
			new_mapping as new_uri_mapping
		end

	WSF_RESOURCE_HANDLER_HELPER
		redefine
			do_get,
			do_post
		end

	REFACTORING_HELPER

create
	make

feature -- Routing

	setup_router (a_router: WSF_ROUTER)
			-- Setup url dispatching for Current handler.
			-- (note: `a_router` is already based with path prefix).
		local
			l_uri_mapping: WSF_URI_MAPPING
			l_tpl_mapping: WSF_URI_TEMPLATE_MAPPING
		do
			create l_uri_mapping.make_trailing_slash_ignored ("/export", Current)
			a_router.map (l_uri_mapping, a_router.methods_get_post)

			create l_tpl_mapping.make ("/export/{archive}", create {WSF_URI_TEMPLATE_AGENT_HANDLER}.make (agent download_archive))
			a_router.map (l_tpl_mapping, a_router.methods_get)

		end

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (req, res)
		end

	do_get (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			l_response: CMS_RESPONSE
			s: STRING
			f: CMS_FORM
		do
			if api.has_permission ("admin export") then
				create {GENERIC_VIEW_CMS_RESPONSE} l_response.make (req, res, api)
				f := exportation_web_form (l_response)
				create s.make_empty
				f.append_to_html (l_response.wsf_theme, s)

				s.append ("<hr/>%N")

				f := exportation_manager_web_form (l_response)
				f.append_to_html (l_response.wsf_theme, s)

				l_response.set_main_content (s)
				l_response.execute
			else
				send_access_denied (req, res)
			end
		end

	do_post (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			fid: READABLE_STRING_GENERAL
		do
			if api.has_permission ("admin export") then
				if attached {WSF_STRING} req.form_parameter ("form-id") as p_fid then
					fid := p_fid.value
				else
					fid := form_export_data
				end
				if fid.same_string (form_export_data) then
					do_export_data (req, res)
				elseif fid.same_string (form_manage_export) then
					do_manage_export (req, res)
				else
					send_bad_request (req, res)
				end
			else
				send_access_denied (req, res)
			end
		end

	download_archive (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			dl: WSF_DOWNLOAD_RESPONSE
			p: PATH
			fut: FILE_UTILITIES
		do
			if api.has_permission ("admin export") then
				if attached {WSF_STRING} req.path_parameter ("archive") as p_archive then
					p := api.site_location.extended ("export").extended (p_archive.value)
					if fut.file_path_exists (p) then
						create dl.make (p.name)
						res.send (dl)
					else
						send_not_found (req, res)
					end
				else
					send_bad_request (req, res)
				end
			else
				send_access_denied (req, res)
			end
		end

feature {NONE} -- Implementation		

	do_export_data (req: WSF_REQUEST; res: WSF_RESPONSE)
		require
			api.has_permission ("admin export")
		local
			l_response: CMS_RESPONSE
			s: STRING
			f: CMS_FORM
			l_exportation: CMS_EXPORT_CONTEXT
		do
			create {GENERIC_VIEW_CMS_RESPONSE} l_response.make (req, res, api)
			f := exportation_web_form (l_response)
			f.process (l_response)
			if
				attached f.last_data as fd and then
				fd.is_valid
			then
				if
					attached fd.string_item ("op") as l_op and then l_op.same_string (text_export_all_data)
				then
					if attached fd.string_item ("folder") as l_folder then
						create l_exportation.make (api.site_location.extended ("export").extended (l_folder))
					else
						create l_exportation.make (api.site_location.extended ("export").extended ((create {DATE_TIME}.make_now_utc).formatted_out ("yyyy-[0]mm-[0]dd---hh24-[0]mi-[0]ss")))
					end
					api.hooks.invoke_export_to (Void, l_exportation, l_response)
					l_response.add_notice_message ("All data exported (if allowed)!")
					create s.make_empty
					across
						l_exportation.logs as log
					loop
						s.append (log)
						s.append ("<br/>")
						s.append_character ('%N')
					end
					l_response.add_notice_message (s)

					f := exportation_manager_web_form (l_response)
				else
					fd.report_error ("Invalid form data!")
				end
			end

			create s.make_empty
			f.append_to_html (l_response.wsf_theme, s)
			l_response.set_main_content (s)
			l_response.execute
		end

	do_manage_export (req: WSF_REQUEST; res: WSF_RESPONSE)
		require
			api.has_permission ("admin export")
		local
			l_response: CMS_RESPONSE
			s: STRING
			f: CMS_FORM
			dir: PATH
			exp_p, p: PATH
			fut: FILE_UTILITIES
		do
			create {GENERIC_VIEW_CMS_RESPONSE} l_response.make (req, res, api)
			f := exportation_manager_web_form (l_response)
			f.process (l_response)
			if
				attached f.last_data as fd and then
				fd.is_valid
			then
				if
					attached fd.string_item ("op") as l_op and then l_op.same_string (text_delete_exportations)
				then
					if attached fd.table_item ("dir") as dirs then
						dir := api.site_location.extended ("export")
						across
							dirs as d
						loop
							if attached {WSF_STRING} d as exp then
								create exp_p.make_from_string (exp.value)
								if exp_p.components.count = 1 then
									p := dir.extended_path (exp_p)
									if api.safe_delete_directory (p) then
										l_response.add_notice_message ("Export "+ api.html_encoded (exp_p.name) +" deleted")
									else
										l_response.add_error_message ("Export "+ api.html_encoded (exp_p.name) +" NOT deleted")
									end
									p := p.appended_with_extension ("zip")
									if fut.file_path_exists (p) then
										api.safe_delete_file (p).do_nothing
									end
								end
							end
						end
					end
					f := exportation_manager_web_form (l_response)
				elseif
					attached fd.string_item ("op") as l_op and then l_op.same_string (text_archive_exportations)
				then
					if attached fd.table_item ("dir") as dirs then
						dir := api.site_location.extended ("export")
						across
							dirs as d
						loop
							if attached {WSF_STRING} d as exp then
								create exp_p.make_from_string (exp.value)
								if exp_p.components.count = 1 then
									p := dir.extended_path (exp_p)
									if api.zip_to (dir.extended_path (exp_p), dir.extended_path (exp_p).appended_with_extension ("zip")) then
										l_response.add_notice_message ("Export "+ api.html_encoded (exp_p.name) +" archived")
									else
										l_response.add_error_message ("Export "+ api.html_encoded (exp_p.name) +" NOT archived")
									end
								end
							end
						end
					end
					f := exportation_manager_web_form (l_response)
				else
					fd.report_error ("Invalid form data!")
				end
			end

			create s.make_empty
			f.append_to_html (l_response.wsf_theme, s)
			l_response.set_main_content (s)
			l_response.execute
		end

feature -- Widget

	exportation_web_form (a_response: CMS_RESPONSE): CMS_FORM
		local
			f_name: WSF_FORM_TEXT_INPUT
			but: WSF_FORM_SUBMIT_INPUT
		do
			create Result.make (a_response.request_url (Void), form_export_data)
			Result.extend_hidden_input ("form-id", form_export_data)
			Result.extend_raw_text ("Export CMS data to ")
			create f_name.make_with_text ("folder", (create {DATE_TIME}.make_now_utc).formatted_out ("yyyy-[0]mm-[0]dd---hh24-[0]mi-[0]ss"))
			f_name.set_label ("Export folder name")
			f_name.set_description ("Folder name under 'exports' folder.")
			f_name.set_is_required (True)
			Result.extend (f_name)
			create but.make_with_text ("op", text_export_all_data)
			Result.extend (but)
		end

	exportation_manager_web_form (a_response: CMS_RESPONSE): CMS_FORM
		local
			cb: WSF_FORM_CHECKBOX_INPUT
			but: WSF_FORM_SUBMIT_INPUT
			dir: PATH
			fut: FILE_UTILITIES
			f_set: WSF_FORM_FIELD_SET
			nb, dl_nb: INTEGER
		do
			create Result.make (a_response.request_url (Void), form_manage_export)
			Result.extend_hidden_input ("form-id", form_manage_export)
--			Result.extend_raw_text ("Manage exportations")

			dir := api.site_location.extended ("export")
			create f_set.make
			f_set.set_legend ("Exportations")
			if attached fut.directory_names (dir.name) as dirs then
				across
					dirs as exp
				loop
					create cb.make_with_value ("dir[]", exp)
					cb.set_title (exp)
					f_set.extend (cb)
					if fut.file_path_exists (dir.extended (exp).appended_with_extension ("zip")) then
						cb.add_css_class ("archive")
						f_set.extend_html_text (api.absolute_link ("download", a_response.request.percent_encoded_path_info + "/" + api.url_encoded (exp) + ".zip", Void))
						dl_nb := dl_nb + 1
					end
					nb := nb + 1
				end
			end
			if nb > 0 then
				Result.extend (f_set)
				create but.make_with_text ("op", text_delete_exportations)
				Result.extend (but)
				if dl_nb < nb then
					create but.make_with_text ("op", text_archive_exportations)
					Result.extend (but)
				end
			else
				Result.extend_html_text ("No exported data available!")
			end
		end

feature -- Interface text.	

	form_export_data: STRING_8 = "export_data"

	text_export_all_data: STRING_32 = "Export all data"

	form_manage_export: STRING_8 = "manage_export"

	text_delete_exportations: STRING_32 = "Delete"

	text_archive_exportations: STRING_32 = "Archive"

end
