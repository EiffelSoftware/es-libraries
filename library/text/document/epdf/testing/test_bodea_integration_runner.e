note
	description: "Dedicated test runner for Bodea Brochure integration tests"

class
	TEST_BODEA_INTEGRATION_RUNNER

create
	make

feature

	make
			-- Run all Bodea Brochure integration tests
		local
			bodea: TEST_BODEA_INTEGRATION
		do
			print ("%N╔════════════════════════════════════════════════════════════╗%N")
			print ("║  Bodea Brochure - Linearized PDF Integration Tests       ║%N")
			print ("╚════════════════════════════════════════════════════════════╝%N%N")
			
			create bodea
			
			print ("Test 1/4: Read/Write Only%N")
			print ("──────────────────────────────────────────────────────────%N")
			bodea.test_read_write_bodea_only
			
			print ("%N%NTest 2/4: Object Loading Verification%N")
			print ("──────────────────────────────────────────────────────────%N")
			bodea.test_object_loading_bodea
			
			print ("%N%NTest 3/4: Encrypt View-Only%N")
			print ("──────────────────────────────────────────────────────────%N")
			bodea.test_encrypt_bodea_view_only
			
			print ("%N%NTest 4/4: Encrypt Print-Only%N")
			print ("──────────────────────────────────────────────────────────%N")
			bodea.test_encrypt_bodea_print_only
			
			print ("%N%N╔════════════════════════════════════════════════════════════╗%N")
			print ("║  ✅ All Bodea Integration Tests Complete                 ║%N")
			print ("╚════════════════════════════════════════════════════════════╝%N")
		end

end
