note
	description: "Convert a Markdown file into an HTML file (XHTML fragment wrapped in a minimal HTML document)."

class
	MD2HTML

inherit
	SHARED_EXECUTION_ENVIRONMENT

	ARGUMENTS_32

create
	make

feature {NONE} -- Initialization

	make
			-- Entry point.
		local
			in_path, out_path: PATH
			md: STRING_8
			html: STRING_8
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
					html := html_document (md, in_path)
					save_text_to (html, out_path)
				end
			end
		end

feature {NONE} -- Implementation

	print_usage
		do
			print ("usage: md2html <input.md> <output.html>%N")
		end

	html_document (a_markdown: READABLE_STRING_8; a_input: PATH): STRING_8
			-- Minimal HTML document containing the XHTML rendering of `a_markdown`.
		require
			a_markdown_attached: a_markdown /= Void
			a_input_attached: a_input /= Void
		local
			t: MD_CONTENT_TEXT
			body: STRING_8
			title: STRING_8
		do
			create t.make_from_string (a_markdown)
			create body.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (body))

			if attached a_input.entry as e then
				title := e.utf_8_name
			else
				title := "Markdown"
			end

			create Result.make (body.count + 256)
			Result.append ("<!DOCTYPE html>%N")
			Result.append ("<html>%N<head>%N")
			Result.append ("%T<meta charset=%"utf-8%"/>%N")
			Result.append ("%T<title>")
			append_html_escaped_to (title, Result)
			Result.append ("</title>%N")
			Result.append ("%T<link rel=%"stylesheet%" href=%"md.css%"/>%N")
			Result.append ("</head>%N<body>%N")
			Result.append ("%T<article class=%"markdown-body%">%N")
			Result.append (body)
			Result.append ("%T</article>%N")
			Result.append ("</body>%N</html>%N")
		ensure
			result_attached: Result /= Void
		end

	append_html_escaped_to (s: READABLE_STRING_8; a_output: STRING_8)
			-- Append HTML-escaped `s` into `a_output`.
		require
			s_attached: s /= Void
			a_output_attached: a_output /= Void
		local
			i, n: INTEGER
			c: CHARACTER
		do
			from
				i := 1
				n := s.count
			until
				i > n
			loop
				c := s [i]
				inspect c
				when '<' then
					a_output.append ("&lt;")
				when '>' then
					a_output.append ("&gt;")
				when '&' then
					a_output.append ("&amp;")
				when '%"' then
					a_output.append ("&quot;")
				else
					a_output.append_character (c)
				end
				i := i + 1
			end
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
				io.error.put_string ("Saved HTML to file " + fn.utf_8_name + "%N")
			else
				io.error.put_string ("[ERROR] could not save to file: " + fn.utf_8_name + "%N")
			end
		end

end

