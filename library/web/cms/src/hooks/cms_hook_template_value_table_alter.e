note
	description: "[
			Hook providing a way to alter the value table for a template.
		]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CMS_HOOK_TEMPLATE_VALUE_TABLE_ALTER

inherit
	CMS_HOOK

feature -- Hook

	template_value_table_alter (a_template_id: READABLE_STRING_GENERAL; a_value: CMS_VALUE_TABLE; a_origin_module: detachable TYPE [CMS_MODULE])
		deferred
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
