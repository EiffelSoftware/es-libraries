note
	description: "Convert a Markdown file into CommonMark XML AST (http://commonmark.org/xml/1.0)."

class
	MD2AST

inherit
	ARGUMENTS_32

create
	make

feature {NONE} -- Initialization

	make
			-- Entry point.
		local
			in_path, out_path: PATH
			md: STRING_8
			xml: STRING_8
		do
			if argument_count /= 2 then
				print_usage
			else
				create in_path.make_from_string (argument (1))
				create out_path.make_from_string (argument (2))

				md := text_from_file (in_path)
				if md.is_empty then
					io.error.put_string ("[ERROR] Empty or unreadable input file: " + in_path.utf_8_name + "%N")
				else
					xml := ast_xml_from_markdown (md)
					save_text_to (xml, out_path)
				end
			end
		end

feature {NONE} -- Implementation

	print_usage
		do
			print ("usage: md2ast <input.md> <output.xml>%N")
		end

	ast_xml_from_markdown (a_markdown: READABLE_STRING_8): STRING_8
			-- CommonMark XML AST (1.0) for `a_markdown`.
		require
			a_markdown_attached: a_markdown /= Void
		local
			t: MD_CONTENT_TEXT
		do
			create t.make_from_string (a_markdown)
			create Result.make_empty
			t.document.process (create {MD_AST_GENERATOR}.make (Result))
		ensure
			result_attached: Result /= Void
		end

	text_from_file (fn: PATH): STRING_8
			-- Content of file `fn` as STRING_8 (read as-is).
		local
			f: PLAIN_TEXT_FILE
		do
			create f.make_with_path (fn)
			if f.exists and then f.is_access_readable then
				f.open_read
				from
					create Result.make (1_024)
				until
					f.exhausted
				loop
					f.read_stream_thread_aware (1_024)
					Result.append (f.last_string)
				end
				f.close
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	save_text_to (s: READABLE_STRING_8; fn: PATH)
			-- Save `s` into `fn`.
		require
			s_attached: s /= Void
			fn_attached: fn /= Void
		local
			f: PLAIN_TEXT_FILE
		do
			create f.make_with_path (fn)
			if not f.exists or else f.is_access_writable then
				f.set_utf8_encoding
				f.create_read_write
				f.put_string (s)
				f.close
				io.error.put_string ("Saved XML to file " + fn.utf_8_name + "%N")
			else
				io.error.put_string ("[ERROR] could not save to file: " + fn.utf_8_name + "%N")
			end
		end

end
