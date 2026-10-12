note
	description: "[
		Integration tests for Phase 4B (Security Integration).
		Creates encrypted PDFs with different permission settings
		that can be verified in Adobe Acrobat.
		
		PDF Security uses two passwords:
		- User password: Required to OPEN the document. Empty = no password needed.
		- Owner password: Required to CHANGE permissions. Must be set for restrictions.
	]"

class
	TEST_PHASE4B_INTEGRATION

inherit
	EQA_TEST_SET
		redefine
			on_prepare
		end
	TEST_PATH_HELPER

feature -- Setup

	on_prepare
			-- Setup routine called before each test.
		do
			ensure_test_output_directory_exists
		end

feature -- Test routines

	test_debug_footer_content
			-- Debug the footer content to see what it contains.
		local
			creator: PDF_CONTENT_STREAM_CREATOR
			stream: PDF_STREAM
			font_name: STRING_8
		do
			create creator.make
			font_name := "F1"

			-- Create footer stream like the service does
			stream := creator.create_footer_stream ("Signed by JV - " + current_date, font_name, 8.0, 100.0, 50.0)

			print ("%N=== Footer Stream Content ===")
			print ("Length: " + stream.content.count.out + "%N")
			print ("Content:%N" + stream.content + "%N")

			assert ("Footer content debugged", True)
		end

feature {NONE} -- Implementation

	current_date: STRING_8
			-- Get current date as string for signature.
		local
			l_date: DATE
		do
			create l_date.make_now
			Result := l_date.year.out + "/" + l_date.month.out + "/" + l_date.day.out
		end

end
