note
	description: "Configuration reader for PDF processor application (INI format)"

class
	PDF_CONFIG_READER

create
	make_from_file

feature -- Initialization

	make_from_file (file_path: STRING)
			-- Load configuration from INI file
		require
			file_path_not_empty: not file_path.is_empty
		local
			file: PLAIN_TEXT_FILE
			line: STRING
			current_section: STRING
			last_key: STRING
			key: STRING
			equal_pos: INTEGER
		do
			create file.make_open_read (file_path)
			
			    -- Initialize defaults
			footer_size := 8.0
			footer_margin := 20.0
			footer_alignment := "center"
			allow_print := False
			allow_modify := False
			allow_copy := False
			allow_annotate := False
			
			from
				current_section := ""
				last_key := ""
			until
				file.exhausted
			loop
				file.read_line
				line := file.last_string.twin
				line.left_adjust
				line.right_adjust
				
				if not line.starts_with (";") and not line.starts_with ("#") then
					if line.starts_with ("[") and line.ends_with ("]") then
						    -- Section header
						current_section := line.substring (2, line.count - 1)
						last_key := ""
					elseif line.has ('=') then
						    -- Key=value pair
						equal_pos := line.index_of ('=', 1)
						if equal_pos > 0 then
							key := line.substring (1, equal_pos - 1)
							key.left_adjust
							key.right_adjust
							parse_key_value (current_section, line)
							last_key := key
						end
					else
						    -- Continuation line
						if current_section.is_equal ("Message") and last_key.is_equal ("text") then
							if attached personalized_message as msg then
								personalized_message := msg + "%N" + line
							end
						elseif current_section.is_equal ("Footer") and last_key.is_equal ("text") then
							if attached footer_text as footer then
								footer_text := footer + "%N" + line
							end
						end
					end
				end
			end
			
			file.close
		ensure
			footer_size_positive: footer_size > 0
			footer_margin_non_negative: footer_margin >= 0
		end

feature -- Access

	input_file: detachable STRING
			-- Path to input PDF file

	footer_text: detachable STRING
			-- Footer text to add

	footer_size: REAL
			-- Font size for footer

	footer_margin: REAL
			-- Bottom margin for footer

	footer_alignment: STRING
			-- Footer horizontal alignment: "left", "center", or "right"

	owner_password: detachable STRING
			-- Owner password for encryption

	allow_print: BOOLEAN
			-- Permission flag: allow printing

	allow_modify: BOOLEAN
			-- Permission flag: allow modifications

	allow_copy: BOOLEAN
			-- Permission flag: allow copying

	allow_annotate: BOOLEAN
			-- Permission flag: allow annotations

	personalized_message: detachable STRING
			-- Personalized message to show on the inserted page

	signature_text: detachable STRING
			-- Signature text to show on the inserted page


feature {NONE} -- Implementation

	parse_key_value (section: STRING; line: STRING)
			-- Parse a key=value line and store the value
		local
			equal_pos: INTEGER
			key: STRING
			value: STRING
		do
			equal_pos := line.index_of ('=', 1)
			if equal_pos > 0 then
				key := line.substring (1, equal_pos - 1)
				key.left_adjust
				key.right_adjust
				
				value := line.substring (equal_pos + 1, line.count)
				value.left_adjust
				value.right_adjust
				
				if section.is_equal ("Input") then
					if key.is_equal ("file_path") then
						input_file := value
					end
				elseif section.is_equal ("Footer") then
					if key.is_equal ("text") then
						footer_text := value
					elseif key.is_equal ("size") then
						if value.is_real then
							footer_size := value.to_real
						end
					elseif key.is_equal ("margin") then
						if value.is_real then
							footer_margin := value.to_real
						end
					elseif key.is_equal ("alignment") then
						footer_alignment := value.as_lower
					end
				elseif section.is_equal ("Encryption") then
					if key.is_equal ("owner_password") then
						owner_password := value
					elseif key.is_equal ("allow_print") then
						allow_print := is_true (value)
					elseif key.is_equal ("allow_modify") then
						allow_modify := is_true (value)
					elseif key.is_equal ("allow_copy") then
						allow_copy := is_true (value)
					elseif key.is_equal ("allow_annotate") then
						allow_annotate := is_true (value)
					end
				elseif section.is_equal ("Message") then
					if key.is_equal ("text") then
						personalized_message := value
					elseif key.is_equal ("signature") then
						signature_text := value
					end
				end
			end
		end

	is_true (value: STRING): BOOLEAN
			-- Check if value represents true
		do
			Result := value.is_equal ("true") or value.is_equal ("True") or 
			          value.is_equal ("TRUE") or value.is_equal ("1") or
			          value.is_equal ("yes") or value.is_equal ("Yes")
		end

end
