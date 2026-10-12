note
	description: "[
			Details of a library search item (library, precompiled library, iron package, class search result):
				- title, category and source, state (in project, not installed, ...)
				- information text (selectable, scrollable): description, void-safety, metadata (tags, license, links, ...),
				  classes, and for iron packages, the installation information.
				- iron package actions: install, uninstall
				- location and name of the library in the project (editable).
			Empty labels are hidden.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	LIBRARY_DETAILS_BOX

inherit
	CONF_GUI_INTERFACE_CONSTANTS

create
	make

convert
	widget: {EV_WIDGET}

feature {NONE} -- Initialization

	make (a_items_box: EIFFEL_SEARCH_ITEMS_BOX; a_iron_service: ES_IRON_SERVICE)
			-- Create details box, using `a_items_box' for queries on items, and `a_iron_service' for iron packages.
		do
			items_box := a_items_box
			iron_service := a_iron_service
			create name_changed_actions
			create install_actions
			create uninstall_actions
			create box
			create title_label
			create subtitle_label
			create state_label
			create info_text
			create iron_actions_box
			create install_button.make_with_text (conf_interface_names.dialog_find_library_install)
			create uninstall_button.make_with_text (conf_interface_names.dialog_find_library_uninstall)
			create location_field
			create name_field
			create name_message_label
			build_interface (box)
			set_item (Void)
		end

	build_interface (b: EV_VERTICAL_BOX)
		local
			hb: EV_HORIZONTAL_BOX
			lab: EV_LABEL
			f: EV_FONT
			l_width: INTEGER
		do
			b.set_padding (layout_constants.small_padding_size)
			b.set_border_width (layout_constants.default_border_size)

			f := title_label.font.twin
			f.set_weight ({EV_FONT_CONSTANTS}.weight_bold)
			title_label.set_font (f)
			title_label.align_text_left
			b.extend (title_label)
			b.disable_item_expand (title_label)

			subtitle_label.align_text_left
			b.extend (subtitle_label)
			b.disable_item_expand (subtitle_label)

			state_label.align_text_left
			b.extend (state_label)
			b.disable_item_expand (state_label)

				-- Information
			info_text.disable_edit
			info_text.enable_word_wrapping
			info_text.set_minimum_height (80)
			b.extend (info_text)

				-- Iron package actions
			iron_actions_box.set_padding (layout_constants.small_padding_size)
			iron_actions_box.extend (create {EV_CELL})
			install_button.set_tooltip (conf_interface_names.dialog_find_library_install_tooltip)
			install_button.set_pixmap (conf_pixmaps.general_add_icon)
			layout_constants.set_default_width_for_button (install_button)
			iron_actions_box.extend (install_button)
			iron_actions_box.disable_item_expand (install_button)
			uninstall_button.set_tooltip (conf_interface_names.dialog_find_library_uninstall_tooltip)
			uninstall_button.set_pixmap (conf_pixmaps.general_remove_icon)
			layout_constants.set_default_width_for_button (uninstall_button)
			iron_actions_box.extend (uninstall_button)
			iron_actions_box.disable_item_expand (uninstall_button)
			b.extend (iron_actions_box)
			b.disable_item_expand (iron_actions_box)

			b.extend (create {EV_HORIZONTAL_SEPARATOR})
			b.disable_item_expand (b.last)

				-- Location
			create lab.make_with_text (conf_interface_names.dialog_find_library_name_in_project)
			l_width := lab.minimum_width
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			create lab.make_with_text (conf_interface_names.dialog_find_library_location)
			lab.align_text_left
			lab.set_minimum_width (l_width)
			hb.extend (lab)
			hb.disable_item_expand (lab)
			hb.extend (location_field)
			b.extend (hb)
			b.disable_item_expand (hb)

				-- Name in project
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			create lab.make_with_text (conf_interface_names.dialog_find_library_name_in_project)
			lab.align_text_left
			lab.set_minimum_width (l_width)
			hb.extend (lab)
			hb.disable_item_expand (lab)
			hb.extend (name_field)
			b.extend (hb)
			b.disable_item_expand (hb)

			name_message_label.align_text_left
			name_message_label.set_foreground_color ((create {EV_STOCK_COLORS}).red)
			b.extend (name_message_label)
			b.disable_item_expand (name_message_label)

			name_field.change_actions.extend (agent on_name_changed)
			location_field.change_actions.extend (agent on_name_changed)
			install_button.select_actions.extend (agent on_install)
			uninstall_button.select_actions.extend (agent on_uninstall)
		end

feature -- Access

	widget: EV_WIDGET
			-- Widget representing Current box.
		do
			Result := box
		end

	item: detachable ES_LIBRARY_PROVIDER_ITEM
			-- Displayed item, if any.

	name_in_project: STRING_32
			-- Name to use for the library in the project.
		do
			Result := name_field.text
			Result.adjust
		end

	location_in_project: STRING_32
			-- Location to use for the library in the project.
		do
			Result := location_field.text
			Result.adjust
		end

	name_error: detachable STRING_32
			-- Error related to `name_in_project' or `location_in_project', if any.
		do
			if attached item as l_item then
				Result := name_error_for (name_in_project, items_box.is_precompile_item (l_item))
				if
					Result = Void and then
					not attached {IRON_PACKAGE} l_item.value and then
					location_in_project.is_empty
				then
					Result := conf_interface_names.dialog_find_library_location_required
				end
			end
		end

	name_error_for (a_name: READABLE_STRING_32; is_precompile: BOOLEAN): detachable STRING_32
			-- Error related to the use of `a_name' as library name in the project (or precompile name, if `is_precompile').
		do
			if a_name.is_empty or else not (create {EIFFEL_SYNTAX_CHECKER}).is_valid_group_name (a_name) then
				Result := conf_interface_names.dialog_find_library_invalid_name (a_name)
			elseif
				group_exists (a_name, items_box.target) and then
				not (is_precompile and then
					attached items_box.target.precompile as p and then p.name.is_case_insensitive_equal (a_name))
			then
				Result := conf_interface_names.dialog_find_library_name_already_used (a_name)
			end
		end

feature -- Status report

	is_name_valid: BOOLEAN
			-- Are `name_in_project' and `location_in_project' valid?
		do
			Result := name_error = Void
		end

feature -- Actions

	name_changed_actions: ACTION_SEQUENCE
			-- Actions triggered when `name_in_project' or `location_in_project' change.

	install_actions: ACTION_SEQUENCE [TUPLE [package: IRON_PACKAGE]]
			-- Actions triggered to install an iron package.

	uninstall_actions: ACTION_SEQUENCE [TUPLE [package: IRON_PACKAGE]]
			-- Actions triggered to uninstall an iron package.

feature -- Element change

	set_item (a_item: detachable ES_LIBRARY_PROVIDER_ITEM)
			-- Display details of `a_item'.
		local
			s: STRING_32
			b: like items_box
		do
			b := items_box
			item := a_item
			info_text.set_text ("")
			if a_item = Void then
				title_label.set_text (conf_interface_names.dialog_find_library_no_selection)
				set_label_text (subtitle_label, Void)
				set_label_text (state_label, Void)
				iron_actions_box.hide
				location_field.remove_text
				location_field.disable_sensitive
				name_field.remove_text
				name_field.disable_sensitive
			else
					-- Title
				create s.make_from_string (b.item_name (a_item))
				if attached b.item_title (a_item) as t and then not t.same_string (s) then
					s.append ({STRING_32} " - ")
					s.append (t)
				end
				title_label.set_text (s)

					-- Category - Source
				create s.make_from_string (b.category_text (a_item))
				if not s.is_empty then
					s.append ({STRING_32} " - ")
				end
				s.append (b.source_text (a_item))
				set_label_text (subtitle_label, s)

					-- State
				if b.is_in_target (a_item) then
					set_label_text (state_label, conf_interface_names.dialog_find_library_in_project)
					state_label.set_foreground_color ((create {EV_STOCK_COLORS}).dark_green)
				elseif not b.is_compatible (a_item) then
					set_label_text (state_label, conf_interface_names.dialog_find_library_void_safety_too_weak)
					state_label.set_foreground_color ((create {EV_STOCK_COLORS}).red)
				elseif attached {IRON_PACKAGE} a_item.value and then not b.is_iron_package_installed (a_item) then
					set_label_text (state_label, conf_interface_names.dialog_find_library_not_installed)
					state_label.set_foreground_color ((create {EV_STOCK_COLORS}).blue)
				else
					set_label_text (state_label, Void)
				end

				fill_information (a_item)

					-- Iron package actions
				if attached {IRON_PACKAGE} a_item.value then
					iron_actions_box.show
					if b.is_iron_package_installed (a_item) then
						install_button.hide
						uninstall_button.show
					else
						install_button.show
						uninstall_button.hide
					end
				else
					iron_actions_box.hide
				end

					-- Location
				if attached b.location_text (a_item) as loc then
					location_field.set_text (loc)
				else
					location_field.remove_text
				end
				if attached {IRON_PACKAGE} a_item.value then
						-- The location is the library of the installed package.
					location_field.disable_sensitive
				else
					location_field.enable_sensitive
				end

					-- Name in project
				name_field.enable_sensitive
				name_field.set_text (default_name (a_item))
			end
			on_name_changed
		end

feature {NONE} -- Information

	fill_information (a_item: ES_LIBRARY_PROVIDER_ITEM)
			-- Fill `info_text' with information about `a_item'.
		local
			l_info: STRING_TABLE [READABLE_STRING_32]
			s: STRING_32
		do
				-- Description
			if attached items_box.item_description (a_item) as d then
				append_text (dedented (d) + {STRING_32} "%N", description_format)
			end

				-- Void-safety
			create s.make_from_string (items_box.void_safety_text (a_item))
			if not s.is_empty then
				inspect
					items_box.void_safety_compatibility (a_item)
				when {EIFFEL_SEARCH_ITEMS_BOX}.compatibility_ok then
					s.append ({STRING_32} " (" + conf_interface_names.dialog_find_library_void_safety_matches + {STRING_32} ")")
				when {EIFFEL_SEARCH_ITEMS_BOX}.compatibility_warning then
					s.append ({STRING_32} " (" + conf_interface_names.dialog_find_library_void_safety_warning + {STRING_32} ")")
				when {EIFFEL_SEARCH_ITEMS_BOX}.compatibility_too_weak then
					s.append ({STRING_32} " (" + conf_interface_names.dialog_find_library_void_safety_too_weak + {STRING_32} ")")
				else
				end
				append_field (conf_interface_names.dialog_search_library_void_safety, s, value_format)
			end

				-- Metadata
			l_info := item_information (a_item)
			if attached l_info.item ("tags") as l_tags then
				append_field (conf_interface_names.dialog_find_library_tags, l_tags, tags_format)
			end
			across
				l_info as ic
			loop
				if
					@ ic.key.same_string ("tags") or
					@ ic.key.same_string ("title") or
					@ ic.key.same_string ("description") or
					@ ic.key.same_string ("category") or
					@ ic.key.starts_with ("_") or
					@ ic.key.starts_with ("link[")
				then
						-- Ignored, or already displayed
				else
					append_field (@ ic.key, ic, value_format)
				end
			end
			across
				l_info as ic
			loop
				if @ ic.key.starts_with ("link[") then
					append_field (link_title (@ ic.key, ic), link_url (ic), link_format)
				end
			end

				-- Classes (search by class)
			if attached items_box.classes_text (a_item) as l_classes then
				append_field (conf_interface_names.dialog_find_library_classes, l_classes, value_format)
			end

				-- Iron package installation
			if attached {IRON_PACKAGE} a_item.value as p then
				append_text ({STRING_32} "%N", value_format)
				append_text (iron_package_installation_text (p) + {STRING_32} "%N", description_format)
			end
		end

	item_information (a_item: ES_LIBRARY_PROVIDER_ITEM): STRING_TABLE [READABLE_STRING_32]
			-- Metadata of `a_item' (from package.iron).
		local
			s: STRING_32
		do
			create Result.make_caseless (5)
			if attached {CONF_SYSTEM_VIEW} a_item.value as cfg then
				across
					cfg.info_items as ic
				loop
					Result.force (ic, @ ic.key)
				end
			elseif attached {IRON_PACKAGE} a_item.value as p then
				if attached p.items as l_items then
					across
						l_items as ic
					loop
						if attached ic as v then
							Result.force (v, @ ic.key)
						end
					end
				end
				if not p.tags.is_empty then
					create s.make_empty
					across
						p.tags as ic
					loop
						if not s.is_empty then
							s.append ({STRING_32} ", ")
						end
						s.append (ic)
					end
					Result.force (s, "tags")
				end
			end
		end

	iron_package_installation_text (p: IRON_PACKAGE): STRING_32
			-- Installation information for iron package `p'.
		local
			l_api: IRON_INSTALLATION_API
		do
			create Result.make_empty
			l_api := iron_service.installation_api
			if l_api.is_package_installed (p) then
				Result.append (conf_interface_names.iron_box_package_installed_message (
						if attached l_api.package_installation_path (p) as l_path then l_path else create {PATH}.make_empty end,
						l_api.projects_from_installed_package (p)
					))
			elseif attached l_api.conflicting_available_package (p) as l_conflict then
				Result.append (conf_interface_names.iron_box_install_conflicting_package_help (p.identifier, p.location.string, l_conflict.location.string))
				Result.append ({STRING_32} "%N%N")
				Result.append (conf_interface_names.iron_box_install_package_help (p.location.string))
			else
				Result.append (conf_interface_names.iron_box_install_package_help (p.identifier))
			end
		end

	link_title (a_key: READABLE_STRING_GENERAL; a_value: READABLE_STRING_32): STRING_32
			-- Title of link `a_key' with value `a_value' (such as `"Documentation" http://...').
		local
			s: STRING_32
			i: INTEGER
		do
			create s.make_from_string (a_value)
			s.adjust
			if s.starts_with ({STRING_32} "%"") and then s.index_of ('%"', 2) > 2 then
				i := s.index_of ('%"', 2)
				Result := s.substring (2, i - 1)
			elseif a_key.count > 6 then
				Result := a_key.substring (6, a_key.count - 1).to_string_32
			else
				Result := a_key.to_string_32
			end
		end

	link_url (a_value: READABLE_STRING_32): STRING_32
			-- URL of link value `a_value' (such as `"Documentation" http://...').
		local
			i: INTEGER
		do
			create Result.make_from_string (a_value)
			Result.adjust
			if Result.starts_with ({STRING_32} "%"") then
				i := Result.index_of ('%"', 2)
				if i > 0 then
					Result.remove_head (i)
					Result.adjust
				end
			end
		end

	dedented (s: READABLE_STRING_32): STRING_32
			-- `s' without the indentation common to all its non empty lines,
			-- and without leading and trailing empty lines.
		local
			l_lines: LIST [READABLE_STRING_32]
			l_min, n: INTEGER
			l: STRING_32
		do
			create l.make_from_string (s)
			l.replace_substring_all ({STRING_32} "%R", {STRING_32} "")
			l_lines := l.split ('%N')
			l_min := {INTEGER}.max_value
			across
				l_lines as ic
			loop
				if not ic.is_whitespace then
					from
						n := 0
					until
						n >= ic.count or else not ic [n + 1].is_space
					loop
						n := n + 1
					end
					l_min := l_min.min (n)
				end
			end
			if l_min = {INTEGER}.max_value then
				l_min := 0
			end
			create Result.make (s.count)
			across
				l_lines as ic
			loop
				if ic.is_whitespace then
					Result.append_character ('%N')
				else
					Result.append (ic.substring (l_min + 1, ic.count))
					Result.right_adjust
					Result.append_character ('%N')
				end
			end
			Result.adjust
		end

	append_field (a_key, a_value: READABLE_STRING_GENERAL; a_value_format: EV_CHARACTER_FORMAT)
			-- Append "key: value" line to `info_text'.
		do
			append_text (a_key, keyword_format)
			append_text (": ", keyword_format)
			append_text (a_value.to_string_32 + {STRING_32} "%N", a_value_format)
		end

	append_text (a_text: READABLE_STRING_GENERAL; a_format: EV_CHARACTER_FORMAT)
			-- Append `a_text' to `info_text' using `a_format'.
		local
			i, j: INTEGER
		do
			i := info_text.text_length + 1
			info_text.append_text (a_text)
			j := info_text.text_length + 1
			if j > i then
				info_text.format_region (i, j, a_format)
			end
		end

feature {NONE} -- Formats

	value_format: EV_CHARACTER_FORMAT
		once
			create Result.make_with_font (create {EV_FONT})
			Result.set_color ((create {EV_STOCK_COLORS}).black)
		end

	keyword_format: EV_CHARACTER_FORMAT
		local
			f: EV_FONT
		once
			create f
			f.set_weight ({EV_FONT_CONSTANTS}.weight_bold)
			create Result.make_with_font (f)
			Result.set_color ((create {EV_STOCK_COLORS}).black)
		end

	description_format: EV_CHARACTER_FORMAT
		local
			f: EV_FONT
		once
			create f
			f.set_shape ({EV_FONT_CONSTANTS}.shape_italic)
			create Result.make_with_font (f)
			Result.set_color (create {EV_COLOR}.make_with_8_bit_rgb (40, 40, 40))
		end

	tags_format: EV_CHARACTER_FORMAT
		local
			f: EV_FONT
		once
			create f
			f.set_shape ({EV_FONT_CONSTANTS}.shape_italic)
			create Result.make_with_font (f)
			Result.set_color (create {EV_COLOR}.make_with_8_bit_rgb (0, 100, 0))
		end

	link_format: EV_CHARACTER_FORMAT
		once
			create Result.make_with_font (create {EV_FONT})
			Result.set_color ((create {EV_STOCK_COLORS}).blue)
		end

feature {NONE} -- Implementation

	default_name (a_item: ES_LIBRARY_PROVIDER_ITEM): STRING_32
			-- Default name of `a_item' in the project.
		do
			if items_box.is_precompile_item (a_item) then
				Result := {STRING_32} "precompile"
			elseif
				attached {CONF_SYSTEM_VIEW} a_item.value as cfg and then
				attached cfg.info ("package") as l_package_name and then
				attached cfg.info ("project") as l_project_name
			then
					-- Project declared in a package.iron file.
				Result := (create {LIBRARY_PACKAGE_FILES}.make).default_library_name (l_package_name, l_project_name)
			elseif attached {CONF_SYSTEM_VIEW} a_item.value as cfg and then not cfg.library_target_name.is_empty then
				create Result.make_from_string (cfg.library_target_name)
			elseif attached {IRON_PACKAGE} a_item.value as p and then attached p.name as n then
				create Result.make_from_string (n)
			else
				create Result.make_from_string (items_box.item_name (a_item))
			end
		end

	set_label_text (a_label: EV_LABEL; a_text: detachable READABLE_STRING_GENERAL)
			-- Set `a_text' to `a_label', and hide `a_label' if there is no text.
		do
			if a_text = Void or else a_text.is_empty then
				a_label.remove_text
				a_label.hide
			else
				a_label.set_text (a_text)
				a_label.show
			end
		end

	on_name_changed
			-- `name_in_project' or `location_in_project' changed.
		do
			set_label_text (name_message_label, name_error)
			name_changed_actions.call (Void)
		end

	on_install
		do
			if attached item as l_item and then attached {IRON_PACKAGE} l_item.value as p then
				install_actions.call ([p])
			end
		end

	on_uninstall
		do
			if attached item as l_item and then attached {IRON_PACKAGE} l_item.value as p then
				uninstall_actions.call ([p])
			end
		end

	group_exists (a_group: READABLE_STRING_GENERAL; a_target: CONF_TARGET): BOOLEAN
			-- Check if `a_target' or any child of `a_target' already has `a_group'.
		require
			a_group_ok: a_group /= Void and then not a_group.is_empty
		local
			l_groups: STRING_TABLE [CONF_GROUP]
		do
			l_groups := a_target.groups
			Result := attached l_groups.item (a_group.as_lower) as g and then g.name.same_string_general (a_group.as_lower)
			if not Result then
				Result := a_target.child_targets.there_exists (agent group_exists (a_group.as_lower, ?))
			end
		end

feature {NONE} -- Widgets

	items_box: EIFFEL_SEARCH_ITEMS_BOX
			-- Items box, used for queries on items.

	iron_service: ES_IRON_SERVICE
			-- Iron service.

	box: EV_VERTICAL_BOX

	title_label, subtitle_label, state_label: EV_LABEL

	info_text: EV_RICH_TEXT
			-- Information (description, metadata, ...).

	iron_actions_box: EV_HORIZONTAL_BOX

	install_button, uninstall_button: EV_BUTTON

	location_field: EV_TEXT_FIELD

	name_field: EV_TEXT_FIELD

	name_message_label: EV_LABEL

;note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.

			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).

			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.

			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
