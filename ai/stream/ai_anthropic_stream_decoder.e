note
	description: "[
		Decoder of the streamed answers of the Anthropic Messages API (Server-Sent Events
		message_start, content_block_start/delta/stop, message_delta, message_stop, error, ping).
		The blocks other than text and tool calls (e.g. thinking blocks) are given back whole, as
		provider data, to be sent back unchanged in the next requests.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_ANTHROPIC_STREAM_DECODER

inherit
	AI_STREAM_DECODER
		redefine
			make
		end

create
	make

feature {NONE} -- Initialization

	make
			-- <Precursor>
		do
			Precursor
			create other_blocks.make (2)
		end

feature {NONE} -- Implementation

	other_blocks: HASH_TABLE [TUPLE [block: JSON_OBJECT; thinking, signature: STRING_32], INTEGER]
			-- Blocks other than text and tool calls being received, by index

	process_event (a_name, a_data: STRING_8)
			-- <Precursor>
		local
			o: detachable JSON_OBJECT
			l_type: detachable STRING_32
			i: INTEGER
		do
			o := parsed_json_object (a_data)
			l_type := string_item (o, "type")
			i := integer_item (o, "index")
			if o = Void or l_type = Void then
					-- (Not a JSON event.)
			elseif l_type.same_string_general ("message_start") then
				if attached object_item (object_item (o, "message"), "usage") as u then
					events.extend (create {AI_STREAM_EVENT}.make_usage (integer_item (u, "input_tokens") + integer_item (u, "cache_read_input_tokens") + integer_item (u, "cache_creation_input_tokens"), 0))
				end
			elseif l_type.same_string_general ("content_block_start") then
				if attached object_item (o, "content_block") as b and then attached string_item (b, "type") as l_block_type then
					if l_block_type.same_string_general ("text") then
						events.extend (create {AI_STREAM_EVENT}.make_text_block_start (i))
						if attached string_item (b, "text") as t and then not t.is_empty then
							events.extend (create {AI_STREAM_EVENT}.make_text_delta (i, t))
						end
					elseif l_block_type.same_string_general ("tool_use") then
						events.extend (create {AI_STREAM_EVENT}.make_tool_block_start (i,
							if attached string_item (b, "id") as l_id then l_id else {STRING_32} "" end,
							if attached string_item (b, "name") as l_tool then l_tool else {STRING_32} "" end))
					else
						other_blocks.force ([b,
							if attached string_item (b, "thinking") as t then t else create {STRING_32}.make_empty end,
							if attached string_item (b, "signature") as l_signature then l_signature else create {STRING_32}.make_empty end], i)
					end
				end
			elseif l_type.same_string_general ("content_block_delta") then
				if attached object_item (o, "delta") as d and then attached string_item (d, "type") as l_delta_type then
					if l_delta_type.same_string_general ("text_delta") then
						if attached string_item (d, "text") as t then
							events.extend (create {AI_STREAM_EVENT}.make_text_delta (i, t))
						end
					elseif l_delta_type.same_string_general ("input_json_delta") then
						if attached string_item (d, "partial_json") as t then
							events.extend (create {AI_STREAM_EVENT}.make_tool_input_delta (i, t))
						end
					elseif attached other_blocks.item (i) as l_other then
						if l_delta_type.same_string_general ("thinking_delta") and then attached string_item (d, "thinking") as t then
							l_other.thinking.append (t)
						elseif l_delta_type.same_string_general ("signature_delta") and then attached string_item (d, "signature") as l_signature then
							l_other.signature.append (l_signature)
						end
					end
				end
			elseif l_type.same_string_general ("content_block_stop") then
				if attached other_blocks.item (i) as l_other then
					events.extend (create {AI_STREAM_EVENT}.make_provider_data (i, finished_block (l_other)))
					other_blocks.remove (i)
				end
			elseif l_type.same_string_general ("message_delta") then
				if attached string_item (object_item (o, "delta"), "stop_reason") as r then
					events.extend (create {AI_STREAM_EVENT}.make_stop (r))
				end
				if attached object_item (o, "usage") as u then
					events.extend (create {AI_STREAM_EVENT}.make_usage (0, integer_item (u, "output_tokens")))
				end
			elseif l_type.same_string_general ("message_stop") then
				events.extend (create {AI_STREAM_EVENT}.make_done)
			elseif l_type.same_string_general ("error") then
				if attached string_item (object_item (o, "error"), "message") as m then
					events.extend (create {AI_STREAM_EVENT}.make_error (m))
				else
					events.extend (create {AI_STREAM_EVENT}.make_error ({STRING_32} "Error from the provider"))
				end
			end
		end

	finished_block (a_block: TUPLE [block: JSON_OBJECT; thinking, signature: STRING_32]): JSON_OBJECT
			-- Block `a_block' as received in full
		do
			if attached string_item (a_block.block, "type") as t and then t.same_string_general ("thinking") then
				create Result.make_with_capacity (3)
				Result.put_string ("thinking", "type")
				Result.put_string (a_block.thinking, "thinking")
				Result.put_string (a_block.signature, "signature")
			else
				Result := a_block.block
			end
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
