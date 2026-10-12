note
	description: "Test PDF permissions flag management."

class
	TEST_SECURITY_PERMISSIONS

inherit
	EQA_TEST_SET

feature -- Tests

	test_all_permitted
			-- Test all permissions granted.
		local
			perms: PDF_PERMISSIONS
		do
			create perms.make_all_permitted
			assert ("print allowed", perms.is_print_allowed)
			assert ("modify allowed", perms.is_modify_allowed)
			assert ("copy allowed", perms.is_copy_allowed)
			assert ("modify annotations allowed", perms.is_modify_annotations_allowed)
		end

	test_all_restricted
			-- Test all permissions denied.
		local
			perms: PDF_PERMISSIONS
		do
			create perms.make_all_restricted
			assert ("print disallowed", not perms.is_print_allowed)
			assert ("modify disallowed", not perms.is_modify_allowed)
			assert ("copy disallowed", not perms.is_copy_allowed)
		end

	test_selective_permissions
			-- Test enabling/disabling individual permissions.
		local
			perms: PDF_PERMISSIONS
		do
			create perms.make_all_restricted
			
			-- Enable only printing
			perms.enable_print
			assert ("print enabled", perms.is_print_allowed)
			assert ("modify still disabled", not perms.is_modify_allowed)
			
			-- Enable copying
			perms.enable_copy
			assert ("copy enabled", perms.is_copy_allowed)
			assert ("print still enabled", perms.is_print_allowed)
			
			-- Disable printing
			perms.disable_print
			assert ("print disabled", not perms.is_print_allowed)
			assert ("copy still enabled", perms.is_copy_allowed)
		end

	test_flags_integer_value
			-- Test raw flags value.
		local
			perms: PDF_PERMISSIONS
		do
			create perms.make (-1)
			assert ("flags set to -1", perms.flags = -1)
			
			create perms.make (0)
			assert ("flags set to 0", perms.flags = 0)
		end

end
