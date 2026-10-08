note
	description: "[
			Box containing the results of a library search.
			Columns: in project, name, category, void-safety, source, information.
			Columns are sorted by clicking on their header,
			an item is activated with a double click, or the Enter key.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_SEARCH_ITEMS_BOX

inherit
	CONF_GUI_INTERFACE_CONSTANTS

	SHARED_BENCH_NAMES

create
	make

convert
	widget: {EV_WIDGET}

feature {NONE} -- Initialization

	make (a_target: like target)
		do
			target := a_target
			create on_item_selected_actions
			create on_item_deselected_actions
			create on_item_activated_actions
			create box
			create grid
			build_interface (box)
		end

	build_interface (b: EV_VERTICAL_BOX)
		local
			g: like grid
		do
			g := grid
			g.enable_always_selected
			g.enable_single_row_selection
			g.set_column_count_to (last_column)
			set_column (in_project_column, "", 24)
			set_column (name_column, conf_interface_names.dialog_create_library_name, 140)
			set_column (category_column, conf_interface_names.dialog_search_library_category, 100)
			set_column (void_safety_column, conf_interface_names.dialog_search_library_void_safety, 110)
			set_column (source_column, conf_interface_names.dialog_search_library_source, 110)
			set_column (info_column, conf_interface_names.dialog_create_library_information, 200)

			g.disable_border
			g.disable_row_height_fixed
			g.enable_row_separators
			g.enable_column_separators

			g.header.item_pointer_button_press_actions.extend (agent on_header_pressed)
			g.pointer_double_press_item_actions.extend (agent on_item_double_pressed)
			g.key_press_actions.extend (agent on_key_pressed)

			b.extend (g)
		end

	set_column (i: INTEGER; a_title: READABLE_STRING_GENERAL; a_width: INTEGER)
		local
			l_col: EV_GRID_COLUMN
		do
			l_col := grid.column (i)
			l_col.set_title (a_title)
			l_col.set_width (a_width)
		end

feature -- Access

	widget: EV_WIDGET
			-- Widget representing Current box.
		do
			Result := box
		end

	target: CONF_TARGET
			-- Target where we add the group.

	items: detachable LIST [ES_LIBRARY_PROVIDER_ITEM] assign set_items
			-- Items to display.

	selected_item: detachable ES_LIBRARY_PROVIDER_ITEM
			-- Selected item, if any.
		do
			if
				attached grid.selected_rows as lst and then
				not lst.is_empty and then
				attached {ES_LIBRARY_PROVIDER_ITEM} lst.first.data as l_item
			then
				Result := l_item
			end
		end

feature -- Change

	set_items (a_lst: like items)
		do
			items := a_lst
			sort_items
		end

	select_row_by_value (p: ANY)
		local
			g: like grid
			i, n: INTEGER
			l_done: BOOLEAN
		do
			g := grid
			n := g.row_count
			if n > 0 then
				from
					i := 1
				until
					l_done or i > n
				loop
					if
						attached g.row (i) as r and then
						attached {ES_LIBRARY_PROVIDER_ITEM} r.data as l_search_item
					then
						if l_search_item.value = p then
							l_done := True
							r.ensure_visible
							r.enable_select
						end
					end
					i := i + 1
				end
			end
		end

feature -- Callback

	on_item_selected (a_row: EV_GRID_ROW; a_item: ES_LIBRARY_PROVIDER_ITEM)
			-- Called when an item is selected.
		do
			on_item_selected_actions.call ([a_item])
		end

	on_item_deselected (a_row: EV_GRID_ROW; a_item: ES_LIBRARY_PROVIDER_ITEM)
			-- Called when an item is deselected..
		do
			on_item_deselected_actions.call ([a_item])
		end

	on_item_selected_actions: ACTION_SEQUENCE [TUPLE [data: ES_LIBRARY_PROVIDER_ITEM]]
			-- Actions to be triggered when an item is selected.

	on_item_deselected_actions: ACTION_SEQUENCE [TUPLE [data: ES_LIBRARY_PROVIDER_ITEM]]
			-- Actions to be triggered when an item is deselected.

	on_item_activated_actions: ACTION_SEQUENCE [TUPLE [data: ES_LIBRARY_PROVIDER_ITEM]]
			-- Actions to be triggered when an item is activated (double click, or Enter key).

feature {NONE} -- Events

	on_header_pressed (a_header_item: detachable EV_HEADER_ITEM; a_x, a_y, a_button: INTEGER)
			-- Sort on the column associated with `a_header_item'.
		local
			i, n: INTEGER
		do
			if a_button = 1 and a_header_item /= Void then
				from
					i := 1
					n := grid.column_count
				until
					i > n
				loop
					if grid.column (i).header_item = a_header_item then
						sort_by_column (i)
						i := n
					end
					i := i + 1
				end
			end
		end

	on_item_double_pressed (a_x, a_y, a_button: INTEGER; a_item: detachable EV_GRID_ITEM)
		do
			if
				a_button = 1 and then
				a_item /= Void and then
				attached a_item.row as r and then
				attached {ES_LIBRARY_PROVIDER_ITEM} r.data as l_data
			then
				on_item_activated_actions.call ([l_data])
			end
		end

	on_key_pressed (a_key: EV_KEY)
		do
			if
				a_key.code = {EV_KEY_CONSTANTS}.key_enter and then
				attached selected_item as l_data
			then
				on_item_activated_actions.call ([l_data])
			end
		end

feature -- Sorting

	sort_column: INTEGER
			-- Column used to sort `items' (0 means the order of the search, by relevance).

	is_sort_ascending: BOOLEAN
			-- Is sort ascending?

	sort_by_column (i: INTEGER)
			-- Sort `items' on column `i' (toggle order if already sorted on `i').
		do
			if sort_column = i then
				is_sort_ascending := not is_sort_ascending
			else
				sort_column := i
				is_sort_ascending := True
			end
			sort_items
			if items /= Void then
				update_grid
			end
		end

feature {NONE} -- Sorting

	sort_items
			-- Sort `items' according to `sort_column'.
		local
			l_sorter: QUICK_SORTER [ES_LIBRARY_PROVIDER_ITEM]
			k: FUNCTION [ES_LIBRARY_PROVIDER_ITEM, READABLE_STRING_GENERAL]
		do
			if attached items as lst and then sort_column > 0 then
				inspect
					sort_column
				when in_project_column then
					k := agent in_project_text
				when name_column then
					k := agent item_name
				when category_column then
					k := agent category_text
				when void_safety_column then
					k := agent void_safety_text
				when source_column then
					k := agent source_text
				else
					k := agent information_text
				end
				create l_sorter.make (create {LIBRARY_SEARCH_ITEM_COMPARATOR}.make (k, is_sort_ascending))
				l_sorter.sort (lst)
			end
		end

feature -- Query on items

	item_name (a_item: ES_LIBRARY_PROVIDER_ITEM): READABLE_STRING_32
			-- Name of `a_item'.
		do
			if attached {CONF_SYSTEM_VIEW} a_item.value as cfg then
				Result := cfg.system_name
			elseif attached {IRON_PACKAGE} a_item.value as p then
				Result := p.identifier.to_string_32
			elseif attached {LIBRARY_INFO} a_item.value as inf then
				Result := inf.name
			else
				Result := a_item.identifier.to_string_32
			end
		end

	item_title (a_item: ES_LIBRARY_PROVIDER_ITEM): detachable READABLE_STRING_32
			-- Title of `a_item', if any.
		do
			if attached {CONF_SYSTEM_VIEW} a_item.value as cfg then
				Result := cfg.title
				if Result = Void or else Result.is_whitespace then
					Result := cfg.info ("title")
				end
			elseif attached {IRON_PACKAGE} a_item.value as p then
				Result := p.title
			end
			if Result /= Void and then Result.is_whitespace then
				Result := Void
			end
		end

	item_description (a_item: ES_LIBRARY_PROVIDER_ITEM): detachable READABLE_STRING_32
			-- Description of `a_item', if any.
		do
			if attached {CONF_SYSTEM_VIEW} a_item.value as cfg then
				Result := cfg.description
				if Result = Void or else Result.is_whitespace then
					Result := cfg.info ("description")
				end
			elseif attached {IRON_PACKAGE} a_item.value as p then
				Result := p.description
			elseif attached {READABLE_STRING_GENERAL} a_item.info ("description") as d then
				Result := d.to_string_32
			end
			if Result /= Void and then Result.is_whitespace then
				Result := Void
			end
		end

	category_text (a_item: ES_LIBRARY_PROVIDER_ITEM): READABLE_STRING_32
			-- Category title of `a_item'.
		do
			if attached a_item.category as c then
				Result := category_title (c)
			else
				Result := {STRING_32} ""
			end
		end

	void_safety_text (a_item: ES_LIBRARY_PROVIDER_ITEM): READABLE_STRING_32
			-- Void-safety level of `a_item', if known.
		do
			if attached {CONF_SYSTEM_VIEW} a_item.value as cfg and then attached cfg.conf_option as l_options then
				Result := conf_interface_names.option_void_safety_value [l_options.void_safety.index]
			elseif attached {LIBRARY_INFO} a_item.value as inf and then attached inf.void_safety_option as v then
				Result := v.to_string_32
			else
				Result := {STRING_32} ""
			end
		end

	void_safety_compatibility (a_item: ES_LIBRARY_PROVIDER_ITEM): INTEGER
			-- Compatibility of void-safety level of `a_item' with `target'.
			-- See `compatibility_unknown', `compatibility_ok', `compatibility_warning', `compatibility_too_weak'.
		do
			if attached {CONF_SYSTEM_VIEW} a_item.value as cfg and then attached cfg.conf_option as l_options then
				if l_options.is_void_safety_supported (target.options) then
					Result := compatibility_ok
				elseif l_options.is_void_safety_sufficient (target.options) then
					Result := compatibility_warning
				else
					Result := compatibility_too_weak
				end
			end
		end

	is_compatible (a_item: ES_LIBRARY_PROVIDER_ITEM): BOOLEAN
			-- Can `a_item' be used by `target' (void-safety)?
		do
			Result := void_safety_compatibility (a_item) /= compatibility_too_weak
		end

	is_iron_package_installed (a_item: ES_LIBRARY_PROVIDER_ITEM): BOOLEAN
			-- Is `a_item' an installed iron package?
		do
			Result := attached {BOOLEAN} a_item.info ("is_installed") as b and then b
		end

	is_precompile_item (a_item: ES_LIBRARY_PROVIDER_ITEM): BOOLEAN
			-- Is `a_item' a precompiled library?
		do
			Result := attached a_item.category as c and then c.is_case_insensitive_equal ({ES_LIBRARY_CATEGORIES}.precompiled)
		end

	source_text (a_item: ES_LIBRARY_PROVIDER_ITEM): READABLE_STRING_32
			-- Source of `a_item' (local, iron, precompiled, class index).
		do
			if attached {IRON_PACKAGE} a_item.value then
				if is_iron_package_installed (a_item) then
					Result := conf_interface_names.dialog_search_library_source_iron_installed
				else
					Result := conf_interface_names.dialog_search_library_source_iron_available
				end
			elseif attached {LIBRARY_INFO} a_item.value then
				Result := conf_interface_names.dialog_search_library_source_class_index
			elseif is_precompile_item (a_item) then
				Result := conf_interface_names.dialog_search_library_precompiled
			elseif attached {CONF_SYSTEM_VIEW} a_item.value as cfg and then cfg.original_location.starts_with ({STRING_32} "iron:") then
				Result := conf_interface_names.dialog_search_library_source_iron_installed
			else
				Result := conf_interface_names.dialog_search_library_source_local
			end
		end

	location_text (a_item: ES_LIBRARY_PROVIDER_ITEM): detachable READABLE_STRING_32
			-- Location of `a_item' (keeping variables such as $ISE_LIBRARY), if any.
		do
			if attached {CONF_SYSTEM_VIEW} a_item.value as cfg then
				Result := cfg.original_location
			elseif attached {LIBRARY_INFO} a_item.value as inf then
				Result := inf.location.name
			elseif attached {IRON_PACKAGE} a_item.value as p then
				Result := p.location.string.to_string_32
			end
		end

	classes_text (a_item: ES_LIBRARY_PROVIDER_ITEM): detachable STRING_32
			-- Comma separated list of classes found by a class search, if any.
		do
			if attached {ITERABLE [READABLE_STRING_GENERAL]} a_item.info ("classes") as l_classes then
				create Result.make_empty
				across
					l_classes as ic
				loop
					if not Result.is_empty then
						Result.append ({STRING_32} ", ")
					end
					Result.append_string_general (ic)
				end
				if Result.is_whitespace then
					Result := Void
				end
			end
		end

	information_text (a_item: ES_LIBRARY_PROVIDER_ITEM): READABLE_STRING_32
			-- One line information on `a_item'.
		local
			s: STRING_32
			nb: INTEGER
		do
			create s.make_empty
			if attached {LIBRARY_INFO} a_item.value then
				if attached {ITERABLE [READABLE_STRING_GENERAL]} a_item.info ("classes") as l_classes then
					across
						l_classes as ic
					loop
						nb := nb + 1
					end
				end
				s.append (conf_interface_names.dialog_search_found_n_classes (nb))
				if attached classes_text (a_item) as l_classes_txt then
					s.append ({STRING_32} ": ")
					s.append (l_classes_txt)
				end
			elseif attached one_line_description (item_description (a_item)) as d then
				s.append_string_general (d)
			end
			Result := s
		end

	in_project_text (a_item: ES_LIBRARY_PROVIDER_ITEM): READABLE_STRING_32
			-- Text used to sort on "in project" column.
		do
			if is_in_target (a_item) then
				Result := {STRING_32} "0"
			else
				Result := {STRING_32} "1"
			end
		end

	is_in_target (a_item: ES_LIBRARY_PROVIDER_ITEM): BOOLEAN
			-- Is `a_item' already used by `target' (as library or precompiled library)?
		local
			l_prefix: STRING_32
		do
			if attached {CONF_SYSTEM_VIEW} a_item.value as cfg then
				Result := is_path_in_target (cfg.path)
			elseif attached {LIBRARY_INFO} a_item.value as inf then
				Result := is_path_in_target ((create {CONF_FILE_LOCATION}.make (inf.location.name, target)).evaluated_path)
			elseif attached {IRON_PACKAGE} a_item.value as p and then attached p.name as l_name then
				l_prefix := {STRING_32} "iron:" + l_name.as_lower + {STRING_32} ":"
				across
					target.libraries as ic
				until
					Result
				loop
					Result := ic.location.original_path.as_lower.starts_with (l_prefix)
				end
			end
		end

	is_path_in_target (p: PATH): BOOLEAN
			-- Is configuration file `p' used by `target' as library or precompiled library?
		local
			s: STRING_32
		do
			s := normalized_path_name (p)
			across
				target.libraries as ic
			until
				Result
			loop
				Result := normalized_path_name (ic.location.evaluated_path).same_string (s)
			end
			if not Result and then attached target.precompile as l_precompile then
				Result := normalized_path_name (l_precompile.location.evaluated_path).same_string (s)
			end
		end

	category_title (a_category: READABLE_STRING_GENERAL): STRING_32
			-- Text to display for category `a_category'.
		do
			if a_category.is_case_insensitive_equal ({ES_LIBRARY_CATEGORIES}.official) then
				Result := conf_interface_names.dialog_search_library_category_official
			elseif a_category.is_case_insensitive_equal ({ES_LIBRARY_CATEGORIES}.contrib) then
				Result := conf_interface_names.dialog_search_library_category_contrib
			elseif a_category.is_case_insensitive_equal ({ES_LIBRARY_CATEGORIES}.prerelease) then
				Result := conf_interface_names.dialog_search_library_category_prerelease
			elseif a_category.is_case_insensitive_equal ({ES_LIBRARY_CATEGORIES}.precompiled) then
				Result := conf_interface_names.dialog_search_library_category_precompiled
			else
					-- Discovered category: capitalized.
				create Result.make_from_string_general (a_category)
				if not Result.is_empty then
					Result.put (Result [1].as_upper, 1)
				end
			end
		end

	one_line_description (a_desc: detachable READABLE_STRING_GENERAL): detachable READABLE_STRING_GENERAL
		local
			s: STRING_32
			i: INTEGER
		do
			if a_desc /= Void then
				create s.make_from_string_general (a_desc)
				s.left_adjust
				s.right_adjust
				if not s.is_empty then
					i := s.index_of ('%N', 1)
					if i > 0 then
						s.keep_head (i - 1)
						s.right_adjust
						s.append ("...")
					end
					Result := s
				end
			end
		end

feature -- Event

	hide
		do
			widget.hide
		end

	show
		do
			widget.show
		end

	set_focus
		do
			grid.set_focus
			if grid.row_count > 0 and then grid.selected_rows.is_empty then
				grid.row (1).enable_select
			end
		end

	set_minimum_size (w,h: INTEGER)
		do
			grid.set_minimum_size (w, h)
		end

	update_grid
			-- Update grid with `items'.
		require
			populated_items_attached: items /= Void
		local
			g: like grid
			l_row: EV_GRID_ROW
			l_col: EV_GRID_COLUMN
			i: INTEGER
			l_selected: like selected_item
		do
			g := grid
			l_selected := selected_item
			g.remove_and_clear_all_rows
			if attached items as lst and then not lst.is_empty then
				g.set_row_count_to (lst.count)
				i := 0
				across
					lst as ic
				loop
					i := i + 1
					l_row := g.row (i)
					l_row.set_data (ic)
					compute_grid_row (l_row, ic)
					l_row.select_actions.extend (agent on_item_selected (l_row, ic))
					l_row.deselect_actions.extend (agent on_item_deselected (l_row, ic))
				end
				across
					<<name_column, category_column, void_safety_column, source_column, info_column>> as c
				loop
					l_col := g.column (c)
					l_col.resize_to_content
					l_col.set_width (l_col.width + 6)
				end
				if l_selected /= Void then
					select_row_by_value (l_selected.value)
				end
			end
		end

	refresh_rows
			-- Refresh the content of the rows (for instance the "in project" status).
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > grid.row_count
			loop
				if attached {ES_LIBRARY_PROVIDER_ITEM} grid.row (i).data as l_data then
					compute_grid_row (grid.row (i), l_data)
				end
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	compute_grid_row (a_row: EV_GRID_ROW; a_data: ES_LIBRARY_PROVIDER_ITEM)
			-- Compute grid items of `a_row' for `a_data'.
		local
			l_item: EV_GRID_LABEL_ITEM
			l_information: READABLE_STRING_32
			nb_lines, c: INTEGER
		do
				-- In project
			create l_item
			if is_in_target (a_data) then
				l_item.set_pixmap (conf_pixmaps.general_tick_icon)
				l_item.set_tooltip (conf_interface_names.dialog_search_library_in_project_tooltip)
			end
			a_row.set_item (in_project_column, l_item)

				-- Name
			create l_item.make_with_text (item_name (a_data))
			if attached {IRON_PACKAGE} a_data.value then
				l_item.set_pixmap (conf_pixmaps.library_iron_package_icon)
			elseif is_precompile_item (a_data) then
				l_item.set_pixmap (conf_pixmaps.new_precompiled_library_icon)
			elseif attached {CONF_SYSTEM_VIEW} a_data.value as cfg and then cfg.original_location.starts_with ({STRING_32} "iron:") then
				l_item.set_pixmap (conf_pixmaps.library_iron_library_icon)
			else
				l_item.set_pixmap (conf_pixmaps.new_library_icon)
			end
			if attached item_description (a_data) as d then
				l_item.set_tooltip (d)
			end
			a_row.set_item (name_column, l_item)

				-- Category
			create l_item.make_with_text (category_text (a_data))
			a_row.set_item (category_column, l_item)

				-- Void-safety
			create l_item.make_with_text (void_safety_text (a_data))
			inspect
				void_safety_compatibility (a_data)
			when compatibility_ok then
				l_item.set_pixmap (conf_pixmaps.general_tick_icon)
			when compatibility_warning then
				l_item.set_pixmap (conf_pixmaps.general_warning_icon)
			when compatibility_too_weak then
				l_item.set_pixmap (conf_pixmaps.general_warning_icon)
				l_item.set_text (void_safety_text (a_data) + {STRING_32} " (" + conf_interface_names.dialog_search_library_incompatible + {STRING_32} ")")
			else
			end
			if attached {CONF_SYSTEM_VIEW} a_data.value as cfg and then attached cfg.conf_option as l_options then
				l_item.set_tooltip (conf_interface_names.option_void_safety_value_description [l_options.void_safety.index])
			end
			a_row.set_item (void_safety_column, l_item)

				-- Source
			create l_item.make_with_text (source_text (a_data))
			if attached {IRON_PACKAGE} a_data.value and then not is_iron_package_installed (a_data) then
				l_item.set_pixmap (conf_pixmaps.general_add_icon)
			end
			a_row.set_item (source_column, l_item)

				-- Information
			l_information := information_text (a_data)
			create l_item.make_with_text (l_information)
			if attached {CONF_SYSTEM_VIEW} a_data.value as cfg and then attached cfg.info ("tags") as l_tags then
				l_item.set_tooltip (conf_interface_names.iron_box_tags_label + {STRING_32} ": " + l_tags)
			end
			a_row.set_item (info_column, l_item)

			from
				c := 1
			until
				c > last_column
			loop
				if attached {EV_GRID_LABEL_ITEM} a_row.item (c) as gi then
					gi.align_text_top
				end
				c := c + 1
			end
			if not is_compatible (a_data) then
				a_row.set_foreground_color ((create {EV_STOCK_COLORS}).grey)
			end
			nb_lines := l_information.occurrences ('%N') + 1
			if nb_lines > 1 then
				a_row.set_height (nb_lines * grid.row_height)
			end
		end

	normalized_path_name (p: PATH): STRING_32
			-- Lower case name of canonical absolute path `p'.
		do
			Result := p.absolute_path.canonical_path.name.as_lower
		end

feature -- Widgets

	box: EV_VERTICAL_BOX

	grid: ES_GRID

feature -- Constants

	compatibility_unknown: INTEGER = 0
	compatibility_ok: INTEGER = 1
	compatibility_warning: INTEGER = 2
	compatibility_too_weak: INTEGER = 3

feature {NONE} -- Constants

	in_project_column: INTEGER = 1
			-- Index of a column with the "in project" marker.

	name_column: INTEGER = 2
			-- Index of a column with name.

	category_column: INTEGER = 3
			-- Index of a column with the category.

	void_safety_column: INTEGER = 4
			-- Index of a column with void-safety status.

	source_column: INTEGER = 5
			-- Index of a column with the source.

	info_column: INTEGER = 6
			-- Index of a column with a information.

	last_column: INTEGER = 6

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
