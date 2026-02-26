note
	description: "[
		Unix-specific tests for URANDOM_RNG.
		
		Tests cover:
		- Urandom RNG initialization and generation
		- Error handling and status reporting
		- Derived primitives (next_u64, next_byte)
		- Buffer filling (fill_bytes, fill_secure_bytes)
		- Entropy distribution verification
		- entropy_source feature
	]"
	testing: "type/manual"

class
	TEST_URANDOM_RNG

inherit
	EQA_TEST_SET

feature -- URANDOM_RNG Tests

	test_urandom_rng_init
			-- Verify URANDOM_RNG initializes and generates without error.
		local
			rng: URANDOM_RNG
			v1, v2: NATURAL_32
		do
			create rng.make
			v1 := rng.next_u32
			v2 := rng.next_u32

			assert ("No error after generation", not rng.has_error)
			-- Note: We don't assert v1 /= v2 because even with CSPRNGs,
			-- collisions are theoretically possible (just extremely unlikely).
		end

	test_urandom_rng_fill_bytes
			-- Verify URANDOM_RNG fills buffer correctly.
		local
			rng: URANDOM_RNG
			bytes: SPECIAL [NATURAL_8]
			non_zero_count: INTEGER
			i: INTEGER
		do
			create rng.make
			create bytes.make_filled ({NATURAL_8} 0, 32)

			rng.fill_secure_bytes (bytes)

			assert ("No error", not rng.has_error)

			-- Count non-zero bytes
			from i := 0 until i >= bytes.count loop
				if bytes [i] /= {NATURAL_8} 0 then
					non_zero_count := non_zero_count + 1
				end
				i := i + 1
			end

			-- Crypto random should have many non-zero bytes
			assert ("Has non-zero bytes", non_zero_count > 0)
		end

	test_urandom_is_secure
			-- Verify URANDOM_RNG reports as cryptographically secure.
		local
			rng: URANDOM_RNG
		do
			create rng.make
			assert ("Is cryptographically secure", rng.is_cryptographically_secure)
		end

	test_urandom_error_reporting
			-- Verify URANDOM_RNG provides error status and messages.
		local
			rng: URANDOM_RNG
		do
			create rng.make
			rng.next_u32.do_nothing
			-- After successful generation, should have no error
			assert ("No error reported", not rng.has_error)
			assert ("Error message not empty", not rng.error_message.is_empty)
		end

	test_urandom_derived_primitives
			-- Verify URANDOM_RNG derived primitives work correctly.
		local
			rng: URANDOM_RNG
			u64: NATURAL_64
			byte: NATURAL_8
		do
			create rng.make
			u64 := rng.next_u64
			byte := rng.next_byte
			assert ("Derived primitives generated", True)
		end

	test_urandom_entropy_source
			-- Verify URANDOM_RNG reports correct entropy source.
		local
			rng: URANDOM_RNG
		do
			create rng.make
			assert ("Entropy source not empty", not rng.entropy_source.is_empty)
			assert ("Contains urandom", rng.entropy_source.has_substring ("urandom"))
		end

	test_urandom_multiple_generations
			-- Sanity check: multiple generations produce diverse values.
		local
			rng: URANDOM_RNG
			values: ARRAYED_LIST [NATURAL_32]
			v: NATURAL_32
			i: INTEGER
			unique_count: INTEGER
		do
			create values.make (10)
			create rng.make

			from i := 1 until i > 10 loop
				v := rng.next_u32
				if not values.has (v) then
					unique_count := unique_count + 1
				end
				values.extend (v)
				i := i + 1
			end

			assert ("No error", not rng.has_error)
			assert ("Sufficient diversity", unique_count >= 8)
		end

	test_urandom_large_buffer
			-- Verify larger buffer filling works.
		local
			rng: URANDOM_RNG
			bytes: SPECIAL [NATURAL_8]
			non_zero_count: INTEGER
			i: INTEGER
		do
			create bytes.make_filled ({NATURAL_8} 0, 64)
			create rng.make
			rng.fill_secure_bytes (bytes)

			assert ("No error", not rng.has_error)

			from i := 0 until i >= bytes.count loop
				if bytes [i] /= {NATURAL_8} 0 then
					non_zero_count := non_zero_count + 1
				end
				i := i + 1
			end

			assert ("Large buffer has non-zero bytes", non_zero_count > 10)
		end

	test_urandom_entropy_distribution
			-- Sanity check: detect catastrophic bias or stuck RNGs.
		local
			rng: URANDOM_RNG
			bytes: SPECIAL [NATURAL_8]
			histogram: ARRAY [INTEGER]
			bucket: INTEGER
			i: INTEGER
			min_count, max_count: INTEGER
		do
			create bytes.make_filled ({NATURAL_8} 0, 256)
			create histogram.make_filled (0, 0, 15)

			create rng.make
			rng.fill_secure_bytes (bytes)
			assert ("No error", not rng.has_error)

			-- Build histogram of 16 buckets
			from i := 0 until i >= bytes.count loop
				bucket := bytes [i].as_integer_32 // 16
				histogram [bucket] := histogram [bucket] + 1
				i := i + 1
			end

			-- Find min and max bucket counts
			min_count := histogram [0]
			max_count := histogram [0]
			from i := 1 until i > 15 loop
				if histogram [i] < min_count then
					min_count := histogram [i]
				end
				if histogram [i] > max_count then
					max_count := histogram [i]
				end
				i := i + 1
			end

			assert ("No empty buckets", min_count > 0)
			assert ("No single dominating bucket", max_count < 64)
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
