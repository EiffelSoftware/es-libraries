note
	description: "Model offered by a provider, as listed by it."
	date: "$Date$"
	revision: "$Revision$"

class
	AI_MODEL

create
	make

feature {NONE} -- Initialization

	make (a_provider_name, a_id: READABLE_STRING_GENERAL)
			-- Model `a_id' of the provider named `a_provider_name'.
		require
			a_id_not_empty: not a_id.is_empty
		do
			provider_name := a_provider_name.to_string_32
			id := a_id.to_string_32
			display_name := id
		end

feature -- Access

	provider_name: STRING_32
			-- Name of the provider (see {AI_PROVIDER_SETTINGS}.name)

	id: STRING_32
			-- Identifier of the model, used in the requests

	display_name: STRING_32
			-- Name to show

	context_size: INTEGER
			-- Number of input tokens the model accepts (0 if not known)

	output_limit: INTEGER
			-- Maximum number of output tokens (0 if not known)

	full_name: STRING_32
			-- "provider/id"
		do
			Result := provider_name + {STRING_32} "/" + id
		end

feature -- Element change

	set_display_name (s: READABLE_STRING_GENERAL)
			-- Set `display_name' to `s'.
		do
			display_name := s.to_string_32
		end

	set_context_size (n: INTEGER)
			-- Set `context_size' to `n'.
		require
			n_non_negative: n >= 0
		do
			context_size := n
		end

	set_output_limit (n: INTEGER)
			-- Set `output_limit' to `n'.
		require
			n_non_negative: n >= 0
		do
			output_limit := n
		end

invariant
	id_not_empty: not id.is_empty

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
