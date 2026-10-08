note
	description: "Tests for library search scorers (strict and non-strict matching, category)."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_LIBRARY_SEARCH_SCORER

inherit
	EQA_TEST_SET

feature -- Tests

	test_non_strict_matches_anywhere
		local
			sc: ES_CONF_SYSTEM_VIEW_SCORER
			lst: like views
		do
			lst := views
			create sc
			assert ("not strict by default", not sc.is_strict)
			assert ("net found in network and eiffelnet", same_names (sc.scored_list ("net", lst, False), <<"eiffelnet", "network">>))
			assert ("case insensitive", same_names (sc.scored_list ("NET", lst, False), <<"eiffelnet", "network">>))
			assert ("typed wildcard still wrapped", same_names (sc.scored_list ("net*", lst, False), <<"eiffelnet", "network">>))
		end

	test_strict_matches_entire_word
		local
			sc: ES_CONF_SYSTEM_VIEW_SCORER
			lst: like views
		do
			lst := views
			create sc
			sc.set_is_strict (True)
			assert ("net is a word only in eiffelnet title", same_names (sc.scored_list ("net", lst, False), <<"eiffelnet">>))
			assert ("typed wildcard used as is", same_names (sc.scored_list ("net*", lst, False), <<"network">>))
			assert ("typed wildcards on both sides", same_names (sc.scored_list ("*net*", lst, False), <<"eiffelnet", "network">>))
		end

	test_category_criteria
		local
			sc: ES_CONF_SYSTEM_VIEW_SCORER
			lst: like views
		do
			lst := views
			create sc
			assert ("official", same_names (sc.scored_list ("category:official", lst, False), <<"base", "eiffelnet">>))
			assert ("contrib", same_names (sc.scored_list ("category:contrib", lst, False), <<"network">>))
			assert ("combined", same_names (sc.scored_list ("category:official net", lst, False), <<"eiffelnet">>))
			sc.set_is_strict (True)
			assert ("strict official", same_names (sc.scored_list ("category:official", lst, False), <<"base", "eiffelnet">>))
			assert ("strict partial category", sc.scored_list ("category:offic", lst, False).is_empty)
		end

	test_empty_query
		local
			sc: ES_CONF_SYSTEM_VIEW_SCORER
			lst: like views
		do
			lst := views
			create sc
			assert ("empty query keeps all", sc.scored_list ("", lst, False).count = lst.count)
			sc.set_is_strict (True)
			assert ("empty strict query keeps all", sc.scored_list ("", lst, False).count = lst.count)
		end

	test_strict_setting_per_scorer
			-- The criteria factory is per scorer object (once per object).
		local
			sc1, sc2: ES_CONF_SYSTEM_VIEW_SCORER
			lst: like views
		do
			lst := views
			create sc1
			create sc2
			sc2.set_is_strict (True)
			assert ("sc1 used first", sc1.scored_list ("net", lst, False).count = 2)
			assert ("sc2 strict", sc2.scored_list ("net", lst, False).count = 1)
		end

	test_provider_service_strict
		local
			m: ES_LIBRARY_PROVIDER_SERVICE
			p: ES_LIBRARY_LOCAL_PROVIDER
		do
			create m.make (1)
			m.set_is_strict (True)
			create p
			m.register (p)
			assert ("registered provider is strict", p.is_strict)
			m.set_is_strict (False)
			assert ("provider updated", not p.is_strict)
		end

	test_category_from_path
		local
			cats: ES_LIBRARY_CATEGORIES
			r: PATH
		do
			create cats
			create r.make_from_string ("ise_root")
			assert ("official", same_string (cats.category_from_path_in (create {PATH}.make_from_string ("$ISE_LIBRARY\library\base\base.ecf"), r), cats.official))
			assert ("C_library", same_string (cats.category_from_path_in (r.extended ("C_library").extended ("zlib").extended ("zlib.ecf"), r), cats.official))
			assert ("contrib", same_string (cats.category_from_path_in (create {PATH}.make_from_string ("$ISE_LIBRARY/contrib/library/text/parser/json/library/json.ecf"), r), cats.contrib))
			assert ("prerelease", same_string (cats.category_from_path_in (create {PATH}.make_from_string ("${ISE_LIBRARY}\unstable\library\base2\base2.ecf"), r), cats.prerelease))
			assert ("framework", cats.category_from_path_in (r.extended ("framework").extended ("environment").extended ("environment.ecf"), r) = Void)
			assert ("experimental", cats.category_from_path_in (create {PATH}.make_from_string ("$ISE_LIBRARY\experimental\library\base\base.ecf"), r) = Void)
			assert ("outside root", cats.category_from_path_in (create {PATH}.make_from_string ("elsewhere/library/foo/foo.ecf"), r) = Void)
		end

	test_precompile_system_name
		local
			cats: ES_LIBRARY_CATEGORIES
		do
			create cats
			assert ("precomp_base-safe", cats.is_precompile_system_name ("precomp_base-safe"))
			assert ("case insensitive", cats.is_precompile_system_name ("Precomp_vision2"))
			assert ("prefix only", not cats.is_precompile_system_name ("precomp_"))
			assert ("library", not cats.is_precompile_system_name ("base"))
			assert ("not prefix", not cats.is_precompile_system_name ("my_precomp_lib"))
			assert ("known category", across cats.predefined_categories as ic some ic.same_string (cats.precompiled) end)
		end

feature {NONE} -- Implementation

	views: ARRAYED_LIST [CONF_SYSTEM_VIEW]
			-- Fake library views.
		do
			create Result.make (3)
			Result.extend (new_view ("base", "EiffelBase", "kernel,structure", "official"))
			Result.extend (new_view ("eiffelnet", "Eiffel Net", "socket,network", "official"))
			Result.extend (new_view ("network", "Networking", "http", "contrib"))
		end

	new_view (a_name, a_title, a_tags, a_category: READABLE_STRING_32): CONF_SYSTEM_VIEW
		do
			create Result.make (create {PATH}.make_from_string ("does-not-exist/" + a_name + ".ecf"), a_name)
			Result.set_info (a_name, "_name")
			Result.set_title (a_title)
			Result.set_info (a_tags, "tags")
			Result.set_info (a_category, "category")
		end

	same_names (a_scores: LIST [SCORED_VALUE [CONF_SYSTEM_VIEW]]; a_expected: ARRAY [READABLE_STRING_32]): BOOLEAN
			-- Do `a_scores' contain exactly the views named `a_expected'?
		do
			Result := a_scores.count = a_expected.count and then
				across a_expected as e all
					across a_scores as s some attached s.value.info ("_name") as n and then n.same_string (e) end
				end
		end

	same_string (a: detachable READABLE_STRING_GENERAL; b: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := a /= Void and then a.same_string (b)
		end

end
