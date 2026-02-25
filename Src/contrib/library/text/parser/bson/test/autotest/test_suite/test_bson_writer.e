note
	description: "Summary description for {TEST_BSON_WRITER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_BSON_WRITER

inherit
	EQA_TEST_SET

feature -- Tests	

	test_hello_world
		local
			w: BSON_WRITER_TO_BYTES
			doc: BSON_DOCUMENT
			exp: ARRAY [NATURAL_8]
			exp_s8: STRING_8
			s: STRING_8
			b: BOOLEAN
			i: INTEGER
			p: BSON_PARSER
		do
			s := "{%"hello%": %"world%"}"
			create doc.make_with_capacity (1)
			doc.put_string ("world", "hello")
			create w.make
			if attached w.to_bytes (doc) as l_bytes then
				exp := <<
						0x16,0x0,0x0,0x0,
						0x2, 0x68,0x65,0x6C,0x6C,0x6F, 0x0,
						0x6,0x0,0x0,0x0, 0x77,0x6F, 0x72, 0x6C, 0x64, 0x0,
						0x0
					>>
				b := exp.count = l_bytes.count
				from
					i := 1
				until
					i > exp.count or not b
				loop
					if exp [i] /= l_bytes [i] then
						b := False
					end
					i := i + 1
				end
				assert("expected bson bytes", b)

				create p.make
				if attached p.parse (l_bytes) as rdoc then
					assert ("same doc", rdoc.count = doc.count)
				end
				assert ("no error", not p.has_error)
			end
			if attached w.to_string (doc) as l_str then
				exp_s8 := "%/0x16/%/0x0/%/0x0/%/0x0/%/0x2/%/0x68/%/0x65/%/0x6C/%/0x6C/%/0x6F/%/0x0/%/0x6/%/0x0/%/0x0/%/0x0/%/0x77/%/0x6F/%/0x72/%/0x6C/%/0x64/%/0x0/%/0x0/"
				assert ("expected bson string", l_str.same_string(exp_s8))
			end


		end

end
