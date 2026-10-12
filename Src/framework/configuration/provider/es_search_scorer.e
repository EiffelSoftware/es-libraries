note
	description: "[
			Scorer for search relevance.
		]"
	author: "$Author$"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	ES_SEARCH_SCORER [G]

feature -- Access

	scored_list (a_query: READABLE_STRING_GENERAL; a_items: LIST [G]; a_keep_all: BOOLEAN): LIST [SCORED_VALUE [G]]
			-- Score `a_items' thanks to `a_query'.
			-- If `a_keep_all' is True, also keep items which don't matched.
		require
			a_query_attached: a_query /= Void
			a_items_attached: a_items /= Void
		deferred
		end

	sorted_scored_list (a_query: READABLE_STRING_GENERAL; a_items: LIST [G]; a_keep_all: BOOLEAN): LIST [SCORED_VALUE [G]]
			-- Score `a_items' thanks to `a_query', and return scored items sorted by score.
			-- If `a_keep_all' is True, also keep items which don't matched.
		require
			a_query_attached: a_query /= Void
			a_items_attached: a_items /= Void
		do
			Result := scored_list (a_query, a_items, a_keep_all)
			sorter.sort (Result)
		end

	sorter: SORTER [SCORED_VALUE [G]]
		do
			create {QUICK_SORTER [SCORED_VALUE [G]]} Result.make (create {SCORED_VALUE_COMPARATOR [G]})
		end

feature -- Status report

	is_strict: BOOLEAN
			-- Is matching strict?
			-- If False, any searched text is considered as "*text*".
			-- If True, no wildcard is added automatically, and a text without wildcard
			-- has to match an entire word.

feature -- Settings

	set_is_strict (b: BOOLEAN)
			-- Set `is_strict' to `b'.
		do
			is_strict := b
		ensure
			is_strict_set: is_strict = b
		end

feature {NONE} -- Implementation

	meet_text (a_text: detachable READABLE_STRING_GENERAL; s: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_text' match `s', according to `is_strict'?
		local
			kmp: KMP_WILD
			tok: READABLE_STRING_GENERAL
			tok_len: INTEGER
			l_lower_text: READABLE_STRING_GENERAL
			c: CHARACTER_32
			i: INTEGER
		do
			if a_text /= Void then
				if s.has ('*') or s.has ('?') then
					if is_strict then
						create kmp.make (s, a_text)
					else
						create kmp.make (wildcarded (s), a_text)
					end
					kmp.disable_case_sensitive
					Result := kmp.pattern_matches
				elseif not is_strict then
					Result := a_text.as_lower.substring_index (s.as_lower, 1) > 0
				else
					from
						l_lower_text := a_text.as_lower
						tok := s.as_lower
						tok_len := tok.count
						i := 1
					until
						i = 0 or Result
					loop
						i := l_lower_text.substring_index (tok, i)
						if i > 0 then
							Result := True
							if i > 1 then
									-- Check lower boundary
								c := l_lower_text [i - 1]
								if c.is_alpha_numeric then
									Result := False
								end
							end
							if Result and i + tok_len <= l_lower_text.count then
									-- Check upper boundary
								c := l_lower_text [i + tok_len]
								if c.is_alpha_numeric then
									Result := False
								end
							end
							if not Result then
								i := i + 1
							end
						end
					end
				end
			end
		end

	fallback_pattern (a_query: READABLE_STRING_GENERAL): STRING_32
			-- Wildcard pattern for `a_query', used when it is not a valid criteria expression.
		do
			create Result.make_from_string_general (a_query)
			Result.adjust
			if Result.is_empty or not is_strict then
				Result := wildcarded (Result)
			end
		end

	wildcarded (s: READABLE_STRING_GENERAL): STRING_32
			-- `s' surrounded by '*' wildcards (i.e "*s*").
		do
			create Result.make_from_string_general (s)
			if Result.is_empty or else Result [1] /= '*' then
				Result.prepend_character ('*')
			end
			if Result [Result.count] /= '*' then
				Result.append_character ('*')
			end
		ensure
			starts_with_wildcard: Result.starts_with ("*")
			ends_with_wildcard: Result.ends_with ("*")
		end

note
	copyright: "Copyright (c) 1984-2016, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
