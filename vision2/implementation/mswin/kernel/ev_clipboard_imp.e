note
	description: "Objects that allow access to the operating %N%
		%system clipboard."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	EV_CLIPBOARD_IMP

inherit
	EV_CLIPBOARD_I
		undefine
			default_create
		redefine
			interface
		end

	WEL_CLIPBOARD

create
	make

feature -- Initialization

	old_make (an_interface: attached like interface)
			-- Create `Current' with interface `an_interface'.
		do
			assign_interface (an_interface)
		end

	make
			-- Initialize `Current'.
		do
			create last_string.make_empty
			create last_files.make (0)
			set_is_initialized (True)
		end

	destroy
		do
			--| FIXME
			set_is_destroyed (True)
		end

feature -- Access

	text: STRING_32
			-- Text content of clipboard.
		local
			l_result: detachable STRING_32
		do
			open_clipboard (Void)
			if clipboard_open then
				if is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_unicodetext) then
					retrieve_clipboard_text_discarding_carriage_return
					l_result := last_string
				end
				close_clipboard
			end
			if l_result = Void then
				create Result.make_empty
			else
				Result := l_result
			end
		end

	has_text: BOOLEAN
			-- Does the clipboard currently contain text?
		do
			open_clipboard (Void)
			if clipboard_open then
				Result := is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_unicodetext)
				close_clipboard
			end
		end

	has_image: BOOLEAN
			-- <Precursor>
		do
			open_clipboard (Void)
			if clipboard_open then
					-- (Windows also gives a `Cf_dib' for a `Cf_bitmap'.)
				Result := is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_dib) or else
					(png_format /= 0 and then is_clipboard_format_available (png_format))
				close_clipboard
			end
		end

	image: detachable EV_PIXEL_BUFFER
			-- <Precursor>
			-- A PNG image if available (it keeps the transparency), otherwise the bitmap.
		local
			l_data: detachable MANAGED_POINTER
		do
			open_clipboard (Void)
			if clipboard_open then
				if png_format /= 0 and then is_clipboard_format_available (png_format) then
					retrieve_clipboard_data (png_format)
					l_data := last_data
				elseif is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_dib) then
					retrieve_clipboard_data ({WEL_CLIPBOARD_CONSTANTS}.Cf_dib)
					if attached last_data as l_dib then
						l_data := bitmap_file (l_dib)
					end
				end
				close_clipboard
			end
			if l_data /= Void then
				Result := pixel_buffer (l_data)
			end
		end

	has_files: BOOLEAN
			-- <Precursor>
		do
			open_clipboard (Void)
			if clipboard_open then
				Result := is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_hdrop)
				close_clipboard
			end
		end

	files: ARRAYED_LIST [PATH]
			-- <Precursor>
		do
			create Result.make (0)
			open_clipboard (Void)
			if clipboard_open then
				if is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_hdrop) then
					retrieve_clipboard_files
					Result := last_files
				end
				close_clipboard
			end
		end

feature -- Status Setting

	set_text (a_text: READABLE_STRING_GENERAL)
			-- Assign `a_text' to clipboard.
		local
			l_app_imp: detachable EV_APPLICATION_IMP
			wel_window: detachable WEL_WINDOW
		do
				-- Retrieve silly main window from application for clipboard retrieval.
			l_app_imp ?= (create {EV_ENVIRONMENT}).implementation.application_i
			check l_app_imp /= Void then end
			wel_window ?= l_app_imp.silly_main_window
			check wel_window /= Void then end
			open_clipboard (wel_window)
			if clipboard_open then
				empty_clipboard
				if not a_text.is_empty then
					set_clipboard_text_with_newline_conversion (a_text)
				end
				close_clipboard
			end
		end

feature {NONE} -- Implementation

	png_format: INTEGER
			-- Clipboard format of the PNG images (registered by the applications as "PNG"), 0 if unknown.
		once
			Result := registered_clipboard_format ("PNG")
		end

	pixel_buffer (a_data: MANAGED_POINTER): detachable EV_PIXEL_BUFFER
			-- Image of the encoded data `a_data' (a file in memory: PNG, BMP...), if it can be read.
		local
			retried: BOOLEAN
		do
			if not retried and a_data.count > 0 then
				create Result
				Result.set_with_pointer (a_data.item, a_data.count)
			end
		rescue
			retried := True
			Result := Void
			retry
		end

	bitmap_file (a_dib: MANAGED_POINTER): detachable MANAGED_POINTER
			-- Bitmap file (.bmp) in memory of the device independent bitmap `a_dib' (`Cf_dib' data:
			-- a BITMAPINFOHEADER or later header, the color masks or table, the pixels), if valid.
		local
			l_header_size, l_bit_count, l_compression, l_colors, l_offset: NATURAL_32
		do
			if a_dib.count >= 40 then
				l_header_size := a_dib.read_natural_32_le (0)
				l_bit_count := a_dib.read_natural_16_le (14)
				l_compression := a_dib.read_natural_32_le (16)
				l_colors := a_dib.read_natural_32_le (32)
				if l_colors = 0 and l_bit_count <= 8 then
					l_colors := ({NATURAL_32} 1) |<< l_bit_count.to_integer_32
				end
				l_offset := {NATURAL_32} 14 + l_header_size + l_colors * 4
				if l_header_size = 40 then
						-- The masks follow a BITMAPINFOHEADER: BI_BITFIELDS (3), BI_ALPHABITFIELDS (6).
					if l_compression = 3 then
						l_offset := l_offset + 12
					elseif l_compression = 6 then
						l_offset := l_offset + 16
					end
				end
				if l_offset <= (14 + a_dib.count).to_natural_32 then
					create Result.make (14 + a_dib.count)
						-- BITMAPFILEHEADER: "BM", the file size, 0, the offset of the pixels.
					Result.put_natural_8 (66, 0)
					Result.put_natural_8 (77, 1)
					Result.put_natural_32_le ((14 + a_dib.count).to_natural_32, 2)
					Result.put_natural_32_le (0, 6)
					Result.put_natural_32_le (l_offset, 10)
					Result.item.plus (14).memory_copy (a_dib.item, a_dib.count)
				end
			end
		end

feature {EV_ANY, EV_ANY_I}

	interface: detachable EV_CLIPBOARD note option: stable attribute end;
		-- Interface of `Current'

note
	copyright:	"Copyright (c) 1984-2017, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end -- class EV_CLIPBOARD_IMP











