note
	description: "[
		State of one libcurl transfer receiving custom callbacks: the data written (to an agent,
		with or without the header), the file read for an upload, and the cancellation.

		libcurl calls back a single {LIBCURL_DEFAULT_FUNCTION} for the whole process; it gives
		each callback the data pointer of the transfer (here, the `object_id' of Current), so
		that transfers running at the same time, in different threads, do not mix.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	LIBCURL_TRANSFER

inherit
	IDENTIFIED

create
	make

feature {NONE} -- Initialization

	make
			-- Create a transfer without custom behavior.
		do
			create header_text.make_empty
			create last_header.make_empty
		end

feature -- Access

	write_procedure: detachable PROCEDURE [READABLE_STRING_8]
			-- Procedure receiving all the data of the response (header and content)

	content_write_procedure: detachable PROCEDURE [READABLE_STRING_8]
			-- Procedure receiving the content of the response only (after its header)

	file_to_read: detachable FILE
			-- File sent by an upload

	cancellation_query: detachable FUNCTION [BOOLEAN]
			-- Function telling whether the transfer has to be stopped

	last_header: STRING_8
			-- Header of the response (the last one, after redirections, proxy or interim responses),
			-- ended by an empty line, when `content_write_procedure' is set

feature -- Status report

	is_cancelled: BOOLEAN
			-- Was the transfer stopped as asked by `cancellation_query'?

feature -- Element change

	set_write_procedure (p: like write_procedure)
			-- Set `write_procedure' to `p'.
		do
			write_procedure := p
		ensure
			write_procedure_set: write_procedure = p
		end

	set_content_write_procedure (p: like content_write_procedure)
			-- Set `content_write_procedure' to `p'.
		do
			content_write_procedure := p
		ensure
			content_write_procedure_set: content_write_procedure = p
		end

	set_file_to_read (f: like file_to_read)
			-- Set `file_to_read' to `f'.
		do
			file_to_read := f
		ensure
			file_to_read_set: file_to_read = f
		end

	set_cancellation_query (q: like cancellation_query)
			-- Set `cancellation_query' to `q'.
		do
			cancellation_query := q
		ensure
			cancellation_query_set: cancellation_query = q
		end

feature -- Callbacks

	write (s: READABLE_STRING_8): BOOLEAN
			-- Receive data `s' of the response. Should the transfer go on?
		do
			if is_cancellation_requested then
				is_cancelled := True
			else
				Result := True
				if attached content_write_procedure as p then
					receive_content (s, p)
				elseif attached write_procedure as p then
					p.call ([s])
				end
			end
		end

	read (a_data_pointer: POINTER; a_count: INTEGER): INTEGER
			-- Put at most `a_count' bytes of `file_to_read' at `a_data_pointer';
			-- Result is the number of bytes put (0 at the end of the file).
		local
			l_pointer: MANAGED_POINTER
			l_max_transfer, l_byte_transfered: INTEGER
		do
			if attached file_to_read as l_file and then not l_file.after then
				l_max_transfer := a_count
				if l_max_transfer > l_file.count - l_file.position then
					l_max_transfer := l_file.count - l_file.position
				end
				create l_pointer.share_from_pointer (a_data_pointer, l_max_transfer)
				from
				until
					l_file.after or l_byte_transfered >= l_max_transfer
				loop
					l_file.read_character
					l_pointer.put_character (l_file.last_character, l_byte_transfered)
					l_byte_transfered := l_byte_transfered + 1
				end
				Result := l_max_transfer
			end
		end

	progress: INTEGER
			-- Progress callback: non zero to stop the transfer.
		do
			if is_cancellation_requested then
				is_cancelled := True
				Result := 1
			end
		end

feature {NONE} -- Implementation

	is_cancellation_requested: BOOLEAN
			-- Does `cancellation_query' ask to stop the transfer?
		do
			Result := attached cancellation_query as q and then q.item (Void)
		end

	header_text: STRING_8
			-- Header data received and not yet complete

	is_content_started: BOOLEAN
			-- Has some content been given to `content_write_procedure'?

	receive_content (s: READABLE_STRING_8; p: attached like content_write_procedure)
			-- Give the content part of `s' to `p', keeping the header (libcurl writes the
			-- header of each response received, e.g. a proxy's or a redirection's, before the
			-- content of the last one).
		local
			i: INTEGER
			l_done: BOOLEAN
		do
			if is_content_started then
				p.call ([s])
			else
				header_text.append (s)
				from
				until
					l_done
				loop
					if
						not last_header.is_empty and then not header_text.is_empty and then
						not (header_text.starts_with ("HTTP/") or ("HTTP/").starts_with (header_text))
					then
							-- After a header, data that is not another response's header: the content.
						is_content_started := True
						p.call ([header_text.twin])
						header_text.wipe_out
						l_done := True
					else
						i := header_text.substring_index ("%R%N%R%N", 1)
						if i > 0 then
								-- End of a header block: what follows is content, or another header block.
							last_header := header_text.substring (1, i + 3)
							header_text.remove_head (i + 3)
						else
							l_done := True
						end
					end
				end
			end
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
