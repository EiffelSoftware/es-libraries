note
	description: "[
			Box to search libraries (local, iron, available packages) or libraries by class name.
			The results can be filtered by category, and the matching can be strict
			(otherwise the searched text is considered as "*text*").
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	LIBRARY_SEARCH_BOX

inherit
	CONF_GUI_INTERFACE_CONSTANTS

	EIFFEL_LAYOUT
		export
			{NONE} all
		end

create
	make

convert
	widget: {EV_WIDGET}

feature {NONE} -- Initialization

	make (a_target: CONF_TARGET; a_iron_service: ES_GUI_IRON_SERVICE)
			-- Create search box for target `a_target', using iron service `a_iron_service'.
			-- See `set_parent_window'.
		do
			target := a_target
			iron_service := a_iron_service
			create on_item_selected_actions
			create filter
			create strict_checkbox.make_with_text (conf_interface_names.dialog_search_library_strict)
			create category_checkboxes.make (5)
			create custom_buttons_box
			create search_results_box.make (a_target)
			create box
			build_interface (box)
		end

	build_interface (b: EV_VERTICAL_BOX)
			-- Build the options + filter + grid + buttons, into `b'.
		local
			l_btn: EV_BUTTON
			l_padding: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
		do
			b.set_padding (layout_constants.small_padding_size)
			b.set_border_width (layout_constants.small_border_size)

				-- Search container
			build_search_options_bar (b)
			build_category_bar (b)

				-- Grid
			search_results_box.set_minimum_size (600, 100)
			search_results_box.on_item_selected_actions.extend (agent (i: ES_LIBRARY_PROVIDER_ITEM)
					do
						on_item_selected_actions.call ([i])
					end)

				-- Create border for the grid
			create l_padding
			l_padding.set_border_width (1)
			l_padding.set_background_color ((create {EV_STOCK_COLORS}).color_3d_shadow)
			l_padding.extend (search_results_box.widget)
			b.extend (l_padding)

				-- Buttons
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			b.extend (hb)
			b.disable_item_expand (hb)

			custom_buttons_box.set_padding (layout_constants.small_padding_size)
			hb.extend (custom_buttons_box)
			hb.disable_item_expand (custom_buttons_box)

			hb.extend (create {EV_CELL})

			create l_btn
			l_btn.select_actions.extend (agent update_index)
			l_btn.set_text (conf_interface_names.dialog_create_refresh)
			l_btn.set_tooltip (conf_interface_names.dialog_create_refresh_tooltip)
			hb.extend (l_btn)
			hb.disable_item_expand (l_btn)
			layout_constants.set_default_width_for_button (l_btn)

			create l_btn
			l_btn.set_pixmap (conf_pixmaps.project_settings_advanced_icon)
			l_btn.select_actions.extend (agent popup_configuration_information)
			l_btn.set_tooltip (conf_interface_names.dialog_display_configuration_tooltip)
			hb.extend (l_btn)
			hb.disable_item_expand (l_btn)

			create l_btn.make_with_text_and_action (conf_interface_names.dialog_search_library_iron_package_manage_button_label, agent launch_iron_tool)
			l_btn.set_pixmap (conf_pixmaps.library_iron_package_icon)
			l_btn.set_tooltip (conf_interface_names.dialog_search_library_iron_package_manage_button_tooltip)
			hb.extend (l_btn)
			hb.disable_item_expand (l_btn)
			layout_constants.set_default_width_for_button (l_btn)
		end

	build_search_options_bar (a_vertical_container: EV_VERTICAL_BOX)
			-- Search options bar
			-- |[ Search in       (*)  abc [x] def [x]  ]| CE |                            |
			-- |[ Search by class ( )  index [x]        ]| LL |[[ search ][Reset] [ ]Strict]|
		local
			l_opts_vb, vbf: EV_VERTICAL_BOX
			l_search_hb, hbf, hb1, hb2, hb1cb, hb2cb: EV_HORIZONTAL_BOX
			l_radio1, l_radio2: EV_RADIO_BUTTON
			l_filter: like filter
			l_clear_filter_button: EV_BUTTON
			cb: EV_CHECK_BUTTON
			l_checkboxes: like provider_checkboxes
		do
			create l_search_hb
			a_vertical_container.extend (l_search_hb)
			a_vertical_container.disable_item_expand (l_search_hb)

				-- Opts
			create l_opts_vb
			l_search_hb.extend (l_opts_vb)

				-- hbf: filter + reset + strict
			create hbf
			hbf.set_padding (layout_constants.small_padding_size)
			hbf.extend (create {EV_LABEL}.make_with_text (Names.l_filter))
			hbf.disable_item_expand (hbf.last)
			l_filter := filter
			hbf.extend (l_filter)
			l_filter.change_actions.extend (agent request_update_filter)
			create l_clear_filter_button
			l_clear_filter_button.select_actions.extend (agent l_filter.remove_text)
			l_clear_filter_button.set_pixmap (conf_pixmaps.general_remove_icon)
			l_clear_filter_button.set_tooltip (names.b_reset)
			hbf.extend (l_clear_filter_button)
			hbf.disable_item_expand (l_clear_filter_button)

			strict_checkbox.set_tooltip (conf_interface_names.dialog_search_library_strict_tooltip)
			strict_checkbox.select_actions.extend (agent on_strict_changed)
			hbf.extend (strict_checkbox)
			hbf.disable_item_expand (strict_checkbox)
			on_strict_changed

				-- Vertical: filter text field + reset button
			create vbf
			vbf.extend (create {EV_CELL})
			vbf.extend (hbf)
			vbf.disable_item_expand (hbf)

			l_search_hb.extend (vbf)

				-- 2 lines, for search in, and search by class options.
			create hb1
			l_opts_vb.extend (hb1)
			l_opts_vb.disable_item_expand (hb1)
			create hb2
			l_opts_vb.extend (hb2)
			l_opts_vb.disable_item_expand (hb2)

				-- lib providers checkbox list.
			create l_checkboxes.make (search_in_manager.providers.count + search_by_class_manager.providers.count)
			provider_checkboxes := l_checkboxes

				-- hb1: Search in
			if search_in_manager.providers.is_empty then
				hb1.hide
			else
				hb1.set_padding (layout_constants.small_padding_size)
				create l_radio1.make_with_text (conf_interface_names.dialog_search_library_in)
				l_radio1.set_tooltip (conf_interface_names.dialog_search_library_in_tooltip)
				l_radio1.align_text_left
				hb1.extend (l_radio1)
				hb1.disable_item_expand (l_radio1)
				create hb1cb
				across
					search_in_manager.providers as ic
				loop
					create cb.make_with_text (@ ic.key)
					cb.enable_select
					if attached ic.description as d then
						cb.set_tooltip (d)
					end
					hb1cb.extend (cb)
					hb1cb.disable_item_expand (cb)
					l_checkboxes.put (cb, @ ic.key)
					cb.select_actions.extend (agent request_update_filter)
				end
				hb1.extend (hb1cb)
				search_in_checkboxes_box := hb1cb
			end

				-- hb2: Search by class
			if search_by_class_manager.providers.is_empty then
				hb2.hide
			else
				hb2.set_padding (layout_constants.small_padding_size)
				create l_radio2.make_with_text (conf_interface_names.dialog_search_library_by_class)
				l_radio2.set_tooltip (conf_interface_names.dialog_search_library_by_class_tooltip)
				l_radio2.align_text_left
				hb2.extend (l_radio2)
				hb2.disable_item_expand (l_radio2)
				create hb2cb
				across
					search_by_class_manager.providers as ic
				loop
					create cb.make_with_text (@ ic.key)
					cb.enable_select
					if attached ic.description as d then
						cb.set_tooltip (d)
					end
					hb2cb.extend (cb)
					hb2cb.disable_item_expand (cb)
					l_checkboxes.put (cb, @ ic.key)
					cb.select_actions.extend (agent request_update_filter)
				end
				hb2.extend (hb2cb)
			end

				-- make the 2 radio buttons works together  (in same radio group).
			hb2.merge_radio_button_groups (hb1)

				-- Enable/disable sensitive on collection of checkboxes, according to selected radio buttons.
			if l_radio1 /= Void then
				l_radio1.select_actions.extend (agent enable_search_in_mode)
				if hb1cb /= Void then
					l_radio1.select_actions.extend (agent hb1cb.enable_sensitive)
				end
				if hb2cb /= Void then
					l_radio1.select_actions.extend (agent hb2cb.disable_sensitive)
				end

					-- Default is "search in .."
				l_radio1.enable_select
			end
			if l_radio2 /= Void then
				l_radio2.select_actions.extend (agent enable_search_by_class_mode)
				if hb1cb /= Void then
					l_radio2.select_actions.extend (agent hb1cb.disable_sensitive)
				end
				if hb2cb /= Void then
					l_radio2.select_actions.extend (agent hb2cb.enable_sensitive)
				end
			end
		end

	build_category_bar (a_vertical_container: EV_VERTICAL_BOX)
			-- Category filter bar
			-- | Category: [x] Official library [x] User contribution [x] Pre-release [x] SDK [x] Other |
		local
			hb: EV_HORIZONTAL_BOX
			lab: EV_LABEL
		do
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			a_vertical_container.extend (hb)
			a_vertical_container.disable_item_expand (hb)

			create lab.make_with_text (conf_interface_names.dialog_search_library_category + ":")
			lab.set_tooltip (conf_interface_names.dialog_search_library_category_tooltip)
			hb.extend (lab)
			hb.disable_item_expand (lab)

			across
				(create {ES_LIBRARY_CATEGORIES}).categories as ic
			loop
				extend_category_checkbox (hb, ic, search_results_box.category_title (ic))
			end
			extend_category_checkbox (hb, other_category, conf_interface_names.dialog_search_library_category_other)
		end

	extend_category_checkbox (hb: EV_HORIZONTAL_BOX; a_category: READABLE_STRING_32; a_title: READABLE_STRING_GENERAL)
			-- Add to `hb' a checkbox for category `a_category' with text `a_title'.
		local
			cb: EV_CHECK_BUTTON
		do
			create cb.make_with_text (a_title)
			cb.enable_select
			cb.set_tooltip (conf_interface_names.dialog_search_library_category_tooltip)
			cb.select_actions.extend (agent update_results_grid)
			hb.extend (cb)
			hb.disable_item_expand (cb)
			category_checkboxes.put (cb, a_category)
		end

feature -- Access

	widget: EV_WIDGET
			-- Widget representing Current box.
		do
			Result := box
		end

	target: CONF_TARGET
			-- Target where we add the library.

	custom_buttons_box: EV_HORIZONTAL_BOX
			-- Box, on the left of the bottom buttons bar, available for additional buttons.

	filter_text: STRING_32
			-- Filter text.
		do
			Result := filter.text
		end

	parent_window: detachable EV_WINDOW
			-- Window containing Current box.

feature -- Element change

	set_parent_window (w: like parent_window)
			-- Set `parent_window' to `w'.
		do
			parent_window := w
		end

feature -- Settings

	enable_precompile_option
			-- Add a "precompiled" checkbox (unchecked by default) to also search precompiled libraries.
			-- Associated items have the {ES_LIBRARY_CATEGORIES}.precompiled category.
		local
			cb: EV_CHECK_BUTTON
		do
			if precompile_checkbox = Void and attached search_in_checkboxes_box as hb then
				create cb.make_with_text (conf_interface_names.dialog_search_library_precompiled)
				cb.set_tooltip (conf_interface_names.dialog_search_library_precompiled_tooltip)
				cb.select_actions.extend (agent request_update_filter)
				hb.extend (cb)
				hb.disable_item_expand (cb)
				precompile_checkbox := cb
			end
		end

feature -- Status report

	is_precompile_search_selected: BOOLEAN
			-- Search also precompiled libraries?
		do
			Result := is_search_in_mode and then
				attached precompile_checkbox as cb and then cb.is_sensitive and then cb.is_selected
		end

	has_filter_focus: BOOLEAN
			-- Has filter text field the focus?
		do
			Result := filter.has_focus
		end

	is_strict: BOOLEAN
			-- Is matching strict?
		do
			Result := strict_checkbox.is_selected
		end

	is_category_shown (a_category: detachable READABLE_STRING_GENERAL): BOOLEAN
			-- Are items of category `a_category' shown?
		do
			if a_category /= Void and then attached category_checkboxes.item (a_category.as_lower) as cb then
				Result := cb.is_selected
			elseif attached category_checkboxes.item (other_category) as cb then
				Result := cb.is_selected
			else
				Result := True
			end
		end

feature -- Actions

	on_item_selected_actions: ACTION_SEQUENCE [TUPLE [search_item: detachable ES_LIBRARY_PROVIDER_ITEM]]
			-- Actions triggered when a search item is selected.

feature -- Basic operation

	set_focus
			-- Set focus to the results grid.
		do
			search_results_box.set_focus
		end

	select_row_by_value (v: ANY)
			-- Select row associated with value `v', if any.
		do
			search_results_box.select_row_by_value (v)
		end

	populate
			-- Search items, and update the UI.
		local
			l_style: detachable EV_POINTER_STYLE
			l_win: like parent_window
			retried: BOOLEAN
			popup: detachable EV_POPUP_WINDOW
			bb, vb: EV_VERTICAL_BOX
			lab: EV_LABEL
		do
			repopulate_requested := False
			l_win := parent_window
			if not retried and l_win /= Void and attached lib_manager as l_lib_manager then
				l_style := l_win.pointer_style
				l_win.set_pointer_style ((create {EV_STOCK_PIXMAPS}).busy_cursor)
				create popup.make_with_shadow
				create bb
				bb.set_border_width (1)
				create vb
				bb.extend (vb)
				vb.set_border_width (3 * layout_constants.default_border_size)
				vb.extend (create {EV_LABEL}.make_with_text (conf_interface_names.dialog_create_searching_please_wait_message))

				create lab.make_with_text ("...")
				vb.extend (lab)

				popup.extend (bb)
				popup.set_background_color ((create {EV_STOCK_COLORS}).white)
				popup.propagate_background_color
				bb.set_background_color ((create {EV_STOCK_COLORS}).blue)
				popup.set_position (l_win.x_position + (l_win.width - popup.width) // 2, l_win.y_position + (l_win.height - popup.height) // 2)
				popup.show_relative_to_window (l_win)
				popup.refresh_now

				l_lib_manager.on_provider_execution_begin_actions.extend (agent (ia_prov: ES_LIBRARY_PROVIDER; ia_lab: EV_LABEL)
							do
								ia_lab.set_text ("Process " + ia_prov.identifier + " ...")
								ia_lab.refresh_now
							end (?, lab)
					)
				l_lib_manager.on_provider_execution_end_actions.extend (agent (ia_prov: ES_LIBRARY_PROVIDER; ia_lab: EV_LABEL)
							do
								ia_lab.set_text ("...")
								ia_lab.refresh_now
							end (?, lab)
					)

				last_results := all_search_results (filter_text, provider_ids)
				update_results_grid

				l_lib_manager.on_provider_execution_begin_actions.wipe_out
				l_lib_manager.on_provider_execution_end_actions.wipe_out
			end
			if popup /= Void then
				popup.destroy
			end

			if l_style /= Void and l_win /= Void then
				l_win.set_pointer_style (l_style)
			end
		rescue
			retried := True
			retry
		end

	update_results_grid
			-- Update the results grid with `last_results', filtered by the selected categories.
		local
			lst: ARRAYED_LIST [ES_LIBRARY_PROVIDER_ITEM]
		do
			if attached last_results as l_results then
				create lst.make (l_results.count)
				across
					l_results as ic
				loop
					if is_category_shown (ic.category) then
						lst.extend (ic)
					end
				end
			else
				create lst.make (0)
			end
			search_results_box.set_items (lst)
			search_results_box.update_grid
		end

	notify_iron_packages_changed (a_package: detachable IRON_PACKAGE)
			-- Iron packages changed (installed, removed, ...).
		do
			reset_iron_configuration_libraries (target)
			if not repopulate_requested then
				populate
			end
		end

feature {NONE} -- Search mode

	search_mode: INTEGER

	is_search_in_mode: BOOLEAN
		do
			Result := search_mode = search_in_mode
		end

	is_search_by_class_mode: BOOLEAN
		do
			Result := search_mode = search_by_class_mode
		end

	search_in_mode: INTEGER = 1
	search_by_class_mode: INTEGER = 2

	enable_search_in_mode
		do
			search_mode := search_in_mode
		end

	enable_search_by_class_mode
		do
			search_mode := search_by_class_mode
		end

feature {NONE} -- Update filter

	on_strict_changed
			-- Strict checkbox changed.
		do
			search_in_manager.set_is_strict (is_strict)
			search_by_class_manager.set_is_strict (is_strict)
			precompile_manager.set_is_strict (is_strict)
			if not filter_text.is_whitespace then
				request_update_filter
			end
		end

	update_filter_timeout: detachable EV_TIMEOUT

	request_update_filter
		local
			l_update_filter_timeout: like update_filter_timeout
		do
			cancel_delayed_update_filter
			l_update_filter_timeout := update_filter_timeout
			if l_update_filter_timeout = Void then
				create l_update_filter_timeout
				update_filter_timeout := l_update_filter_timeout
				l_update_filter_timeout.actions.extend_kamikaze (agent delayed_update_filter)
			end
			l_update_filter_timeout.set_interval (1_000) -- 1 second is enough.
		end

	cancel_delayed_update_filter
		do
			if attached update_filter_timeout as l_update_filter_timeout then
				l_update_filter_timeout.destroy
				update_filter_timeout := Void
			end
		end

	delayed_update_filter
		do
			cancel_delayed_update_filter
			if not box.is_destroyed then
				populate
			end
		end

	repopulate_requested: BOOLEAN
			-- Any pending request to call `populate'?

feature {NONE} -- Libraries cache.

	update_index
		local
			nb: INTEGER
		do
			if attached lib_manager as m then
				if attached provider_checkboxes as l_provider_checkboxes then
					across
						l_provider_checkboxes as ic
					loop
						if ic.is_sensitive and then ic.is_selected then
							m.reset_provider (@ ic.key, target)
							nb := nb + 1
						end
					end
				end
				if nb = 0 then
					m.reset_all (target)
				end
			end
			if is_precompile_search_selected then
				precompile_manager.reset_all (target)
			end
			populate
		end

feature {NONE} -- Iron

	iron_service: ES_GUI_IRON_SERVICE

	launch_iron_tool
		local
			dlg: detachable IRON_PACKAGE_TOOL_DIALOG
		do
			dlg := last_launch_iron_tool
			if dlg /= Void and then dlg.is_destroyed then
				dlg := Void
			end
			if dlg = Void then
				create dlg.make (iron_service)
				if attached parent_window as l_win then
					dlg.set_size (l_win.width, l_win.height)
					dlg.set_position (l_win.x_position, l_win.y_position)
				end
					--| Whenever an operation is made on iron packages via the current EiffelStudio's dialog
					--| `notify_iron_packages_changed' will be executed.
				dlg.iron_box.on_iron_packages_changed_actions.extend (agent notify_iron_packages_changed)
				last_launch_iron_tool := dlg
			end
			if attached parent_window as l_win then
				dlg.show_modal_to_window (l_win)
			else
				dlg.show
			end
		end

	last_launch_iron_tool: detachable IRON_PACKAGE_TOOL_DIALOG

feature {NONE} -- Configuration settings for libraries

	popup_configuration_information
			-- Popup information related to library dialog configuration.
		local
			dlg: EV_DIALOG
			p1, p2: PATH
			us1, us2: detachable READABLE_STRING_GENERAL
			vb: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
			t: EV_TEXT
			l_close_button: EV_BUTTON
		do
			p1 := eiffel_layout.libraries_config_name
			if eiffel_layout.is_user_files_supported and then attached eiffel_layout.user_priority_file_name (p1, False) as p then
				us1 := p.name
			end
			p2 := eiffel_layout.precompiles_config_name
			if eiffel_layout.is_user_files_supported and then attached eiffel_layout.user_priority_file_name (p2, False) as p then
				us2 := p.name
			end

			create dlg
			dlg.set_title (conf_interface_names.dialog_display_configuration_title)
			create vb
			vb.set_border_width (Layout_constants.Default_border_size)
			vb.set_padding (Layout_constants.Default_padding_size)

			create t.make_with_text (conf_interface_names.dialog_display_configuration_text (p1.name, us1, p2.name, us2, eiffel_layout.is_user_files_supported))
			t.disable_edit
			t.set_background_color ((create {EV_STOCK_COLORS}).white)
			t.set_minimum_size (500, 200)
			vb.extend (t)
			create hb
			create l_close_button.make_with_text (conf_interface_names.general_close)
			l_close_button.select_actions.extend (agent dlg.destroy)
			hb.set_padding (Layout_constants.Default_padding_size)
			dlg.set_icon_pixmap ((create {EV_STOCK_PIXMAPS}).information_pixmap)

			hb.extend (create {EV_CELL})
			hb.extend (l_close_button)
			hb.disable_item_expand (l_close_button)
			hb.extend (create {EV_CELL})
			vb.extend (hb)
			vb.disable_item_expand (hb)
			dlg.extend (vb)

			if attached parent_window as l_win then
				dlg.show_modal_to_window (l_win)
			else
				dlg.show
			end
		end

feature {NONE} -- Access

	lib_manager: detachable ES_LIBRARY_PROVIDER_SERVICE
		do
			if is_search_by_class_mode then
				Result := search_by_class_manager
			elseif is_search_in_mode then
				Result := search_in_manager
			end
		end

	search_in_manager: ES_LIBRARY_PROVIDER_SERVICE
		once
			create Result.make (3)
			Result.register (create {ES_LIBRARY_LOCAL_PROVIDER})
			Result.register (create {ES_LIBRARY_IRON_PROVIDER})
			Result.register (create {ES_LIBRARY_IRON_PACKAGE_PROVIDER}.make (create {ES_IRON_SERVICE}))
		end

	search_by_class_manager: ES_LIBRARY_PROVIDER_SERVICE
		once
			create Result.make (1)
			Result.register (create {ES_LIBRARY_INDEX_PROVIDER})
		end

	precompile_manager: ES_LIBRARY_PROVIDER_SERVICE
			-- Providers of precompiled libraries.
		once
			create Result.make (2)
			Result.register (create {ES_PRECOMPILE_LIBRARY_LOCAL_PROVIDER})
			Result.register (create {ES_PRECOMPILE_LIBRARY_IRON_PROVIDER})
		end

	reset_iron_configuration_libraries (a_target: CONF_TARGET)
		do
			search_in_manager.reset_provider ({ES_LIBRARY_IRON_PROVIDER}.identifier, a_target)
			search_in_manager.reset_provider ({ES_LIBRARY_IRON_PACKAGE_PROVIDER}.identifier, a_target)
		end

	provider_ids: detachable ARRAYED_LIST [READABLE_STRING_GENERAL]
		do
			if attached provider_checkboxes as tb then
				create Result.make (tb.count)
				across
					tb as ic
				loop
					if ic.is_sensitive and then ic.is_selected then
						Result.extend (@ ic.key)
					end
				end
				if Result.is_empty then
					Result := Void
				end
			end
		end

	all_search_results (a_filter: detachable READABLE_STRING_32; a_provider_ids: detachable LIST [READABLE_STRING_GENERAL]): LIST [ES_LIBRARY_PROVIDER_ITEM]
		require
			provider_ids_void_or_not_empty: a_provider_ids /= Void implies not a_provider_ids.is_empty
		local
			libs: detachable LIST [ES_LIBRARY_PROVIDER_ITEM]
		do
			if attached lib_manager as m then
				libs := m.libraries (a_filter, target, a_provider_ids)
			end
			if libs /= Void then
				create {ARRAYED_LIST [ES_LIBRARY_PROVIDER_ITEM]} Result.make (libs.count)
				across
					libs as ic
				loop
					Result.force (ic)
				end
			else
				create {ARRAYED_LIST [ES_LIBRARY_PROVIDER_ITEM]} Result.make (0)
			end
			if is_precompile_search_selected then
				Result.append (precompile_libraries (precompile_manager, a_filter, Void))
			end
			search_in_manager.sort_list (Result)
		end

	precompile_libraries (a_manager: ES_LIBRARY_PROVIDER_SERVICE; a_filter: detachable READABLE_STRING_32; a_provider_ids: detachable LIST [READABLE_STRING_GENERAL]): LIST [ES_LIBRARY_PROVIDER_ITEM]
			-- Precompiled libraries provided by `a_manager' (i.e "precomp_*" systems),
			-- associated items have the {ES_LIBRARY_CATEGORIES}.precompiled category.
		local
			l_precompilation: detachable STRING_32
		do
				-- We store the ISE_PRECOMP environment variable because when editing an ECF, it can
				-- be either .NET or classic so we need to compute the right path.
			l_precompilation := eiffel_layout.get_environment_32 ({EIFFEL_CONSTANTS}.ise_precomp_env)
			eiffel_layout.set_precompile (target.setting_msil_generation, target.setting_msil_clr_version)

				-- Lookup all the ECFs that matches.
			create {ARRAYED_LIST [ES_LIBRARY_PROVIDER_ITEM]} Result.make (0)
			across
				a_manager.libraries (a_filter, target, a_provider_ids) as ic
			loop
				if attached {CONF_SYSTEM_VIEW} ic.value as cfg and then categories.is_precompile_system_name (cfg.system_name) then
					ic.set_category (categories.precompiled)
					Result.force (ic)
				end
			end

				-- Restore ISE_PRECOMP to its previous value.
			if l_precompilation /= Void then
				eiffel_layout.set_environment (l_precompilation, {EIFFEL_CONSTANTS}.ise_precomp_env)
			else
				eiffel_layout.set_environment ("", {EIFFEL_CONSTANTS}.ise_precomp_env)
			end
		end

	last_results: detachable LIST [ES_LIBRARY_PROVIDER_ITEM]
			-- Results of last search, not filtered by category.

	other_category: STRING_32 = "-"

	categories: ES_LIBRARY_CATEGORIES
			-- Library categories helper.
		once
			create Result
		end
			-- Key used for items without any (known) category.

feature {NONE} -- Widgets

	box: EV_VERTICAL_BOX
			-- Main box.

	filter: EV_TEXT_FIELD
			-- Filter.

	strict_checkbox: EV_CHECK_BUTTON
			-- Strict matching checkbox.

	precompile_checkbox: detachable EV_CHECK_BUTTON
			-- Optional checkbox to search also precompiled libraries (see `enable_precompile_option').

	search_in_checkboxes_box: detachable EV_HORIZONTAL_BOX
			-- Box containing the "search in" provider checkboxes.

	provider_checkboxes: detachable STRING_TABLE [EV_CHECK_BUTTON]
			-- Checkboxes, indexed by provider identifier.

	category_checkboxes: STRING_TABLE [EV_CHECK_BUTTON]
			-- Checkboxes, indexed by category (see `other_category').

	search_results_box: EIFFEL_SEARCH_ITEMS_BOX [ES_LIBRARY_PROVIDER_ITEM]
			-- Search results box.

invariant
	target_set_in_boxes: search_results_box.target = target

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
