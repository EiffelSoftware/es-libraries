note
	description: "[
			Interactive check of {EV_WEB_BROWSER} on the current platform:
			opens a window, runs every check in sequence, prints the results,
			and exits with status 0 if all checks pass, 1 otherwise.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WEB_BROWSER_CHECK

create
	make

feature {NONE} -- Initialization

	make
			-- Run the checks.
		local
			l_window: EV_TITLED_WINDOW
			l_app: EV_APPLICATION
			l_timeout: EV_TIMEOUT
		do
			create l_app
			application := l_app
			create steps.make (10)
			create browser
			l_app.uncaught_exception_actions.extend (agent (e: EXCEPTION)
				do
					if attached e.trace as t then report (False, t) else report (False, e.tag) end
					finish
				end)
			create l_window.make_with_title ("EV_WEB_BROWSER check")
			l_window.extend (browser)
			l_window.set_size (800, 600)
			l_window.close_request_actions.extend (agent finish)
			l_window.show
			browser.load_failed_actions.extend (agent (a_uri, a_error: READABLE_STRING_32)
				do
					report (False, {STRING_32} "load_failed_actions: " + a_uri + ": " + a_error)
				end)

			steps.extend (agent check_usable)
			steps.extend (agent check_load_html)
			steps.extend (agent check_evaluate_number)
			steps.extend (agent check_evaluate_string)
			steps.extend (agent check_evaluate_promise)
			steps.extend (agent check_evaluate_undefined)
			steps.extend (agent check_evaluate_error)
			steps.extend (agent check_document_start_script_and_navigation_handler)
			steps.extend (agent check_zoom)
			steps.extend (agent check_history)

				-- Fail if the checks are not done in time.
			create l_timeout.make_with_interval (Timeout_seconds * 1000)
			l_timeout.actions.extend (agent
				do
					report (False, "timeout: step " + step_index.out + " did not complete")
					finish
				end)

			l_app.do_once_on_idle (agent next_step)
			l_app.launch

			io.put_string ("%N" + passed_count.out + " passed, " + failed_count.out + " failed%N")
			if failed_count > 0 or passed_count = 0 then
				(create {EXCEPTIONS}).die (1)
			end
		end

feature -- Checks

	check_usable
		do
			report (browser.is_browser_usable, "is_browser_usable")
			if browser.is_browser_usable then
				next_step
			else
				finish
			end
		end

	check_load_html
			-- `load_html`, events, and message from the page.
		local
			l_received: ARRAYED_LIST [STRING_32]
			l_done: PROCEDURE
		do
			create l_received.make (3)
			l_done := agent (a_received: ARRAYED_LIST [STRING_32])
				do
					if
						across a_received as r some r.same_string ("finished") end and
						across a_received as r some r.same_string ({STRING_32} "message:{%"hello%":%"wörld%"}") end and
						across a_received as r some r.same_string ({STRING_32} "title:Page ⓵") end
					then
						report (True, "load_html: load_finished_actions, title_changed_actions, message_received_actions")
						browser.load_finished_actions.wipe_out
						browser.title_changed_actions.wipe_out
						browser.message_received_actions.wipe_out
						next_step
					end
				end (l_received)
			browser.load_started_actions.extend (agent (a_uri: READABLE_STRING_32) do report (True, "load_started_actions") ; browser.load_started_actions.wipe_out end)
			browser.load_finished_actions.extend (agent (a_uri: READABLE_STRING_32; a_received: ARRAYED_LIST [STRING_32]; a_done: PROCEDURE)
				do
					a_received.extend ("finished")
					a_done.call
				end (?, l_received, l_done))
			browser.title_changed_actions.extend (agent (a_title: READABLE_STRING_32; a_received: ARRAYED_LIST [STRING_32]; a_done: PROCEDURE)
				do
					a_received.extend ({STRING_32} "title:" + a_title)
					a_done.call
				end (?, l_received, l_done))
			browser.message_received_actions.extend (agent (a_message: READABLE_STRING_32; a_received: ARRAYED_LIST [STRING_32]; a_done: PROCEDURE)
				do
					a_received.extend ({STRING_32} "message:" + a_message)
					a_done.call
				end (?, l_received, l_done))
			browser.load_html ({STRING_32} "[
				<!DOCTYPE html>
				<html><head><meta charset="utf-8"><title>Page ⓵</title></head>
				<body><h1>Page ⓵</h1>
				<script>window.eiffel.postMessage ({hello: "wörld"});</script>
				</body></html>
			]", Void)
		end

	check_evaluate_number
		do
			expect_evaluation ("1 + 2", "3", Void, Void)
		end

	check_evaluate_string
			-- Script and result with characters to escape.
		do
			expect_evaluation ({STRING_32} "'a\%"b\\c\n' + String.fromCharCode (0x2028) + 'é' + `${document.title}`", {STRING_32} "%"a\%"b\\c\n%/0x2028/é" + "Page ⓵%"", Void, Void)
		end

	check_evaluate_promise
		do
			expect_evaluation ("new Promise ((resolve) => setTimeout (() => resolve ({a: [1, true, null]}), 10))", "{%"a%":[1,true,null]}", Void, Void)
		end

	check_evaluate_undefined
		do
			expect_evaluation ("undefined", "null", Void, Void)
		end

	check_evaluate_error
		do
			expect_evaluation ("throw new Error ('boom')", Void, "Error: boom", Void)
		end

	check_document_start_script_and_navigation_handler
			-- `add_document_start_script`, and veto of a navigation by `navigation_handler`.
		local
			l_requested: ARRAYED_LIST [READABLE_STRING_32]
		do
			create l_requested.make (2)
			browser.add_document_start_script ("window.startValue = 40 + 2;")
			browser.set_navigation_handler (agent (a_uri: READABLE_STRING_32; a_requested: ARRAYED_LIST [READABLE_STRING_32]): BOOLEAN
				do
					a_requested.extend (a_uri)
					Result := not a_uri.has_substring ("blocked")
				end (?, l_requested))
			browser.message_received_actions.extend (agent (a_message: READABLE_STRING_32; a_requested: ARRAYED_LIST [READABLE_STRING_32])
				do
					if a_message.same_string ("page 2") then
						browser.message_received_actions.wipe_out
						expect_evaluation ("[window.startValue, document.title]", "[42,%"Page 2%"]", Void, agent (a_req: ARRAYED_LIST [READABLE_STRING_32])
							do
								report (across a_req as r some r.has_substring ("blocked.example") end, "navigation_handler called for the blocked URI")
								browser.set_navigation_handler (Void)
							end (a_requested))
					end
				end (?, l_requested))
				-- The page tries to leave to a blocked URI, then reports.
			browser.load_html ("[
				<!DOCTYPE html>
				<html><head><title>Page 2</title></head><body>
				<script>
					location.href = "https://blocked.example/";
					setTimeout (function () { window.eiffel.postMessage ("page 2"); }, 300);
				</script>
				</body></html>
			]", "https://www.example.com/")
		end

	check_zoom
		do
			browser.set_zoom_level (1.5)
			report ((browser.zoom_level - 1.5).abs < 0.01, "set_zoom_level / zoom_level")
			browser.set_zoom_level (1.0)
			next_step
		end

	check_history
			-- `uri`, `title`, `can_go_back`, `back`, `can_go_forth`, with two local files.
			-- (Documents displayed with `load_html` are not recorded in the history by every engine.)
		local
			l_page_a, l_page_b: STRING_32
		do
			report (attached browser.uri as u and then u.has_substring ("www.example.com"), "uri")
			report (attached browser.title as t and then t.same_string ("Page 2"), "title")
			l_page_a := new_page_file ("web_browser_check_a.html", "Page A")
			l_page_b := new_page_file ("web_browser_check_b.html", "Page B")
			browser.load_finished_actions.extend (agent (a_uri: READABLE_STRING_32; a_b: READABLE_STRING_32)
				do
					browser.load_finished_actions.wipe_out
					report (a_uri.has_substring ("web_browser_check_a.html"), "load_uri (file)")
					browser.load_finished_actions.extend (agent (a_uri_b: READABLE_STRING_32)
						do
							browser.load_finished_actions.wipe_out
							report (attached browser.uri as u and then u.has_substring ("web_browser_check_b.html"), "load_uri (second file)")
							report (browser.can_go_back, "can_go_back")
							report (not browser.can_go_forth, "not can_go_forth")
							browser.load_finished_actions.extend (agent (a_back_uri: READABLE_STRING_32)
								do
									browser.load_finished_actions.wipe_out
									report (a_back_uri.has_substring ("web_browser_check_a.html"), "back")
									report (browser.can_go_forth, "can_go_forth")
									next_step
								end)
							browser.back
						end)
					browser.load_uri (a_b)
				end (?, l_page_b))
			browser.load_uri (l_page_a)
		end

feature {NONE} -- Implementation

	expect_evaluation (a_script: READABLE_STRING_GENERAL; a_expected_value, a_expected_error: detachable READABLE_STRING_GENERAL; a_then: detachable PROCEDURE)
			-- Evaluate `a_script`, check the value or the error, then call `a_then` if set, and go to the next step.
		do
			browser.evaluate_script (a_script, agent (a_value, a_error: detachable READABLE_STRING_32; a_scr: READABLE_STRING_GENERAL; a_exp_value, a_exp_error: detachable READABLE_STRING_GENERAL; a_next: detachable PROCEDURE)
				do
					report (
						(a_exp_value /= Void implies (a_value /= Void and then a_value.same_string_general (a_exp_value))) and
						(a_exp_error /= Void implies (a_error /= Void and then a_error.same_string_general (a_exp_error))) and
						(a_exp_value = Void implies a_value = Void) and
						(a_exp_error = Void implies a_error = Void),
						evaluation_label (a_scr, a_value, a_error))
					if a_next /= Void then
						a_next.call
					end
					next_step
				end (?, ?, a_script, a_expected_value, a_expected_error, a_then))
		end

	new_page_file (a_file_name: STRING_8; a_title: STRING_8): STRING_32
			-- URI of a new HTML file `a_file_name` with title `a_title`, in the temporary directory.
		local
			l_path: PATH
			l_file: PLAIN_TEXT_FILE
		do
			if attached {EXECUTION_ENVIRONMENT}.temporary_directory_path as l_temp then
				l_path := l_temp.extended (a_file_name)
			else
				create l_path.make_from_string (a_file_name)
			end
			l_path := l_path.absolute_path
			create l_file.make_with_path (l_path)
			l_file.create_read_write
			l_file.put_string ("<!DOCTYPE html><html><head><title>" + a_title + "</title></head><body>" + a_title + "</body></html>")
			l_file.close
			create Result.make_from_string_general ("file://")
			if not l_path.name.starts_with ("/") then
				Result.append_character ('/')
			end
			Result.append (l_path.name)
			Result.replace_substring_all ("\", "/")
			Result.replace_substring_all (" ", "%%20")
		end

	evaluation_label (a_script: READABLE_STRING_GENERAL; a_value, a_error: detachable READABLE_STRING_32): STRING_32
			-- Label of the check of the evaluation of `a_script`.
		do
			create Result.make_from_string_general ("evaluate_script (")
			Result.append_string_general (a_script)
			Result.append_string_general (") -> ")
			if a_value /= Void then
				Result.append (a_value)
			elseif a_error /= Void then
				Result.append_string_general ("error: ")
				Result.append (a_error)
			end
		end

	next_step
			-- Run the next step, or finish.
		do
			if step_index < steps.count then
				step_index := step_index + 1
				application.do_once_on_idle (steps [step_index])
			else
				finish
			end
		end

	finish
			-- Stop the application.
		do
			application.destroy
		end

	report (a_ok: BOOLEAN; a_label: READABLE_STRING_GENERAL)
			-- Print the result `a_ok` of the check `a_label`.
		do
			if a_ok then
				passed_count := passed_count + 1
				io.put_string ("PASS ")
			else
				failed_count := failed_count + 1
				io.put_string ("FAIL ")
			end
			io.put_string_32 (a_label.to_string_32)
			io.put_new_line
		end

	application: EV_APPLICATION
			-- Application.

	browser: EV_WEB_BROWSER
			-- Checked browser.

	steps: ARRAYED_LIST [PROCEDURE]
			-- Checks to run, in sequence.

	step_index: INTEGER
			-- Index of the current step in `steps`.

	passed_count, failed_count: INTEGER
			-- Number of passed and failed checks.

	Timeout_seconds: INTEGER = 30
			-- Maximum duration of the checks.

;note
	copyright:	"Copyright (c) 1984-2026, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
