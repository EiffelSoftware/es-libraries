note
	date: "$Date$"
	revision: "$Revision$"

class
	ES_IRON_PACKAGE_SCORER

inherit
	ES_SEARCH_SCORER [IRON_PACKAGE]

feature -- Conversion

	scored_list (a_query: READABLE_STRING_GENERAL; a_packages: LIST [IRON_PACKAGE]; a_keep_all: BOOLEAN): LIST [SCORED_VALUE [IRON_PACKAGE]]
		local
			l_filter_engine: detachable KMP_WILD
			f: STRING_32
		do
			if a_packages.is_empty then
				create {ARRAYED_LIST [SCORED_VALUE [IRON_PACKAGE]]} Result.make (0)
			elseif
				attached scores_factory.criteria_from_string (a_query) as l_score
			then
					-- Using SCORE Criteria
				Result := l_score.scores (a_packages, a_packages.count)
			else
				create {ARRAYED_LIST [SCORED_VALUE [IRON_PACKAGE]]} Result.make (a_packages.count)
					-- Using simple wildchar comparison.
				f := fallback_pattern (a_query)
				create l_filter_engine.make_empty
				l_filter_engine.set_pattern (f)
				l_filter_engine.disable_case_sensitive
				across
					a_packages as p
				loop
					l_filter_engine.set_text (p.identifier)
					if l_filter_engine.pattern_matches then
						Result.force (create {SCORED_VALUE [IRON_PACKAGE]}.make (p, 1.0))
					elseif a_keep_all then
						Result.force (create {SCORED_VALUE [IRON_PACKAGE]}.make (p, 0.0))
					end
				end
			end
		end

	name_weight: REAL = 0.3
	title_weight: REAL = 0.25
	description_weight: REAL = 0.20
	tag_weight: REAL = 0.25
	category_weight: REAL = 0.25
	any_weight: REAL
		do
			Result := name_weight + title_weight + tag_weight + description_weight
		end

	scores_factory: SCORER_CRITERIA_FACTORY [IRON_PACKAGE]
			-- Factory, with criteria associated with Current scorer (see `is_strict').
		once ("OBJECT")
			create Result.make
			Result.register_builder ("name", agent (n, v: READABLE_STRING_32): detachable SCORER_CRITERIA [IRON_PACKAGE]
						do
							create {SCORER_CRITERIA_AGENT [IRON_PACKAGE]} Result.make (n + ":" + v, name_weight, agent score_name (?, v))
						end
				)
			Result.register_builder ("title", agent (n, v: READABLE_STRING_32): detachable SCORER_CRITERIA [IRON_PACKAGE]
						do
							create {SCORER_CRITERIA_AGENT [IRON_PACKAGE]} Result.make (n + ":" + v, title_weight, agent score_title (?, v))
						end
				)
			Result.register_builder ("description", agent (n, v: READABLE_STRING_32): detachable SCORER_CRITERIA [IRON_PACKAGE]
						do
							create {SCORER_CRITERIA_AGENT [IRON_PACKAGE]} Result.make (n + ":" + v, description_weight, agent score_description (?, v))
						end
				)
			Result.register_builder ("tag", agent (n, v: READABLE_STRING_32): detachable SCORER_CRITERIA [IRON_PACKAGE]
						do
							create {SCORER_CRITERIA_AGENT [IRON_PACKAGE]} Result.make (n + ":" + v, tag_weight, agent score_tag (?, v))
						end
				)
			Result.register_builder ("category", agent (n, v: READABLE_STRING_32): detachable SCORER_CRITERIA [IRON_PACKAGE]
						do
							create {SCORER_CRITERIA_AGENT [IRON_PACKAGE]} Result.make (n + ":" + v, category_weight, agent score_category (?, v))
						end
				)
			Result.register_builder ("any", agent (n, v: READABLE_STRING_32): detachable SCORER_CRITERIA [IRON_PACKAGE]
						do
							create {SCORER_CRITERIA_AGENT [IRON_PACKAGE]} Result.make (n + ":" + v, any_weight, agent score_any (?, v))
						end
				)
			Result.register_default_builder ("any")
		end

	meet_any (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := meet_name (obj, s)
				or meet_title (obj, s)
				or meet_tag (obj, s)
		end

	meet_name (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := meet_text (obj.identifier, s)
		end

	meet_title (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := meet_text (obj.title, s)
		end

	meet_description (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := meet_text (obj.description, s)
		end

	meet_tag (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := ∃ ic: obj.tags ¦ meet_text (ic, s)
		end

	meet_category (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := meet_text (obj.category, s)
		end

	score_any (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): REAL
		do
			Result := score_name (obj, s) * name_weight
				+ score_title (obj, s) * title_weight
				+ score_tag (obj, s) * tag_weight
				+ score_description (obj, s) * description_weight
		end

	score_name (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): REAL
		do
			Result := if meet_name (obj, s) then 1.0 else 0.0 end
		end

	score_title (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): REAL
		do
			Result := if meet_title (obj, s) then 1.0 else 0.0 end
		end

	score_description (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): REAL
		do
			Result := if meet_description (obj, s) then 1.0 else 0.0 end
		end

	score_tag (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): REAL
		do
			Result := if meet_tag (obj, s) then 1.0 else 0.0 end
		end

	score_category (obj: IRON_PACKAGE; s: READABLE_STRING_GENERAL): REAL
		do
			Result := if meet_category (obj, s) then 1.0 else 0.0 end
		end

note
	copyright: "Copyright (c) 1984-2021, Eiffel Software"
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
