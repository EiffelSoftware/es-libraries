note
	description: "Debug test to investigate hello_world.pdf loading"

class
	TEST_PDF_DEBUG

inherit
	EQA_TEST_SET
	TEST_PATH_HELPER

feature -- Test

	test_debug_pdf_loading
			-- Debug PDF loading step by step.
		local
			file: RAW_FILE
			content: STRING
			source: PDF_STRING_BYTE_SOURCE
			doc: PDF_DOCUMENT
			pdf_path: PATH
		do
			pdf_path := test_pdf_path ("hello_world.pdf")
			create file.make_open_read (pdf_path.name)
			if file.exists and then file.is_readable then
				file.read_stream (file.count)
				content := file.last_string.twin
				file.close

				print ("%N=== PDF Content Size: " + content.count.out + " bytes ===%N")

				create source.make (content)
				create doc.make_from_source (source)

				print ("Version: " + doc.version + "%N")
				
				if attached doc.trailer as t then
					print ("Trailer exists%N")
					print ("Trailer size: " + t.size.out + "%N")
					if attached t.root as r then
						print ("Root exists: " + r.object_id.object_number.out + " " + r.object_id.generation.out + " R%N")
					else
						print ("Root is VOID%N")
					end
					print ("Trailer is_valid: " + t.is_valid.out + "%N")
				else
					print ("Trailer is VOID%N")
				end

				print ("Document is_loaded: " + doc.is_loaded.out + "%N")
				
				-- Print xref table contents
				print ("XRef table count: " + doc.xref_table.count.out + "%N")
			else
				print ("File does not exist or is not readable%N")
			end
		end

end
