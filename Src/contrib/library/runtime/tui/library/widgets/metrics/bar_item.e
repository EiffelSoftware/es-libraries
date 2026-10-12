note
	description: "[
		Data item for a TUI_BARCHART bar, defining numerical value,
		optional bottom label, optional custom value text, and element styles.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BAR_ITEM

inherit
	ANY
		redefine
			default_create,
			copy,
			is_equal,
			out
		end

create
	default_create,
	make,
	make_with_text

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty zero-valued bar.
		do
			create label.make_empty
			value := 0
			create style.default_create
			create value_style.default_create
			create label_style.default_create
		ensure then
			label_empty: label.is_empty
			value_zero: value = 0
		end

	make (a_label: READABLE_STRING_GENERAL; a_value: NATURAL_64)
			-- Initialize bar with `a_label` and `a_value`.
		require
			label_not_void: a_label /= Void
		do
			default_create
			create label.make_from_string_general (a_label)
			value := a_value
		ensure
			label_set: label.same_string_general (a_label)
			value_set: value = a_value
		end

	make_with_text (a_label: READABLE_STRING_GENERAL; a_value: NATURAL_64; a_text: READABLE_STRING_GENERAL)
			-- Initialize bar with `a_label`, `a_value`, and explicit `a_text` value string.
		require
			label_not_void: a_label /= Void
			text_not_void: a_text /= Void
		do
			make (a_label, a_value)
			create text_value.make_from_string_general (a_text)
		ensure
			label_set: label.same_string_general (a_label)
			value_set: value = a_value
			text_set: attached text_value as tv and then tv.same_string_general (a_text)
		end

feature -- Access

	label: STRING_32
			-- Category label displayed beneath the bar

	value: NATURAL_64
			-- Numerical value of the bar

	text_value: detachable STRING_32
			-- Optional custom formatted value printed above label (defaults to `value.out`)

	style: STYLE
			-- Style applied to the bar column

	value_style: STYLE
			-- Style applied to the numerical value text

	label_style: STYLE
			-- Style applied to the label text

feature -- Element change

	set_label (a_label: READABLE_STRING_GENERAL)
			-- Set bar label.
		require
			label_not_void: a_label /= Void
		do
			create label.make_from_string_general (a_label)
		ensure
			label_set: label.same_string_general (a_label)
		end

	set_value (a_value: NATURAL_64)
			-- Set numerical value.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

	set_text_value (a_text: detachable READABLE_STRING_GENERAL)
			-- Set or clear custom formatted value text.
		do
			if attached a_text as t then
				create text_value.make_from_string_general (t)
			else
				text_value := Void
			end
		ensure
			text_set: attached a_text implies attached text_value
		end

	set_style (a_style: STYLE)
			-- Set bar column style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_value_style (a_style: STYLE)
			-- Set value text style.
		require
			style_not_void: a_style /= Void
		do
			value_style := a_style
		ensure
			value_style_set: value_style = a_style
		end

	set_label_style (a_style: STYLE)
			-- Set label text style.
		require
			style_not_void: a_style /= Void
		do
			label_style := a_style
		ensure
			label_style_set: label_style = a_style
		end

feature -- Fluent Builders

	with_text_value (a_text: READABLE_STRING_GENERAL): like Current
			-- Bar item with custom value text `a_text`.
		require
			text_not_void: a_text /= Void
		do
			Result := twin
			Result.set_text_value (a_text)
		ensure
			result_is_copy: Result /= Current
		end

	with_style (a_style: STYLE): like Current
			-- Bar item with bar column `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_is_copy: Result /= Current
			style_set: Result.style = a_style
		end

	with_value_style (a_style: STYLE): like Current
			-- Bar item with `a_style` for value text.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_value_style (a_style)
		ensure
			result_is_copy: Result /= Current
			value_style_set: Result.value_style = a_style
		end

	with_label_style (a_style: STYLE): like Current
			-- Bar item with `a_style` for label text.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_label_style (a_style)
		ensure
			result_is_copy: Result /= Current
			label_style_set: Result.label_style = a_style
		end

feature -- Output

	copy (a_other: like Current)
			-- Copy `a_other` with its own label and text value strings.
		do
			if a_other /= Current then
				standard_copy (a_other)
				label := a_other.label.twin
				if attached a_other.text_value as t then
					text_value := t.twin
				end
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Same label, value, text value and styles?
		do
			if a_other = Current then
				Result := True
			else
				Result := label.same_string (a_other.label)
					and value = a_other.value
					and text_value ~ a_other.text_value
					and style.is_equal (a_other.style)
					and value_style.is_equal (a_other.value_style)
					and label_style.is_equal (a_other.label_style)
			end
		end

	out: STRING
			-- String representation for debugging, UTF-8 encoded.
		do
			create Result.make_from_string ("BAR_ITEM(")
			{UTF_CONVERTER}.utf_32_string_into_utf_8_string_8 (label, Result)
			Result.append_string (": ")
			Result.append (value.out)
			Result.append_character (')')
		end

invariant
	label_not_void: label /= Void
	style_not_void: style /= Void
	value_style_not_void: value_style /= Void
	label_style_not_void: label_style /= Void

end
