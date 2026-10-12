note
	description: "[
		Deferred base class for PDF text encoding.
		
		PDF text strings can be encoded using either PDFDocEncoding (single-byte)
		or UTF-16BE (big-endian Unicode). This class defines the interface for
		encoding and decoding text to/from PDF byte sequences.
		
		Per ISO 32000-1:2008 §7.9.2.2, text strings use:
		- PDFDocEncoding (default, single-byte encoding)
		- UTF-16BE (identified by BOM 0xFE 0xFF)
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PDF_TEXT_ENCODING

feature -- Encoding

	encode_text (text: READABLE_STRING_GENERAL): STRING_8
			-- Encode `text' to PDF byte sequence.
			-- Per Eiffel.md §14: Use READABLE_STRING_GENERAL for maximum API flexibility.
		require
			text_not_void: text /= Void
		deferred
		ensure
			result_not_void: Result /= Void
		end

feature -- Decoding

	decode_bytes (bytes: STRING_8): STRING_32
			-- Decode PDF byte sequence to Unicode text.
		require
			bytes_not_void: bytes /= Void
		deferred
		ensure
			result_not_void: Result /= Void
		end

feature -- Status

	can_encode (text: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `text' be encoded with this encoding?
			-- Returns True if all characters in `text' can be represented.
		require
			text_not_void: text /= Void
		deferred
		end

	encoding_name: STRING_8
			-- Name of this encoding (e.g., "PDFDocEncoding", "UTF-16BE").
		deferred
		ensure
			result_not_void: Result /= Void
			result_not_empty: not Result.is_empty
		end

end
