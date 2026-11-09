note
	description: "[
		Settings of a provider: its name, kind (protocol), base URL, and its API key, read from an
		environment variable (`key_variable') or, if given, from the settings themselves (`key').
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_PROVIDER_SETTINGS

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL; a_kind: READABLE_STRING_8; a_url: READABLE_STRING_8; a_key_variable: detachable READABLE_STRING_GENERAL)
			-- Provider `a_name' of kind `a_kind' (see `Kind_*') at `a_url', whose key is in the environment
			-- variable `a_key_variable' (if any).
		require
			a_name_not_empty: not a_name.is_empty
			valid_kind: is_valid_kind (a_kind)
		do
			name := a_name.to_string_32
			kind := a_kind.to_string_8
			url := a_url.to_string_8
			if a_key_variable /= Void and then not a_key_variable.is_empty then
				key_variable := a_key_variable.to_string_32
			end
		end

feature -- Access

	name: STRING_32
			-- Name of the provider (unique among the settings)

	kind: STRING_8
			-- Protocol of the provider (see `Kind_*')

	url: STRING_8
			-- Base URL, e.g. "https://api.anthropic.com"

	key_variable: detachable STRING_32
			-- Name of the environment variable holding the API key, if any

	key: detachable STRING_32
			-- API key kept in the settings, if any (used when `key_variable' is not set)

	api_key: detachable STRING_32
			-- API key to use: the value of `key_variable', or `key'
		do
			if attached key_variable as v and then attached (create {EXECUTION_ENVIRONMENT}).item (v) as l_value and then not l_value.is_empty then
				Result := l_value
			elseif attached key as k and then not k.is_empty then
				Result := k
			end
		end

feature -- Status report

	is_valid_kind (a_kind: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_kind' a kind of provider?
		do
			Result := a_kind.same_string (Kind_anthropic) or a_kind.same_string (Kind_openai) or a_kind.same_string (Kind_ollama)
		ensure
			class
		end

	needs_key: BOOLEAN
			-- Does the provider need an API key? (Not Ollama, nor a local server without `key_variable'.)
		do
			Result := kind.same_string (Kind_anthropic) or else (kind.same_string (Kind_openai) and key_variable /= Void)
		end

	is_local: BOOLEAN
			-- Is the provider on this machine (`url' on localhost)? Nothing sent to it leaves the machine.
		local
			l_host: STRING_8
			i: INTEGER
		do
			l_host := url.as_lower
			i := l_host.substring_index ("://", 1)
			if i > 0 then
				l_host.remove_head (i + 2)
			end
			if l_host.starts_with ("[") then
				i := l_host.index_of (']', 1)
				if i > 0 then
					l_host := l_host.substring (2, i - 1)
				end
			else
				i := l_host.index_of ('/', 1)
				if i > 0 then
					l_host.keep_head (i - 1)
				end
				i := l_host.index_of (':', 1)
				if i > 0 then
					l_host.keep_head (i - 1)
				end
			end
			Result := l_host.same_string ("localhost") or l_host.starts_with ("127.") or l_host.same_string ("::1")
		end

	is_usable: BOOLEAN
			-- Can requests be sent (an API key when needed)?
		do
			Result := not needs_key or else api_key /= Void
		end

feature -- Element change

	set_key (k: detachable READABLE_STRING_GENERAL)
			-- Set `key' to `k'.
		do
			if k = Void or else k.is_empty then
				key := Void
			else
				key := k.to_string_32
			end
		end

feature -- Kinds

	Kind_anthropic: STRING = "anthropic"
			-- Anthropic Messages API

	Kind_openai: STRING = "openai"
			-- OpenAI Chat Completions API, and the servers compatible with it

	Kind_ollama: STRING = "ollama"
			-- Ollama (models listed by its own API, chat through its OpenAI-compatible API)

invariant
	name_not_empty: not name.is_empty
	valid_kind: is_valid_kind (kind)

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
