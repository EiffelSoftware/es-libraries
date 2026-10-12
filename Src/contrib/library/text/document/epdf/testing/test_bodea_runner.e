note
	description: "Standalone test runner specifically for Bodea Brochure tests"

class
	TEST_BODEA_RUNNER

create
	make

feature

	make
			-- Run all Bodea Brochure tests
		local
			bodea: TEST_BODEA_BROCHURE
		do
			print ("%N╔════════════════════════════════════════════════════╗%N")
			print ("║  Bodea Brochure - Linearized PDF Test Suite      ║%N")
			print ("╚════════════════════════════════════════════════════╝%N%N")
			
			create bodea
			
			print ("📄 Test 1: Read Bodea Brochure%N")
			print ("─────────────────────────────────────────────────────%N")
			bodea.test_read_bodea_brochure
			
			print ("%N%N📊 Test 2: Analyze Structure%N")
			print ("─────────────────────────────────────────────────────%N")
			bodea.test_analyze_bodea_structure
			
			print ("%N%N💾 Test 3: Write Bodea Brochure%N")
			print ("─────────────────────────────────────────────────────%N")
			bodea.test_write_bodea_brochure
			
			print ("%N%N╔════════════════════════════════════════════════════╗%N")
			print ("║  ✅ All Bodea Brochure Tests Complete            ║%N")
			print ("╚════════════════════════════════════════════════════╝%N")
		end

end
