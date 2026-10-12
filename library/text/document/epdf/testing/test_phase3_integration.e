note
	description: "[
		Integration test for Phase 3: Modifier.
		Demonstrates footer injection on a real PDF document.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PHASE3_INTEGRATION

inherit
	EQA_TEST_SET

feature -- Test

	test_footer_injection_workflow
			-- Test complete footer injection workflow.
		local
			service: PDF_FOOTER_SERVICE
			doc: PDF_DOCUMENT
			page: PDF_DICTIONARY
			media_box: PDF_ARRAY
		do
			create service.make
			create doc.make
			create page.make_empty

				-- Set up page with MediaBox
			create media_box.make (4)
			media_box.add_number (0)
			media_box.add_number (0)
			media_box.add_number (612)
			media_box.add_number (792)
			page.put (media_box, "MediaBox")
			page.put_name ("Page", "Type")

				-- Add footer
			service.add_footer_to_page (doc, page, "page1", "Page 1 of 10")

				-- Verify results
			assert ("page has resources", page.has_key ("Resources"))
			assert ("page has contents", page.has_key ("Contents"))
		end

end
