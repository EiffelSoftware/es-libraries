note
	description: "Tests for EV_CLIPBOARD"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_EV_CLIPBOARD

inherit
	EV_VISION2_TEST_SET

	EQA_TEST_SET

feature -- Test routines

	test_text_is_neither_image_nor_files
			-- A text in the clipboard is not taken for an image or for files.
		note
			testing: "execution/isolated"
		do
			run_test (agent
				do
					if attached application as l_application then
						l_application.clipboard.set_text ("file:///tmp/not_a_file.png")
						assert ("text", l_application.clipboard.has_text)
						assert ("no image", not l_application.clipboard.has_image)
						assert ("image void", l_application.clipboard.image = Void)
						assert ("no files", not l_application.clipboard.has_files)
						assert ("files empty", l_application.clipboard.files.is_empty)
					else
						assert ("An application should be running", False)
					end
				end)
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
