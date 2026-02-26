note
    description: "Abstract interface for Random Number Generators."
    date: "2026-01-20"
    revision: "$Revision$"
    EIS: "name=Secure Random Generators", "src=https://github.com/nakov/Practical-Cryptography-for-Developers-Book/tree/master/secure-random-generators", "protocol=uri"

deferred class
    RNG

feature -- Core primitive

    next_u32: NATURAL_32
            -- Next 32-bit random number.
        deferred
        ensure
            result_exists: True -- Range is full 32-bit integer space
        end

feature -- Derived primitives

    next_byte: NATURAL_8
            -- Next random byte.
        do
            -- Extract low byte from 32-bit random
            Result := (next_u32.bit_and ({NATURAL_32} 0xFF)).as_natural_8
        end

    next_u64: NATURAL_64
            -- Next 64-bit random number.
        do
            Result := (next_u32.as_natural_64.bit_shift_left (32)).bit_or (next_u32.as_natural_64)
        end

    fill_bytes (a_buffer: SPECIAL [NATURAL_8])
            -- Fill `a_buffer` with random bytes.
        require
            a_buffer_not_void: a_buffer /= Void
        local
            i, count, full_words: INTEGER
            word: NATURAL_32
        do
            count := a_buffer.count
            full_words := count // 4
            from i := 0 until i >= full_words loop
                word := next_u32
                a_buffer [i * 4] := (word.bit_and ({NATURAL_32} 0xFF)).as_natural_8
                a_buffer [i * 4 + 1] := ((word.bit_shift_right (8)).bit_and ({NATURAL_32} 0xFF)).as_natural_8
                a_buffer [i * 4 + 2] := ((word.bit_shift_right (16)).bit_and ({NATURAL_32} 0xFF)).as_natural_8
                a_buffer [i * 4 + 3] := ((word.bit_shift_right (24)).bit_and ({NATURAL_32} 0xFF)).as_natural_8
                i := i + 1
            end
            -- Handle remaining bytes
            if count \\ 4 > 0 then
                word := next_u32
                from i := full_words * 4 until i >= count loop
                    a_buffer [i] := (word.bit_and ({NATURAL_32} 0xFF)).as_natural_8
                    word := word.bit_shift_right (8)
                    i := i + 1
                end
            end
        end

    next_bounded (a_bound: NATURAL_32): NATURAL_32
            -- Random number in [0, `a_bound`), uniformly distributed.
        require
            positive_bound: a_bound > 0
        local
            threshold: NATURAL_32
        do
            -- threshold = (2^32 - a_bound) % a_bound
            -- equivalent to (-a_bound) % a_bound in 32-bit arithmetic
            threshold := ({NATURAL_32} 0 - a_bound) \\ a_bound

            from Result := next_u32 until Result >= threshold loop
                Result := next_u32
            end
            Result := Result \\ a_bound
        ensure
            in_range: Result < a_bound
        end

    fill_bytes_string (a_count: INTEGER): STRING_8
            -- `a_count` random bytes as STRING_8.
        require
            positive_count: a_count > 0
        local
            l_special: SPECIAL [NATURAL_8]
            l_result: STRING_8
            i: INTEGER
        do
            create l_result.make (a_count)
            l_result.fill_character ('%U')

            -- Use fill_bytes on a temporary SPECIAL and copy
            create l_special.make_filled ({NATURAL_8} 0, a_count)
            fill_bytes (l_special)

            from i := 0 until i >= a_count loop
                l_result.put_code (l_special [i].to_natural_32, i + 1)
                i := i + 1
            end

            Result := l_result
        ensure
            correct_length: Result.count = a_count
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
