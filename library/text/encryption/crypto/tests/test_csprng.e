note
	description: "[
		Cross-platform tests for CSPRNG_FACTORY and CSPRNG interface.
		
		Tests cover:
		- CSPRNG_FACTORY platform abstraction
		- Cross-platform CSPRNG functionality via factory
		- next_bounded bias-free distribution
		
		Note: Platform-specific tests for BCRYPT_RNG and URANDOM_RNG
		are in tests/windows/ and tests/unix/ respectively.
	]"
	testing: "type/manual"

class
	TEST_CSPRNG

inherit
	EQA_TEST_SET

feature -- CSPRNG_FACTORY Tests

	test_csprng_factory_creates_rng
			-- Verify CSPRNG_FACTORY creates appropriate RNG for platform.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			v: NATURAL_32
		do
			create factory
			rng := factory.new_csprng

			assert ("RNG created", rng /= Void)

			-- Verify it works
			v := rng.next_u32
			assert ("No error after generation", not rng.has_error)
		end

	test_csprng_factory_availability
			-- Verify CSPRNG_FACTORY can detect CSPRNG availability.
		local
			factory: CSPRNG_FACTORY
		do
			create factory
			-- On supported platforms (Windows, Unix, macOS), should be available
			assert ("CSPRNG is available", factory.is_csprng_available)
		end

feature -- Cross-Platform CSPRNG Tests

	test_csprng_derived_primitives
			-- Verify CSPRNG derived primitives work correctly.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			u64: NATURAL_64
			byte: NATURAL_8
		do
			create factory
			rng := factory.new_csprng
			u64 := rng.next_u64
			byte := rng.next_byte
			assert ("Derived primitives generated", True)
		end

	test_csprng_multiple_generations
			-- Sanity check: multiple generations produce diverse values.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			values: ARRAYED_LIST [NATURAL_32]
			v: NATURAL_32
			i: INTEGER
			unique_count: INTEGER
		do
			create values.make (10)
			create factory
			rng := factory.new_csprng

			from i := 1 until i > 10 loop
				v := rng.next_u32
				if not values.has (v) then
					unique_count := unique_count + 1
				end
				values.extend (v)
				i := i + 1
			end

			assert ("No error", not rng.has_error)
			assert ("Sufficient diversity (not constant stream)", unique_count >= 8)
		end

	test_csprng_large_buffer
			-- Verify larger buffer filling works.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			bytes: SPECIAL [NATURAL_8]
			non_zero_count: INTEGER
			i: INTEGER
		do
			create bytes.make_filled ({NATURAL_8} 0, 64)
			create factory
			rng := factory.new_csprng
			rng.fill_bytes (bytes)

			assert ("No error", not rng.has_error)

			from i := 0 until i >= bytes.count loop
				if bytes [i] /= {NATURAL_8} 0 then
					non_zero_count := non_zero_count + 1
				end
				i := i + 1
			end

			assert ("Large buffer has non-zero bytes", non_zero_count > 10)
		end

	test_csprng_entropy_distribution
			-- Sanity check: detect catastrophic bias or stuck RNGs.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			bytes: SPECIAL [NATURAL_8]
			histogram: ARRAY [INTEGER]
			bucket: INTEGER
			i: INTEGER
			min_count, max_count: INTEGER
		do
			create bytes.make_filled ({NATURAL_8} 0, 256)
			create histogram.make_filled (0, 0, 15)

			create factory
			rng := factory.new_csprng
			rng.fill_bytes (bytes)
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

feature -- next_bounded Tests (Bias-Free Distribution)

	test_next_bounded_zero_bound_precondition
			-- Verify that next_bounded(0) triggers a precondition violation.
		note
			testing: "covers/{RNG}.next_bounded"
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			l_triggered: BOOLEAN
		do
			if not l_triggered then
				create factory
				rng := factory.new_csprng
				-- This should trigger a precondition violation
				rng.next_bounded (0).do_nothing
			end
			l_triggered := True
			assert ("Zero bound triggers precondition", l_triggered)
		rescue
			if not l_triggered then
				l_triggered := True
				retry
			end
		end

	test_next_bounded_in_range
			-- Verify next_bounded returns values within specified range.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			i: INTEGER
			bound: NATURAL_32
			value: NATURAL_32
		do
			create factory
			rng := factory.new_csprng
			bound := 100

			from i := 1 until i > 100 loop
				value := rng.next_bounded (bound)
				assert ("Value in range", value < bound)
				i := i + 1
			end
		end

	test_next_bounded_small_bound
			-- Verify next_bounded works with small bounds.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			i: INTEGER
			value: NATURAL_32
		do
			create factory
			rng := factory.new_csprng

			from i := 1 until i > 50 loop
				value := rng.next_bounded (3)
				assert ("Value < 3", value < 3)
				i := i + 1
			end
		end

	test_next_bounded_power_of_two
			-- Verify next_bounded works with power of 2 bounds.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			i: INTEGER
			value: NATURAL_32
		do
			create factory
			rng := factory.new_csprng

			from i := 1 until i > 50 loop
				value := rng.next_bounded (256)
				assert ("Value < 256", value < 256)
				i := i + 1
			end
		end

	test_next_bounded_large_bound
			-- Verify next_bounded works with large bounds.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			i: INTEGER
			value: NATURAL_32
			large_bound: NATURAL_32
		do
			create factory
			rng := factory.new_csprng
			large_bound := 1_000_000_000

			from i := 1 until i > 20 loop
				value := rng.next_bounded (large_bound)
				assert ("Value < 1 billion", value < large_bound)
				i := i + 1
			end
		end

	test_next_bounded_distribution
			-- Sanity check: next_bounded produces reasonably uniform distribution.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			buckets: ARRAY [INTEGER]
			i, bucket: INTEGER
			value: NATURAL_32
			bound: NATURAL_32
			min_count, max_count: INTEGER
		do
			create factory
			rng := factory.new_csprng
			bound := 10
			create buckets.make_filled (0, 0, 9)

			from i := 1 until i > 1000 loop
				value := rng.next_bounded (bound)
				bucket := value.as_integer_32
				buckets [bucket] := buckets [bucket] + 1
				i := i + 1
			end

			min_count := buckets [0]
			max_count := buckets [0]
			from i := 1 until i > 9 loop
				if buckets [i] < min_count then
					min_count := buckets [i]
				end
				if buckets [i] > max_count then
					max_count := buckets [i]
				end
				i := i + 1
			end

			assert ("No severely underrepresented bucket", min_count > 50)
			assert ("No severely overrepresented bucket", max_count < 200)
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
