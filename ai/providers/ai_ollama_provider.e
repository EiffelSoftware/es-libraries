note
	description: "[
		Ollama (local models): the models installed are listed by its own API (GET /api/tags); the
		conversations go through its OpenAI-compatible API (POST /v1/chat/completions).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_OLLAMA_PROVIDER

inherit
	AI_OPENAI_PROVIDER
		redefine
			models_request,
			models
		end

create
	make

feature -- Requests

	models_request: AI_HTTP_REQUEST
			-- <Precursor>
		do
			create Result.make_get (base_url, "/api/tags")
		end

feature -- Answers

	models (a_body: READABLE_STRING_8): ARRAYED_LIST [AI_MODEL]
			-- <Precursor>
		do
			create Result.make (10)
			if attached array_item (parsed_json (a_body), "models") as l_models then
				⟳ d: l_models ¦
					if attached string_item (d, "name") as l_name and then not l_name.is_empty then
						Result.extend (create {AI_MODEL}.make (name, l_name))
					end
				⟲
			end
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
