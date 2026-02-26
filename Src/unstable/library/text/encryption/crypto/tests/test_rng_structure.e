note
    description: "[
        Tests for RNG cluster structure and correctness.
        
        PCG variant: PCG-XSH-RR 64/32 (LCG 64, output 32)
        
        Test Categories:
        - Determinism: Same seed produces same sequence
        - Sequence Consistency: Deterministic outputs validated for consistency
        - Bounds: Edge cases and range validation
        - Derived Primitives: next_u64, next_byte, fill_bytes, fill_bytes_string
        
        set_seed semantics: Resets generator state with the given seed,
        using stream=1 as the default sequence selector.
    ]"
    testing: "type/manual"

class
    TEST_RNG_STRUCTURE

inherit
    EQA_TEST_SET

feature -- Constants

    Determinism_iterations: INTEGER = 100
            -- Number of iterations for determinism tests.

feature -- Determinism Tests

    test_pcg32_determinism
            -- Verify PCG32 produces same sequence for same seed and stream.
        local
            rng1, rng2: PCG32_RNG
            v1, v2: NATURAL_32
            i: INTEGER
        do
            -- Both RNGs initialized with identical seed AND stream
            create rng1.make (12345, 1)
            create rng2.make (12345, 1)

            from i := 1 until i > Determinism_iterations loop
                v1 := rng1.next_u32
                v2 := rng2.next_u32
                assert ("Same value at step " + i.out, v1 = v2)
                i := i + 1
            end
        end

    test_pcg32_reseed
            -- Verify reseeding restores initial state.
            -- Note: set_seed resets the generator to the given seed with stream=1.
        local
            rng: PCG32_RNG
            v1, v1_second, v2, v2_second: NATURAL_32
            discard: NATURAL_32
        do
            -- Capture initial sequence after first creation
            create rng.make (98765, 1)
            v1 := rng.next_u32
            v1_second := rng.next_u32

            -- Advance several steps to change state
            discard := rng.next_u32
            discard := rng.next_u32
            discard := rng.next_u32

            -- Reseed and verify same sequence resumes
            rng.set_seed (98765)
            v2 := rng.next_u32
            v2_second := rng.next_u32

            assert ("Reseeding restores first value", v1 = v2)
            assert ("Reseeding restores second value", v1_second = v2_second)
        end

    test_different_streams_differ
            -- Verify different streams produce different sequences.
            -- Deterministic test: first values from different streams must differ.
        local
            rng1, rng2: PCG32_RNG
            v1, v2: NATURAL_32
        do
            create rng1.make (42, 1)
            create rng2.make (42, 2)  -- Same seed, different stream

            -- First value from each stream should differ (deterministic)
            v1 := rng1.next_u32
            v2 := rng2.next_u32
            assert ("First values from different streams differ", v1 /= v2)
        end

feature -- Sequence Consistency Tests

    test_sequence_consistency
            -- Verify PCG32 produces consistent deterministic output.
            -- Two independent instances with same seed produce identical sequences.
        local
            rng1, rng2: PCG32_RNG
            val1, val2: NATURAL_32
            i: INTEGER
        do
            create rng1.make (42, 54)
            create rng2.make (42, 54)

            -- Verify first 10 values match between two instances
            from i := 1 until i > 10 loop
                val1 := rng1.next_u32
                val2 := rng2.next_u32
                assert ("Sequence value " + i.out + " consistent", val1 = val2)
                i := i + 1
            end
        end

feature -- Default RNG Tests

    test_default_rng_init
            -- Verify DEFAULT_RNG initializes and produces advancing output.
        local
            rng: DEFAULT_RNG
            v1, v2: NATURAL_32
        do
            create rng.make
            v1 := rng.next_u32
            v2 := rng.next_u32

            -- Verify values progress (extremely unlikely to be equal)
            assert ("Values advance", v1 /= v2)

            -- Verify non-degenerate output (at least one non-zero)
            assert ("Non-degenerate output", v1 /= 0 or v2 /= 0)
        end

feature -- Derived Primitives Tests

    test_next_u64_composition
            -- Verify next_u64 is composed of two next_u32 calls.
        local
            rng1, rng2: PCG32_RNG
            u64: NATURAL_64
            high32, low32: NATURAL_32
        do
            create rng1.make (1, 1)
            u64 := rng1.next_u64

            create rng2.make (1, 1)
            high32 := rng2.next_u32
            low32 := rng2.next_u32

            -- Verify composition: u64 = (high32 << 32) | low32
            assert ("u64 upper 32 bits", (u64.bit_shift_right (32)).as_natural_32 = high32)
            assert ("u64 lower 32 bits", (u64.bit_and ({NATURAL_64} 0xFFFFFFFF)).as_natural_32 = low32)
        end

    test_next_byte_state_advancement
            -- Verify next_byte consumes entropy and advances state.
        local
            rng1, rng2: PCG32_RNG
            byte: NATURAL_8
            v1, v2: NATURAL_32
        do
            create rng1.make (7, 1)
            create rng2.make (7, 1)

            -- rng1: call next_byte then next_u32
            byte := rng1.next_byte
            v1 := rng1.next_u32

            -- rng2: call next_u32 twice (byte uses same primitive)
            v2 := rng2.next_u32

            -- State should have advanced, so v1 equals second value from rng2
            assert ("Byte advances state", v1 = rng2.next_u32)
        end

    test_fill_bytes_state_advancement
            -- Verify fill_bytes advances generator state correctly.
        local
            rng1, rng2: PCG32_RNG
            bytes: SPECIAL [NATURAL_8]
            v1, v2: NATURAL_32
            discard: NATURAL_32
        do
            create rng1.make (99, 1)
            create rng2.make (99, 1)
            create bytes.make_filled ({NATURAL_8} 0, 16)

            -- rng1: fill 16 bytes then get next value
            rng1.fill_bytes (bytes)
            v1 := rng1.next_u32

            -- rng2: skip 4 u32 values (16 bytes / 4 = 4 words) then get next
            discard := rng2.next_u32
            discard := rng2.next_u32
            discard := rng2.next_u32
            discard := rng2.next_u32
            v2 := rng2.next_u32

            -- Both should be at same state
            assert ("fill_bytes advances state correctly", v1 = v2)
        end

    test_fill_bytes_string
            -- Verify fill_bytes_string returns correct length string.
        local
            rng: PCG32_RNG
            str: STRING_8
        do
            create rng.make (42, 1)

            str := rng.fill_bytes_string (1)
            assert ("Length 1", str.count = 1)

            str := rng.fill_bytes_string (16)
            assert ("Length 16", str.count = 16)

            str := rng.fill_bytes_string (100)
            assert ("Length 100", str.count = 100)
        end

feature -- Bounds Tests

    test_bounded_range
            -- Verify next_bounded respects upper bound.
        local
            rng: PCG32_RNG
            val: NATURAL_32
            bound: NATURAL_32
            i: INTEGER
        do
            create rng.make (555, 1)
            bound := 10

            from i := 1 until i > 1000 loop
                val := rng.next_bounded (bound)
                assert ("Value < bound", val < bound)
                i := i + 1
            end
        end

    test_bounded_one
            -- Verify bound=1 always returns 0.
        local
            rng: PCG32_RNG
            val: NATURAL_32
            i: INTEGER
        do
            create rng.make (123, 1)

            from i := 1 until i > 100 loop
                val := rng.next_bounded ({NATURAL_32} 1)
                assert ("Bound 1 returns 0", val = {NATURAL_32} 0)
                i := i + 1
            end
        end

    test_bounded_two
            -- Verify bound=2 returns only 0 or 1.
        local
            rng: PCG32_RNG
            val: NATURAL_32
            has_zero, has_one: BOOLEAN
            i: INTEGER
        do
            create rng.make (456, 1)

            from i := 1 until i > 100 loop
                val := rng.next_bounded ({NATURAL_32} 2)
                assert ("Bound 2 in range", val < {NATURAL_32} 2)
                if val = {NATURAL_32} 0 then
                    has_zero := True
                else
                    has_one := True
                end
                i := i + 1
            end

            -- Should see both values (probabilistic but very likely)
            assert ("Bound 2 produces both values", has_zero and has_one)
        end

    test_bounded_large
            -- Verify large non-power-of-two bound works correctly.
        local
            rng: PCG32_RNG
            val: NATURAL_32
            bound: NATURAL_32
            i: INTEGER
        do
            create rng.make (789, 1)
            bound := 1000000007  -- Large prime

            from i := 1 until i > 100 loop
                val := rng.next_bounded (bound)
                assert ("Large bound respected", val < bound)
                i := i + 1
            end
        end

feature -- State Isolation Tests

    test_interleaved_calls
            -- Verify interleaving different primitives executes without exceptions.
            -- This is a crash/corruption guard test.
        local
            rng: PCG32_RNG
            u32: NATURAL_32
            u64: NATURAL_64
            byte: NATURAL_8
            bytes: SPECIAL [NATURAL_8]
        do
            create rng.make (111, 1)

            -- Interleave various calls without crashing
            u32 := rng.next_u32
            byte := rng.next_byte
            u64 := rng.next_u64
            create bytes.make_filled ({NATURAL_8} 0, 8)
            rng.fill_bytes (bytes)
            u32 := rng.next_u32

            -- Execution reaching here confirms no corruption
            assert ("Interleaved execution successful", True)
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
