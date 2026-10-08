note
	description: "[
			Dialog to find libraries (local, iron packages, precompiled libraries), by metadata or by class name,
			and add them to the target (as library, or precompiled library).
			Each change is stored (see `store_target'), and the dialog stays open to add other libraries.
			The added libraries are listed in `added_libraries'.

			Layout:
				| search options (search text, mode, sources, categories)                |
				| results grid                  | details of the selected item (optional) |
				| custom, refresh, packages, status       [Details] [Add to project] [Close] |
			When the dialog is not wide enough, the details are displayed below the results.
		]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	FIND_LIBRARY_DIALOG

inherit
	EV_DIALOG
		redefine
			create_interface_objects,
			initialize
		end

	CONF_ACCESS
		undefine
			copy,
			default_create
		end

	CONF_FILE_CONSTANTS
		undefine
			copy,
			default_create
		end

	CONF_GUI_INTERFACE_CONSTANTS
		undefine
			copy,
			default_create
		end

	EIFFEL_LAYOUT
		export
			{NONE} all
		undefine
			copy,
			default_create
		end

feature {NONE} -- Initialization

	make (a_target: CONF_TARGET; a_factory: like factory)
			-- Create dialog to add libraries to `a_target', using `a_factory'.
		do
			target := a_target
			factory := a_factory
			default_create
		ensure
			target_set: target = a_target
			factory_set: factory = a_factory
		end

	create_interface_objects
		local
			l_service: ES_GUI_IRON_SERVICE
		do
			Precursor
			create l_service
			iron_service := l_service
			create search_box.make (target, l_service)
			create details_box.make (search_box.items_box, l_service)
			create details_frame
			create add_button.make_with_text (conf_interface_names.dialog_find_library_add_to_project)
			create close_button.make_with_text (conf_interface_names.dialog_find_library_close)
			create details_toggle.make_with_text (conf_interface_names.dialog_find_library_details)
			create custom_button.make_with_text (conf_interface_names.dialog_find_library_add_custom)
			create add_menu_button.make_with_text (conf_interface_names.dialog_find_library_add_menu + menu_indicator)
			create settings_menu_button.make_with_text (conf_interface_names.dialog_find_library_settings_menu + menu_indicator)
			create footer_box
			create footer_viewport
			create status_line_cell
			is_footer_status_inline := True
			create layout_cell
			create horizontal_split
			create vertical_split
			create added_libraries.make (1)
			is_details_shown := True
		end

	initialize
		local
			main: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
		do
			Precursor
			set_title (conf_interface_names.dialog_find_library_title)
			set_icon_pixmap (conf_pixmaps.new_library_icon)

			if is_precompile_supported then
				search_box.enable_precompile_option
			end

			create main
			main.set_padding (layout_constants.default_padding_size)
			main.set_border_width (layout_constants.default_border_size)
			extend (main)

				-- Search options (full width)
			main.extend (search_box.options_widget)
			main.disable_item_expand (search_box.options_widget)

				-- Results | Details
			details_frame.extend (details_box.widget)
			main.extend (layout_cell)

				-- Status line (only used when the footer is too narrow, see `update_footer_layout')
			main.extend (status_line_cell)
			main.disable_item_expand (status_line_cell)
			status_line_cell.hide

				-- Footer: | (Settings v) tools bar | [Details] [Add to project] [Add custom...] (Add v) [Close] |
			hb := footer_box
			hb.set_padding (layout_constants.default_padding_size)
			settings_menu_button.set_tooltip (conf_interface_names.dialog_find_library_settings_menu_tooltip)
			settings_menu_button.hide
			hb.extend (settings_menu_button)
			hb.disable_item_expand (settings_menu_button)
			hb.extend (search_box.tools_bar_widget)
			details_toggle.set_tooltip (conf_interface_names.dialog_find_library_details_tooltip)
			details_toggle.enable_select
			hb.extend (details_toggle)
			hb.disable_item_expand (details_toggle)
			hb.extend (add_button)
			hb.disable_item_expand (add_button)
			custom_button.set_tooltip (conf_interface_names.dialog_find_library_add_custom_tooltip)
			custom_button.set_pixmap (conf_pixmaps.new_library_icon)
			hb.extend (custom_button)
			hb.disable_item_expand (custom_button)
			add_menu_button.set_tooltip (conf_interface_names.dialog_find_library_add_menu_tooltip)
			add_menu_button.hide
			hb.extend (add_menu_button)
			hb.disable_item_expand (add_menu_button)
			close_button.set_tooltip (conf_interface_names.dialog_find_library_close_tooltip)
			layout_constants.set_default_width_for_button (close_button)
			hb.extend (close_button)
			hb.disable_item_expand (close_button)
			footer_viewport.extend (hb)
			footer_viewport.set_minimum_height (hb.minimum_height)
			main.extend (footer_viewport)
			main.disable_item_expand (footer_viewport)

			set_default_cancel_button (close_button)

				-- Actions
			add_button.select_actions.extend (agent on_add)
			close_button.select_actions.extend (agent on_close)
			close_request_actions.extend (agent on_close)
			custom_button.select_actions.extend (agent on_add_custom_library)
			add_menu_button.select_actions.extend (agent show_add_menu)
			settings_menu_button.select_actions.extend (agent show_settings_menu)
			footer_viewport.resize_actions.extend (agent (ia_x, ia_y, ia_w, ia_h: INTEGER) do update_footer_layout end)
			search_box.status_change_actions.extend (agent update_footer_layout)
			details_toggle.select_actions.extend (agent on_details_toggled)
			search_box.on_item_selected_actions.extend (agent on_item_selected)
			search_box.on_item_activated_actions.extend (agent on_item_activated)
			details_box.name_changed_actions.extend (agent update_add_button)
			details_box.install_actions.extend (agent install_package)
			details_box.uninstall_actions.extend (agent uninstall_package)
			resize_actions.extend (agent (ia_x, ia_y, ia_w, ia_h: INTEGER) do on_resized (ia_w) end)
			search_box.set_parent_window (Current)
			iron_service.set_associated_widget (Current)

			set_size (1000, 650)
			load_settings
			update_layout
			update_add_button

			show_actions.extend_kamikaze (agent
					do
						on_resized (width)
						apply_split_proportion
						search_box.populate
						search_box.set_search_focus
					end)
		end

feature -- Access

	target: CONF_TARGET
			-- Target where the libraries are added.

	factory: CONF_PARSE_FACTORY
			-- Factory to create the libraries.

	added_libraries: ARRAYED_LIST [CONF_LIBRARY]
			-- Libraries added to `target', in order.

feature -- Status report

	is_precompile_supported: BOOLEAN
			-- Can precompiled libraries be searched and set as precompile of `target'?
		do
			Result := True
		end

	has_included_libraries: BOOLEAN
			-- Was any library added to `target'?

	has_changed_precompile: BOOLEAN
			-- Was the precompiled library of `target' changed?
			-- (then the project has to be recompiled from scratch).

feature {NONE} -- Storage

	store_target: BOOLEAN
			-- Store the configuration file of `target' (and refresh the environment).
			-- Return True if succeeded, otherwise report the error.
		deferred
		end

feature {NONE} -- Layout

	is_details_shown: BOOLEAN
			-- Is the details panel shown?

	is_vertical_layout: BOOLEAN
			-- Are the details displayed below the results (instead of on the right)?

	vertical_layout_width: INTEGER = 900
			-- Width under which the details are displayed below the results.

	on_resized (a_width: INTEGER)
			-- Dialog resized to `a_width'.
		do
			if (a_width < vertical_layout_width) /= is_vertical_layout then
				save_split_proportion
				is_vertical_layout := not is_vertical_layout
				update_layout
				apply_split_proportion
			end
		end

	is_footer_compact: BOOLEAN
			-- Are the footer buttons merged into drop down menus ("Settings" and "Add")?

	is_footer_status_inline: BOOLEAN
			-- Is the status line displayed in the footer (otherwise on its own line, above the footer)?

	update_footer_layout
			-- Update the footer according to the available width:
			--  - wide enough: tools buttons, status, and all buttons,
			--  - otherwise: status on its own line, between the results and the footer,
			--  - even smaller: tools buttons and "Add" buttons merged into drop down menus.
		local
			w, l_buttons_width, l_status_width: INTEGER
			l_compact, l_inline: BOOLEAN
		do
			w := footer_viewport.width
			if w > 0 then
				l_buttons_width := search_box.tools_buttons_widget.minimum_width
					+ details_toggle.minimum_width + add_button.minimum_width
					+ custom_button.minimum_width + close_button.minimum_width
					+ 6 * layout_constants.default_padding_size
				if not search_box.status_text.is_empty then
					l_status_width := search_box.status_widget.font.string_width (search_box.status_text) + layout_constants.default_padding_size
				end
				l_inline := w >= l_buttons_width + l_status_width
				l_compact := w < l_buttons_width
				if l_inline /= is_footer_status_inline then
					is_footer_status_inline := l_inline
					if l_inline then
						status_line_cell.wipe_out
						status_line_cell.hide
						search_box.restore_status_widget
					else
						if attached search_box.status_widget.parent as p then
							p.prune (search_box.status_widget)
						end
						status_line_cell.extend (search_box.status_widget)
						status_line_cell.show
					end
				end
				if l_compact /= is_footer_compact then
					is_footer_compact := l_compact
					if l_compact then
						search_box.tools_buttons_widget.hide
						add_button.hide
						custom_button.hide
						settings_menu_button.show
						add_menu_button.show
					else
						settings_menu_button.hide
						add_menu_button.hide
						search_box.tools_buttons_widget.show
						add_button.show
						custom_button.show
					end
				end
					-- Footer fills the viewport (or is clipped, while the layout is updated).
				footer_viewport.set_item_size (w.max (footer_box.minimum_width), footer_box.minimum_height)
			end
		end

	menu_indicator: STRING_32 = " %/9662/"
			-- Suffix of buttons opening a drop down menu.

	show_add_menu
			-- Show the "Add" drop down menu.
		local
			m: EV_MENU
			mi: EV_MENU_ITEM
		do
			create m
			create mi.make_with_text_and_action (add_button.text, agent on_add)
			mi.set_pixmap (conf_pixmaps.new_library_icon)
			if not add_button.is_sensitive then
				mi.disable_sensitive
			end
			m.extend (mi)
			create mi.make_with_text_and_action (custom_button.text, agent on_add_custom_library)
			m.extend (mi)
			m.show_at (add_menu_button, 0, add_menu_button.height)
		end

	show_settings_menu
			-- Show the "Settings" drop down menu.
		do
			search_box.new_tools_menu.show_at (settings_menu_button, 0, settings_menu_button.height)
		end

	on_details_toggled
			-- Show/hide the details panel.
		do
			save_split_proportion
			is_details_shown := details_toggle.is_selected
			update_layout
			apply_split_proportion
		end

	update_layout
			-- Place the results and the details according to `is_details_shown' and `is_vertical_layout'.
		local
			w_results: EV_WIDGET
			l_split: EV_SPLIT_AREA
		do
			w_results := search_box.results_widget
			layout_cell.wipe_out
			if attached w_results.parent as p then
				p.prune (w_results)
			end
			if attached details_frame.parent as p then
				p.prune (details_frame)
			end
			if is_details_shown then
				l_split := current_split
				l_split.set_first (w_results)
				l_split.set_second (details_frame)
				layout_cell.extend (l_split)
			else
				layout_cell.extend (w_results)
			end
		end

	current_split: EV_SPLIT_AREA
			-- Split area used by the current layout.
		do
			if is_vertical_layout then
				Result := vertical_split
			else
				Result := horizontal_split
			end
		end

	apply_split_proportion
			-- Apply the split proportion (once the layout is displayed).
		do
			if attached (create {EV_ENVIRONMENT}).application as l_app then
				l_app.do_once_on_idle (agent
					local
						l_split: EV_SPLIT_AREA
					do
						l_split := current_split
						if is_details_shown and then l_split.full and then l_split.is_displayed then
							if is_vertical_layout then
								l_split.set_proportion (vertical_split_proportion)
							else
								l_split.set_proportion (horizontal_split_proportion)
							end
						end
					end)
			end
		end

	save_split_proportion
			-- Remember the split proportion of the current layout.
		local
			l_split: EV_SPLIT_AREA
		do
			l_split := current_split
			if is_details_shown and then l_split.full and then l_split.is_displayed then
				if is_vertical_layout then
					if l_split.height > 0 then
						vertical_split_proportion := (l_split.split_position / l_split.height).truncated_to_real.max (0.2).min (0.9)
					end
				elseif l_split.width > 0 then
					horizontal_split_proportion := (l_split.split_position / l_split.width).truncated_to_real.max (0.2).min (0.9)
				end
			end
		end

	horizontal_split_proportion: REAL
			-- Proportion of the results, when the details are on the right.

	vertical_split_proportion: REAL
			-- Proportion of the results, when the details are below.

feature {NONE} -- Events

	on_item_selected (a_item: detachable ES_LIBRARY_PROVIDER_ITEM)
			-- `a_item' was selected in the results.
		do
			details_box.set_item (a_item)
			update_add_button
		end

	on_item_activated (a_item: ES_LIBRARY_PROVIDER_ITEM)
			-- `a_item' was activated (double click, Enter key) in the results.
		do
			if details_box.item = a_item and add_button.is_sensitive then
				on_add
			end
		end

	on_close
			-- Close the dialog.
		do
			save_settings
			destroy
		end

	update_add_button
			-- Update the text, tooltip and sensitivity of `add_button' according to the selected item.
		local
			b: EIFFEL_SEARCH_ITEMS_BOX
		do
			b := search_box.items_box
			if attached details_box.item as l_item then
				if attached {IRON_PACKAGE} l_item.value and then not b.is_iron_package_installed (l_item) then
					add_button.set_text (conf_interface_names.dialog_find_library_install_and_add)
					add_button.set_tooltip (conf_interface_names.dialog_find_library_install_and_add_tooltip)
				elseif b.is_precompile_item (l_item) and then target.precompile /= Void then
					add_button.set_text (conf_interface_names.dialog_find_library_replace_precompile)
					add_button.set_tooltip (conf_interface_names.dialog_find_library_replace_precompile_tooltip)
				else
					add_button.set_text (conf_interface_names.dialog_find_library_add_to_project)
					add_button.set_tooltip (conf_interface_names.dialog_find_library_add_to_project_tooltip)
				end
				if
					b.is_in_target (l_item) or else
					not b.is_compatible (l_item) or else
					(b.is_precompile_item (l_item) and not is_precompile_supported) or else
					not details_box.is_name_valid
				then
					add_button.disable_sensitive
				else
					add_button.enable_sensitive
				end
			else
				add_button.set_text (conf_interface_names.dialog_find_library_add_to_project)
				add_button.set_tooltip (conf_interface_names.dialog_find_library_add_to_project_tooltip)
				add_button.disable_sensitive
			end
				-- Ensure the whole text is visible.
			add_button.set_minimum_width (
					(add_button.font.string_width (add_button.text) + 4 * layout_constants.default_padding_size)
					.max (layout_constants.default_button_width)
				)
			update_footer_layout
		end

feature {NONE} -- Add to project

	on_add
			-- Add the selected item to `target'.
		local
			b: EIFFEL_SEARCH_ITEMS_BOX
			n, l_location: STRING_32
		do
			b := search_box.items_box
			if attached details_box.item as l_item and then add_button.is_sensitive then
				n := details_box.name_in_project
				l_location := details_box.location_in_project
				if attached {IRON_PACKAGE} l_item.value as p then
					if b.is_iron_package_installed (l_item) then
						add_package_library (p, n)
					else
						iron_service.install_package (p, agent on_package_installed (p, n, True, ?))
					end
				elseif b.is_precompile_item (l_item) then
					if attached target.precompile as l_precompile then
						prompts.show_question_prompt (
								conf_interface_names.dialog_find_library_replace_precompile_question (l_precompile.name, l_precompile.location.original_path, l_location),
								Current,
								agent set_target_precompile (n, l_location), Void
							)
					else
						set_target_precompile (n, l_location)
					end
				else
					add_library (n, l_location)
				end
			end
		end

	add_library (a_name, a_location: READABLE_STRING_32)
			-- Add library `a_name' located at `a_location' to `target', and store the configuration.
		local
			g: CONF_LIBRARY
			l_sys: CONF_SYSTEM
		do
			g := factory.new_library (a_name, a_location, target)
				-- Add an empty classes list so that it gets displayed in the classes tree.
			g.set_classes (create {STRING_TABLE [CONF_CLASS]}.make (0))
			l_sys := factory.new_system_generate_uuid_with_file_name ("dummy_location", "dummy", latest_namespace)
			l_sys.set_application_target (target)
			g.set_library_target (factory.new_target ("dummy", l_sys))
			target.add_library (g)
			if store_target then
				has_included_libraries := True
				added_libraries.extend (g)
				on_target_changed (conf_interface_names.dialog_find_library_added (a_name))
			else
					-- Revert
				target.remove_library (g.name)
			end
		end

	set_target_precompile (a_name, a_location: READABLE_STRING_32)
			-- Set precompiled library `a_name' located at `a_location' as the precompile of `target',
			-- and store the configuration.
		local
			l_old: like {CONF_TARGET}.precompile
		do
			l_old := target.precompile
			target.set_precompile (factory.new_precompile (a_name, a_location, target))
			if store_target then
				has_changed_precompile := True
				on_target_changed (conf_interface_names.dialog_find_library_precompile_set (a_name))
			else
					-- Revert
				target.set_precompile (l_old)
			end
		end

	add_package_library (p: IRON_PACKAGE; a_name: READABLE_STRING_32)
			-- Add the library of installed package `p' (as `a_name' if the package has a single library).
		local
			l_api: IRON_INSTALLATION_API
			l_projects: LIST [PATH]
		do
			l_api := iron_service.installation_api
			if l_api.is_package_installed (p) then
				l_projects := l_api.projects_from_installed_package (p)
				if l_projects.is_empty then
					prompts.show_error_prompt (conf_interface_names.dialog_find_library_no_project_in_package (p.identifier), Current, Void)
				elseif l_projects.count = 1 then
					add_library (a_name, iron_location (p, l_projects.first))
				else
					choose_package_project (p, l_projects)
				end
			end
		end

	choose_package_project (p: IRON_PACKAGE; a_projects: LIST [PATH])
			-- Choose which project of package `p' to add, among `a_projects'.
		local
			dlg: EV_DIALOG
			vb: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
			lst: EV_LIST
			li: EV_LIST_ITEM
			b_ok, b_cancel: EV_BUTTON
		do
			create dlg.make_with_title (conf_interface_names.dialog_find_library_choose_project_title (p.identifier))
			create vb
			vb.set_padding (layout_constants.default_padding_size)
			vb.set_border_width (layout_constants.default_border_size)
			create lst
			lst.set_minimum_size (350, 150)
			across
				a_projects as ic
			loop
				create li.make_with_text (ic.name)
				li.set_data (ic)
				lst.extend (li)
			end
			if attached lst.first as l_first then
				l_first.enable_select
			end
			vb.extend (lst)

			create hb
			hb.set_padding (layout_constants.default_padding_size)
			hb.extend (create {EV_CELL})
			create b_ok.make_with_text (conf_interface_names.dialog_find_library_add_to_project)
			b_ok.set_tooltip (conf_interface_names.dialog_find_library_add_to_project_tooltip)
			b_ok.select_actions.extend (agent (ia_p: IRON_PACKAGE; ia_lst: EV_LIST; ia_dlg: EV_DIALOG)
					do
						if attached ia_lst.selected_item as sel and then attached {PATH} sel.data as l_proj then
							ia_dlg.destroy
							add_library (project_name (l_proj), iron_location (ia_p, l_proj))
						end
					end (p, lst, dlg))
			layout_constants.set_default_width_for_button (b_ok)
			hb.extend (b_ok)
			hb.disable_item_expand (b_ok)
			create b_cancel.make_with_text_and_action (conf_interface_names.dialog_find_library_close, agent dlg.destroy)
			b_cancel.set_tooltip (conf_interface_names.dialog_find_library_close_tooltip)
			layout_constants.set_default_width_for_button (b_cancel)
			hb.extend (b_cancel)
			hb.disable_item_expand (b_cancel)
			vb.extend (hb)
			vb.disable_item_expand (hb)
			dlg.extend (vb)
			dlg.set_default_push_button (b_ok)
			dlg.set_default_cancel_button (b_cancel)
			dlg.show_modal_to_window (Current)
		end

	iron_location (p: IRON_PACKAGE; a_project: PATH): STRING_32
			-- Location of the library `a_project' from iron package `p'.
		do
			Result := {STRING_32} "iron:" + p.identifier + {STRING_32} ":" + a_project.name
		end

	project_name (a_project: PATH): STRING_32
			-- Default library name for project `a_project' (file name without extension).
		local
			i: INTEGER
		do
			if attached a_project.entry as e then
				create Result.make_from_string (e.name)
			else
				create Result.make_from_string (a_project.name)
			end
			i := Result.last_index_of ('.', Result.count)
			if i > 1 then
				Result.keep_head (i - 1)
			end
		end

	on_target_changed (a_message: READABLE_STRING_GENERAL)
			-- `target' was changed: refresh the UI, and report `a_message'.
		do
			search_box.refresh_rows
			details_box.set_item (details_box.item)
			update_add_button
			search_box.set_status_message (a_message)
		end

feature {NONE} -- Custom library

	on_add_custom_library
			-- Add a library from any location.
		local
			dlg: EV_DIALOG
			vb: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
			lab: EV_LABEL
			l_name, l_location: EV_TEXT_FIELD
			b_browse, b_ok, b_cancel: EV_BUTTON
			l_width: INTEGER
		do
			create dlg.make_with_title (conf_interface_names.dialog_find_library_add_custom_title)
			dlg.set_icon_pixmap (conf_pixmaps.new_library_icon)
			create vb
			vb.set_padding (layout_constants.default_padding_size)
			vb.set_border_width (layout_constants.default_border_size)
			create l_name
			create l_location
			l_location.set_minimum_width (400)

			create lab.make_with_text (conf_interface_names.dialog_find_library_location)
			l_width := lab.minimum_width.max ((create {EV_LABEL}.make_with_text (conf_interface_names.dialog_create_library_name)).minimum_width)

				-- Location
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			lab.align_text_left
			lab.set_minimum_width (l_width)
			hb.extend (lab)
			hb.disable_item_expand (lab)
			hb.extend (l_location)
			create b_browse.make_with_text (conf_interface_names.browse)
			b_browse.set_tooltip (conf_interface_names.dialog_find_library_add_custom_tooltip)
			b_browse.select_actions.extend (agent browse_ecf (dlg, l_name, l_location))
			hb.extend (b_browse)
			hb.disable_item_expand (b_browse)
			vb.extend (hb)
			vb.disable_item_expand (hb)

				-- Name
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			create lab.make_with_text (conf_interface_names.dialog_create_library_name)
			lab.align_text_left
			lab.set_minimum_width (l_width)
			hb.extend (lab)
			hb.disable_item_expand (lab)
			hb.extend (l_name)
			vb.extend (hb)
			vb.disable_item_expand (hb)

				-- Buttons
			create hb
			hb.set_padding (layout_constants.default_padding_size)
			hb.extend (create {EV_CELL})
			create b_ok.make_with_text (conf_interface_names.dialog_find_library_add_to_project)
			b_ok.set_tooltip (conf_interface_names.dialog_find_library_add_to_project_tooltip)
			b_ok.select_actions.extend (agent on_custom_library_ok (dlg, l_name, l_location))
			layout_constants.set_default_width_for_button (b_ok)
			hb.extend (b_ok)
			hb.disable_item_expand (b_ok)
			create b_cancel.make_with_text_and_action (conf_interface_names.dialog_find_library_close, agent dlg.destroy)
			b_cancel.set_tooltip (conf_interface_names.dialog_find_library_close_tooltip)
			layout_constants.set_default_width_for_button (b_cancel)
			hb.extend (b_cancel)
			hb.disable_item_expand (b_cancel)
			vb.extend (hb)
			vb.disable_item_expand (hb)

			dlg.extend (vb)
			dlg.set_default_push_button (b_ok)
			dlg.set_default_cancel_button (b_cancel)
			dlg.show_actions.extend_kamikaze (agent l_location.set_focus)
			dlg.show_modal_to_window (Current)
		end

	browse_ecf (a_dialog: EV_DIALOG; a_name, a_location: EV_TEXT_FIELD)
			-- Browse for an Eiffel configuration file, and set `a_location' (and `a_name' if empty).
		local
			fd: EV_FILE_OPEN_DIALOG
			s: STRING_32
			i: INTEGER
		do
			create fd
			fd.filters.extend ([config_files_filter, config_files_description])
			fd.filters.extend ([all_files_filter, all_files_description])
			fd.show_modal_to_window (a_dialog)
			if attached fd.full_file_path as p and then not p.is_empty then
				a_location.set_text (p.name)
				if a_name.text.is_whitespace and then attached p.entry as e then
					create s.make_from_string (e.name)
					i := s.last_index_of ('.', s.count)
					if i > 1 then
						s.keep_head (i - 1)
					end
					a_name.set_text (s)
				end
			end
		end

	on_custom_library_ok (a_dialog: EV_DIALOG; a_name, a_location: EV_TEXT_FIELD)
			-- Add the custom library.
		local
			n, loc: STRING_32
		do
			n := a_name.text
			n.adjust
			loc := a_location.text
			loc.adjust
			if loc.is_empty then
				prompts.show_error_prompt (conf_interface_names.dialog_find_library_location_required, a_dialog, Void)
			elseif attached details_box.name_error_for (n, False) as e then
				prompts.show_error_prompt (e, a_dialog, Void)
			else
				a_dialog.destroy
				add_library (n, loc)
			end
		end

feature {NONE} -- Iron packages

	install_package (p: IRON_PACKAGE)
			-- Install iron package `p' (without adding it to the project).
		do
			iron_service.install_package (p, agent on_package_installed (p, Void, False, ?))
		end

	uninstall_package (p: IRON_PACKAGE)
			-- Uninstall iron package `p'.
		do
			iron_service.uninstall_package (p, agent on_package_uninstalled (p, ?))
		end

	on_package_installed (p: IRON_PACKAGE; a_name: detachable READABLE_STRING_32; a_add: BOOLEAN; a_succeed: BOOLEAN)
			-- Package `p' was installed (if `a_succeed'), then if `a_add', add its library as `a_name'.
		do
			if a_succeed then
				search_box.notify_iron_packages_changed (p)
				search_box.select_row_by_value (p)
				if a_add and a_name /= Void then
					add_package_library (p, a_name)
				end
			end
		end

	on_package_uninstalled (p: IRON_PACKAGE; a_succeed: BOOLEAN)
			-- Package `p' was uninstalled (if `a_succeed').
		do
			if a_succeed then
				search_box.notify_iron_packages_changed (p)
				search_box.select_row_by_value (p)
			end
		end

feature {NONE} -- Settings

	settings_file: PATH
			-- File to store the dialog settings.
		do
			if eiffel_layout.is_hidden_files_path_available then
				Result := eiffel_layout.hidden_files_path.extended ("find_library.settings")
			else
				Result := eiffel_layout.temporary_path.extended ("find_library.settings")
			end
		end

	load_settings
			-- Load and apply the dialog settings, if any.
		local
			f: PLAIN_TEXT_FILE
			tb: STRING_TABLE [READABLE_STRING_32]
			s: STRING_32
			i: INTEGER
			u: UTF_CONVERTER
			retried: BOOLEAN
		do
			horizontal_split_proportion := 0.62
			vertical_split_proportion := 0.55
			if not retried and is_eiffel_layout_defined then
				create f.make_with_path (settings_file)
				if f.exists and then f.is_readable then
					create tb.make (20)
					f.open_read
					from
						f.read_line
					until
						f.exhausted
					loop
						s := u.utf_8_string_8_to_string_32 (f.last_string)
						i := s.index_of ('=', 1)
						if i > 1 then
							tb [s.head (i - 1)] := s.substring (i + 1, s.count)
						end
						f.read_line
					end
					f.close
					search_box.apply_settings (tb)
					if
						attached tb ["width"] as w and then w.is_integer and then
						attached tb ["height"] as h and then h.is_integer
					then
						set_size (w.to_integer.max (500), h.to_integer.max (350))
					end
					if attached tb ["split"] as l_split and then l_split.is_real then
						horizontal_split_proportion := l_split.to_real.max (0.2).min (0.9)
					end
					if attached tb ["vertical_split"] as l_split and then l_split.is_real then
						vertical_split_proportion := l_split.to_real.max (0.2).min (0.9)
					end
					if attached tb ["details"] as l_details and then l_details.is_case_insensitive_equal ("false") then
						is_details_shown := False
						details_toggle.disable_select
					end
				end
			end
		rescue
			retried := True
			retry
		end

	save_settings
			-- Save the dialog settings.
		local
			f: PLAIN_TEXT_FILE
			tb: STRING_TABLE [READABLE_STRING_32]
			u: UTF_CONVERTER
			retried: BOOLEAN
		do
			if not retried and is_eiffel_layout_defined then
				save_split_proportion
				tb := search_box.settings
				tb ["width"] := width.out.to_string_32
				tb ["height"] := height.out.to_string_32
				tb ["split"] := horizontal_split_proportion.out.to_string_32
				tb ["vertical_split"] := vertical_split_proportion.out.to_string_32
				if is_details_shown then
					tb ["details"] := {STRING_32} "true"
				else
					tb ["details"] := {STRING_32} "false"
				end
				create f.make_with_path (settings_file)
				f.create_read_write
				across
					tb as ic
				loop
					f.put_string (u.string_32_to_utf_8_string_8 (@ ic.key.to_string_32 + {STRING_32} "=" + ic))
					f.put_new_line
				end
				f.close
			end
		rescue
			retried := True
			retry
		end

feature {NONE} -- Implementation

	iron_service: ES_GUI_IRON_SERVICE
			-- Iron service.

	search_box: LIBRARY_SEARCH_BOX
			-- Search options, results and tools bar.

	details_box: LIBRARY_DETAILS_BOX
			-- Details of the selected item.

	details_frame: EV_FRAME
			-- Frame containing the details.

	layout_cell: EV_CELL
			-- Cell containing the results (and the details).

	horizontal_split: EV_HORIZONTAL_SPLIT_AREA
			-- Results | Details.

	vertical_split: EV_VERTICAL_SPLIT_AREA
			-- Results above Details.

	details_toggle: EV_TOGGLE_BUTTON
			-- Show/hide details.

	custom_button: EV_BUTTON
			-- "Add custom library..." button.

	add_button: EV_BUTTON
			-- "Add to project" button.

	close_button: EV_BUTTON
			-- "Close" button.

	add_menu_button: EV_BUTTON
			-- "Add" drop down menu (compact version of `add_button' and `custom_button').

	settings_menu_button: EV_BUTTON
			-- "Settings" drop down menu (compact version of the tools buttons).

	footer_box: EV_HORIZONTAL_BOX
			-- Tools bar and buttons.

	footer_viewport: EV_VIEWPORT
			-- Viewport containing `footer_box', so that the footer does not constrain the dialog width.

	status_line_cell: EV_CELL
			-- Status line between the results and the footer, when the footer is too narrow for it.

invariant
	search_box_target: search_box.target = target

note
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
