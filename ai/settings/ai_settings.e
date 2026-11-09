note
	description: "[
		Settings of the AI access of a user: the providers, and the model chosen. Kept in a JSON
		file (see `load', `save'):
			{"providers": [{"name": "anthropic", "kind": "anthropic", "url": "https://api.anthropic.com",
				"key_variable": "ANTHROPIC_API_KEY"}, ...],
			 "model": {"provider": "anthropic", "id": "claude-opus-5-5"}}
		A provider may also have a "key" (better kept in the environment variable).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_SETTINGS

inherit
	AI_JSON_HELPER

create
	make_default

feature {NONE} -- Initialization

	make_default
			-- The usual providers: Anthropic, OpenAI, NVIDIA, OpenRouter (keys in their usual environment
			-- variables), Ollama and llama.app (local), with Claude Opus 5.5 as the model.
		do
			create providers.make (4)
			reset_to_default
		end

feature -- Access

	providers: ARRAYED_LIST [AI_PROVIDER_SETTINGS]
			-- Providers

	model_provider: detachable STRING_32
			-- Name of the provider of the model chosen, if any

	model_id: detachable STRING_32
			-- Identifier of the model chosen, if any

	provider_named (a_name: READABLE_STRING_GENERAL): detachable AI_PROVIDER_SETTINGS
			-- Provider named `a_name', if any
		do
			⟳ p: providers ¦
				if Result = Void and then p.name.is_case_insensitive_equal_general (a_name) then
					Result := p
				end
			⟲
		end

	last_error: detachable STRING_32
			-- Error of the last `load' or `save', if any

	keeps_transcripts: BOOLEAN
			-- Are transcripts of the conversations kept?

feature -- Element change

	reset_to_default
			-- Forget the settings: the usual providers.
		do
			providers.wipe_out
			providers.extend (create {AI_PROVIDER_SETTINGS}.make ("anthropic", {AI_PROVIDER_SETTINGS}.Kind_anthropic, "https://api.anthropic.com", "ANTHROPIC_API_KEY"))
			providers.extend (create {AI_PROVIDER_SETTINGS}.make ("openai", {AI_PROVIDER_SETTINGS}.Kind_openai, "https://api.openai.com", "OPENAI_API_KEY"))
			providers.extend (create {AI_PROVIDER_SETTINGS}.make ("nvidia", {AI_PROVIDER_SETTINGS}.Kind_openai, "https://integrate.api.nvidia.com", "NVIDIA_API_KEY"))
			providers.extend (create {AI_PROVIDER_SETTINGS}.make ("openrouter", {AI_PROVIDER_SETTINGS}.Kind_openai, "https://openrouter.ai/api/v1", "OPENROUTER_API_KEY"))
			providers.extend (create {AI_PROVIDER_SETTINGS}.make ("ollama", {AI_PROVIDER_SETTINGS}.Kind_ollama, "http://localhost:11434", Void))
			providers.extend (create {AI_PROVIDER_SETTINGS}.make ("llama.app", {AI_PROVIDER_SETTINGS}.Kind_openai, "http://localhost:9931", Void))
			model_provider := {STRING_32} "anthropic"
			model_id := {STRING_32} "claude-opus-5-5"
			keeps_transcripts := True
		end

	set_keeps_transcripts (b: BOOLEAN)
			-- Set `keeps_transcripts' to `b'.
		do
			keeps_transcripts := b
		ensure
			set: keeps_transcripts = b
		end

	put_provider (p: AI_PROVIDER_SETTINGS)
			-- Add `p', replacing the provider of the same name if any.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > providers.count or else providers [i].name.is_case_insensitive_equal (p.name)
			loop
				i := i + 1
			end
			if i <= providers.count then
				providers [i] := p
			else
				providers.extend (p)
			end
		ensure
			has: provider_named (p.name) = p
		end

	remove_provider (a_name: READABLE_STRING_GENERAL)
			-- Remove the provider named `a_name' (and the model chosen, if of this provider).
		local
			i: INTEGER
		do
			from
				i := providers.count
			until
				i < 1
			loop
				if providers [i].name.is_case_insensitive_equal_general (a_name) then
					providers.go_i_th (i)
					providers.remove
				end
				i := i - 1
			end
			if attached model_provider as mp and then mp.is_case_insensitive_equal_general (a_name) then
				model_provider := Void
				model_id := Void
			end
		ensure
			removed: provider_named (a_name) = Void
		end

	set_model (a_provider, a_id: READABLE_STRING_GENERAL)
			-- Choose model `a_id' of provider `a_provider'.
		require
			a_id_not_empty: not a_id.is_empty
		do
			model_provider := a_provider.to_string_32
			model_id := a_id.to_string_32
		end

feature -- Persistence

	load (a_path: PATH)
			-- Read the settings kept in file `a_path' (the default ones if there is no such file).
		local
			f: PLAIN_TEXT_FILE
			l_content: STRING_8
			l_settings: AI_PROVIDER_SETTINGS
			retried: BOOLEAN
		do
			last_error := Void
			if not retried then
				create f.make_with_path (a_path)
				if f.exists and then f.is_readable then
					f.open_read
					create l_content.make (f.count)
					if f.count > 0 then
						f.read_stream (f.count)
						l_content.append (f.last_string)
					end
					f.close
					if attached parsed_json_object (l_content) as o then
						providers.wipe_out
						model_provider := Void
						model_id := Void
						if attached array_item (o, "providers") as l_providers then
							⟳ p: l_providers ¦
								if
									attached string_item (p, "name") as n and then not n.is_empty and then
									attached string_item (p, "kind") as k and then
									(k.same_string_general ({AI_PROVIDER_SETTINGS}.Kind_anthropic) or k.same_string_general ({AI_PROVIDER_SETTINGS}.Kind_openai) or k.same_string_general ({AI_PROVIDER_SETTINGS}.Kind_ollama)) and then
									attached string_item (p, "url") as u
								then
									create l_settings.make (n, k.to_string_8, utf_8 (u), string_item (p, "key_variable"))
									l_settings.set_key (string_item (p, "key"))
									put_provider (l_settings)
								end
							⟲
						end
						keeps_transcripts := not attached {JSON_BOOLEAN} o.item ("transcripts") as t or else t.item
						if attached object_item (o, "model") as m and then attached string_item (m, "provider") as mp and then attached string_item (m, "id") as l_id and then not l_id.is_empty then
							set_model (mp, l_id)
						end
					else
						last_error := {STRING_32} "Invalid settings in " + a_path.name
					end
				end
			else
				last_error := {STRING_32} "Cannot read " + a_path.name
			end
		rescue
			retried := True
			if attached f as l_file and then not l_file.is_closed then
				l_file.close
			end
			retry
		end

	save (a_path: PATH)
			-- Write the settings into file `a_path' (readable by its owner only if it holds a key).
		local
			f: PLAIN_TEXT_FILE
			o, p, m: JSON_OBJECT
			l_providers: JSON_ARRAY
			l_has_key: BOOLEAN
			retried: BOOLEAN
		do
			last_error := Void
			if not retried then
				create o.make_with_capacity (3)
				create l_providers.make (providers.count)
				⟳ s: providers ¦
					create p.make_with_capacity (5)
					p.put_string (s.name, "name")
					p.put_string (s.kind, "kind")
					p.put_string (s.url, "url")
					if attached s.key_variable as v then
						p.put_string (v, "key_variable")
					end
					if attached s.key as k then
						p.put_string (k, "key")
						l_has_key := True
					end
					l_providers.extend (p)
				⟲
				o.put (l_providers, "providers")
				o.put_boolean (keeps_transcripts, "transcripts")
				if attached model_provider as mp and then attached model_id as l_id then
					create m.make_with_capacity (2)
					m.put_string (mp, "provider")
					m.put_string (l_id, "id")
					o.put (m, "model")
				end
				create f.make_with_path (a_path)
				f.open_write
				if l_has_key and not {PLATFORM}.is_windows then
					f.change_mode (0c600)
				end
				f.put_string (o.representation)
				f.put_new_line
				f.close
			else
				last_error := {STRING_32} "Cannot write " + a_path.name
			end
		rescue
			retried := True
			if attached f as l_file and then not l_file.is_closed then
				l_file.close
			end
			retry
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
