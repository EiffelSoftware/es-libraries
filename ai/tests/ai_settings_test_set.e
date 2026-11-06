note
	description: "Tests of the settings of the providers and of the model."
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	AI_SETTINGS_TEST_SET

inherit
	EQA_TEST_SET

feature -- Tests

	test_default
			-- The usual providers, and Claude Opus 5.5.
		local
			s: AI_SETTINGS
		do
			create s.make_default
			assert ("four", s.providers.count = 4)
			assert ("anthropic", attached s.provider_named ("Anthropic") as p and then p.kind.same_string ({AI_PROVIDER_SETTINGS}.Kind_anthropic))
			assert ("nvidia", attached s.provider_named ("nvidia") as p and then p.kind.same_string ({AI_PROVIDER_SETTINGS}.Kind_openai))
			assert ("ollama without key", attached s.provider_named ("ollama") as p and then (not p.needs_key and p.is_usable))
			assert ("model", s.model_provider ~ {STRING_32} "anthropic" and s.model_id ~ {STRING_32} "claude-opus-5-5")
		end

	test_change
			-- Add, replace and remove providers.
		local
			s: AI_SETTINGS
			p: AI_PROVIDER_SETTINGS
		do
			create s.make_default
			create p.make ("local", {AI_PROVIDER_SETTINGS}.Kind_openai, "http://localhost:8080", Void)
			s.put_provider (p)
			assert ("added", s.providers.count = 5 and s.provider_named ("LOCAL") = p)
			assert ("local server without key", not p.needs_key)
			create p.make ("local", {AI_PROVIDER_SETTINGS}.Kind_openai, "http://localhost:1234", Void)
			s.put_provider (p)
			assert ("replaced", s.providers.count = 5 and s.provider_named ("local") = p)
			s.remove_provider ("anthropic")
			assert ("removed", s.provider_named ("anthropic") = Void)
			assert ("model forgotten", s.model_id = Void)
		end

	test_api_key
			-- The key of the environment variable comes first.
		local
			p: AI_PROVIDER_SETTINGS
			env: EXECUTION_ENVIRONMENT
		do
			create env
			create p.make ("x", {AI_PROVIDER_SETTINGS}.Kind_anthropic, "https://api.anthropic.com", "ES_AI_TEST_KEY")
			env.put ("", "ES_AI_TEST_KEY")
			assert ("not usable", not p.is_usable)
			p.set_key ("kept")
			assert ("kept key", p.api_key ~ {STRING_32} "kept")
			env.put ("from-env", "ES_AI_TEST_KEY")
			assert ("environment", p.api_key ~ {STRING_32} "from-env")
			assert ("usable", p.is_usable)
		end

	test_save_and_load
			-- What is saved is loaded back.
		local
			s, l: AI_SETTINGS
			p: AI_PROVIDER_SETTINGS
			l_path: PATH
			f: RAW_FILE
		do
			l_path := (create {EXECUTION_ENVIRONMENT}).current_working_path.extended ("ai_settings_test.json")
			create s.make_default
			s.remove_provider ("openai")
			create p.make ({STRING_32} "local é", {AI_PROVIDER_SETTINGS}.Kind_openai, "http://localhost:8080/v1", Void)
			p.set_key ("secret")
			s.put_provider (p)
			s.set_model ({STRING_32} "local é", "qwen3")
			s.save (l_path)
			assert ("saved", s.last_error = Void)
			create f.make_with_path (l_path)
			assert ("exists", f.exists)
			if not {PLATFORM}.is_windows then
				assert ("owner only", f.protection & 0c077 = 0)
			end
			create l.make_default
			l.load (l_path)
			assert ("loaded", l.last_error = Void)
			assert ("same count", l.providers.count = s.providers.count)
			assert ("no openai", l.provider_named ("openai") = Void)
			if attached l.provider_named ({STRING_32} "local é") as lp then
				assert ("url", lp.url.same_string ("http://localhost:8080/v1"))
				assert ("key", lp.key ~ {STRING_32} "secret")
				assert ("no variable", lp.key_variable = Void)
			else
				assert ("local", False)
			end
			assert ("variable", attached l.provider_named ("nvidia") as n and then n.key_variable ~ {STRING_32} "NVIDIA_API_KEY")
			assert ("model", l.model_provider ~ {STRING_32} "local é" and l.model_id ~ {STRING_32} "qwen3")
			f.delete
		end

	test_load_invalid
			-- Invalid file: error, settings unchanged; no file: unchanged, no error.
		local
			s: AI_SETTINGS
			l_path: PATH
			f: PLAIN_TEXT_FILE
		do
			l_path := (create {EXECUTION_ENVIRONMENT}).current_working_path.extended ("ai_settings_invalid.json")
			create f.make_with_path (l_path)
			f.create_read_write
			f.put_string ("{not json")
			f.close
			create s.make_default
			s.load (l_path)
			assert ("error", s.last_error /= Void)
			assert ("unchanged", s.providers.count = 4)
			f.delete
			s.load (l_path)
			assert ("no error", s.last_error = Void)
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
