note
	description: "Creation of the provider of some settings, according to their kind."
	date: "$Date$"
	revision: "$Revision$"

class
	AI_PROVIDER_FACTORY

feature -- Factory

	new_provider (a_settings: AI_PROVIDER_SETTINGS): AI_PROVIDER
			-- Provider of `a_settings'
		do
			if a_settings.kind.same_string (a_settings.Kind_anthropic) then
				create {AI_ANTHROPIC_PROVIDER} Result.make (a_settings)
			elseif a_settings.kind.same_string (a_settings.Kind_ollama) then
				create {AI_OLLAMA_PROVIDER} Result.make (a_settings)
			else
				create {AI_OPENAI_PROVIDER} Result.make (a_settings)
			end
		ensure
			same_settings: Result.settings = a_settings
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
