note
	description: "Summary description for {CMS_ADMIN_CLI}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_ADMIN_CLI

inherit
	CMS_MODULE_CLI [CMS_ADMIN_MODULE]
		redefine
			setup_hooks,
			permissions
		end

	CMS_HOOK_AUTO_REGISTER

	CMS_CLI_COMMAND_UTILITY

	SHARED_EXECUTION_ENVIRONMENT

create
	make

feature -- Access		

	permissions: LIST [READABLE_STRING_8]
			-- List of permission ids, used by this module, and declared.
		do
			Result := Precursor
		end

feature -- Hooks configuration

	setup_hooks (a_hooks: CMS_HOOK_CORE_MANAGER)
			-- Module hooks configuration.
		do
			module.setup_hooks (a_hooks)
		end

feature -- Setup

	setup_shell (a_shell: CMS_CLI_SHELL; a_api: CMS_API)
		local
			cmd: CMS_CLI_AGENT_COMMAND
		do
			if not a_api.is_cms_installed then
				create cmd.make ("install", agent install_cms (a_api, ?, ?, ?))
				cmd.set_description ("Install CMS")
				a_shell.register_command (cmd, Current)
			end

			create cmd.make ("info", agent list_info (a_api, ?, ?, ?))
			cmd.set_short_name ('i')
			cmd.set_description ("Display CMS information")
			a_shell.register_command (cmd, Current)

			a_shell.register_command (create {CMS_ADMIN_MODULES_CLI_COMMAND}.make (a_api), Current)
			a_shell.register_command (create {CMS_ADMIN_USERS_CLI_COMMAND}.make (a_api), Current)

			create cmd.make ("cleanup", agent process_cleanup (a_api, ?, ?, ?))
			cmd.set_description ("Process CMS cleanup")
			a_shell.register_command (cmd, Current)
		end

feature -- Execution

	install_cms (api: CMS_API; sh: CMS_CLI_SHELL; n:  READABLE_STRING_32; args: detachable READABLE_STRING_32)
		do
			output_h1 (sh, "Install CMS:%N")
			output_h2 (sh, "Install all modules:%N")
			api.install_all_modules
			output_information (sh, "Installation completed.%N")
		end

	list_info (api: CMS_API; sh: CMS_CLI_SHELL; n:  READABLE_STRING_32; args: detachable READABLE_STRING_32)
		local
			n1, col1, n2, col2: INTEGER
			k: READABLE_STRING_GENERAL
			sp: STRING_8
			l_mailer: NOTIFICATION_MAILER
		do
			output_h1 (sh, "System information:%N")

			across
				api.setup.system_info as v
			loop
				k := @v.key
				col1 := col1.max (k.count)
				col2 := col2.max (v.count)
			end
			across
				api.setup.system_info as v
			loop
				k := @v.key
				n1 := k.count
				n2 := v.count
				sh.output.put_string (" ")
				output_key (sh, k)
--				sh.ansi.set_foreground_color_to_yellow
				if n1 < col1 then
					create sp.make_filled (' ', col1 - n1)
					sh.output.put_string (sp)
				end
				sh.output.put_character (':')
				sh.output.put_character (' ')
--				if n2 < col2 then
--					create sp.make_filled (' ', col2 - n2)
--					sh.output.put_string (sp)
--				end
				sh.output.put_string_general (v)
--				sh.ansi.reset_foreground_color
				sh.output.put_new_line
			end

			output_h1 (sh, "Storage:%N")
			sh.output.put_string ("  ")
			sh.output.put_string_general (api.storage.description)
			sh.output.put_new_line

			output_h1 (sh, "Mailer:%N")
			l_mailer := api.setup.mailer
			from until l_mailer = Void loop
				sh.output.put_string (" -> ")
--				sh.output.put_string (l_mailer.generator)
				if attached {NOTIFICATION_CHAIN_MAILER} l_mailer as l_chain_mailer then
					if attached l_chain_mailer.active as l_active then
						output_key (sh, l_active.generator)
					end
					l_mailer := l_chain_mailer.next
				else
					output_key (sh, l_mailer.generator)
					l_mailer := Void
				end
			end
			sh.output.put_new_line
			if args /= Void and then args.same_string ("all") then
				output_h1 (sh, "Environment:%N")
				output_h2 (sh, "- from setup:%N")
				if attached api.setup.environment_items as l_site_envs then
					across
						l_site_envs as env
					loop
						sh.output.put_string ("  ")
						output_key (sh, @env.key)
						sh.output.put_character (':')
						sh.output.put_character (' ')
						if attached env as v then
							sh.output.put_string_32 (v)
						end
						sh.output.put_new_line
					end
				end
				output_h2 (sh, "- from process:%N")
				if attached execution_environment.starting_environment as l_proc_envs then
					across
						l_proc_envs as env
					loop
						sh.output.put_string ("  ")
						output_key (sh, @env.key)
						sh.output.put_character (':')
						sh.output.put_character (' ')
						sh.output.put_string_32 (env)
						sh.output.put_new_line
					end
				end
			else
				output_help (sh, {STRING_32} "%NUse %""+ n +" all%" to display all available informations...%N")
			end
		end

	process_cleanup (api: CMS_API; sh: CMS_CLI_SHELL; n:  READABLE_STRING_32; args: detachable READABLE_STRING_32)
		local
			ctx: CMS_HOOK_CLEANUP_CONTEXT
		do
			sh.output.put_string ("Invoke clean.%N")
			create ctx.make (Void)
			api.hooks.invoke_cleanup (ctx, Void)
			across
				ctx.logs as log
			loop
				sh.output.put_string (log)
				sh.output.put_new_line
			end
		end

note
	copyright: "2011-2025, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
