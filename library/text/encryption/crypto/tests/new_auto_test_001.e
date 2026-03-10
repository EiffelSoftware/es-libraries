note
	description: "Generated tests created by AutoTest."
	author: "Testing tool"

class
	NEW_AUTO_TEST_001
	
inherit
	EQA_GENERATED_TEST_SET

feature -- Test routines

	generated_test_1
		note
			testing: "type/generated"
			testing: "covers/{EQA_TEST_OUTPUT_BUFFER}.make"
		local
			v_2: INTEGER_32
			v_3: EQA_TEST_OUTPUT_BUFFER
		do
			v_2 := {INTEGER_32} -3

				-- Final routine call
			set_is_recovery_enabled (False)
			execute_safe (agent (a_arg1: INTEGER_32): EQA_TEST_OUTPUT_BUFFER
				do
					create {EQA_TEST_OUTPUT_BUFFER} Result.make (a_arg1)
				end (v_2))
			check attached {EQA_TEST_OUTPUT_BUFFER} last_object as l_ot1 then
				v_3 := l_ot1
			end
		end

end

