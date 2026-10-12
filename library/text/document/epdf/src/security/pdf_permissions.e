note
	description: "Represents PDF user access permissions as defined in ISO 32000-1:2008 Table 22."

class
	PDF_PERMISSIONS

create
	make,
	make_all_restricted,
	make_all_permitted

feature -- Initialization

	make (a_flags: INTEGER)
			-- Initialize with specific permission flags (P value from encryption dictionary).
		do
			flags := a_flags
		ensure
			flags_set: flags = a_flags
		end

	make_all_restricted
			-- Initialize with all permissions restricted (except those required to be 1 by spec).
			-- Defaults to -4 (just bit 3, 4, 5, 6... cleared, but top bits set to 1 as per spec usually).
			-- Spec says: "The value of the P entry is an integer... it is interpreted as a 32-bit unsigned integer..."
			-- "If the P entry is not present... the default value is -1 (all bits 1)."
			-- For restricted, we usually set the non-reserved bits we want to restrict to 0.
			-- Bit 1 and 2 are reserved, must be 0.
			-- Bits 7, 8, 13-32 are reserved, must be 1.
		do
				-- Base restricted value: bits 1-2 are 0, bits 3-6 (standard) are 0, bits 7-8 are 1, bits 9-12 (rev 3) are 0.
				-- Reserved bits 13-32 should be 1.
				-- Let's stick to the bits we control.
				-- A common "no permissions" value behaves like -4 or similar depending on revision.
				-- Let's start with a base where user controllable bits are 0 and reserved are 1 where needed.
				-- NOTE: P is signed integer.
				-- Let's initialize to a safe default that respects the reserved flags logic if we were building it up.
				-- For now, let's just use the integer.
			flags := -1 -- Start with all permitted (all 1s)
			disable_print
			disable_modify
			disable_copy
			disable_modify_annotations
			disable_fill_forms
			disable_extract_accessibility
			disable_assemble
			disable_print_high_quality
		end

	make_all_permitted
			-- Initialize with all permissions granted.
		do
			flags := -1 -- All bits set to 1
		ensure
			all_permitted: flags = -1
		end

feature -- Access

	flags: INTEGER
			-- The raw 32-bit signed integer value for the P entry.

	is_print_allowed: BOOLEAN
			-- (Bit 3) Print the document.
		do
			Result := is_bit_set (3)
		end

	is_modify_allowed: BOOLEAN
			-- (Bit 4) Modify the document contents.
		do
			Result := is_bit_set (4)
		end

	is_copy_allowed: BOOLEAN
			-- (Bit 5) Copy or extract text and graphics.
		do
			Result := is_bit_set (5)
		end

	is_modify_annotations_allowed: BOOLEAN
			-- (Bit 6) Add or modify text annotations, fill in interactive form fields.
		do
			Result := is_bit_set (6)
		end

	is_fill_forms_allowed: BOOLEAN
			-- (Bit 9, Rev 3+) Fill in existing interactive form fields (even if Bit 6 is clear).
		do
			Result := is_bit_set (9)
		end

	is_extract_accessibility_allowed: BOOLEAN
			-- (Bit 10, Rev 3+) Extract text and graphics in support of accessibility.
		do
			Result := is_bit_set (10)
		end

	is_assemble_allowed: BOOLEAN
			-- (Bit 11, Rev 3+) Assemble the document (insert, rotate, delete pages).
		do
			Result := is_bit_set (11)
		end

	is_print_high_quality_allowed: BOOLEAN
			-- (Bit 12, Rev 3+) Print the document to a representation from which a faithful digital copy could be generated.
		do
			Result := is_bit_set (12)
		end

feature -- Status Setting

	enable_print
			-- Allow printing.
		do
			set_bit (3)
		ensure
			can_print: is_print_allowed
		end

	disable_print
			-- Disallow printing.
		do
			clear_bit (3)
		ensure
			cannot_print: not is_print_allowed
		end

	enable_modify
			-- Allow modification.
		do
			set_bit (4)
		ensure
			can_modify: is_modify_allowed
		end

	disable_modify
			-- Disallow modification.
		do
			clear_bit (4)
		ensure
			cannot_modify: not is_modify_allowed
		end

	enable_copy
			-- Allow copying/extraction.
		do
			set_bit (5)
		ensure
			can_copy: is_copy_allowed
		end

	disable_copy
			-- Disallow copying/extraction.
		do
			clear_bit (5)
		ensure
			cannot_copy: not is_copy_allowed
		end

	enable_modify_annotations
			-- Allow annotation modification.
		do
			set_bit (6)
		ensure
			can_modify_annotations: is_modify_annotations_allowed
		end

	disable_modify_annotations
			-- Disallow annotation modification.
		do
			clear_bit (6)
		ensure
			cannot_modify_annotations: not is_modify_annotations_allowed
		end

	enable_fill_forms
			-- Allow filling forms.
		do
			set_bit (9)
		ensure
			can_fill_forms: is_fill_forms_allowed
		end

	disable_fill_forms
			-- Disallow filling forms.
		do
			clear_bit (9)
		ensure
			cannot_fill_forms: not is_fill_forms_allowed
		end

	enable_extract_accessibility
			-- Allow accessibility extraction.
		do
			set_bit (10)
		ensure
			can_extract_accessibility: is_extract_accessibility_allowed
		end

	disable_extract_accessibility
			-- Disallow accessibility extraction.
		do
			clear_bit (10)
		ensure
			cannot_extract_accessibility: not is_extract_accessibility_allowed
		end

	enable_assemble
			-- Allow assembly.
		do
			set_bit (11)
		ensure
			can_assemble: is_assemble_allowed
		end

	disable_assemble
			-- Disallow assembly.
		do
			clear_bit (11)
		ensure
			cannot_assemble: not is_assemble_allowed
		end

	enable_print_high_quality
			-- Allow high quality printing.
		do
			set_bit (12)
		ensure
			can_print_high_quality: is_print_high_quality_allowed
		end

	disable_print_high_quality
			-- Disallow high quality printing.
		do
			clear_bit (12)
		ensure
			cannot_print_high_quality: not is_print_high_quality_allowed
		end

feature {NONE} -- Implementation

	is_bit_set (n: INTEGER): BOOLEAN
			-- Is the n-th bit set (1-based index)?
		require
			n_valid: n >= 1 and n <= 32
		do
			-- Eiffel INTEGER is 32-bit signed.
			-- To check bit n, we mask with 1 shifted left by (n-1).
			Result := (flags.bit_and ((1).bit_shift_left (n - 1))) /= 0
		end

	set_bit (n: INTEGER)
			-- Set the n-th bit to 1.
		require
			n_valid: n >= 1 and n <= 32
		do
			flags := flags.bit_or ((1).bit_shift_left (n - 1))
		end

	clear_bit (n: INTEGER)
			-- Set the n-th bit to 0.
		require
			n_valid: n >= 1 and n <= 32
		do
			flags := flags.bit_and (((1).bit_shift_left (n - 1)).bit_not)
		end

invariant
	-- Flags is a 32-bit integer

end
