note
	description: "API providing email related features (templates, rendering, ...)."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_EMAIL_API

inherit
	CMS_MODULE_API

create
	make

feature -- Access

	email_templates: ARRAYED_LIST [CMS_EMAIL_TEMPLATE]
			-- List of stored email templates.
		local
			lst: detachable STRING_TABLE [detachable READABLE_STRING_32]
		do
			create Result.make (10)
			lst := storage.custom_values_for (custom_value_type)
			if lst /= Void then
				across
					lst as v
				loop
					if attached template_from_json_string (utf_8_value (v)) as tpl then
						Result.extend (tpl)
					end
				end
			end
		end

	email_template (a_id: READABLE_STRING_GENERAL): detachable CMS_EMAIL_TEMPLATE
			-- Template identified by `a_id', if any.
		do
			if attached storage.custom_string_8_value (a_id, custom_value_type) as l_json then
				Result := template_from_json_string (l_json)
			end
		end

feature -- Element change

	save_email_template (a_template: CMS_EMAIL_TEMPLATE): BOOLEAN
			-- Save new template `a_template'.
		require
			valid_template: a_template.has_id and a_template.has_content
		do
			reset_error
			if attached a_template.id as l_id then
				if email_template (l_id) /= Void then
					error_handler.add_custom_error (0, "Template exists", "An email template with the same id already exists.")
				else
					persist_template (a_template)
				end
			else
				error_handler.add_custom_error (0, "Invalid template", "Missing template id.")
			end
			Result := not has_error
		ensure
			result_reflects_error: Result = not has_error
		end

	update_email_template (a_template: CMS_EMAIL_TEMPLATE): BOOLEAN
			-- Update existing template `a_template'.
		require
			valid_template: a_template.has_id and a_template.has_content
		do
			reset_error
			if attached a_template.id as l_id then
				if email_template (l_id) = Void then
					error_handler.add_custom_error (0, "Template not found", "No email template with the given id.")
				else
					persist_template (a_template)
				end
			else
				error_handler.add_custom_error (0, "Invalid template", "Missing template id.")
			end
			Result := not has_error
		ensure
			result_reflects_error: Result = not has_error
		end

	render_email_template (a_template: CMS_EMAIL_TEMPLATE; a_variables: detachable JSON_OBJECT; a_target_user: detachable CMS_USER; a_value_table: detachable CMS_VALUE_TABLE): STRING_8
			-- Render full email body from `a_template' title, content and footer.
		require
			valid_template: a_template.has_content
		do
			Result := render_template_parts (a_template, a_variables, a_target_user, a_value_table)
		end

	render_email_template_title (a_template: CMS_EMAIL_TEMPLATE; a_variables: detachable JSON_OBJECT; a_target_user: detachable CMS_USER; a_value_table: detachable CMS_VALUE_TABLE): detachable READABLE_STRING_8
			-- Render template title from `a_template', if any.
		do
			if attached a_template.title as l_title then
				Result := render_content (l_title, a_template.engine, a_variables, a_target_user, a_value_table)
			end
		end

	template_from_json_object (jobj: JSON_OBJECT; a_id: detachable READABLE_STRING_GENERAL): TUPLE [template: detachable CMS_EMAIL_TEMPLATE; error: detachable READABLE_STRING_32]
			-- Build template from JSON object `jobj', optionally using `a_id'.
		local
			l_id: detachable READABLE_STRING_8
			l_content: detachable READABLE_STRING_32
			l_template: detachable CMS_EMAIL_TEMPLATE
			l_err: STRING_32
		do
			create l_err.make_empty
			if a_id /= Void then
				if attached {STRING_8} a_id as s8 then
					l_id := s8
				else
					l_id := a_id.to_string_8
				end
			elseif attached jobj.string_item ("id") as j_id then
				l_id := j_id.unescaped_string_8
			else
				l_err.append ({STRING_32} "Missing id field!%N")
			end
			if attached jobj.string_item ("content") as j_content then
				l_content := j_content.unescaped_string_32
			else
				l_err.append ({STRING_32} "Missing content field!%N")
			end
			if l_err.is_empty and then attached l_id as id and then l_content /= Void then
				create l_template.make (id, l_content)
				if attached jobj.string_item ("id") as j_id and then a_id /= Void then
					if not j_id.unescaped_string_8.same_string_general (id) then
						l_err.append ({STRING_32} "Template id does not match path!%N")
						l_template := Void
					end
				end
				if l_template /= Void then
					apply_optional_template_fields_from_json (jobj, l_template)
				end
			end
			if l_err.is_empty then
				Result := [l_template, Void]
			else
				Result := [Void, l_err]
			end
		end

	builtin_variables_json_array: JSON_ARRAY
			-- JSON array describing known site builtin variables.
		local
			l_vars: STRING_TABLE [detachable ANY]
			jo: JSON_OBJECT
		do
			l_vars := cms_api.builtin_variables
			create Result.make (known_builtin_variable_names.count)
			across
				known_builtin_variable_names as n
			loop
				create jo.make_with_capacity (4)
				jo.put_string (n, "name")
				if l_vars.has (n) then
					jo.put_boolean (True, "available")
					jo.put (builtin_variable_value_to_json (l_vars [n]), "value")
				else
					jo.put_boolean (False, "available")
				end
				jo.put_string (builtin_variable_description (n), "description")
				Result.extend (jo)
			end
		end

	template_to_json_object (a_template: CMS_EMAIL_TEMPLATE): JSON_OBJECT
			-- JSON object representation of `a_template'.
		local
			jo: JSON_OBJECT
		do
			create jo.make_with_capacity (5)
			if attached a_template.id as l_id then
				jo.put_string (l_id, "id")
			end
			if attached a_template.title as l_title then
				jo.put_string (cms_api.utf_8_decoded (l_title), "title")
			end
			if attached a_template.content as l_content then
				jo.put_string (cms_api.utf_8_decoded (l_content), "content")
			end
			if attached a_template.footer as l_footer then
				jo.put_string (cms_api.utf_8_decoded (l_footer), "footer")
			end
			if attached a_template.engine as l_engine then
				jo.put_string (l_engine, "engine")
			end
			Result := jo
		end

	render_content_from_template_request (a_request: JSON_OBJECT; a_target_user: detachable CMS_USER; a_target_address: detachable READABLE_STRING_8): TUPLE [content: detachable READABLE_STRING_8; subject: detachable READABLE_STRING_8; error: detachable READABLE_STRING_32]
			-- Render email body and optional subject from WebAPI template request `a_request'.
			-- Recipient `a_target_user' and `a_target_address' are exposed as `target' variables.
		local
			l_template_id: detachable READABLE_STRING_8
			l_template: detachable CMS_EMAIL_TEMPLATE
			l_context: like template_context_for_recipient
			l_content, l_subject: detachable READABLE_STRING_8
			l_err: STRING_32
		do
			create l_err.make_empty
			if attached a_request.string_item ("template") as j_template then
				l_template_id := j_template.unescaped_string_8
			else
				l_err.append ({STRING_32} "Missing template field in content object!%N")
			end
			if l_err.is_empty and then attached l_template_id as l_id then
				l_template := email_template (l_id)
				if l_template = Void then
					l_err.append ({STRING_32} "Unknown email template: ")
					l_err.append_string_general (l_id)
					l_err.append ({STRING_32} "!%N")
				end
			end
			if l_err.is_empty and then attached l_template as tpl then
				if attached a_request.object_item ("variables") as j_request_variables then
					l_context := template_context_for_recipient (j_request_variables, a_target_user, a_target_address, l_template_id)
				else
					l_context := template_context_for_recipient (Void, a_target_user, a_target_address, l_template_id)
				end
				l_content := render_email_template (tpl, l_context.variables, a_target_user, l_context.value_table)
				l_subject := render_email_template_title (tpl, l_context.variables, a_target_user, l_context.value_table)
			end
			if l_err.is_empty then
				Result := [l_content, l_subject, Void]
			else
				Result := [Void, Void, l_err]
			end
		end

	render_plain_content (a_content: READABLE_STRING_8; a_request_variables: detachable JSON_OBJECT; a_target_user: detachable CMS_USER; a_target_address: detachable READABLE_STRING_8): STRING_8
			-- Render plain `a_content' using merged recipient variables.
		local
			l_context: like template_context_for_recipient
		do
			l_context := template_context_for_recipient (a_request_variables, a_target_user, a_target_address, Void)
			Result := render_with_string_expander (a_content, l_context.variables)
		end

feature -- Constants

	known_builtin_variable_names: ARRAYED_LIST [STRING_8]
			-- Names of builtin variables usable in email templates.
		once
			create Result.make (7)
			Result.extend (var_site_url)
			Result.extend (var_site_email)
			Result.extend (var_site_name)
			Result.extend (var_user)
			Result.extend (var_user_id)
			Result.extend (var_user_profile_name)
			Result.extend (var_active_user)
		end

	var_site_url: STRING_8 = "site_url"
	var_site_email: STRING_8 = "site_email"
	var_site_name: STRING_8 = "site_name"
	var_user: STRING_8 = "user"
	var_user_id: STRING_8 = "user_id"
	var_user_profile_name: STRING_8 = "user_profile_name"
	var_active_user: STRING_8 = "active_user"

feature {NONE} -- Implementation

	custom_value_type: STRING_8 = "email-template"

	merged_template_variables (a_request_variables: detachable JSON_OBJECT): JSON_OBJECT
			-- Merge site builtin variables with `a_request_variables'.
			-- Builtin values are set first; request variables override on conflict.
		local
			l_builtin: STRING_TABLE [detachable ANY]
			l_result: JSON_OBJECT
		do
			l_builtin := cms_api.builtin_variables
			create l_result.make_with_capacity (l_builtin.count + 5)
			across
				l_builtin as v
			loop
				if attached builtin_variable_value_to_json (v) as jv then
					l_result.put (jv, @v.key)
				end
			end
			if a_request_variables /= Void then
				across
					a_request_variables as v
				loop
					if l_result.has_key (@v.key) then
						l_result.replace (v, @v.key)
					else
						l_result.put (v, @v.key)
					end
				end
			end
			Result := l_result
		end

	template_context_for_recipient (a_request_variables: detachable JSON_OBJECT; a_target_user: detachable CMS_USER; a_target_address: detachable READABLE_STRING_8; a_template_id: detachable READABLE_STRING_GENERAL): TUPLE [variables: JSON_OBJECT; value_table: CMS_VALUE_TABLE]
			-- Merge builtin, request, target and hook variables for recipient `a_target_user'.
		local
			l_variables: JSON_OBJECT
			l_target_variables: JSON_OBJECT
		do
			l_variables := merged_template_variables (a_request_variables)
			l_target_variables := target_template_variables (a_target_user, a_target_address)
			across
				l_target_variables as v
			loop
				if l_variables.has_key (@v.key) then
					l_variables.replace (v, @v.key)
				else
					l_variables.put (v, @v.key)
				end
			end
			Result := apply_template_value_table_hooks (a_template_id, l_variables)
		end

	apply_template_value_table_hooks (a_template_id: detachable READABLE_STRING_GENERAL; a_variables: JSON_OBJECT): TUPLE [variables: JSON_OBJECT; value_table: CMS_VALUE_TABLE]
			-- Let modules alter template variables via {CMS_HOOK_TEMPLATE_VALUE_TABLE_ALTER}.
		local
			l_table: CMS_VALUE_TABLE
			l_id: READABLE_STRING_GENERAL
			l_variables: JSON_OBJECT
		do
			create l_table.make (a_variables.count)
			across
				a_variables as v
			loop
				l_table.force (json_value_to_any (v), @v.key.unescaped_string_8)
			end
			if a_template_id = Void then
				create {STRING_8} l_id.make_empty
			else
				l_id := {STRING_32} "mail." + a_template_id
			end
			cms_api.hooks.invoke_template_value_table_alter (l_id, l_table, {CMS_CORE_MODULE})
			l_variables := a_variables
			across
				l_table as v
			loop
				if attached builtin_variable_value_to_json (v) as jv then
					if l_variables.has_key (@v.key) then
						l_variables.replace (jv, @v.key)
					else
						l_variables.put (jv, @v.key)
					end
				end
			end
			Result := [l_variables, l_table]
		end

	target_template_variables (a_target_user: detachable CMS_USER; a_target_address: detachable READABLE_STRING_8): JSON_OBJECT
			-- Template variables related to email recipient `a_target_user'.
		local
			l_email: detachable READABLE_STRING_8
		do
			create Result.make_with_capacity (8)
			if a_target_user /= Void then
				Result.put (user_to_json_object (a_target_user), "target")
				Result.put_string (a_target_user.name, "target.name")
				Result.put_string (a_target_user.id.out, "target.uid")
				if attached a_target_user.profile_name as l_profile_name and then not l_profile_name.is_whitespace then
					Result.put_string (l_profile_name, "target.profile_name")
				else
					Result.put_string (cms_api.user_api.user_display_name (a_target_user), "target.profile_name")
				end
				if attached a_target_user.email as l_user_email then
					l_email := l_user_email
				end
				if attached a_target_user.creation_date as l_creation_date then
					Result.put_string (cms_api.date_time_to_iso8601_string (l_creation_date), "target.creation_date")
				end
				if attached a_target_user.last_login_date as l_last_login_date then
					Result.put_string (cms_api.date_time_to_iso8601_string (l_last_login_date), "target.last_login_date")
				end
			end
			if l_email = Void then
				l_email := a_target_address
			end
			if l_email /= Void then
				Result.put_string (l_email, "target.email")
			end
		end

	builtin_variable_description (a_name: READABLE_STRING_8): STRING_8
			-- Human-readable description for builtin variable `a_name'.
		do
			if a_name.same_string_general (var_site_url) then
				Result := "Absolute URL of the CMS site."
			elseif a_name.same_string_general (var_site_email) then
				Result := "Site email address used as default sender."
			elseif a_name.same_string_general (var_site_name) then
				Result := "Site display name."
			elseif a_name.same_string_general (var_user) then
				Result := "Username of the current authenticated user."
			elseif a_name.same_string_general (var_user_id) then
				Result := "Numeric id of the current authenticated user."
			elseif a_name.same_string_general (var_user_profile_name) then
				Result := "Display name of the current authenticated user."
			elseif a_name.same_string_general (var_active_user) then
				Result := "Current authenticated user object (Smarty templates)."
			else
				Result := ""
			end
		end

	builtin_variable_value_to_json (a_value: detachable ANY): detachable JSON_VALUE
			-- Serialize builtin variable `a_value' as JSON.
		do
			if a_value = Void then
				Result := create {JSON_NULL}
			elseif attached {READABLE_STRING_8} a_value as s8 then
				create {JSON_STRING} Result.make_from_string (s8)
			elseif attached {READABLE_STRING_32} a_value as s32 then
				create {JSON_STRING} Result.make_from_string ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (s32))
			elseif attached {READABLE_STRING_GENERAL} a_value as sg then
				create {JSON_STRING} Result.make_from_string_general (sg)
			elseif attached {INTEGER_64} a_value as i64 then
				create {JSON_NUMBER} Result.make_integer_64 (i64)
			elseif attached {INTEGER_32} a_value as i32 then
				create {JSON_NUMBER} Result.make_integer_32 (i32)
			elseif attached {CMS_USER} a_value as u then
				Result := user_to_json_object (u)
			else
				create {JSON_STRING} Result.make_from_string (a_value.out)
			end
		end

	user_to_json_object (u: CMS_USER): JSON_OBJECT
			-- JSON representation of user `u'.
		local
			jo: JSON_OBJECT
		do
			create jo.make_with_capacity (4)
			jo.put_string (u.id.out, "uid")
			jo.put_string (u.name, "name")
			if attached u.email as l_email then
				jo.put_string (l_email, "email")
			end
			jo.put_string (cms_api.user_api.user_display_name (u), "profile_name")
			Result := jo
		end

	persist_template (a_template: CMS_EMAIL_TEMPLATE)
			-- Store `a_template' as custom value.
		do
			if attached a_template.id as l_id then
				storage.set_custom_value (l_id, template_to_json_string (a_template), custom_value_type)
			end
		end

	template_to_json_string (a_template: CMS_EMAIL_TEMPLATE): STRING_8
			-- JSON representation of `a_template'.
		do
			Result := template_to_json_object (a_template).representation
		end

	template_from_json_string (a_json: READABLE_STRING_8): detachable CMS_EMAIL_TEMPLATE
			-- Build template from JSON string `a_json'.
		local
			jp: JSON_PARSER
			l_parsed: like template_from_json_object
		do
			create jp.make
			jp.parse_string (a_json)
			if
				jp.is_parsed and then
				jp.is_valid and then
				attached jp.parsed_json_object as jo
			then
				l_parsed := template_from_json_object (jo, Void)
				if l_parsed.error = Void then
					Result := l_parsed.template
				end
			end
		end

	apply_optional_template_fields_from_json (jobj: JSON_OBJECT; a_template: CMS_EMAIL_TEMPLATE)
			-- Apply optional template fields from JSON object `jobj'.
		do
			if attached jobj.string_item ("title") as j_title then
				a_template.set_title (j_title.unescaped_string_32)
			end
			if attached jobj.string_item ("footer") as j_footer then
				a_template.set_footer (j_footer.unescaped_string_32)
			end
			if attached jobj.string_item ("engine") as j_engine then
				a_template.set_engine (j_engine.unescaped_string_8)
			end
		end

	render_template_parts (a_template: CMS_EMAIL_TEMPLATE; a_variables: detachable JSON_OBJECT; a_target_user: detachable CMS_USER; a_value_table: detachable CMS_VALUE_TABLE): STRING_8
			-- Render and assemble content and footer from `a_template'.
		local
			l_body: STRING_8
		do
			create l_body.make_empty
			if attached a_template.content as l_content then
				append_rendered_part (l_body, render_content (l_content, a_template.engine, a_variables, a_target_user, a_value_table))
			end
			if attached a_template.footer as l_footer then
				append_rendered_part (l_body, render_content (l_footer, a_template.engine, a_variables, a_target_user, a_value_table))
			end
			Result := l_body
		end

	append_rendered_part (a_body: STRING_8; a_part: READABLE_STRING_8)
			-- Append rendered part `a_part' to `a_body'.
		do
			if not a_part.is_empty then
				if not a_body.is_empty then
					a_body.append ("%N%N")
				end
				a_body.append (a_part)
			end
		end

	render_content (a_content: READABLE_STRING_8; a_engine: detachable READABLE_STRING_8; a_variables: detachable JSON_OBJECT; a_target_user: detachable CMS_USER; a_value_table: detachable CMS_VALUE_TABLE): STRING_8
			-- Render `a_content' with engine `a_engine' and merged `a_variables'.
		do
			if
				a_engine = Void or else
				a_engine.is_empty or else
				a_engine.is_case_insensitive_equal_general ("expand") or else
				a_engine.is_case_insensitive_equal_general ("string")
			then
				Result := render_with_string_expander (a_content, a_variables)
			elseif a_engine.is_case_insensitive_equal_general ("smarty") then
				Result := render_with_smarty (a_content, a_variables, a_target_user, a_value_table)
			else
				Result := render_with_string_expander (a_content, a_variables)
			end
		end

	render_with_string_expander (a_content: READABLE_STRING_8; a_variables: detachable JSON_OBJECT): STRING_8
			-- Render `a_content' using ${var} expansion.
		local
			exp: CMS_STRING_EXPANDER [READABLE_STRING_8]
			resolver: CMS_JSON_STRING_8_RESOLVER
			l_content: STRING_8
		do
			if attached {STRING_8} a_content as s8 then
				l_content := s8
			else
				create l_content.make_from_string (a_content)
			end
			if a_variables /= Void and then not a_variables.is_empty then
				create resolver.make (a_variables)
				create exp.make (resolver)
				exp.expand_string_8 (l_content)
			end
			Result := l_content
		end

	render_with_smarty (a_content: READABLE_STRING_8; a_variables: detachable JSON_OBJECT; a_target_user: detachable CMS_USER; a_value_table: detachable CMS_VALUE_TABLE): STRING_8
			-- Render `a_content' using Smarty template engine.
		local
			tpl: CMS_SMARTY_TEMPLATE_TEXT
		do
			create tpl.make (a_content)
			if a_variables /= Void then
				apply_json_object_to_smarty (tpl, a_variables)
			end
			if a_value_table /= Void then
				apply_value_table_to_smarty (tpl, a_value_table)
			end
			if a_target_user /= Void then
				tpl.set_value (a_target_user, "target")
			end
			Result := tpl.string.to_string_8
		end

	apply_value_table_to_smarty (a_template: CMS_SMARTY_TEMPLATE_TEXT; a_value_table: CMS_VALUE_TABLE)
			-- Add or override Smarty values from `a_value_table'.
			-- Live objects from hooks take precedence over JSON values.
		do
			across
				a_value_table as v
			loop
				a_template.set_value (v, @v.key)
			end
		end

	apply_json_object_to_smarty (a_template: CMS_SMARTY_TEMPLATE_TEXT; a_variables: JSON_OBJECT)
			-- Add values from `a_variables' to Smarty template `a_template'.
		do
			across
				a_variables as v
			loop
				a_template.set_value (json_value_to_any (v), @v.key.unescaped_string_8)
			end
		end

	json_value_to_any (jv: JSON_VALUE): detachable ANY
			-- Convert JSON value `jv' to a value usable by template engines.
		do
			if attached {JSON_STRING} jv as js then
				Result := js.unescaped_string_8
			elseif attached {JSON_NUMBER} jv as jnum then
				if jnum.is_integer_64 then
					Result := jnum.integer_64_item
				elseif jnum.is_integer_32 then
					Result := jnum.integer_32_item
				else
					Result := jnum.item
				end
			elseif attached {JSON_BOOLEAN} jv as jb then
				Result := jb.item
			elseif attached {JSON_ARRAY} jv as ja then
				Result := ja
			elseif attached {JSON_OBJECT} jv as jo then
				Result := jo
			else
				Result := jv.representation
			end
		end

	utf_8_value (a_value: detachable READABLE_STRING_32): READABLE_STRING_8
			-- Convert `a_value' to UTF-8 string.
		do
			if a_value = Void then
				create {STRING_8} Result.make_empty
			else
				Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_value)
			end
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
