note
	description: "Dialog to add a library."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	ADD_LIBRARY_DIALOG

inherit
	ADD_GROUP_DIALOG
		redefine
			initialize,
			create_interface_objects,
			last_group
		end

	CONF_ACCESS
		undefine
			copy,
			default_create
		end

	PROPERTY_GRID_LAYOUT
		undefine
			copy,
			default_create
		end

	CONF_FILE_CONSTANTS
		undefine
			copy,
			default_create
		end

	CONF_VALIDITY
		undefine
			copy,
			default_create
		end

	CONF_GUI_INTERFACE_CONSTANTS
		undefine
			default_create,
			copy
		end

	EIFFEL_LAYOUT
		export
			{NONE} all
		undefine
			default_create,
			copy
		end

create
	make

feature {NONE} -- Initialization

	create_interface_objects
		local
			l_service: ES_GUI_IRON_SERVICE
		do
			Precursor
			create l_service
			iron_service := l_service

			create selection_cell
			search_box := new_search_box (l_service)
			create library_widget.make (target)
			create iron_package_widget.make (l_service)
		end

	new_search_box (a_iron_service: ES_GUI_IRON_SERVICE): LIBRARY_SEARCH_BOX
			-- New search box, using `a_iron_service'.
		do
			create Result.make (target, a_iron_service)
		end

	initialize
			-- Initialize.
		local
			fr: EV_FRAME
			main: EV_VERTICAL_BOX
			cl: EV_CELL
			hsp: EV_VERTICAL_SPLIT_AREA
			l_service: like iron_service
		do
			l_service := iron_service

			Precursor

			set_title (conf_interface_names.dialog_create_library_title)
			set_icon_pixmap (conf_pixmaps.new_library_icon)

				-- libraries
			create main
			main.set_padding (layout_constants.default_padding_size)
			main.set_border_width (layout_constants.default_border_size)

			extend (main)
			create hsp
			main.extend (hsp)
			create fr
			fr.extend (search_box.widget)

			hsp.set_first (fr)
			build_search_box

			cl := selection_cell
			hsp.set_second (cl)
			build_iron_package_box
			build_library_selection_box
			cl.extend (library_selection_box)
			cl.set_minimum_height (library_selection_box.height)

				-- Initial Event
			show_actions.extend_kamikaze (agent (a_split: EV_VERTICAL_SPLIT_AREA)
					do
						a_split.set_proportion (0.9)
						search_box.populate
						search_box.set_focus
					end (hsp))

			resize_actions.extend (agent (ia_x, ia_y, ia_width, ia_height: INTEGER; a_split: EV_VERTICAL_SPLIT_AREA)
					do
						a_split.set_proportion (0.9)
					end (?, ?, ?, ?, hsp))

			dpi_changed_actions.extend (agent (a_dpi: NATURAL_32; ia_x, ia_y, ia_width, ia_height: INTEGER; a_split: EV_VERTICAL_SPLIT_AREA)
					do
						a_split.set_proportion (0.9)
					end (?, ?, ?, ?, ?, hsp))

			l_service.set_associated_widget (Current)
			search_box.set_parent_window (Current)
		end

	build_search_box
			-- Complete the search box (with "Custom" button).
		local
			l_btn: EV_BUTTON
		do
			search_box.on_item_selected_actions.extend (agent on_search_item_selected)

			create l_btn
			l_btn.select_actions.extend (agent on_search_item_selected (Void))
			l_btn.set_text (conf_interface_names.dialog_create_library_custom_location)
			l_btn.enable_sensitive
			search_box.custom_buttons_box.extend (l_btn)
			layout_constants.set_default_width_for_button (l_btn)
		end

	build_iron_package_box
			-- Build the iron package box.
		local
			w: like iron_package_widget
			vb: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
			but: EV_BUTTON
		do
			w := iron_package_widget

			create vb
			vb.extend (w.widget)

			create hb
			vb.extend (hb)
			vb.disable_item_expand (hb)

			create but.make_with_text_and_action (names.b_cancel, agent on_cancel)
			layout_constants.set_default_width_for_button (but)
			hb.extend (create {EV_CELL})
			hb.extend (but)
			hb.disable_item_expand (but)

			iron_package_box := vb

			w.on_install_actions.extend (agent (p: IRON_PACKAGE)
						do
							iron_service.install_package (p, agent on_iron_package_installed (p, ?))
						end
				)
			w.on_uninstall_actions.extend (agent (p: IRON_PACKAGE)
						do
							iron_service.uninstall_package (p, agent on_iron_package_uninstalled (p, ?))
						end
				)
		end

	build_library_selection_box
			-- Build the name + location + browse button.
		local
			w: like library_widget
		do
			w := library_widget
			w.on_ok_actions.extend (agent on_ok)
			w.on_cancel_actions.extend (agent on_cancel)
		end

feature {NONE} -- GUI elements

	selection_cell: EV_CELL

	iron_package_box: detachable EV_WIDGET

	iron_package_widget: IRON_PACKAGE_WIDGET

	library_selection_box: EV_WIDGET
		do
			Result := library_widget.widget
		end

	library_widget: ADD_LIBRARY_WIDGET

	search_box: LIBRARY_SEARCH_BOX
			-- Search box (options, filter and results).

feature -- Access

	last_group: detachable CONF_LIBRARY
			-- Last created group.

feature {NONE} -- Callback

	on_iron_package_installed (p: IRON_PACKAGE; a_succeed: BOOLEAN)
		do
			if a_succeed then
				search_box.notify_iron_packages_changed (p)
				search_box.select_row_by_value (p)
			end
		end

	on_iron_package_uninstalled (p: IRON_PACKAGE; a_succeed: BOOLEAN)
		do
			if a_succeed then
				search_box.notify_iron_packages_changed (p)
				search_box.select_row_by_value (p)
			end
		end

feature {NONE} -- Action handlers

	on_library_selected (a_library: detachable CONF_SYSTEM_VIEW)
			-- Called when a library is selected
		require
			is_library_target: a_library /= Void implies a_library.has_library_target
		do
			library_widget.set_library (a_library)
		end

	on_iron_package_selected (a_iron_package: IRON_PACKAGE)
		require
			a_iron_package_set: a_iron_package /= Void
		do
			iron_package_widget.set_package (a_iron_package)
		end

	on_search_item_selected (a_search_item: detachable ES_LIBRARY_PROVIDER_ITEM)
		local
			cl_item: EV_WIDGET
			w: EV_WIDGET
		do
			if not selection_cell.is_empty then
				cl_item := selection_cell.item
			else
				w := library_selection_box
			end

			if a_search_item = Void then
				w := library_selection_box
				on_library_selected (Void)
			elseif attached {CONF_SYSTEM_VIEW} a_search_item.value as cfg then
				w := library_selection_box
				on_library_selected (cfg)
			elseif attached {IRON_PACKAGE} a_search_item.value as l_iron_package then
				w := iron_package_box
				on_iron_package_selected (l_iron_package)
			elseif attached {LIBRARY_INFO} a_search_item.value as l_lib_info then
					-- FIXME: try to get more information from the associated library!
				w := library_selection_box
				on_library_selected (Void)
				library_widget.set_name (l_lib_info.name)
				library_widget.set_location (l_lib_info.location.name)
			else
				w := library_selection_box
			end
			if cl_item /= w then
				selection_cell.wipe_out
				if w /= Void then
					selection_cell.extend (w)
				end
			end
		end

	on_ok (w: ADD_LIBRARY_WIDGET)
			-- Add library and close the dialog.
		local
			l_sys: CONF_SYSTEM
			l_name: READABLE_STRING_32
			l_location: READABLE_STRING_32
			g: like last_group
		do
				-- library choosen?
			if search_box.has_filter_focus then
					-- Ignore global Ok.
			else
				l_name := w.name
				l_location := w.location
				if not l_location.is_empty and not l_name.is_empty then
					if not is_valid_group_name (l_name) then
						(create {ES_SHARED_PROMPT_PROVIDER}).prompts.show_error_prompt (conf_interface_names.invalid_library_name, Current, Void)
					elseif group_exists (l_name, target) then
						(create {ES_SHARED_PROMPT_PROVIDER}).prompts.show_error_prompt (conf_interface_names.group_already_exists (l_name), Current, Void)
					else
						g := factory.new_library (l_name, l_location, target)
						last_group := g
							-- add an empty classes list that it get's displayed in the classes tree
						g.set_classes (create {STRING_TABLE [CONF_CLASS]}.make (0))
						l_sys := factory.new_system_generate_uuid_with_file_name ("dummy_location", "dummy", latest_namespace)
						l_sys.set_application_target (target)
						g.set_library_target (factory.new_target ("dummy", l_sys))
						target.add_library (g)
						on_library_added (g)
					end
				end
			end
		ensure
			is_ok_last_library: is_ok implies last_group /= Void
		end

	on_library_added (g: CONF_LIBRARY)
			-- Library `g' was added to `target'.
		require
			g_added: target.libraries.has (g.name)
		do
			destroy
		end

	on_cancel
			-- Close the dialog.
		do
			destroy
		end

feature {NONE} -- Implementation: iron api

	iron_service: ES_GUI_IRON_SERVICE

invariant
	target_set_in_boxes: search_box.target = target

note
	copyright: "Copyright (c) 1984-2021, Eiffel Software"
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
