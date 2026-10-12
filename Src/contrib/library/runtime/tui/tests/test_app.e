note
	description: "[
		Robust test suite runner executing all EiffelTUI test sets.
		Catches failures per test, prints clear [PASS] / [FAIL] status with exception reasons,
		continues running all remaining tests on failure, and exits non-zero if any test fails.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

inherit
	ANY

create
	make

feature {NONE} -- Initialization

	make
			-- Run all test suites with per-test failure isolation and summary reporting.
		local
			l_t1: TEST_TERMINAL_BACKEND
			l_t2: TEST_BUFFER_AND_DIFF
			l_t3: TEST_LAYOUT_SOLVER
			l_t4: TEST_EVENTS_AND_PARSER
			l_t5: TEST_TEXT_AND_WIDGETS
			l_t6: TEST_STATEFUL_WIDGETS
			l_t7: TEST_TABLE_WIDGET
			l_t8: TEST_SCROLLBAR
			l_t9: TEST_METRIC_WIDGETS
			l_t10: TEST_CANVAS
			l_t11: TEST_LAYOUT_AND_BORDERS
			l_t12: TEST_VIEWPORT_AND_POSIX
			l_t13: TEST_EDGE_CASES
			l_t14: TEST_MILESTONE_C
			l_t15: TEST_MILESTONE_D
			l_t16: TEST_MILESTONE_D_REVIEW
			l_t17: TEST_MILESTONE_E
			l_t18: TEST_MILESTONE_E_REVIEW
			l_t19: TEST_MILESTONE_E_FOLLOWUPS
			l_t20: TEST_MILESTONE_F
			l_t21: TEST_WIDGET_SMOKE
			l_t22: TEST_MILESTONE_F_REVIEW
			l_t23: TEST_MILESTONE_F_GAPS
			l_t24: TEST_MILESTONE_G
			l_t25: TEST_MILESTONE_G_REVIEW
			l_t26: TEST_MILESTONE_G_FOLLOWUPS
			l_t27: TEST_KEYBOARD_ENHANCEMENT
			l_t28: TEST_TIER1_EXAMPLES
			l_t29: TEST_TIER2_EXAMPLES
			l_t30: TEST_PASTE_ROBUSTNESS
			l_t31: TEST_UNICODE_WRAP
			l_t32: TEST_CONSOLE_INPUT_CLAIM
			l_t33: TEST_UNICODE_SCALAR
			l_t34: TEST_UTF_8_INPUT
			l_t35: TEST_SERIALIZER_REANCHOR
			l_t36: TEST_TEXT_INPUT_EDGES
			l_t37: TEST_FRAME_OUTPUT
			l_t38: TEST_FAILURE_RECOVERY
			l_t39: TEST_UTF_8_OUT
			l_t40: TEST_UNICODE_GAPS
			l_t41: TEST_DIFF_POOL
			l_t42: TEST_SHARED_OBJECTS
			l_t43: TEST_EVENT_FLOOD
			l_platform: TEST_PLATFORM_DRIVER
		do
			total_count := 0
			pass_count := 0
			fail_count := 0

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 1 Test Suite (Terminal Backend)...%N")
			print ("============================================================%N")
			create l_t1
			run_test ("test_virtual_terminal_initialization", agent l_t1.test_virtual_terminal_initialization)
			run_test ("test_cursor_movement", agent l_t1.test_cursor_movement)
			run_test ("test_put_string_and_cell_inspection", agent l_t1.test_put_string_and_cell_inspection)
			run_test ("test_clear_screen", agent l_t1.test_clear_screen)
			run_test ("test_screen_modes", agent l_t1.test_screen_modes)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 2 Test Suite (Buffer & Diff)...%N")
			print ("============================================================%N")
			create l_t2
			run_test ("test_color_and_styles", agent l_t2.test_color_and_styles)
			run_test ("test_unicode_and_wide_glyphs", agent l_t2.test_unicode_and_wide_glyphs)
			run_test ("test_buffer_wide_character_placement", agent l_t2.test_buffer_wide_character_placement)
			run_test ("test_diff_engine_dirty_detection", agent l_t2.test_diff_engine_dirty_detection)
			run_test ("test_diff_engine_gap_merging", agent l_t2.test_diff_engine_gap_merging)
			run_test ("test_ansi_serializer_with_virtual_terminal", agent l_t2.test_ansi_serializer_with_virtual_terminal)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 3 Test Suite (Layout Solver)...%N")
			print ("============================================================%N")
			create l_t3
			run_test ("test_rect_geometry", agent l_t3.test_rect_geometry)
			run_test ("test_split_vertical_fixed_and_flex", agent l_t3.test_split_vertical_fixed_and_flex)
			run_test ("test_split_horizontal_ratios", agent l_t3.test_split_horizontal_ratios)
			run_test ("test_split_horizontal_percentage", agent l_t3.test_split_horizontal_percentage)
			run_test ("test_flex_remainder_distribution", agent l_t3.test_flex_remainder_distribution)
			run_test ("test_split_with_margin", agent l_t3.test_split_with_margin)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 4 Test Suite (Events & Parser)...%N")
			print ("============================================================%N")
			create l_t4
			run_test ("test_modifiers", agent l_t4.test_modifiers)
			run_test ("test_key_code_definitions", agent l_t4.test_key_code_definitions)
			run_test ("test_parser_ground_characters", agent l_t4.test_parser_ground_characters)
			run_test ("test_parser_csi_arrow_keys", agent l_t4.test_parser_csi_arrow_keys)
			run_test ("test_parser_csi_modifiers", agent l_t4.test_parser_csi_modifiers)
			run_test ("test_parser_sgr_mouse", agent l_t4.test_parser_sgr_mouse)
			run_test ("test_synchronized_queue", agent l_t4.test_synchronized_queue)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 5 Test Suite (Text & Widgets)...%N")
			print ("============================================================%N")
			create l_t5
			run_test ("test_text_span_and_unicode_width", agent l_t5.test_text_span_and_unicode_width)
			run_test ("test_text_line_and_composition", agent l_t5.test_text_line_and_composition)
			run_test ("test_text_wrapping", agent l_t5.test_text_wrapping)
			run_test ("test_text_alignment", agent l_t5.test_text_alignment)
			run_test ("test_tui_block_geometry_and_rendering", agent l_t5.test_tui_block_geometry_and_rendering)
			run_test ("test_tui_paragraph_rendering", agent l_t5.test_tui_paragraph_rendering)
			run_test ("test_tui_clear", agent l_t5.test_tui_clear)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 6 Test Suite (Stateful & Terminal)...%N")
			print ("============================================================%N")
			create l_t6
			run_test ("test_terminal_and_frame_agent_draw", agent l_t6.test_terminal_and_frame_agent_draw)
			run_test ("test_list_state_navigation", agent l_t6.test_list_state_navigation)
			run_test ("test_list_viewport_scrolling", agent l_t6.test_list_viewport_scrolling)
			run_test ("test_tui_list_stateful_rendering", agent l_t6.test_tui_list_stateful_rendering)
			run_test ("test_tabs_state_and_rendering", agent l_t6.test_tabs_state_and_rendering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 7 Test Suite (Table Widget)...%N")
			print ("============================================================%N")
			create l_t7
			run_test ("test_table_cell_and_row_construction", agent l_t7.test_table_cell_and_row_construction)
			run_test ("test_table_state_navigation", agent l_t7.test_table_state_navigation)
			run_test ("test_tui_table_rendering_stateless", agent l_t7.test_tui_table_rendering_stateless)
			run_test ("test_tui_table_stateful_selection_and_highlight", agent l_t7.test_tui_table_stateful_selection_and_highlight)
			run_test ("test_tui_table_column_spanning", agent l_t7.test_tui_table_column_spanning)
			run_test ("test_tui_table_with_block_and_footer", agent l_t7.test_tui_table_with_block_and_footer)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 8 Test Suite (Scrollbar Widget)...%N")
			print ("============================================================%N")
			create l_t8
			run_test ("test_scrollbar_orientation_constants", agent l_t8.test_scrollbar_orientation_constants)
			run_test ("test_scrollbar_state_navigation", agent l_t8.test_scrollbar_state_navigation)
			run_test ("test_tui_scrollbar_vertical_rendering", agent l_t8.test_tui_scrollbar_vertical_rendering)
			run_test ("test_tui_scrollbar_horizontal_rendering", agent l_t8.test_tui_scrollbar_horizontal_rendering)
			run_test ("test_tui_scrollbar_pairing_with_list", agent l_t8.test_tui_scrollbar_pairing_with_list)
			run_test ("test_scrollbar_valid_symbols", agent l_t8.test_scrollbar_valid_symbols)
			run_test ("test_scrollbar_setters_refuse_wide_symbols", agent l_t8.test_scrollbar_setters_refuse_wide_symbols)
			run_test ("test_scrollbar_invariant_catches_edited_symbol", agent l_t8.test_scrollbar_invariant_catches_edited_symbol)
			run_test ("test_scrollbar_stays_in_its_column", agent l_t8.test_scrollbar_stays_in_its_column)
			run_test ("test_horizontal_scrollbar_symbols_do_not_blank_each_other", agent l_t8.test_horizontal_scrollbar_symbols_do_not_blank_each_other)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 9 Test Suite (Metric Widgets)...%N")
			print ("============================================================%N")
			create l_t9
			run_test ("test_gauge_rendering_and_label", agent l_t9.test_gauge_rendering_and_label)
			run_test ("test_gauge_label_wide_char_across_fill_edge", agent l_t9.test_gauge_label_wide_char_across_fill_edge)
			run_test ("test_gauge_label_wide_char_after_fill_edge", agent l_t9.test_gauge_label_wide_char_after_fill_edge)
			run_test ("test_one_column_symbols", agent l_t9.test_one_column_symbols)
			run_test ("test_line_gauge_refuses_wide_symbols", agent l_t9.test_line_gauge_refuses_wide_symbols)
			run_test ("test_line_gauge_invariant_catches_edited_symbol", agent l_t9.test_line_gauge_invariant_catches_edited_symbol)
			run_test ("test_line_gauge_multi_code_point_symbol_in_every_cell", agent l_t9.test_line_gauge_multi_code_point_symbol_in_every_cell)
			run_test ("test_gauge_unicode_sub_cell", agent l_t9.test_gauge_unicode_sub_cell)
			run_test ("test_line_gauge_rendering", agent l_t9.test_line_gauge_rendering)
			run_test ("test_sparkline_rendering", agent l_t9.test_sparkline_rendering)
			run_test ("test_barchart_rendering", agent l_t9.test_barchart_rendering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 10 Test Suite (Canvas & Chart)...%N")
			print ("============================================================%N")
			create l_t10
			run_test ("test_braille_canvas_subpixels", agent l_t10.test_braille_canvas_subpixels)
			run_test ("test_canvas_painter_bresenham_line", agent l_t10.test_canvas_painter_bresenham_line)
			run_test ("test_canvas_painter_circle_and_rect", agent l_t10.test_canvas_painter_circle_and_rect)
			run_test ("test_tui_canvas_rendering_with_agent", agent l_t10.test_tui_canvas_rendering_with_agent)
			run_test ("test_tui_chart_rendering", agent l_t10.test_tui_chart_rendering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 11 Test Suite (Layout & Borders)...%N")
			print ("============================================================%N")
			create l_t11
			run_test ("test_layout_split_with_spacing", agent l_t11.test_layout_split_with_spacing)
			run_test ("test_layout_justification_end_and_center", agent l_t11.test_layout_justification_end_and_center)
			run_test ("test_layout_justification_space_between", agent l_t11.test_layout_justification_space_between)
			run_test ("test_border_collision_symbol_merging", agent l_t11.test_border_collision_symbol_merging)
			run_test ("test_buffer_border_fusion", agent l_t11.test_buffer_border_fusion)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 12 Test Suite (Viewport & POSIX)...%N")
			print ("============================================================%N")
			create l_t12
			run_test ("test_viewport_modes", agent l_t12.test_viewport_modes)
			run_test ("test_fixed_viewport_resize", agent l_t12.test_fixed_viewport_resize)
			run_test ("test_frame_cursor_positioning", agent l_t12.test_frame_cursor_positioning)
			run_test ("test_terminal_with_inline_viewport_and_cursor", agent l_t12.test_terminal_with_inline_viewport_and_cursor)
			run_test ("test_platform_terminal_driver", agent l_t12.test_platform_terminal_driver)

			print ("============================================================%N")
			print ("  Running EiffelTUI Edge Cases Test Suite (Milestone B)...%N")
			print ("============================================================%N")
			create l_t13
			run_test ("test_zero_and_oversized_areas", agent l_t13.test_zero_and_oversized_areas)
			run_test ("test_wide_characters_in_widgets", agent l_t13.test_wide_characters_in_widgets)
			run_test ("test_wide_over_wide_overwrite", agent l_t13.test_wide_over_wide_overwrite)
			run_test ("test_combining_marks_and_emoji", agent l_t13.test_combining_marks_and_emoji)
			run_test ("test_rect_bounds_and_overflow", agent l_t13.test_rect_bounds_and_overflow)
			run_test ("test_overconstrained_and_min_max_layouts", agent l_t13.test_overconstrained_and_min_max_layouts)
			run_test ("test_malformed_and_partial_input", agent l_t13.test_malformed_and_partial_input)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone C Test Suite...%N")
			print ("============================================================%N")
			create l_t14
			run_test ("test_platform_console_driver", agent l_t14.test_platform_console_driver)
			run_test ("test_utf8_streaming_input", agent l_t14.test_utf8_streaming_input)
			run_test ("test_lone_escape_flush", agent l_t14.test_lone_escape_flush)
			run_test ("test_mouse_modifiers_and_horizontal_scroll", agent l_t14.test_mouse_modifiers_and_horizontal_scroll)
			run_test ("test_focus_events", agent l_t14.test_focus_events)
			run_test ("test_bracketed_paste_event", agent l_t14.test_bracketed_paste_event)
			run_test ("test_modified_function_keys", agent l_t14.test_modified_function_keys)
			run_test ("test_cursor_position_report", agent l_t14.test_cursor_position_report)
			run_test ("test_synchronized_queue_timeout", agent l_t14.test_synchronized_queue_timeout)
			run_test ("test_synchronized_queue_wake", agent l_t14.test_synchronized_queue_wake)
			run_test ("test_event_thread_with_fake_driver", agent l_t14.test_event_thread_with_fake_driver)
			run_test ("test_event_thread_failure_reported", agent l_t14.test_event_thread_failure_reported)
			run_test ("test_backend_restores_before_driver", agent l_t14.test_backend_restores_before_driver)
			run_test ("test_backend_cursor_position_query", agent l_t14.test_backend_cursor_position_query)
			run_test ("test_terminal_resize_on_draw", agent l_t14.test_terminal_resize_on_draw)
			run_test ("test_inline_viewport_setup_and_insert_before", agent l_t14.test_inline_viewport_setup_and_insert_before)
			run_test ("test_inline_viewport_moves_down_while_room", agent l_t14.test_inline_viewport_moves_down_while_room)
			run_test ("test_tui_application_run_and_restore", agent l_t14.test_tui_application_run_and_restore)
			run_test ("test_tui_application_exception_restores_terminal", agent l_t14.test_tui_application_exception_restores_terminal)
			run_test ("test_tui_application_ticks_under_steady_input", agent l_t14.test_tui_application_ticks_under_steady_input)
			run_test ("test_tui_application_runs_twice", agent l_t14.test_tui_application_runs_twice)
			run_test ("test_event_thread_renewed", agent l_t14.test_event_thread_renewed)
			run_test ("test_tui_application_input_thread_timeout", agent l_t14.test_tui_application_input_thread_timeout)
			run_test ("test_termination_request_ends_run_after_restore", agent l_t14.test_termination_request_ends_run_after_restore)
			run_test ("test_termination_request_wakes_slow_loop", agent l_t14.test_termination_request_wakes_slow_loop)
			run_test ("test_event_budget_redraws_during_flood", agent l_t14.test_event_budget_redraws_during_flood)
			run_test ("test_termination_request_outside_run_is_immediate", agent l_t14.test_termination_request_outside_run_is_immediate)
			run_test ("test_second_termination_request_is_immediate", agent l_t14.test_second_termination_request_is_immediate)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone D Test Suite...%N")
			print ("============================================================%N")
			create l_t15
			run_test ("test_style_modifiers_and_fluent_builders", agent l_t15.test_style_modifiers_and_fluent_builders)
			run_test ("test_unicode_width_uax11_and_graphemes", agent l_t15.test_unicode_width_uax11_and_graphemes)
			run_test ("test_buffer_wide_over_wide_repair", agent l_t15.test_buffer_wide_over_wide_repair)
			run_test ("test_buffer_api_extensions", agent l_t15.test_buffer_api_extensions)
			run_test ("test_rect_saturating_bounds_and_helpers", agent l_t15.test_rect_saturating_bounds_and_helpers)
			run_test ("test_synchronized_output_and_minimal_sgr", agent l_t15.test_synchronized_output_and_minimal_sgr)
			run_test ("test_backend_cursor_tracking_and_escapes", agent l_t15.test_backend_cursor_tracking_and_escapes)
			run_test ("test_allocation_reuse", agent l_t15.test_allocation_reuse)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone D Review Test Suite...%N")
			print ("============================================================%N")
			create l_t16
			run_test ("test_paragraph_horizontal_scroll_clips_per_grapheme", agent l_t16.test_paragraph_horizontal_scroll_clips_per_grapheme)
			run_test ("test_set_line_clipped_negative_start", agent l_t16.test_set_line_clipped_negative_start)
			run_test ("test_put_char_zero_width_keeps_consistency", agent l_t16.test_put_char_zero_width_keeps_consistency)
			run_test ("test_resize_cuts_wide_char", agent l_t16.test_resize_cuts_wide_char)
			run_test ("test_merge_repairs_cut_wide_char", agent l_t16.test_merge_repairs_cut_wide_char)
			run_test ("test_grapheme_clusters_in_buffer", agent l_t16.test_grapheme_clusters_in_buffer)
			run_test ("test_combining_mark_across_spans", agent l_t16.test_combining_mark_across_spans)
			run_test ("test_unicode_tables_from_ucd", agent l_t16.test_unicode_tables_from_ucd)
			run_test ("test_backend_cursor_tracking_utf8_bytes", agent l_t16.test_backend_cursor_tracking_utf8_bytes)
			run_test ("test_cells_updated_in_place_and_styles_shared", agent l_t16.test_cells_updated_in_place_and_styles_shared)
			run_test ("test_terminal_swaps_buffers", agent l_t16.test_terminal_swaps_buffers)
			run_test ("test_diff_span_pool_reused", agent l_t16.test_diff_span_pool_reused)
			run_test ("test_style_same_rendering_and_reset", agent l_t16.test_style_same_rendering_and_reset)
			run_test ("test_serializer_exact_sgr_deltas", agent l_t16.test_serializer_exact_sgr_deltas)
			run_test ("test_rect_clamp_moves_and_inner_does_not_wrap", agent l_t16.test_rect_clamp_moves_and_inner_does_not_wrap)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone E Test Suite (Layout Parity)...%N")
			print ("============================================================%N")
			create l_t17
			run_test ("test_layout_value_object_and_builders", agent l_t17.test_layout_value_object_and_builders)
			run_test ("test_layout_split_array", agent l_t17.test_layout_split_array)
			run_test ("test_deterministic_min_can_grow", agent l_t17.test_deterministic_min_can_grow)
			run_test ("test_deterministic_max_can_shrink", agent l_t17.test_deterministic_max_can_shrink)
			run_test ("test_deterministic_pct_and_ratio_remainders", agent l_t17.test_deterministic_pct_and_ratio_remainders)
			run_test ("test_deterministic_overconstrained_proportional_shrink", agent l_t17.test_deterministic_overconstrained_proportional_shrink)
			run_test ("test_deterministic_flex_split_by_weight", agent l_t17.test_deterministic_flex_split_by_weight)
			run_test ("test_flex_justify_proper_type_and_constants", agent l_t17.test_flex_justify_proper_type_and_constants)
			run_test ("test_flex_justify_space_evenly", agent l_t17.test_flex_justify_space_evenly)
			run_test ("test_flex_justify_remainder_distribution", agent l_t17.test_flex_justify_remainder_distribution)
			run_test ("test_flex_justify_legacy", agent l_t17.test_flex_justify_legacy)
			run_test ("test_layout_cache", agent l_t17.test_layout_cache)
			run_test ("test_layout_postconditions", agent l_t17.test_layout_postconditions)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone E Review Test Suite...%N")
			print ("============================================================%N")
			create l_t18
			run_test ("test_percentage_rounding_bounded_by_exact_total", agent l_t18.test_percentage_rounding_bounded_by_exact_total)
			run_test ("test_ratio_does_not_overflow", agent l_t18.test_ratio_does_not_overflow)
			run_test ("test_overconstrained_shrink_order", agent l_t18.test_overconstrained_shrink_order)
			run_test ("test_space_around_is_symmetric", agent l_t18.test_space_around_is_symmetric)
			run_test ("test_large_spacing_does_not_overflow", agent l_t18.test_large_spacing_does_not_overflow)
			run_test ("test_layout_split_returns_copies", agent l_t18.test_layout_split_returns_copies)
			run_test ("test_layout_is_immutable", agent l_t18.test_layout_is_immutable)
			run_test ("test_postcondition_queries_reject_bad_chunks", agent l_t18.test_postcondition_queries_reject_bad_chunks)
			run_test ("test_overlap_with_zero_width_chunk", agent l_t18.test_overlap_with_zero_width_chunk)
			run_test ("test_overlap_bound_query", agent l_t18.test_overlap_bound_query)
			run_test ("test_merged_borders_keep_line_family", agent l_t18.test_merged_borders_keep_line_family)
			run_test ("test_merged_border_ignores_text", agent l_t18.test_merged_border_ignores_text)
			run_test ("test_render_merged_restores_setting", agent l_t18.test_render_merged_restores_setting)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone E Follow-ups Test Suite...%N")
			print ("============================================================%N")
			create l_t19
			run_test ("test_spacing_value_object", agent l_t19.test_spacing_value_object)
			run_test ("test_layout_overlap_spacing_ratatui_cases", agent l_t19.test_layout_overlap_spacing_ratatui_cases)
			run_test ("test_adjacent_blocks_overlap_border_merging", agent l_t19.test_adjacent_blocks_overlap_border_merging)
			run_test ("test_layout_split_with_spacers", agent l_t19.test_layout_split_with_spacers)
			run_test ("test_layout_cache_lru_eviction", agent l_t19.test_layout_cache_lru_eviction)
			run_test ("test_tui_table_layout_integration", agent l_t19.test_tui_table_layout_integration)
			run_test ("test_split_list_is_independent_of_cache", agent l_t19.test_split_list_is_independent_of_cache)
			run_test ("test_cache_hit_reuses_stored_solution", agent l_t19.test_cache_hit_reuses_stored_solution)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone F Test Suite (Widget Completion)...%N")
			print ("============================================================%N")
			create l_t20
			run_test ("test_table_horizontal_column_scroll_and_highlight", agent l_t20.test_table_horizontal_column_scroll_and_highlight)
			run_test ("test_barchart_bar_group_and_horizontal", agent l_t20.test_barchart_bar_group_and_horizontal)
			run_test ("test_chart_legend_position_axis_titles_markers", agent l_t20.test_chart_legend_position_axis_titles_markers)
			run_test ("test_canvas_shapes_layers_color_policy", agent l_t20.test_canvas_shapes_layers_color_policy)
			run_test ("test_block_multiple_titles_background_padding_borders", agent l_t20.test_block_multiple_titles_background_padding_borders)
			run_test ("test_list_multiline_highlight_spacing_direction", agent l_t20.test_list_multiline_highlight_spacing_direction)
			run_test ("test_tabs_padding_and_divider_clipping", agent l_t20.test_tabs_padding_and_divider_clipping)
			run_test ("test_gauge_color_inversion_and_line_gauge_truncation", agent l_t20.test_gauge_color_inversion_and_line_gauge_truncation)
			run_test ("test_sparkline_direction_and_ordering", agent l_t20.test_sparkline_direction_and_ordering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Widget Smoke Test Suite...%N")
			print ("============================================================%N")
			create l_t21
			run_test ("test_text_widgets_survive_awkward_areas", agent l_t21.test_text_widgets_survive_awkward_areas)
			run_test ("test_stateful_widgets_survive_awkward_areas", agent l_t21.test_stateful_widgets_survive_awkward_areas)
			run_test ("test_metric_widgets_survive_awkward_areas", agent l_t21.test_metric_widgets_survive_awkward_areas)
			run_test ("test_canvas_widgets_survive_awkward_areas", agent l_t21.test_canvas_widgets_survive_awkward_areas)
			run_test ("test_ecosystem_widgets_survive_awkward_areas", agent l_t21.test_ecosystem_widgets_survive_awkward_areas)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone F Review Test Suite...%N")
			print ("============================================================%N")
			create l_t22
			run_test ("test_list_highlight_spacing", agent l_t22.test_list_highlight_spacing)
			run_test ("test_list_scrolls_by_rows", agent l_t22.test_list_scrolls_by_rows)
			run_test ("test_list_scroll_padding_leaves_no_blank_rows", agent l_t22.test_list_scroll_padding_leaves_no_blank_rows)
			run_test ("test_horizontal_bar_value_at_maximum", agent l_t22.test_horizontal_bar_value_at_maximum)
			run_test ("test_block_title_kept_with_other_titles", agent l_t22.test_block_title_kept_with_other_titles)
			run_test ("test_chart_dot_marker_is_drawn", agent l_t22.test_chart_dot_marker_is_drawn)
			run_test ("test_chart_y_title_and_label_order", agent l_t22.test_chart_y_title_and_label_order)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone F Gaps Test Suite...%N")
			print ("============================================================%N")
			create l_t23
			run_test ("test_table_clips_columns_and_scrolls_right", agent l_t23.test_table_clips_columns_and_scrolls_right)
			run_test ("test_table_highlights_win_over_cell_styles", agent l_t23.test_table_highlights_win_over_cell_styles)
			run_test ("test_barchart_vertical_groups_and_group_labels", agent l_t23.test_barchart_vertical_groups_and_group_labels)
			run_test ("test_barchart_max_follows_group_changes", agent l_t23.test_barchart_max_follows_group_changes)
			run_test ("test_barchart_hides_values_wider_than_the_bar", agent l_t23.test_barchart_hides_values_wider_than_the_bar)
			run_test ("test_canvas_layers_stack", agent l_t23.test_canvas_layers_stack)
			run_test ("test_canvas_half_block_resolution", agent l_t23.test_canvas_half_block_resolution)
			run_test ("test_canvas_text_clipped_to_area", agent l_t23.test_canvas_text_clipped_to_area)
			run_test ("test_chart_line_uses_marker", agent l_t23.test_chart_line_uses_marker)
			run_test ("test_chart_bars_rise_from_zero", agent l_t23.test_chart_bars_rise_from_zero)
			run_test ("test_chart_legend_border_and_hiding", agent l_t23.test_chart_legend_border_and_hiding)
			run_test ("test_block_titles_laid_out_per_side", agent l_t23.test_block_titles_laid_out_per_side)
			run_test ("test_gauge_label_keeps_explicit_colour", agent l_t23.test_gauge_label_keeps_explicit_colour)
			run_test ("test_gauge_label_wide_char_clipped", agent l_t23.test_gauge_label_wide_char_clipped)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone G Test Suite (Ergonomics & Ecosystem)...%N")
			print ("============================================================%N")
			create l_t24
			run_test ("test_style_immutability_and_cqs", agent l_t24.test_style_immutability_and_cqs)
			run_test ("test_block_container_and_inner_area", agent l_t24.test_block_container_and_inner_area)
			run_test ("test_text_hierarchy_direct_rendering", agent l_t24.test_text_hierarchy_direct_rendering)
			run_test ("test_symbols_and_themes", agent l_t24.test_symbols_and_themes)
			run_test ("test_text_input_editing_and_rendering", agent l_t24.test_text_input_editing_and_rendering)
			run_test ("test_popup_helpers_and_rendering", agent l_t24.test_popup_helpers_and_rendering)
			run_test ("test_tree_navigation_and_rendering", agent l_t24.test_tree_navigation_and_rendering)
			run_test ("test_calendar_state_and_rendering", agent l_t24.test_calendar_state_and_rendering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone G Review Test Suite...%N")
			print ("============================================================%N")
			create l_t25
			run_test ("test_builders_do_not_share_lists", agent l_t25.test_builders_do_not_share_lists)
			run_test ("test_frame_rejects_mismatched_state", agent l_t25.test_frame_rejects_mismatched_state)
			run_test ("test_text_input_edits_grapheme_clusters", agent l_t25.test_text_input_edits_grapheme_clusters)
			run_test ("test_text_input_renders_by_display_width", agent l_t25.test_text_input_renders_by_display_width)
			run_test ("test_text_input_scrolls_by_column_and_keeps_invariant", agent l_t25.test_text_input_scrolls_by_column_and_keeps_invariant)
			run_test ("test_tree_stays_in_area_and_follows_selection", agent l_t25.test_tree_stays_in_area_and_follows_selection)
			run_test ("test_calendar_stays_in_narrow_area", agent l_t25.test_calendar_stays_in_narrow_area)
			run_test ("test_calendar_weekday_before_year_one", agent l_t25.test_calendar_weekday_before_year_one)
			run_test ("test_gray_is_ansi_7", agent l_t25.test_gray_is_ansi_7)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone G Follow-ups Test Suite...%N")
			print ("============================================================%N")
			create l_t26
			run_test ("test_is_equal_differentiates_titles_and_borders", agent l_t26.test_is_equal_differentiates_titles_and_borders)
			run_test ("test_is_equal_table_and_canvas_and_chart", agent l_t26.test_is_equal_table_and_canvas_and_chart)
			run_test ("test_copied_list_and_table_elements_isolated", agent l_t26.test_copied_list_and_table_elements_isolated)
			run_test ("test_tree_collapse_reselects_visible_ancestor", agent l_t26.test_tree_collapse_reselects_visible_ancestor)
			run_test ("test_calendar_custom_first_day_and_date_styles", agent l_t26.test_calendar_custom_first_day_and_date_styles)
			run_test ("test_copied_tabs_bars_and_tree_roots_isolated", agent l_t26.test_copied_tabs_bars_and_tree_roots_isolated)
			run_test ("test_block_title_copies_keep_mirroring", agent l_t26.test_block_title_copies_keep_mirroring)
			run_test ("test_calendar_is_equal_compares_date_styles", agent l_t26.test_calendar_is_equal_compares_date_styles)
			run_test ("test_copy_on_write_keeps_copies_independent", agent l_t26.test_copy_on_write_keeps_copies_independent)
			run_test ("test_tree_state_collapse_uses_recorded_path", agent l_t26.test_tree_state_collapse_uses_recorded_path)
			run_test ("test_calendar_shows_surrounding_days", agent l_t26.test_calendar_shows_surrounding_days)
			run_test ("test_calendar_rejects_impossible_date_style", agent l_t26.test_calendar_rejects_impossible_date_style)

			print ("============================================================%N")
			print ("  Running EiffelTUI Keyboard Enhancement Test Suite...%N")
			print ("============================================================%N")
			create l_t27
			run_test ("test_insert_key_code", agent l_t27.test_insert_key_code)
			run_test ("test_key_event_kinds", agent l_t27.test_key_event_kinds)
			run_test ("test_parser_insert_key", agent l_t27.test_parser_insert_key)
			run_test ("test_kitty_csi_u_characters", agent l_t27.test_kitty_csi_u_characters)
			run_test ("test_kitty_csi_u_functional_keys", agent l_t27.test_kitty_csi_u_functional_keys)
			run_test ("test_csi_event_types_legacy_keys", agent l_t27.test_csi_event_types_legacy_keys)
			run_test ("test_modified_f3_disambiguation", agent l_t27.test_modified_f3_disambiguation)
			run_test ("test_backend_keyboard_enhancement", agent l_t27.test_backend_keyboard_enhancement)
			run_test ("test_tilde_function_keys", agent l_t27.test_tilde_function_keys)
			run_test ("test_application_pushes_and_pops_keyboard_flags", agent l_t27.test_application_pushes_and_pops_keyboard_flags)

			print ("============================================================%N")
			print ("  Running EiffelTUI Platform Driver Test Suite...%N")
			print ("============================================================%N")
			create l_platform
			across l_platform.tests as t loop
				run_test (t.name, t.routine)
			end

			print ("============================================================%N")
			print ("  Running EiffelTUI Tier 1 Foundation Examples Test Suite...%N")
			print ("============================================================%N")
			create l_t28
			run_test ("test_example_hello_world", agent l_t28.test_example_hello_world)
			run_test ("test_example_minimal", agent l_t28.test_example_minimal)
			run_test ("test_example_colors_rgb", agent l_t28.test_example_colors_rgb)
			run_test ("test_example_color_explorer", agent l_t28.test_example_color_explorer)
			run_test ("test_example_modifiers", agent l_t28.test_example_modifiers)
			run_test ("test_example_popup", agent l_t28.test_example_popup)
			run_test ("test_example_inline", agent l_t28.test_example_inline)

			print ("============================================================%N")
			print ("  Running EiffelTUI Tier 2 Widget Specialist Examples Test Suite...%N")
			print ("============================================================%N")
			create l_t29
			run_test ("test_example_todo_list", agent l_t29.test_example_todo_list)
			run_test ("test_example_user_input", agent l_t29.test_example_user_input)
			run_test ("test_example_input_form", agent l_t29.test_example_input_form)
			run_test ("test_example_table", agent l_t29.test_example_table)
			run_test ("test_example_scrollbar", agent l_t29.test_example_scrollbar)
			run_test ("test_example_gauge", agent l_t29.test_example_gauge)
			run_test ("test_example_calendar_explorer", agent l_t29.test_example_calendar_explorer)

			print ("============================================================%N")
			print ("  Running EiffelTUI Bracketed Paste Robustness Test Suite...%N")
			print ("============================================================%N")
			create l_t30
			run_test ("test_end_marker_split_by_timeout", agent l_t30.test_end_marker_split_by_timeout)
			run_test ("test_escape_before_end_marker", agent l_t30.test_escape_before_end_marker)
			run_test ("test_long_parameters_in_paste_kept", agent l_t30.test_long_parameters_in_paste_kept)
			run_test ("test_paste_watchdog", agent l_t30.test_paste_watchdog)
			run_test ("test_flush_outside_paste_unchanged", agent l_t30.test_flush_outside_paste_unchanged)
			run_test ("test_event_thread_pause_inside_end_marker", agent l_t30.test_event_thread_pause_inside_end_marker)
			run_test ("test_event_thread_lost_end_marker", agent l_t30.test_event_thread_lost_end_marker)
			run_test ("test_paste_split_into_parts", agent l_t30.test_paste_split_into_parts)
			run_test ("test_paste_exact_multiple_ends_with_empty_part", agent l_t30.test_paste_exact_multiple_ends_with_empty_part)
			run_test ("test_paste_parts_keep_sequences", agent l_t30.test_paste_parts_keep_sequences)
			run_test ("test_paste_watchdog_delivers_parts", agent l_t30.test_paste_watchdog_delivers_parts)
			run_test ("test_paste_event_owns_its_text", agent l_t30.test_paste_event_owns_its_text)
			run_test ("test_event_thread_resize_poll_not_per_byte", agent l_t30.test_event_thread_resize_poll_not_per_byte)

			print ("============================================================%N")
			print ("  Running EiffelTUI Failure Recovery Test Suite...%N")
			print ("============================================================%N")
			create l_t38
			run_test ("test_sgr_mouse_large_coordinates_clamped", agent l_t38.test_sgr_mouse_large_coordinates_clamped)
			run_test ("test_discard_pending", agent l_t38.test_discard_pending)
			run_test ("test_event_thread_retry_starts_clean", agent l_t38.test_event_thread_retry_starts_clean)
			run_test ("test_event_thread_large_mouse_coordinate", agent l_t38.test_event_thread_large_mouse_coordinate)
			run_test ("test_failed_push_releases_lock", agent l_t38.test_failed_push_releases_lock)

			print ("============================================================%N")
			print ("  Running EiffelTUI UTF-8 out Test Suite...%N")
			print ("============================================================%N")
			create l_t39
			run_test ("test_text_out_is_utf_8", agent l_t39.test_text_out_is_utf_8)
			run_test ("test_widget_items_out_is_utf_8", agent l_t39.test_widget_items_out_is_utf_8)

			print ("============================================================%N")
			print ("  Running EiffelTUI Unicode Gaps Test Suite...%N")
			print ("============================================================%N")
			create l_t40
			run_test ("test_vs16_widens_only_emoji", agent l_t40.test_vs16_widens_only_emoji)
			run_test ("test_bidi_controls_are_own_clusters", agent l_t40.test_bidi_controls_are_own_clusters)
			run_test ("test_buffer_drops_bidi_controls", agent l_t40.test_buffer_drops_bidi_controls)
			run_test ("test_calendar_header_centred_by_width", agent l_t40.test_calendar_header_centred_by_width)
			run_test ("test_sub_span_on_cluster_boundaries", agent l_t40.test_sub_span_on_cluster_boundaries)

			print ("============================================================%N")
			print ("  Running EiffelTUI Diff Pool Test Suite...%N")
			print ("============================================================%N")
			create l_t41
			run_test ("test_sparse_frame_pool_is_small", agent l_t41.test_sparse_frame_pool_is_small)
			run_test ("test_unused_spans_emptied", agent l_t41.test_unused_spans_emptied)
			run_test ("test_span_grows_to_a_row", agent l_t41.test_span_grows_to_a_row)
			run_test ("test_discard_pool", agent l_t41.test_discard_pool)
			run_test ("test_terminal_resize_discards_pool", agent l_t41.test_terminal_resize_discards_pool)

			print ("============================================================%N")
			print ("  Running EiffelTUI Shared Objects Test Suite...%N")
			print ("============================================================%N")
			create l_t42
			run_test ("test_symbols_are_immutable", agent l_t42.test_symbols_are_immutable)
			run_test ("test_set_style_stores_private_copy", agent l_t42.test_set_style_stores_private_copy)

			print ("============================================================%N")
			print ("  Running EiffelTUI Event Flood Test Suite...%N")
			print ("============================================================%N")
			create l_t43
			run_test ("test_drag_and_resize_coalesced", agent l_t43.test_drag_and_resize_coalesced)
			run_test ("test_clicks_and_moves_not_merged", agent l_t43.test_clicks_and_moves_not_merged)
			run_test ("test_coalescing_off", agent l_t43.test_coalescing_off)
			run_test ("test_queue_full", agent l_t43.test_queue_full)
			run_test ("test_input_thread_waits_while_full", agent l_t43.test_input_thread_waits_while_full)

			print ("============================================================%N")
			print ("  Running EiffelTUI Unicode Wrap Test Suite...%N")
			print ("============================================================%N")
			create l_t31
			run_test ("test_character_wrap_keeps_combining_marks", agent l_t31.test_character_wrap_keeps_combining_marks)
			run_test ("test_character_wrap_keeps_vs16", agent l_t31.test_character_wrap_keeps_vs16)
			run_test ("test_character_wrap_keeps_zwj_sequence", agent l_t31.test_character_wrap_keeps_zwj_sequence)
			run_test ("test_character_wrap_keeps_flags_whole", agent l_t31.test_character_wrap_keeps_flags_whole)
			run_test ("test_character_wrap_round_trip", agent l_t31.test_character_wrap_round_trip)
			run_test ("test_character_wrap_trims_leading_space", agent l_t31.test_character_wrap_trims_leading_space)
			run_test ("test_character_wrap_across_spans", agent l_t31.test_character_wrap_across_spans)
			run_test ("test_word_wrap_vs16_not_under_counted", agent l_t31.test_word_wrap_vs16_not_under_counted)
			run_test ("test_word_wrap_emoji_not_over_counted", agent l_t31.test_word_wrap_emoji_not_over_counted)
			run_test ("test_word_wrap_oversized_keeps_zwj", agent l_t31.test_word_wrap_oversized_keeps_zwj)
			run_test ("test_word_wrap_keeps_combining_marks", agent l_t31.test_word_wrap_keeps_combining_marks)
			run_test ("test_word_wrap_keeps_flags_whole", agent l_t31.test_word_wrap_keeps_flags_whole)
			run_test ("test_word_wrap_round_trip", agent l_t31.test_word_wrap_round_trip)
			run_test ("test_wrap_same_style_spans_split_vs16", agent l_t31.test_wrap_same_style_spans_split_vs16)
			run_test ("test_wrap_same_style_spans_split_zwj", agent l_t31.test_wrap_same_style_spans_split_zwj)
			run_test ("test_append_span_moves_continuation", agent l_t31.test_append_span_moves_continuation)
			run_test ("test_append_span_keeps_independent_span", agent l_t31.test_append_span_keeps_independent_span)
			run_test ("test_append_span_skips_empty_spans", agent l_t31.test_append_span_skips_empty_spans)
			run_test ("test_append_text", agent l_t31.test_append_text)
			run_test ("test_right_adjust", agent l_t31.test_right_adjust)
			run_test ("test_wrap_split_around_empty_span", agent l_t31.test_wrap_split_around_empty_span)
			run_test ("test_buffer_draws_vs16_split_around_empty_span", agent l_t31.test_buffer_draws_vs16_split_around_empty_span)
			run_test ("test_wrap_different_style_spans_split_zwj", agent l_t31.test_wrap_different_style_spans_split_zwj)
			run_test ("test_buffer_draws_vs16_split_across_styles", agent l_t31.test_buffer_draws_vs16_split_across_styles)

			print ("============================================================%N")
			print ("  Running EiffelTUI Console Input Claim Test Suite...%N")
			print ("============================================================%N")
			create l_t32
			run_test ("test_claim_is_exclusive", agent l_t32.test_claim_is_exclusive)
			run_test ("test_platform_drivers_share_one_claim", agent l_t32.test_platform_drivers_share_one_claim)
			run_test ("test_event_thread_holds_claim_while_running", agent l_t32.test_event_thread_holds_claim_while_running)
			run_test ("test_second_reader_refused", agent l_t32.test_second_reader_refused)
			run_test ("test_query_releases_claim", agent l_t32.test_query_releases_claim)
			run_test ("test_query_refused_while_reader_runs", agent l_t32.test_query_refused_while_reader_runs)
			run_test ("test_inline_setup_refused_while_reader_runs", agent l_t32.test_inline_setup_refused_while_reader_runs)
			run_test ("test_application_holds_claim_while_running", agent l_t32.test_application_holds_claim_while_running)
			run_test ("test_run_refused_while_input_in_use", agent l_t32.test_run_refused_while_input_in_use)

			print ("============================================================%N")
			print ("  Running EiffelTUI Unicode Scalar Test Suite...%N")
			print ("============================================================%N")
			create l_t33
			run_test ("test_scalar_value_boundaries", agent l_t33.test_scalar_value_boundaries)
			run_test ("test_scalar_string", agent l_t33.test_scalar_string)
			run_test ("test_replacement_is_measurement_neutral", agent l_t33.test_replacement_is_measurement_neutral)
			run_test ("test_buffer_draws_surrogates_as_replacement", agent l_t33.test_buffer_draws_surrogates_as_replacement)
			run_test ("test_buffer_replaces_values_above_u10ffff", agent l_t33.test_buffer_replaces_values_above_u10ffff)
			run_test ("test_put_char_replaces_surrogate", agent l_t33.test_put_char_replaces_surrogate)
			run_test ("test_surrogate_keeps_its_combining_mark", agent l_t33.test_surrogate_keeps_its_combining_mark)
			run_test ("test_line_spans_stay_in_place", agent l_t33.test_line_spans_stay_in_place)
			run_test ("test_cell_setters_replace_non_scalar_values", agent l_t33.test_cell_setters_replace_non_scalar_values)
			run_test ("test_frame_is_valid_utf_8", agent l_t33.test_frame_is_valid_utf_8)
			run_test ("test_frames_with_mixed_text_are_valid_utf_8", agent l_t33.test_frames_with_mixed_text_are_valid_utf_8)

			print ("============================================================%N")
			print ("  Running EiffelTUI UTF-8 Input Test Suite...%N")
			print ("============================================================%N")
			create l_t34
			run_test ("test_well_formed_boundaries", agent l_t34.test_well_formed_boundaries)
			run_test ("test_unicode_table_3_8_example", agent l_t34.test_unicode_table_3_8_example)
			run_test ("test_overlongs_rejected", agent l_t34.test_overlongs_rejected)
			run_test ("test_surrogates_rejected", agent l_t34.test_surrogates_rejected)
			run_test ("test_above_u10ffff_rejected", agent l_t34.test_above_u10ffff_rejected)
			run_test ("test_stray_continuation_bytes", agent l_t34.test_stray_continuation_bytes)
			run_test ("test_truncated_sequences", agent l_t34.test_truncated_sequences)
			run_test ("test_decoded_code_points", agent l_t34.test_decoded_code_points)
			run_test ("test_overlong_esc_does_not_end_paste", agent l_t34.test_overlong_esc_does_not_end_paste)
			run_test ("test_paste_keeps_character_split_by_pause", agent l_t34.test_paste_keeps_character_split_by_pause)
			run_test ("test_paste_watchdog_replaces_unfinished_character", agent l_t34.test_paste_watchdog_replaces_unfinished_character)

			print ("============================================================%N")
			print ("  Running EiffelTUI Serializer Re-anchoring Test Suite...%N")
			print ("============================================================%N")
			create l_t35
			run_test ("test_narrow_text_has_one_move", agent l_t35.test_narrow_text_has_one_move)
			run_test ("test_move_after_wide_cell", agent l_t35.test_move_after_wide_cell)
			run_test ("test_move_after_multi_code_point_cluster", agent l_t35.test_move_after_multi_code_point_cluster)
			run_test ("test_no_move_after_last_cell", agent l_t35.test_no_move_after_last_cell)
			run_test ("test_moves_use_the_offset", agent l_t35.test_moves_use_the_offset)
			run_test ("test_text_after_zwj_sequence_lands_in_place", agent l_t35.test_text_after_zwj_sequence_lands_in_place)
			run_test ("test_diff_keeps_the_row_in_place", agent l_t35.test_diff_keeps_the_row_in_place)

			print ("============================================================%N")
			print ("  Running EiffelTUI Text Input Edge Case Test Suite...%N")
			print ("============================================================%N")
			create l_t36
			run_test ("test_single_line_text", agent l_t36.test_single_line_text)
			run_test ("test_paste_is_single_line", agent l_t36.test_paste_is_single_line)
			run_test ("test_typed_controls", agent l_t36.test_typed_controls)
			run_test ("test_set_value_is_single_line", agent l_t36.test_set_value_is_single_line)
			run_test ("test_insert_regional_indicator_before_flag", agent l_t36.test_insert_regional_indicator_before_flag)
			run_test ("test_insert_before_combining_mark", agent l_t36.test_insert_before_combining_mark)
			run_test ("test_insert_zwj_between_emoji", agent l_t36.test_insert_zwj_between_emoji)
			run_test ("test_backspace_regroups_flags", agent l_t36.test_backspace_regroups_flags)
			run_test ("test_delete_regroups_flags", agent l_t36.test_delete_regroups_flags)
			run_test ("test_typing_keeps_cursor_on_boundaries", agent l_t36.test_typing_keeps_cursor_on_boundaries)
			run_test ("test_cursor_on_zero_width_cluster_keeps_next_character", agent l_t36.test_cursor_on_zero_width_cluster_keeps_next_character)
			run_test ("test_cursor_at_end_is_blank_cell", agent l_t36.test_cursor_at_end_is_blank_cell)

			print ("============================================================%N")
			print ("  Running EiffelTUI Frame Output Test Suite...%N")
			print ("============================================================%N")
			create l_t37
			run_test ("test_frame_buffer_reused", agent l_t37.test_frame_buffer_reused)
			run_test ("test_cursor_after_frame", agent l_t37.test_cursor_after_frame)
			run_test ("test_cursor_after_zwj_sequence", agent l_t37.test_cursor_after_zwj_sequence)
			run_test ("test_cursor_at_right_edge", agent l_t37.test_cursor_at_right_edge)
			run_test ("test_empty_frame_keeps_cursor", agent l_t37.test_empty_frame_keeps_cursor)
			run_test ("test_put_frame_does_not_scan", agent l_t37.test_put_frame_does_not_scan)
			run_test ("test_put_string_still_tracks", agent l_t37.test_put_string_still_tracks)

			print ("============================================================%N")
			print ("  TEST SUITE SUMMARY%N")
			print ("============================================================%N")
			print ("  Total tests executed: " + total_count.out + "%N")
			print ("  Passed:               " + pass_count.out + "%N")
			print ("  Failed:               " + fail_count.out + "%N")
			print ("============================================================%N")

			if fail_count > 0 then
				print ("  SUITE RESULT: FAILED (" + fail_count.out + " failure(s))%N%N")
				(create {EXCEPTIONS}).die (1)
			else
				print ("  SUITE RESULT: ALL TESTS PASSED!%N%N")
			end
		end

feature {NONE} -- Execution Engine

	total_count: INTEGER
			-- Number of tests executed

	pass_count: INTEGER
			-- Number of tests that completed successfully

	fail_count: INTEGER
			-- Number of tests that raised an exception

	run_test (a_name: STRING; a_routine: PROCEDURE)
			-- Execute `a_routine` within an isolated rescue context.
			-- If an exception occurs, record failure, log reason, and continue.
		local
			l_failed: BOOLEAN
			l_exc_mgr: EXCEPTION_MANAGER
		do
			if not l_failed then
				total_count := total_count + 1
				a_routine.call
				pass_count := pass_count + 1
				print ("  [PASS] " + a_name + "%N")
			end
		rescue
			if not l_failed then
				l_failed := True
				fail_count := fail_count + 1
				print ("  [FAIL] " + a_name + "%N")
				create l_exc_mgr
				if attached l_exc_mgr.last_exception as l_exc then
					if attached l_exc.description as l_desc and then not l_desc.is_empty then
						print ("         Reason: ")
						print (l_desc)
						print ("%N")
					elseif attached l_exc.tag as l_tag and then not l_tag.is_empty then
						print ("         Tag: ")
						print (l_tag)
						print ("%N")
					end
					if attached l_exc.recipient_name as l_rec then
						print ("         Location: " + l_rec + "%N")
					end
				end
				retry
			end
		end

end
