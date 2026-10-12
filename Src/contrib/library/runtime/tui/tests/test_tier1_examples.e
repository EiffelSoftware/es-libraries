note
	description: "[
		Automated test suite verifying all 7 Tier 1 Foundation examples
		execute cleanly in batch / headless mode without raising exceptions,
		and properly restore the terminal environment.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TIER1_EXAMPLES

inherit
	EQA_TEST_SET

feature -- Test: Hello World

	test_example_hello_world
			-- Verify EXAMPLE_HELLO_WORLD runs in batch mode without error.
		local
			l_app: EXAMPLE_HELLO_WORLD
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Minimal

	test_example_minimal
			-- Verify EXAMPLE_MINIMAL runs in batch mode without error.
		local
			l_app: EXAMPLE_MINIMAL
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Colors RGB

	test_example_colors_rgb
			-- Verify EXAMPLE_COLORS_RGB runs in batch mode without error.
		local
			l_app: EXAMPLE_COLORS_RGB
		do
			create l_app.make_batch (2)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Color Explorer

	test_example_color_explorer
			-- Verify EXAMPLE_COLOR_EXPLORER runs in batch mode without error.
		local
			l_app: EXAMPLE_COLOR_EXPLORER
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Modifiers

	test_example_modifiers
			-- Verify EXAMPLE_MODIFIERS runs in batch mode without error.
		local
			l_app: EXAMPLE_MODIFIERS
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Popup

	test_example_popup
			-- Verify EXAMPLE_POPUP runs in batch mode without error.
		local
			l_app: EXAMPLE_POPUP
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Inline

	test_example_inline
			-- Verify EXAMPLE_INLINE runs in batch mode without error.
		local
			l_app: EXAMPLE_INLINE
		do
			create l_app.make_batch (2)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

end
