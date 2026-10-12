# EiffelTUI — Concurrency, Unicode & Memory Management Review

**Date:** 2026-09-28
**Scope:** `library/**` (core, widgets, both platform drivers) at commit `75f184b`.
**Status (updated 2026-09-28):** C1 fixed (committed in `3fc3e9f`). U1 fixed (committed in `d81d319`). U2 and U11 fixed (committed in `fdca736`, with `9417d23`). M1 fixed (committed in `3a719cd`). C2 fixed (committed in `99af210`). C3 fixed (committed in `264cee1`). U3 fixed (committed in `82b95bd`). U4 fixed (committed in `b9b6f62`). U5 fixed (committed in `4b55a6b`). U12, found while fixing U5, fixed (committed in `005a2ed`). U6 fixed (committed in `8f86563`). U7 fixed (committed in `ac59449`). U8 fixed (committed in `a02ad7a`). M2 fixed (committed in `3fbe449`). C4 fixed (uncommitted, working tree). All other findings are open.
**Prompt for this review:** the question raised after the TUI story: *"concurrency and Unicode... and then memory management. These things need to be cared for in detail, carefully."* These are the areas where generated code can look fine while hiding subtle, high-severity defects. So this review traces real paths (event thread → parser → queue → app, text → buffer → serializer → terminal), looks for *implicit* contracts that the code relies on but never states, and confirms the key claims by running code, not just reading it.

**How it was done:**
- **Core read line by line:** `EVENT_THREAD`, `SYNCHRONIZED_EVENT_QUEUE`, `TUI_APPLICATION`, both console drivers, `ANSI_INPUT_PARSER`, `UNICODE_WIDTH`, `BUFFER`, `TERMINAL_CELL`, `ANSI_SERIALIZER`, `TERMINAL`.
- **Two focused sweeps:** Unicode handling in the widget/text layer, and memory/aliasing/C interop across the whole library.
- **Every sweep finding cited below was re-checked against the source.**
- **Four findings confirmed by a compiled probe** built against the library with assertions on (see [Appendix A](#appendix-a--probe-results)).

---

## Verdict

The foundations are better than typical. Specifically:
- **Threading:** proper `MUTEX` + `CONDITION_VARIABLE` queue with spurious-wakeup handling, and `C blocking` on the reads so the GC is never held up.
- **Terminal safety:** control characters are stripped before they reach cells, so there is no terminal escape injection from content.
- **Unicode:** display widths generated from Unicode 16 with a real grapheme segmenter.
- **Bounded caches:** layout cache and symbol pool.
- **Signals:** async-signal-safe signal handlers.

The defects are where the review theme predicted: **timing interactions between threads and the input state machine, per-code-point loops that ignore the grapheme layer that already exists, and invalid Unicode passing through unchecked**. Two of them are **High** and user-visible:
1. A paste whose end marker arrives split across the 25 ms poll timeout **locks the application's keyboard permanently** (probe-verified). The paste buffer then grows without bound. *(Both are now fixed, see C1 and M1.)*
2. Character wrap **deletes every combining mark, ZWJ and variation selector**, and word wrap measures by code point, so emoji and accented/Indic text is corrupted or truncated. *(Both are now fixed, see U1 and U2.)*

None of the findings is a memory-safety bug in the C sense. The C interop is careful.

### Findings at a glance

| ID | Area | Severity | Finding | Evidence | Status |
|----|------|----------|---------|----------|--------|
| C1 | Concurrency × input | **High** | Input timeout mid-escape-sequence during a paste leaves `is_in_paste` stuck; all later keys are swallowed | Probe ✔ | **Fixed** |
| U1 | Unicode | **High** | Character wrap drops all zero-width code points (combining marks, ZWJ, VS16) | Code ✔ | **Fixed** |
| U2 | Unicode | **High** | Word wrap measures per code point: emoji over- or under-counted; oversized split drops ZWJ | Code ✔ | **Fixed** |
| M1 | Memory | **High** (with C1) | Paste buffer unbounded; `wipe_out` keeps peak capacity for the life of the thread | Code ✔ | **Fixed** |
| C2 | Concurrency | Medium | `run` is single-shot: second run fails `THREAD.launch` precondition (or hangs without input when assertions are off) | Probe ✔ | **Fixed** |
| C3 | Concurrency | Medium | `query_cursor_position` / `setup_inline_viewport` are public but unsafe while the input thread runs (two readers race on unsynchronized state) | Code ✔ | **Fixed** |
| U3 | Unicode | Medium | Lone surrogates / non-scalar code points are given width 1 and emitted as CESU-8, so the terminal and the buffer disagree on columns | Probe ✔ | **Fixed** |
| U4 | Unicode × security | Medium | UTF-8 input decoder accepts overlongs, surrogates and > U+10FFFF; an overlong ESC ends a bracketed paste and the rest arrives as keystrokes | Probe ✔ | **Fixed** |
| U5 | Unicode | Medium | Serializer positions the cursor only at span start, so any width disagreement with the terminal drifts the rest of the span, and diffing keeps it wrong | Code ✔ | **Fixed** |
| U6 | Unicode | Medium | Scrollbar symbols written with `put_string`: not clipped to the widget area | Code ✔ | **Fixed** |
| U7 | Unicode | Medium | Gauge label loses a wide glyph straddling the fill boundary; line-gauge wide symbols blank each other | Code ✔ | **Fixed** |
| U8 | Unicode | Medium | Text input: cursor on a zero-width cluster overwrites the next char; insertion can leave the cursor inside a cluster | Code ✔ | **Fixed** |
| M2 | Memory | Medium | Every frame is re-decoded to `STRING_32` just to track the cursor; new frame string per frame | Code ✔ | **Fixed** |
| C4 | Concurrency | Low | `clean_up` ignores the `join_with_timeout` result: restore proceeds with the reader possibly alive | Code ✔ | **Fixed** |
| C5 | Concurrency | Low | Ctrl/signal handlers write the reset concurrently with a frame being written; `restore_modes` races | Code ✔ | **Fixed** |
| C6 | Concurrency | Low | Exception after the parser is part-way through a sequence is retried without resetting the parser; a mutex held during an exception is never released | Code ✔ | **Fixed** |
| U9 | Unicode | Low | `out` on spans/lines/cells uses `to_string_8`: precondition violation on non-Latin-1 text (assertions are on in the ECF) | Code ✔ | **Fixed** |
| U10 | Unicode | Low | Segmentation/width gaps: no SpacingMark/Prepend rules, VS16 widens any base, ambiguous width fixed at 1, bidi controls pass through | Code ✔ | **Fixed** (5 closed, 3 documented) |
| U11 | Unicode | Low | A grapheme cluster split across spans of different styles is measured and drawn as two clusters; a wrap can break inside it, and the buffer draws the next span over a widened cluster | Test ✔ | **Fixed** |
| U12 | Unicode × tests | Medium | Non-ASCII string literals are compiled as Latin-1: tests that write emoji or CJK literally test mojibake, and an example shows it on screen | Probe ✔ | **Fixed** |
| M3 | Memory | Low | Diff span pool sizes each span to the rest of the row and never shrinks | Code ✔ | **Fixed** |
| M4 | Memory / aliasing | Low | Shared pooled symbol strings are mutable and reachable; `set_style` stores the reference while the class note promises a private copy | Code ✔ | **Fixed** |
| M5 | Memory | Low | Event queue unbounded; the drain loop does not redraw while input keeps arriving | Code ✔ | **Fixed** |

---

## 1. Concurrency

### Threading model (as implemented)
- **Main thread:** owns `TERMINAL`, the buffers, rendering, and every write to stdout.
- **`EVENT_THREAD` (Eiffel `THREAD`):** owns the `ANSI_INPUT_PARSER` and the driver's input state. It polls resize, reads **one byte per iteration** with a 25 ms timeout, and pushes events into `SYNCHRONIZED_EVENT_QUEUE`. On a timeout it called `flush_escape`; since the C1 fix it calls `notify_idle` with the time since the last byte.
- **Stop and failure flags:** guarded by `stop_mutex`.
- **Console input claim** (since the C3 fix): at most one reader reads a console at a time. `EVENT_THREAD` holds the claim from `start` until `execute` ends; a DSR query holds it while it reads. The claim is a `CONSOLE_INPUT_CLAIM` (mutex-guarded), one per process for the platform drivers.
- **OS thread (Windows Ctrl handler) / any thread (POSIX signals):** writes a reset sequence and restores console modes.
- **All `once` routines are per-thread (the Eiffel default).** So `LAYOUT`'s cache, `TERMINAL_CELL`'s symbol pool and the `KEY_CODE` constants exist once per thread. This is correct: every cross-thread comparison of `KEY_CODE` goes through `is_equal` / `~` or `is_up`-style queries, and the enums compared with `=` are `NATURAL_8` constants. Worth writing down, because a future `once` object compared with `=` across threads would silently fail.

### C1 — High — A timeout inside the paste end marker locks the keyboard — **FIXED**
`library/core/event/ansi_input_parser.e:100-110`, `event_thread.e:149-156` (locations as of `75f184b`)

> **Status: fixed on 2026-09-28** (committed in `3fc3e9f`).
>
> **Changes:**
> - **`ANSI_INPUT_PARSER.flush_escape`:** during a paste it flushes nothing. A pending sequence is kept, and the next bytes complete it.
> - **ESC inside a pending sequence:** an ESC that interrupts a pending `ESC`, `ESC[`, `ESC[params`, `ESC O` or `ESC[<params` inside a paste is kept as text (`abandon_sequence_to_paste`) and starts a new sequence. This closes a **second path to the same lock-up**, one the original analysis missed: pasted text ending in an ESC, followed by the real end marker, lost the marker with no timing involved. A pseudo-sequence of more than 64 parameter characters inside a paste is also kept whole instead of silently losing bytes.
> - **Watchdog, `notify_idle (a_idle_ms)`:** new. `EVENT_THREAD` calls it on each timeout with the real time since the last byte (`MONOTONIC_CLOCK`). If a paste has been silent for `paste_timeout_ms` (default 2000 ms, set with `ANSI_INPUT_PARSER.set_paste_timeout` or `EVENT_THREAD.set_paste_timeout`), it ends the paste and delivers the collected text; an unfinished sequence is dropped.
> - **Late end marker:** an `ESC[201~` outside a paste (for example after the watchdog fired) is ignored instead of emitting an empty `PASTE_EVENT`.
>
> **Trade-off:** a genuine paste that stalls for longer than `paste_timeout_ms` in mid-stream is split; the rest arrives as keystrokes. Tune `paste_timeout_ms` for high-latency links.
>
> **Verification:**
> - **New tests** (`tests/test_paste_robustness.e`, registered in `test_app.e`, 7 in all):
>   - the marker cut by a timeout after each of its 5 prefixes;
>   - an ESC right before the marker from each of the six parser states;
>   - long parameters in a paste;
>   - the watchdog, plus keys working again after it;
>   - the lone Escape key outside a paste (unchanged);
>   - `EVENT_THREAD` with a real pause inside the marker, and with a lost marker.
> - **Full suite:** 250/250 pass (workbench, Windows).
> - **Probe case 1** now prints `is_in_paste=False events=2` (clean rebuild; see Appendix A).
>
> **Follow-up:** M1 (paste size cap, buffer replacement, block reads) was fixed afterwards, see M1.

**Original analysis** (kept for the record):

```eiffel
flush_escape
    do
        if state = State_escape then
            events.extend (create {KEY_EVENT}.make_special ({KEY_CODE}.escape))
            state := State_ground
        elseif state = State_csi or state = State_csi_param or ... then
            state := State_ground
            param_buffer.wipe_out          -- discards "20" of "ESC[201~"
        end
    end
```

`EVENT_THREAD` calls `flush_escape` whenever 25 ms pass without a byte. `flush_escape` does not know about `is_in_paste`. The bytes of a large paste arrive in chunks, and over SSH or a slow pty the chunk boundary can land inside `ESC[201~` with a gap longer than 25 ms. When that happens:
1. The partial `ESC[20` is thrown away.
2. `1~` is appended to the paste text.
3. **`is_in_paste` stays `True` forever.** Every later keystroke, including the app's quit key, goes into `paste_buffer`, and the app never receives another `KEY_EVENT`.

The same timeout emits a spurious `Escape` key in the middle of a paste if the pasted text contains an ESC right before a gap.

**Probe:** `ESC[200~hello`, `ESC[20`, `flush_escape`, `1~`, `q` ⇒ `is_in_paste=True, events=0`. The `q` was swallowed.

**Fix:**
- While `is_in_paste`, `flush_escape` should append the pending partial sequence (`ESC`, `ESC[`, parameters) to `paste_buffer` and keep the paste open, not reset to ground.
- Add a paste watchdog: if no `ESC[201~` arrives within N seconds (or N bytes, see M1), emit what has been collected as a `PASTE_EVENT` and leave paste mode.
- Add a test that interleaves `flush_escape` at every byte position of `ESC[201~`. The existing `test_bracketed_paste_event` feeds bytes contiguously, so it cannot catch this.

### C2 — Medium — `run` works once per application object, but its contract does not say so — **FIXED**
`library/core/application/tui_application.e:142-156`, `event_thread.e:67-75` (locations as of `75f184b`)

> **Status: fixed on 2026-09-28** (committed in `99af210`).
>
> **Choice:** `run` can now be called again. The review offered two ways out: support a second run, or state that there is none (`require not_run_before`). A second run is the more useful contract. `EXAMPLE_RUNNER`-style programs can run a screen, go back to a menu and run it again.
>
> **Changes:**
> - **`EVENT_THREAD.renewed`** (new): returns a new, not yet launched thread with the same queue, driver and settings (poll interval, paste timeout, paste size). A `THREAD` object runs only once (`terminated` is never reset, so `is_launchable` stays `False`), so a new object is the only way to read input again. The new parser starts in the ground state: nothing from the first run's input state carries over, and `internal_should_stop` is `False`.
> - **`TUI_APPLICATION.run`:** when `event_thread` has already run, it is replaced by `event_thread.renewed` before setup, and events left in `event_queue` from the previous run (keys typed after the quit key, a late resize) are discarded. The first run is unchanged: it launches the thread created in `make_with_terminal`, and events pushed into the queue before it are kept. Settings made on `event_thread` before any run are therefore kept for every later run.
> - **New precondition `input_thread_available`** (`is_input_thread_available`, new public query: `event_thread.is_launchable or event_thread.terminated`). It is `False` only if the previous run's input thread did not stop within `Join_timeout_ms`, and is still reading the console. A second reader would then race it (see C3 and C4), so the contract refuses the run instead of starting one. `clean_up` still ignores the join result. That is C4, which stays open, but its worst consequence (two readers) is now stated and checked.
> - **New invariant `event_thread_uses_queue`:** `event_thread.queue = event_queue`, which holds across the replacement.
>
> **Note for callers:** `event_thread` is a different object after the second `run` starts. Code that kept a reference to the old thread and changes its settings between runs still works, since `renewed` copies them from that object; settings changed on the old reference *during* a later run have no effect.
>
> **Verification:**
> - **New tests** (`tests/test_milestone_c.e`, 2, registered in `test_app.e`):
>   - `test_tui_application_runs_twice`: the same application runs twice on a scripted driver (`q` each time). The second run gets a new thread with the same queue and poll interval. A key left in the queue between runs is not processed. Raw mode is entered and left twice, and the modes are restored twice.
>   - `test_event_thread_renewed`: the renewed thread is launchable, shares the queue and driver, keeps the poll interval, and reads input after the first thread has terminated. The paste settings are checked through behaviour: a 100-character paste arrives in parts of 77 and 23.
> - **Against the old code** (`TUI_APPLICATION` reverted to `HEAD`, with the `is_input_thread_available` assertion removed so the test compiles): `test_tui_application_runs_twice` fails with a routine failure (the `is_launchable` precondition of `THREAD.launch`).
> - **Full suite:** 282/282 pass (workbench, Windows).
>
> **Not tested:** the refused run after a failed join (`input_thread_available = False`). It needs a driver whose read blocks for longer than 500 ms, which `FAKE_CONSOLE_DRIVER` does not offer.

**Original analysis** (kept for the record):

`run` requires only `not is_running`. On the second call on the same object:
1. `event_thread.launch` is called on a terminated thread.
2. EiffelThread's `launch` requires `is_launchable` (`thread_id = default_pointer and not terminated`), so the call raises.

With assertions off, the thread is relaunched with `internal_should_stop` still `True`. It exits at once, and the app runs with **no input at all**: it hangs until killed.

**Probe:** after launch/stop/join, `is_launchable=False, should_stop=True`; a second `launch` raises `is_launchable`.

**Fix:** create a fresh `EVENT_THREAD` (and queue) at the start of each `run`, or reset the stop flag and document re-launch. If single-shot is intended, state it: `require not_run_before`.

### C3 — Medium — Two input readers can run at once (implicit "input thread not started" contract) — **FIXED**
`library/core/terminal/ansi_terminal_backend.e:180-217`, `terminal.e:178-188`, `win32_console_driver.e:147-174, 566-572` (locations as of `75f184b`)

> **Status: fixed on 2026-09-28** (committed in `264cee1`).
>
> **Choice:** the rule is now a contract, enforced by a claim that every reader takes. The review's other option, routing the DSR reply through the event queue while the thread runs, was not done. Nothing in the library needs the cursor position during a run, and a queue-based query would have to take one event out of the middle of the queue while keeping the others in order. It can be added later as a `TUI_APPLICATION` feature if an app needs it.
>
> **Changes:**
> - **`CONSOLE_INPUT_CLAIM`** (new, `library/core/terminal/`): the right to read console input, held by at most one reader. `try_acquire` / `release` / `is_held`, guarded by a `MUTEX`, so it can be taken on one thread and released on another.
> - **`CONSOLE_DRIVER.input_claim`** and **`is_input_claimed`** (new). By default there is one claim per driver object (the fake test driver keeps this). `WIN32_CONSOLE_DRIVER` and `POSIX_CONSOLE_DRIVER` redefine it as `once ("PROCESS")`: every platform driver reads the same console and shares its C state (`l_seq_buf` / `l_seq_pos` / `l_seq_len` on Windows, the `eiffeltui_posix_input` read-ahead buffer on POSIX). So a second driver object, for example in the next application of `EXAMPLE_RUNNER`, cannot start a second reader.
> - **`EVENT_THREAD.start`** (new): takes the claim, then launches the thread. It requires `launchable` and `input_not_claimed`, and raises if another reader took the claim first (a race the precondition cannot rule out). `execute` releases the claim when it ends: after `stop`, or after the thread gives up. If the launch fails, `start` releases it at once. `launch` still works, without a claim, for code that knows it is the only reader.
> - **`TERMINAL_BACKEND.is_input_in_use`** (new, deferred). `ANSI_TERMINAL_BACKEND` answers `driver.is_input_claimed`; `VIRTUAL_TERMINAL` answers `False`, since it has no input.
> - **New preconditions `input_not_in_use`** on `TERMINAL_BACKEND.query_cursor_position`, `TERMINAL.setup_inline_viewport` and `TUI_APPLICATION.run`. They replace the comment in `run` and the "must not be used while another reader…" note on the query.
> - **`ANSI_TERMINAL_BACKEND.query_cursor_position`:** holds the claim while it writes DSR and reads the answer, and releases it on every path, including an exception (rescue clause). If the claim is taken anyway (a race, or preconditions off), it returns `Void` without sending the query.
> - **`TUI_APPLICATION.run`** starts the thread with `event_thread.start` instead of `launch`. The setup, and with it the inline viewport's DSR query, still runs before the thread starts.
>
> **Effect on C4:** if an input thread does not stop within `Join_timeout_ms`, its claim stays held. A later `run`, on this application or on any other application using the platform driver, is then refused by `input_not_in_use` instead of starting a second reader. `clean_up` still ignores the join result; C4 stays open.
>
> **Found while testing — assertions were off in the test cluster:** the `eiffeltui_tests` target extends `eiffeltui`, but the `<option>` that enables assertions did not reach the clusters that the extending target adds. Nothing in a `tests` class was checked, *including library routines inherited into test classes*: `TUI_APPLICATION.run` compiled into `TEST_TUI_APP_IMPL` ran without its preconditions, while the same kind of check in a library class (`EVENT_THREAD.start`) fired. A `require False` probe in a test class confirmed it. The `tests` cluster now has the same `<assertions>` option as the library (`eiffeltui.ecf`), and the full suite passes with it. The `tests_windows` / `tests_posix` clusters still have no option. `TEST_MILESTONE_G_FOLLOWUPS.preconditions_monitored` had answered `False` until now, so `test_calendar_rejects_impossible_date_style` passed without checking anything; it now checks.
>
> **Verification:**
> - **New tests** (`tests/test_console_input_claim.e`, 9, registered in `test_app.e`; a `key_hook` added to `TEST_TUI_APP_IMPL`):
>   - the claim is exclusive and can be taken again after `release`;
>   - two platform drivers share one claim, and two fake drivers do not;
>   - `EVENT_THREAD.start` holds the claim as soon as it returns and frees it when the thread ends;
>   - a second input thread on the same console is refused while the first runs, and starts once the first has ended;
>   - the DSR query frees the claim after an answer and after a timeout;
>   - while the thread runs, the query is refused, no DSR is sent, and the thread still gets every byte (a report becomes a `CURSOR_POSITION_EVENT`);
>   - `setup_inline_viewport` is refused while the thread runs;
>   - inside `run` (from a key handler), the input is in use and a query is refused; after `run`, it is free;
>   - `run` is refused, without entering raw mode, while another reader holds the claim, and runs once it is free.
> - **Against the old contracts** (`run` back to `launch`, and the three `input_not_in_use` preconditions removed): the last 4 tests fail. The first 5 test the new claim and API, so there is no old behaviour for them to fail against.
> - **Full suite:** 291/291 pass (workbench, Windows). The examples and demo targets compile.
> - **POSIX driver:** not compiled on this machine. The only change there is the `input_claim` redefinition.

**Original analysis** (kept for the record):

`query_cursor_position` reads bytes straight from the driver. The only protection against racing the event thread is a comment in `TUI_APPLICATION.run` ("the input thread starts after setup"). Both `query_cursor_position` and `setup_inline_viewport` are public, and `TUI_APPLICATION.backend` is exported.

If either is called while the app runs, two threads call `read_char_with_timeout` at the same time. On Windows they then share:
- the unsynchronized Eiffel `ARRAYED_QUEUE` `pending_bytes`,
- `pending_high_surrogate`,
- the `static` C `l_seq_buf` / `l_seq_pos` / `l_seq_len`.

That corrupts the queue state (index errors, lost or duplicated bytes). The cursor report can also be consumed by the event thread (it becomes a `CURSOR_POSITION_EVENT`), so the query times out.

**Fix:** state it as a contract, e.g. `require not input_reader_active` (the backend tracks a flag set by `TUI_APPLICATION`). Better, route the DSR reply through the event queue once the thread runs: wait for a `CURSOR_POSITION_EVENT` on the queue instead of reading the driver.

### C4 — Low — Restore proceeds even if the input thread did not stop — **FIXED**
`tui_application.e:238-246` (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (working tree, not yet committed).
>
> **What C2 and C3 already covered:**
> - **No second reader:** a thread that does not stop keeps its console input claim (C3). The next `run`, of this or of any application on the platform driver, is refused by `input_not_in_use` and `input_thread_available` (C2) instead of starting a second reader.
> - **The menu case:** the review's example (the orphan stealing `EXAMPLE_RUNNER`'s menu input) was therefore limited to input read outside EiffelTUI, such as `io.read_line`, while the thread's read stays blocked.
>
> **Changes** (`TUI_APPLICATION`), the rest of the review's fix:
> - **The join result is recorded:** `clean_up` sets `input_thread_timed_out` (new, public) from `join_with_timeout`. Its rescue path sets it too, from whether the thread is still alive, so the flag holds even if stopping the thread is what failed. `run` resets it.
> - **The terminal is still restored** when the thread does not stop. Leaving the console in raw mode would be worse, and the thread cannot read another application's input, since it holds the claim. It ends as soon as its blocked read returns: it checks `should_stop` after every read, and releases the claim when it ends.
> - **`wait_for_input_thread (a_timeout_ms)`** (new) waits again for that thread, and clears `input_thread_timed_out` once it has ended. Its postcondition: `not input_thread_timed_out implies is_input_thread_available`. A program can call it after `run` returns, before reading the console itself or running again.
> - **New `clean_up` postcondition `input_thread_stopped_or_reported`:** `is_input_thread_available or input_thread_timed_out`. This states the implicit rule "`join_with_timeout` always succeeds" as what actually holds.
>
> **Test support:** `FAKE_CONSOLE_DRIVER.set_idle_read_ms` makes a read without input block longer than its timeout, and `blocked_read_count` reports when a read has started doing so.
>
> **Verification:**
> - **New test** (`test_tui_application_input_thread_timeout` in `tests/test_milestone_c.e`): each idle read blocks for 1.5 s, so the 500 ms join in `clean_up` fails. The test checks that:
>   - `run` still restores the terminal, and reports `input_thread_timed_out`;
>   - no second reader is possible, and the console input is still claimed;
>   - `wait_for_input_thread` then sees the thread end and frees the input;
>   - a second `run` works and stops in time.
>
>   The test's key handler waits until the thread is inside its blocked read before `q` stops the application. Without that wait, the thread could see the stop request before starting the read, and the join would succeed. That race is the likely cause of one failure seen in an early run.
> - **Against the old code** (`TUI_APPLICATION` reverted to `HEAD`, with a never-set `input_thread_timed_out` and a `wait_for_input_thread` that only joins, so that the test compiles): the test fails at "timeout reported".
> - **Full suite:** 351/351 pass (workbench, Windows), in repeated runs. The examples and demo targets compile.
>
> **Found while verifying — timing-sensitive tests:** the suite was run about 30 times. Two existing tests failed once each, on timing:
> - **`test_event_thread_resize_poll_not_per_byte`** (M1): it reads a 5,000-byte paste and allowed 3 s. That takes about 1 s in a workbench build with all assertions on, so a busy machine could exceed it. The deadline is now 20 s. Collecting returns as soon as the six events arrive, so a passing run is no slower.
> - **`test_tui_application_ticks_under_steady_input`** (open, not changed): it expects at least 5 ticks while keys arrive every 5 ms, and failed once in 10 runs. A real starvation bug would fail every run, so this looks like load, but the test was left as it is rather than weakened.

**Original analysis** (kept for the record):

`event_thread.join_with_timeout (500).do_nothing` throws away the result. Reads are bounded (25 ms), so this should not happen today. But if a driver ever blocks longer (a new driver, a hung console), the terminal is restored while the reader still runs. After `run` returns, that orphan thread keeps consuming stdin: in `EXAMPLE_RUNNER` it would steal the menu's input.

**Fix:** check the result; if the join failed, keep the thread object and do not start another reader. At minimum, record the failure.

### C5 — Low — Handler output interleaves with a frame being written — **FIXED**
`win32_console_driver.e:359-379`, `posix_console_driver.e:212-222` (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (working tree, not yet committed).
>
> **Change:** the review's fix. While `run` has the terminal set up, the handlers only record the request, and the application loop restores the terminal.
> - **New `CONSOLE_DRIVER` interface:** `is_deferring_termination`, `set_deferring_termination`, `has_termination_request`, `termination_request_code`, `discard_termination_request` and `finish_termination`.
> - **`TUI_APPLICATION`:**
>   - `set_up_terminal` turns deferral on before it touches the console.
>   - The loop stops once a request is pending.
>   - `clean_up` restores the terminal, turns deferral off, then calls `finish_termination`. So nothing is written after the restore, and no console mode is changed from another thread while the loop runs.
> - **Ending the process:** `finish_termination` ends it as the default action would, and the platform drivers do not return from it.
>   - **Windows:** `ExitProcess (STATUS_CONTROL_C_EXIT)`.
>   - **POSIX:** the signal is raised again with `SIG_DFL`, with `_exit (128 + sig)` as a fallback.
> - **Deferred requests:**
>   - **Windows:** Ctrl+C and Ctrl+Break. The handler returns `TRUE`, and the loop ends the process.
>   - **Windows close, logoff and shutdown:** the process ends when the handler returns. So the handler waits up to 3 s (the system allows 5) for the loop's restore, then returns. If the loop does not answer in time, the handler restores the console itself, as before.
>   - **POSIX:** SIGINT, SIGQUIT and SIGHUP.
> - **Still handled at once:** SIGTERM (a signal handler cannot wait for the loop), any request outside `run`, and a second request while one is pending. So a stuck loop cannot keep the terminal from being restored: press Ctrl+C twice.
> - **Prompt wake-up:** the loop used to see a request only when its poll timed out, which can be a full `tick_rate_ms` later. That is too slow for the 3 s close wait with a slow tick. The fix:
>   - **`SYNCHRONIZED_EVENT_QUEUE.wake`** (new) ends a waiting `poll_with_timeout` with no event.
>   - **`EVENT_THREAD`** calls it on every read step (at most 25 ms apart) while a request is pending.
> - **Race at the end of `run`:** a handler could see deferral still on, record its request just after `clean_up` has checked for one, and have it ignored. The handlers now check deferral again after recording. If it has been turned off, they also handle the request at once. At worst both the handler and `clean_up` end the process, which is harmless.
>
> **Remaining (by design):** outside `run`, for SIGTERM and for a second request, the handler still writes directly, as the review suggests for a last resort.
>
> **Verification:**
> - **New tests** (`tests/test_milestone_c.e`, `tests/platform/windows/test_platform_driver.e`):
>   - `test_termination_request_ends_run_after_restore`: the request is recorded, not handled at once. The process ends once, after the single restore, with nothing written after it, and deferral is off afterwards.
>   - `test_termination_request_wakes_slow_loop`: with a 10 s tick, a request recorded on the input thread ends `run` in well under 2 s, with no tick.
>   - `test_termination_request_outside_run_is_immediate`.
>   - `test_second_termination_request_is_immediate`.
>   - `test_synchronized_queue_wake`: waking before the wait and from another thread, the next wait is normal again, and a queued event still comes first.
>   - `test_win32_ctrl_handler_defers_to_loop`, on the real handler: Ctrl+C is recorded and the console left alone. A second event is restored at once. A close event with no loop to answer is restored by the handler after its 3 s wait.
>   - `test_posix_signal_handler_defers_to_loop` (`tests/platform/posix/test_platform_driver.e`), on the real handler: `raise (SIGINT)` and `raise (SIGHUP)` while deferring are recorded, and the process lives on.
> - **Test support:** `FAKE_CONSOLE_DRIVER` simulates handler requests (`simulate_termination_request`, and `set_request_on_read` on the input thread). It records `finish_termination` calls instead of ending the process.
> - **Against the fix without the wake-up:** with `queue.wake` removed from `EVENT_THREAD`, `test_termination_request_wakes_slow_loop` fails.
> - **Full suite, Windows:** 357/357 pass (workbench). The library (`eiffeltui`, all classes) and demo targets compile.
> - **Full suite, Linux** (Docker image `eiffeltui/tool-eiffel-compilation`, Debian 12, GCC): 354/354 pass in a workbench build (`ecb`, assertions on). The POSIX driver compiles with no errors or warnings.
>   - **Finalized builds:** `docker/build.sh --test` used `eiffel build`, which makes a finalized build and drops assertions. There, 9 tests that expect a contract violation failed: the symbol-width checks of U7 and the input-claim checks of C3. This was not related to C5.
>   - **Fix:** the container's `test` mode now builds with `ecb -finalize -keep`, which keeps the ECF's assertions (`ec` needs GTK, which the image lacks), and `docker/build.sh --test` passes 354/354. The Dockerfile copies the entrypoint after the EiffelStudio install, so editing it no longer reinstalls EiffelStudio.
> - **End to end, Linux:** `hello_tui` was run under `script` (a pseudo-terminal) and sent a real signal.
>   - **SIGINT:** after the last frame, the output holds only the loop's restore (`ESC[<u ESC[?25h ESC[?1049l`), with nothing after it. The exit status is 130, so the process still dies by SIGINT.
>   - **SIGTERM** (handled at once, by design): the handler writes its full reset, and the exit status is 143, as before.

**Original analysis** (kept for the record):

The Windows Ctrl handler runs on a new system thread, and a POSIX signal lands on whichever thread the kernel picks. Either can write the reset sequence while the main thread is part-way through `print`ing a frame:
- **Output interleaving:** on POSIX the reset bytes may land between two halves of a buffered frame. On Windows, the main thread keeps writing until the default handler's `ExitProcess` takes effect, so frame bytes can follow the reset and draw on the normal screen.
- **Mode races:** `eiffeltui_w32_restore_modes` can race with a main-thread `SetConsoleMode` read-modify-write in `enable_*` / `disable_*`.

Practical impact is cosmetic, and most parsers abort a CSI on ESC. The handlers are otherwise correct: they only use async-signal-safe calls, and they chain to the default handler or re-raise the signal.

**Fix (if wanted):** have the handler set an atomic flag and let the main loop restore; keep the direct write only as a last resort for `CTRL_CLOSE_EVENT` / `SIGTERM`.

### C6 — Low — The failure/retry path assumes nothing is half-done — **FIXED**
`event_thread.e:89-113`, `synchronized_event_queue.e:227-236`, `ansi_input_parser.e:282-315` (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (working tree, not yet committed).
>
> **Changes, parser left mid-sequence:**
> - **Clamp:** SGR mouse coordinates are clamped to 65535 (`.min (65535)`), as the cursor position report already was. A number too big for an INTEGER is still not a mouse report, and the parser returns to the ground state.
> - **Reset on retry:** the `EVENT_THREAD.execute` rescue clause calls the new `ANSI_INPUT_PARSER.discard_pending`. It drops the sequence or UTF-8 character in progress, and the events collected by the failed step. That also means a step that failed part-way through pushing its events cannot push them twice. A bracketed paste goes on. The routine does not allocate, so it is safe in a rescue clause.
> - **New query `is_between_sequences`:** true when no sequence or UTF-8 character is in progress.
>
> **Found while verifying:** with the review's example (column 70000) and no clamp, this build raised no exception. The contracts of EiffelBase's own routines, such as `to_natural_16`'s `not_too_big` precondition, are not checked here, so the coordinate wrapped silently: 70000 gave column 4464. The stall described in the review happens only in a build that checks those preconditions; otherwise the event has the wrong position. The clamp fixes both.
>
> **Changes, mutex never released:**
> - **Queue:** `SYNCHRONIZED_EVENT_QUEUE.push` (`extend` may allocate) and `poll_with_timeout` (a failed wait returns with the mutex locked again) unlock in their rescue clauses. The other locked regions (`poll`, `wipe_out`, `count`, `is_empty`, `wake`) do not allocate. The class note states this rule.
> - **`EVENT_THREAD`:**
>   - `failure_description` copies the string after unlocking. This is safe because `record_failure` replaces the string, never changes it.
>   - `internal_failure_description` is created in `make` rather than on first use, since its first use happened under the lock.
>   - The remaining `stop_mutex` regions only read or assign flags.
> - **`CONSOLE_INPUT_CLAIM`:** only assigns a flag under its lock. No change.
>
> **Verification:**
> - **New tests** (`tests/test_failure_recovery.e`, registered in `test_app.e`, 5 in all):
>   - `test_sgr_mouse_large_coordinates_clamped`: 70000 and 99999999 give 65535, and a number too big for an INTEGER gives no event.
>   - `test_discard_pending`: covers a half-read mouse report, a partial UTF-8 character, and a paste that goes on.
>   - `test_event_thread_retry_starts_clean`: a read fails in the middle of `ESC[<0;5`, and the next bytes still arrive as the keys `x` and `q`.
>   - `test_event_thread_large_mouse_coordinate`: the review's example through the input thread.
>   - `test_failed_push_releases_lock`: a push that raises while holding the lock (test queue `FAILING_EVENT_QUEUE`), after which another thread's push still reaches the consumer.
> - **Test support:** `FAKE_CONSOLE_DRIVER.set_failing_read (n)` makes one read raise.
> - **Against the old code** (clamp, rescue reset and `push` rescue removed): 4 of the 5 fail. `test_discard_pending` covers the new routine, and passes.
> - **Full suite, Windows:** 362/362 pass (workbench). The library (`eiffeltui`, all classes) and demo targets compile.
> - **Full suite, Linux** (`docker/build.sh --test`, finalized with assertions kept): 359/359 pass.
> - **Not tested:** a failing `wait_with_timeout`, which there is no way to trigger. The unlock is the same code as in `push`.

**Original analysis** (kept for the record):

- **Parser left mid-sequence:** `retry` resumes with the parser in whatever state the exception left it. Example: an SGR mouse report with a coordinate above 65535 makes `to_natural_16` fail its `not_too_big` precondition *before* `state := State_ground`. Every later `M`/`m` re-raises until a 25 ms quiet period resets the state. It cannot reach `Max_consecutive_failures`, because the bytes in between succeed and reset the counter, so this is a stall, not an abort. Clamp as the CPR path already does (`.min (65535)`) and reset the parser in the rescue clause.
- **Mutex never released:** `push`, `poll` and `stop` hold a `MUTEX` across calls that can raise (`extend` on out-of-memory). With no rescue that unlocks, the main thread would then deadlock in `poll_with_timeout`. Rare, but it is the classic lock-leak shape. Unlock in a rescue clause, or keep the locked region free of allocation.

### Benign races (noted, no action needed)
- **`poll_interval_ms` and `is_keyboard_enhancement_enabled`:** written by the main thread and read by the event thread without a lock. Both are word-sized, and a stale read is harmless.
- **Console-size calls:** `console_width` / `console_height` (main thread) and `poll_resize` (event thread) call the OS independently. `last_polled_*` is touched only by the event thread.

---

## 2. Unicode

### What is solid
- **Width tables:** generated from Unicode 16.0 (`tools/generate_unicode_width.py`). C0/C1 controls and Mn/Me/Cf are width 0, Hangul medial/final jamo are width 0, and wide means East Asian W/F plus Emoji_Presentation.
- **Grapheme clusters:** CR LF, Extend, ZWJ emoji sequences, regional-indicator pairs, skin tones and tag sequences.
- **`BUFFER.set_string_clipped`:** places text per grapheme and clips per grapheme at both edges. It **drops control clusters**, so ESC, TAB and NL in user data never reach a cell. That closes the classic TUI escape-injection hole.
- **Wide cells:** continuation consistency is enforced by postconditions on every write.
- **Text input:** backspace/delete/left/right move by grapheme, and the cursor column uses `string_width`.
- **Widget measurements:** block titles, tabs, table cells, list/tree highlight symbols, barchart and chart labels all measure with `string_width` and clip through the buffer.
- **Windows input:** UTF-16 → UTF-8 re-encoding handles surrogate pairs and caps repeats. Kitty `u` decoding rejects surrogates and out-of-range code points.

### U1 — High — Character wrap deletes every zero-width code point — **FIXED**
`library/core/text/text_layout.e:112-136` (locations as of `75f184b`)

> **Status: fixed on 2026-09-28** (committed in `d81d319`).
>
> **Change:** `TEXT_LAYOUT.wrap_line_character` now steps one grapheme cluster at a time (`{UNICODE_WIDTH}.grapheme_end`) and measures each one with `grapheme_width`, the same way `BUFFER.set_string_clipped` does. Lines break only between clusters, and every code point is kept: zero-width clusters stay on the line they follow and never cause a break. With `a_trim`, a lone space or tab at the start of a line is still skipped. Tabs and other controls are kept in the line text now, and the buffer drops them when it draws, as before.
>
> **Scope:** word wrap and `append_oversized_word` were fixed separately, see U2.
>
> **Verification:**
> - **New tests** (`tests/test_unicode_wrap.e`, registered in `test_app.e`, 7 in all): combining marks (`cafe` + U+0301 at widths 10 and 2), VS16 hearts at width 3, a ZWJ family, flag pairs, leading-space trim, styled spans with clusters, and a round-trip check. The round-trip check runs Devanagari, skin tones, mixed text and a leading combining mark at widths 1 to 6. It checks that every line fits and that the lines join back to the input, code point for code point.
> - **Against the old code:** 6 of the 7 new tests fail. The trim test passes, as expected.
> - **Full suite:** 257/257 pass (workbench, Windows).

**Original analysis** (kept for the record):

```eiffel
l_char := l_span.content.item (i)
l_cw := {UNICODE_WIDTH}.width (l_char.natural_32_code).to_natural_16
if l_cw > 0 then
    ...
    l_acc_str.append_character (l_char)      -- only reached for width > 0
end
```

The loop runs per code point, and characters are appended only when `l_cw > 0`. In character-wrap mode, at any width:
- `"cafe" + U+0301` renders as **"cafe"**;
- Devanagari loses its viramas and vowel signs (Mn);
- `❤️` (U+2764 U+FE0F) loses VS16 and changes presentation;
- ZWJ families fall apart into separate emoji.

Flags can also be split across lines, because each regional indicator counts as 1.

**Fix:** iterate with `{UNICODE_WIDTH}.grapheme_end` and measure with `grapheme_width`, exactly as `BUFFER.set_string_clipped` already does. Never drop code points; only choose break positions.

### U2 — High — Word wrap measures width per code point — **FIXED**
`text_layout.e:200-212` and `append_oversized_word` (`~316-331`) (locations as of `75f184b`)

> **Status: fixed on 2026-09-28** (committed in `fdca736`).
>
> **Changes** (`library/core/text/text_layout.e`):
> - **`wrap_line_word`:** builds words and whitespace runs from whole grapheme clusters, and adds up their widths one cluster at a time. So a word has the width `BUFFER` draws: `"❤️❤️"` is 4, `👨‍👩‍👧` is 2 and `👍🏽` is 2. A cluster counts as whitespace only if it is a lone space or tab; a space carrying a combining mark counts as part of a word.
> - **`append_oversized_word`:** splits a word that is wider than the line between clusters only, and keeps every code point. ZWJ sequences, flags and base + mark stay whole.
> - **Shared helpers:** `cluster_width` and `is_blank_cluster` (new, `{NONE}`) are now used by character wrap, word tokenizing and the oversized split, so all three measure the same way.
>
> **Verification:**
> - **New tests** (`tests/test_unicode_wrap.e`, 6 more, registered in `test_app.e`):
>   - VS16 hearts in 3 columns (the under-count);
>   - a ZWJ family and a skin-tone emoji that fit a short line (the over-count);
>   - three ZWJ families split at width 4, kept whole;
>   - accented words written with combining marks, wrapped at the space and split inside a word;
>   - flags in an oversized word;
>   - a word-mode round trip (Devanagari, skin tones, mixed text, leading mark) at widths 1 to 6.
> - **Against the old code:** all 6 fail when only the word-wrap section is reverted to `HEAD`, keeping the U1 fix.
> - **Full suite:** 263/263 pass (workbench, Windows).
>
> **Follow-up, same day (clusters split across spans):** the wrappers join neighbouring same-style pieces in their output (`append_to_line`). If the input had a cluster split over two spans of one style (`"ab❤"` + VS16, `"👨‍"` + `"👩"`), joining rebuilt the cluster with a different width than the one measured. Lines could then come out wider than the area (the last character is dropped at the edge), or a ZWJ pair could be broken across lines. `wrap_line` now joins neighbouring equal-style spans first (`with_merged_spans`, a no-op when there are none), so the wrappers measure the text they produce. Three more tests (`test_wrap_same_style_spans_split_vs16`, `_split_zwj`, `test_wrap_different_style_spans_measured_apart`); the first two fail before the change. Full suite: 266/266. A cluster split across spans of *different* styles was fixed afterwards, see U11.

**Original analysis** (kept for the record):

- **Under-count:** `"❤️❤️"` counts as 2 but renders as 4, so in a width-3 area it is kept on one line and the buffer **silently drops the second heart** at the edge.
- **Over-count:** `👨‍👩‍👧` counts as 6 (actual 2) and `👍🏽` counts as 4 (actual 2), so short lines break early.
- **Oversized split:** `append_oversized_word` then splits the "oversized" word per code point and, like U1, drops the ZWJs.

**Fix:** the same fix as U1. Tokenize by grapheme and use `grapheme_width`. Add wrap tests with combining marks, VS16, ZWJ sequences and flags at several widths.

### U3 — Medium — Invalid scalar values go out as invalid UTF-8 — **FIXED**
`unicode_width.e:163-176`, `ansi_serializer.e` (`string_32_into_utf_8_string_8`), generator `tools/generate_unicode_width.py:119-123` (locations as of `75f184b`)

> **Status: fixed on 2026-09-28** (committed in `82b95bd`).
>
> **Choice:** clean the text at the buffer boundary, as the review suggested. Each non-scalar value becomes U+FFFD, and a cell invariant states the rule. The serializer and the generated width tables are unchanged.
>
> **Why this is safe for layout:** in the width tables, a surrogate, a value above U+10FFFF and U+FFFD have the same properties. All three are width 1, and none is a control, an extending code point, Extended_Pictographic or a regional indicator. So replacing them changes no width and no cluster boundary. Text measured before the replacement (`TEXT_SPAN.width`, `string_width`, the wrappers) takes exactly the columns it is drawn in. The width of 1 that the generator gives to non-scalar values is therefore correct as it is.
>
> **Surrogate pairs are not joined** (the review's optional step). `D83D DE00` becomes two U+FFFD, not 😀. Joining would draw one wide character where the text had been measured as two narrow ones. With ZWJ sequences written as surrogates (`D83D DC68 200D D83D DC69`), the measured and drawn widths would differ (4 against 2). Data decoded one UTF-16 code unit at a time should be decoded as UTF-16 before it is drawn.
>
> **Changes:**
> - **`UNICODE_SCALAR`** (new, hand-written, next to the generated `UNICODE_WIDTH`, which is left untouched): `is_scalar_value`, `is_scalar_string`, `scalar_value` (the code or U+FFFD), `scalar_string` (the string itself when valid, so the common case allocates nothing; otherwise a copy with each non-scalar value replaced), and `Replacement_character`.
> - **`BUFFER.set_string_clipped`** (and so `put_string`, `set_stringn`, `set_span`, `set_line`, `set_line_clipped`) lays out `scalar_string (a_string)`. **`BUFFER.put_char`** draws `scalar_value` of its character.
> - **`TERMINAL_CELL.set_char`, `make_with_char` and `set_symbol`** store U+FFFD for a non-scalar value; the postconditions say so. **`set_content`** (exported to `BUFFER`) gets the precondition `scalar_symbol`.
> - **New `TERMINAL_CELL` invariant `scalar_symbol`:** `symbol` holds only scalar values, so every cell has a UTF-8 form, and `ANSI_SERIALIZER` can only emit valid UTF-8 for cell content. The class note states the rule. Cost while assertions are on: one comparison per code point of the symbol, usually one.
>
> **Verification:**
> - **New tests** (`tests/test_unicode_scalar.e`, 11, registered in `test_app.e`):
>   - the scalar range boundaries (U+D7FF, U+D800, U+DFFF, U+E000, U+10FFFF, U+110000, the maximum);
>   - `scalar_string` returning a valid string as the same object, and replacing values one by one;
>   - measurement neutrality: `string_width` is the same before and after replacement for surrogate pairs, a surrogate with a combining mark, a surrogate in a ZWJ sequence, between regional indicators, before VS16, and above U+10FFFF;
>   - the probe case in `BUFFER`: `D83D DE00 'x'` is drawn as U+FFFD U+FFFD `x` in the 3 columns it measures;
>   - a value above U+10FFFF, and `put_char` with a lone surrogate;
>   - a combining mark staying on the replacement in one cell;
>   - a styled span with a surrogate pair leaving the next span in place;
>   - the `TERMINAL_CELL` setters;
>   - the probe case through `BUFFER` → `DIFF_ENGINE` → `ANSI_SERIALIZER`: the frame holds `EF BF BD EF BF BD 78` and no `ED` byte;
>   - frames of valid text, lone surrogates, values above U+10FFFF and mixes, all checked with a strict RFC 3629 validator in the test. EiffelBase's `is_valid_utf_8_string_8` accepts CESU-8, so the test does not use it.
> - **Against the old code** (`buffer.e` and `terminal_cell.e` reverted to `HEAD`, `UNICODE_SCALAR` kept so that the tests compile): 7 of the 11 fail. The 3 `UNICODE_SCALAR` tests pass, as they test only the new class. The span-placement test passes too: the old code already placed spans by the same widths, and the test guards that the replacement keeps it so.
> - **Full suite:** 302/302 pass (workbench, Windows). The examples and demo targets compile.
>
> **Not covered:** text written to the terminal without going through a cell (`TERMINAL_BACKEND.put_string` called directly with a `STRING_32`) is not cleaned. The library itself sends only serializer frames and escape sequences that way.

**Original analysis** (kept for the record):

Surrogates (Cs), and code points above U+10FFFF that a `CHARACTER_32` can still hold, are not in any table, so they get width 1. `UTF_CONVERTER` encodes a surrogate as a 3-byte CESU-8 sequence. **EiffelBase's own `is_valid_utf_8_string_8` accepts it**, but RFC 3629 does not. Terminals render 1 to 3 U+FFFD per such sequence, so the terminal's column differs from the buffer's.

The diff renderer only repaints changed cells, so the rest of that row stays misplaced until a full redraw. A common source: UTF-16 data (JSON `😀`, Win32 APIs) decoded code unit by code unit into a `STRING_32`.

**Probe:** a `STRING_32` holding `D83D DE00 'x'` has `string_width=3`, and the serializer emits `ED A0 BD ED B8 80`.

**Fix:** sanitize at the buffer boundary: map any non-scalar value (`0xD800..0xDFFF`, `> 0x10FFFF`) to U+FFFD (width 1) in `set_string_clipped` / `put_char`. Optionally pair adjacent surrogates when they form a valid pair.

### U4 — Medium — The UTF-8 input decoder is too lenient — **FIXED**
`ansi_input_parser.e:60-98` (locations as of `75f184b`)

> **Status: fixed on 2026-09-28** (committed in `b9b6f62`).
>
> **Choice:** the review's fix: Unicode 16.0 §3.9, with table 3-7 for the well-formed sequences and the "U+FFFD per maximal subpart" practice of table 3-8. This is what `UTF_CONVERTER` and most terminals do. Only the byte `1B` can now decode to ESC, so a paste can be ended only by a real `ESC[201~`.
>
> **Changes** (`library/core/event/ansi_input_parser.e`):
> - **`parse_code`:** each lead byte sets the allowed range of the next byte (`utf8_next_min` / `utf8_next_max`, new). These are `A0..BF` after `E0` (no overlongs), `80..9F` after `ED` (no surrogates), `90..BF` after `F0` (no overlongs), `80..8F` after `F4` (nothing above U+10FFFF), and `80..BF` otherwise.
> - **Ill-formed input:** a continuation byte without a lead, and the bytes `C0`, `C1` and `F5..FF`, each give one U+FFFD. They used to become the key characters U+0080..U+00FF, C1 controls included. A sequence broken by an unexpected byte gives one U+FFFD for what was read of it, and the breaking byte is decoded again. It used to be dropped without a trace.
> - **Truncated sequence at a pause:** `flush_escape` (called by `notify_idle`) replaces an unfinished sequence with U+FFFD outside a paste. Inside a paste the sequence is kept, so a character split by a pause is completed by the next bytes (same rule as the escape sequences in C1). When the paste watchdog ends a paste in the middle of a character, U+FFFD ends the pasted text.
> - **A code above 255** (an already decoded character, from `parse_string` on a `STRING_32`) is passed through `{UNICODE_SCALAR}.scalar_value`, so a surrogate becomes U+FFFD there too. A pending sequence before it becomes U+FFFD first.
> - **Helpers and contracts:** `start_utf_8_sequence` and `replace_utf_8_subpart` (new, `{NONE}`, with contracts). A postcondition on `parse_code` and the new invariant `utf_8_sequence_state` bound the number of pending bytes to 0..3. The class note states the decoding rules.
>
> **Not changed:** well-formed C1 controls (`C2 80..C2 9F`, U+0080..U+009F) still arrive as character keys. They are valid UTF-8, and the parser has no 8-bit C1 handling, so they cannot start a sequence. The Windows driver needed no change: its UTF-16 to UTF-8 conversion drops unpaired surrogates and encodes pairs as 4-byte sequences, so it never produces ill-formed UTF-8.
>
> **Verification:**
> - **New tests** (`tests/test_utf_8_input.e`, 11, registered in `test_app.e`):
>   - the first and last code point of every row of table 3-7;
>   - the table 3-8 example (`61 F1 80 80 E1 80 C2 62 80 63 80 BF 64` gives `a FFFD FFFD FFFD b FFFD c FFFD FFFD d`);
>   - overlongs (`C0 80`, `C1 BF`, the overlong ESC `E0 80 9B`, `E0 9F BF`, `F0 80 80 80`, `F0 8F BF BF`);
>   - surrogates, including a CESU-8 pair;
>   - values above U+10FFFF, `F5`, a 5-byte form, `FE`, `FF`;
>   - stray continuation bytes, `9B` included (the 8-bit CSI);
>   - truncated sequences, broken by the next byte or at a pause;
>   - decoded code points above 255, surrogates included;
>   - the review's probe as a paste (`ESC[200~safe` `E0 80 9B` `[201~rm` `ESC[201~`): one `PASTE_EVENT` with the whole text and no key event;
>   - a character split by a pause inside a paste, kept whole;
>   - the watchdog ending a paste mid-character, with U+FFFD at the end and the next key decoded normally.
> - **Existing test changed:** cases 4 and 5 of `test_utf8_streaming_input` asserted that a broken sequence disappears. They now expect U+FFFD before the next character.
> - **Against the old code** (parser reverted to `HEAD`): 9 of the 11 new tests fail, and so does the changed existing test. The well-formed boundaries and the split character in a paste pass, as the old decoder already handled them.
> - **Full suite:** 313/313 pass (workbench, Windows). The examples and demo targets compile.

**Original analysis** (kept for the record):

The decoder checks the lead byte range and continuation bytes, but not:
- the second-byte ranges that rule out **overlongs** (`E0 80..9F`, `F0 80..8F`),
- **surrogates** (`ED A0..BF`),
- values **above U+10FFFF** (`F4 90..BF`).

Invalid lead bytes (`80..C1`, `F5..FF`) are passed on as U+0080..U+00FF key characters, including C1 controls, instead of U+FFFD.

The overlong case matters: `E0 80 9B` decodes to **ESC**. Inside a bracketed paste, `…E0 80 9B [201~rm -rf…` ends the paste early, and everything after it arrives as individual keystrokes. That defeats the point of bracketed paste. Real terminals re-encode clipboard text, so exposure is low, but this is exactly the input-validation contract a parser should own.

**Probe:** paste `safe` + `E0 80 9B` + `[201~rm` ⇒ `PASTE_EVENT` followed by 2 `KEY_EVENT`s; `ED A0 80` ⇒ key character U+D800.

**Fix:** implement the Unicode "maximal subpart" rules (the table in Unicode §3.9, D93): check the second byte against the lead-specific range and emit U+FFFD for each ill-formed subsequence. Emit U+FFFD for bad lead bytes as well.

### U5 — Medium — The cursor is placed only at span start, so width disagreements persist — **FIXED**
`ansi_serializer.e` (`render_spans_with_offset`)

> **Status: fixed on 2026-09-29** (committed in `4b55a6b`).
>
> **Change** (`library/core/buffer/ansi_serializer.e`): the review's low-cost fix.
> - **The rule:** after a cell whose width terminals may see differently, the next printed cell of the span starts with an absolute cursor move to its own column (`start_col + i - 1`, plus the viewport offset).
> - **Which cells** (`is_width_disputed`, new public query): a wide cell (`width = 2`), or a cluster of more than one code point (ZWJ sequences, VS16, flags, skin tones, combining and Indic marks).
> - **No move** after the last cell of a span, and none between plain one-code-point narrow cells, so ASCII output is byte-for-byte unchanged.
> - **The move is `CSI row;col H`**, not the shorter `CSI col G`. The backend's cursor tracking (`ANSI_TEXT_SCANNER`) and `VIRTUAL_TERMINAL` already interpret `H`. Using `G` would have needed both taught first.
>
> **Effect:** a width disagreement now misplaces at most the disputed cell itself, never the cells after it. Because every later cell is drawn where the buffer has it, the diff no longer keeps a shifted row on screen.
>
> **Cost:** about 6 to 9 bytes after each wide or multi-code-point cell (`ESC[r;cH`). CJK text pays it for every character. That was left as the review proposed: terminals built on old Unicode tables disagree on the widths of newer wide characters too, not only on emoji.
>
> **Verification:**
> - **New tests** (`tests/test_serializer_reanchor.e`, 7, registered in `test_app.e`):
>   - plain narrow text keeps one move per span;
>   - a move follows a wide cell, and a multi-code-point cluster (combining mark, ZWJ family);
>   - there is no move between the narrow cells after it, and none after a disputed last cell;
>   - the viewport offset is applied to the re-anchoring move;
>   - two tests draw on `VIRTUAL_TERMINAL`, which places text one code point at a time like a terminal without ZWJ support, so a ZWJ family takes 4 columns there against 2 in the buffer. The text after the family lands in the buffer's columns. After a second frame that changes one cell, the row still lines up. Before the fix, the old cells stayed 2 columns to the right.
> - **Against the old code** (serializer reverted to `HEAD`): 5 of the 7 fail. The narrow-text and last-cell tests pass, as they guard that no extra moves are added.
> - **Full suite:** 320/320 pass (workbench, Windows). The examples and demo targets compile.
>
> **Not changed at the time:** the backend's cursor tracking still added up widths one code point at a time (a ZWJ family counts 4 there), so the position tracked after the last cell of a frame could be off. **Resolved by M2:** the serializer now reports the position, in the buffer's columns.
>
> **Found while testing:** see U12. The first version of these tests wrote 日 literally, and the compiler turned it into three Latin-1 characters. `test_no_move_after_last_cell` passed then only because 日 had become three narrow characters.

**Original analysis** (kept for the record):

The serializer emits one `CSI row;col H` per dirty span, then writes the cells back to back. Terminals disagree on width in several known cases:
- ZWJ sequences on terminals without ZWJ support (Windows conhost, older xterm/VTE render 2+2+2 columns);
- VS16 on text-default symbols;
- East Asian Ambiguous characters in CJK-configured terminals;
- Indic spacing marks.

In each case every cell after the disputed cluster in that span lands in the wrong column. Because unchanged cells are never rewritten, the corruption stays on screen.

**Fix (low cost):** after any cluster with more than one code point, or any width-2 cell, re-emit an absolute cursor move before the next cell (or `CSI n G`). This is the defence several TUI libraries use; it costs a few bytes per wide cluster and makes the diff self-healing.

### U6 — Medium — Scrollbar symbols are not clipped to the scrollbar — **FIXED**
`library/widgets/scrollbar/tui_scrollbar.e:411` (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (committed in `8f86563`).
>
> **Choice:** both of the review's fixes. The width-1 rule is the contract, and the clip is a backstop.
> - **Why a contract:** the bar gives every symbol exactly one cell, so a wider symbol cannot be drawn correctly.
> - **Why the clip too:** it keeps a symbol that got past the contract inside its cell.
>
> **Changes** (`library/widgets/scrollbar/tui_scrollbar.e`):
> - **`is_valid_symbol`** (new, class feature; since U7 it delegates to `{TERMINAL_CELL}.is_one_column_symbol`, shared with the line gauge): one grapheme cluster, one column wide, or the empty string (which draws nothing). So `"▲"` and `"e"` + U+0301 are valid, while `"🔼"`, `"日"`, `"=>"`, `"a"` + TAB and a lone combining mark are not.
> - **Precondition `one_column`** on `set_thumb_symbol`, `set_track_symbol`, `set_begin_symbol`, `set_end_symbol` and the four `with_*_symbol` builders. `Void` still clears an optional symbol.
> - **Invariants `one_column_thumb`, `one_column_track`, `one_column_begin` and `one_column_end`.** The symbols are exported as mutable `STRING_32` objects, so `thumb_symbol.append (…)` could widen one without a setter. The invariant catches that on the next call.
> - **`render_stateful`** draws each symbol with `set_string_clipped (row, col, s, col, col + 1, style)`, clipped to its own cell, instead of `put_string`, which clips only at the buffer edge.
> - **The class note** states the rule.
>
> **Callers:** every symbol used in `examples/` and `demo/` is a single one-column glyph (`▲ ▼ ◄ ► █ ▒ ░ │ ─`), so none of them changes.
>
> **Verification:**
> - **New tests** (`tests/test_scrollbar.e`, 5, registered in `test_app.e`):
>   - `is_valid_symbol` on valid and invalid symbols;
>   - every setter and builder refusing a wide or multi-character symbol, with the old symbols kept, and `Void` or an empty symbol accepted;
>   - the invariant catching a thumb symbol widened in place;
>   - a vertical bar with multi-code-point symbols writing only its own column;
>   - a horizontal bar where every cell keeps its own symbol.
> - **Against the old code** (the scrollbar reverted to `HEAD`, with only `is_valid_symbol` added so the tests compile): the precondition test and the invariant test fail. The other 3 pass: they guard that valid symbols still draw in their cells, which the old code already did.
> - **Not covered by a test:** the per-cell clip itself. A symbol it would clip can only reach `render_stateful` past the preconditions and the invariant, that is, with assertions off.
> - **Full suite:** 325/325 pass (workbench, Windows). This includes `test_example_scrollbar`, which runs the scrollbar showcase. The examples and demo targets compile.

**Original analysis** (kept for the record):

`a_buffer.put_string (cell_row, cell_col, s, l_sym_style)` clips only at the buffer edge. A 2-column or multi-character symbol (`set_begin_symbol ("🔼")`, custom thumb/track) spills into the neighbouring widget in a vertical bar. In a horizontal bar each cell's write blanks the previous glyph. The setters (lines 103-137) have no width precondition.

**Fix:** use `set_string_clipped (row, col, s, col, col + 1, style)`, or add `require {UNICODE_WIDTH}.string_width (a_symbol) = 1` to the setters.

### U7 — Medium — Gauges assume 1-column symbols and split labels badly — **FIXED**
`tui_gauge.e:308-309`, `tui_line_gauge.e:121-139, 303-307` (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (committed in `ac59449`).
>
> **Changes:**
> - **Gauge label drawn once** (`TUI_GAUGE.render`), the review's fix. The label is written once over the whole gauge with the unfilled label style, then `BUFFER.set_style` restyles the label's columns over the filled cells with the inverted label style. A wide character straddling the fill edge is now drawn whole, in the style of its first column. Before, the first clipped pass stopped before it, and the second one blanked its right half, so it disappeared.
> - **Styles over the fill:** as before, the inverted colours are patched onto the label's style, and then the label style, so an explicit label colour still wins (`test_gauge_label_keeps_explicit_colour` is unchanged and passes). The base `style`'s own attributes now also carry into the filled part, where they are not overridden. Before, the filled pass ignored `style`.
> - **`{TERMINAL_CELL}.is_one_column_symbol`** (new, class feature): one grapheme cluster, one column wide, or empty. It is the rule for a symbol that a widget repeats once per cell. `TUI_SCROLLBAR.is_valid_symbol` (U6) now delegates to it, so the two widgets share one definition.
> - **Line gauge symbols** (`TUI_LINE_GAUGE`), as for the scrollbar:
>   - precondition `one_column` on `set_filled_symbol` and `set_unfilled_symbol`;
>   - invariants `one_column_filled` and `one_column_unfilled`, since both symbols are exported as mutable `STRING_32`;
>   - `render` clips each symbol to its own cell (`l_col + i` .. `l_col + i + 1`) instead of the whole line;
>   - the class note states the rule.
>
> The review also offered stepping by the symbol's width. That was not done: a line of 2-column symbols cannot fill an odd width, and it would make the gauge's cell count depend on the symbol.
>
> **Callers:** no example or demo sets a line gauge symbol, and the defaults (`━`, `─`) are one column wide.
>
> **Verification:**
> - **New tests** (`tests/test_metric_widgets.e`, 6, registered in `test_app.e`):
>   - a wide label character straddling the fill edge, drawn whole and with the filled style, with the characters on both sides styled by their side;
>   - a wide character starting at the fill edge, drawn unfilled;
>   - `is_one_column_symbol`, and the scrollbar agreeing with it;
>   - the line gauge setters refusing wide and two-character symbols, with the defaults kept;
>   - the invariant catching a filled symbol widened in place;
>   - a one-column symbol of two code points (`=` + U+0332) filling every cell whole.
> - **Against the old code** (`tui_gauge.e` and `tui_line_gauge.e` reverted to `HEAD`, the shared check kept so the tests compile): the straddling-character test, the setter test and the invariant test fail. The other 3 pass: they are guards for behaviour the old code already had, or test only the new shared check.
> - **Full suite:** 331/331 pass (workbench, Windows). This includes the existing gauge tests (colour inversion, explicit label colour, wide label clipped at the edge) and `test_example_gauge`. The examples and demo targets compile.

**Original analysis** (kept for the record):

- **Gauge label:** `tui_gauge.e:308-309` draws the label twice with two clip ranges. A wide glyph that straddles the fill boundary is stopped by the first pass and blanked by the second, so it **disappears**. **Fix:** draw the label once, then `set_style` over the filled columns.
- **Line gauge symbols:** `tui_line_gauge.e:303-307`, setters at 121-139. One `filled_symbol` is written per column, so a wide symbol (`"🟩"`) blanks its neighbours and a multi-character one (`"=>"`) is cut. **Fix:** add a width-1 precondition, or step by the symbol's width.

### U8 — Medium/Low — Text input edge cases — **FIXED**
`tui_text_input.e:263-269`, `text_input_state.e:116-138` (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (committed in `a02ad7a`).
>
> **Changes, `TEXT_INPUT_STATE`:**
> - **Single-line text:** `single_line_text` (new, class feature) turns each TAB and line break (CR LF, CR or LF) into one space and removes every other control character (C0, DEL, C1). It is applied on every way in: `insert_character`, `insert_string` (so pastes), `set_value` and `make_with_text`. The review asked for the insertions only. Applying it everywhere lets a new invariant, `single_line` (`not has_control (value)`), state the rule. A pasted escape sequence therefore loses its ESC, and a typed ESC is ignored. The postconditions of the four features say so.
> - **Cursor after an insertion** (the review's fix, in the other direction): the review suggested snapping back with `boundary_at_or_before`. The cursor moves *forward* to the next boundary instead (`boundary_at_or_after`, new), because what was typed joined the cluster after it. Examples:
>   - 🇯 typed before `🇺🇸` gives (🇯🇺)(🇸), with the cursor after 🇯🇺;
>   - `a` typed before a leading combining mark gives `á`, with the cursor after it;
>   - a ZWJ typed between two emoji joins them into one cluster, with the cursor after it.
>
>   Snapping back would have put the cursor before the character just typed.
> - **Cursor after a deletion** (a case the review did not list): removing a character can also join the clusters on either side. For example, deleting `x` from `🇦 x 🇧🇨` regroups the indicators into (🇦🇧)(🇨). `delete_backward` and `delete_forward` now move the cursor back to the start of the new cluster. The postconditions changed accordingly: the cursor moves back at least as far as the text shrank, and `delete_forward` never moves it right.
> - **New invariant `cursor_on_boundary`**, with `is_boundary` (new, public). The class note promised the rule, but nothing checked it. The check scans the text from the start, which is cheap for the short texts of an input field.
>
> **Change, `TUI_TEXT_INPUT.render_stateful`:** the end of the text is detected by position (`displayed_cursor_index = text.count`), no longer by "the cluster at the cursor has width 0". A cursor on a zero-width cluster, such as a lone leading combining mark (controls cannot reach the text any more), highlights at least one cell instead of writing a blank over the next character.
>
> **Verification:**
> - **New tests** (`tests/test_text_input_edges.e`, 12, registered in `test_app.e`):
>   - `single_line_text`;
>   - a multi-line paste with tabs and an escape sequence becoming one clean line;
>   - a typed TAB becoming a space and a typed ESC being ignored;
>   - `make_with_text` and `set_value` following the same rule;
>   - the three insertion cases above;
>   - Backspace and Delete regrouping flags;
>   - typing a ZWJ family with a skin tone and a mark, one code point at a time, with the cursor on a boundary after each;
>   - the widget cursor on a lone leading mark keeping the next character;
>   - the cursor after the last character still drawn as a blank cell.
> - **Against the old code** (both classes reverted to `HEAD`, with only the new queries `single_line_text`, `has_control` and `is_boundary` added so that the tests compile): 9 of the 12 fail. The 3 that pass test the conversion helper alone, typing at the end of the text, and the blank cursor after the last character, none of which the old code got wrong.
> - **Full suite:** 343/343 pass (workbench, Windows). This includes the existing text input and user input example tests. The examples and demo targets compile.

**Original analysis** (kept for the record):

- **Cursor overwrites the next character** (`tui_text_input.e:263-269`): `cell_width_at_cursor = 0` is taken to mean "end of text". When the cursor sits on a zero-width cluster (a pasted `%T`, or a lone leading combining mark), the cursor blank overwrites the next visible character. **Fix:** test `cursor_position = value.count` instead, and filter control characters in `insert_*` (pastes come in as raw `PASTE_EVENT.text`).
- **Cursor inside a cluster** (`text_input_state.e:116-138`): the documented "cursor on a grapheme boundary" invariant can be broken by insertion. Inserting 🇯 before `🇺🇸` regroups the flags as (🇯🇺)(🇸), leaving the cursor inside a cluster; inserting before a combining mark or ZWJ tail does the same. **Fix:** re-snap with `boundary_at_or_before` after insertion.

### U9 — Low — `out` crashes on non-Latin-1 text — **FIXED**
`text_span.e:163`, `text_line.e:254`, `text.e:268` (`to_string_8`); `table_cell.e:272`, `bar_item.e:233` (`STRING_8.append_string_general`) (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (working tree, not yet committed).
>
> **Change:** the review's fix. `out` is UTF-8 encoded in `TEXT_SPAN`, `TEXT_LINE`, `TEXT` (`{UTF_CONVERTER}.utf_32_string_to_utf_8_string_8`), `TABLE_CELL` and `BAR_ITEM` (`utf_32_string_into_utf_8_string_8`, appended to the prefix). `TABLE_ROW.out` joins its cells' `out`, so it is fixed too.
>
> **Behaviour change:** Latin-1 characters above U+007F (such as `é`) used to come out as one byte each. They now come out as two UTF-8 bytes, like every other non-ASCII character. ASCII text is unchanged.
>
> **Checked, no change:** the other `out` routines in the library only build ASCII text. `KEY_CODE.out` uses `CHARACTER_32.out`, which gives `U+…` in hex rather than the character (for example `Char('U+00000061')`). That is odd, but it cannot fail.
>
> **Verification:**
> - **New tests** (`tests/test_utf_8_out.e`, registered in `test_app.e`, 2 in all):
>   - **Spans, lines and texts:** CJK, an emoji and Latin-1 give their exact UTF-8 bytes. The result decodes back to the original text, and ASCII is unchanged.
>   - **Widget items:** a table cell, a table row and a bar item.
>
>   The non-ASCII text is built from code points, because BOM-less sources compile as Latin-1 (U12).
> - **Against the old code:** both tests fail on the precondition violations the review describes (`is_valid_as_string_8` in `to_string_8`, `compatible_strings` in `append_string_general`).
> - **Full suite, Windows:** 364/364 pass (workbench). The library (`eiffeltui`, all classes) and demo targets compile.
> - **Full suite, Linux** (`docker/build.sh --test`): 361/361 pass.

**Original analysis** (kept for the record):

The ECF enables all assertions, so `print (span)` on `"日本"` raises a precondition violation. With assertions off, the characters are narrowed. **Fix:** build `out` with UTF-8 (`{UTF_CONVERTER}.string_32_to_utf_8_string_8`).

### U10 — Low — Known subset gaps (document or close) — **FIXED**

> **Status: fixed on 2026-09-29** (working tree, not yet committed). Five gaps are closed and three are documented.
>
> **Closed:**
> - **VS16 widens any base:** VS16 now gives 2 columns only when the base has the Emoji property (new `Emoji_table` and `{UNICODE_WIDTH}.is_emoji_code`). That property includes the keycap bases `0-9 # *`. So `A` + VS16 stays 1 column, while `❤` + VS16, `☺` + VS16 and keycap `#` are 2.
> - **Bidi controls:** the explicit formatting characters U+202A..U+202E and U+2066..U+2069 are now clusters of their own, as UAX #29 has them (Control). Before, they extended the previous cluster. The buffer drops them like C0/C1 controls (`is_bidi_control`, and `is_never_drawn` = control or bidi control, used by `grapheme_end`, `is_extend` and `BUFFER.set_string_clipped`). The implicit marks LRM, RLM and ALM are unchanged: they cannot reorder text on their own.
> - **Windows key-up of astral characters:** the driver keeps the high UTF-16 half of a key-up record and reports the whole code point with the low half. A half without its partner is dropped.
> - **Calendar centring:** the month header is centred by `string_width`, not by `count`.
> - **`sub_span`:** new preconditions `start_on_boundary` and `end_on_boundary` (new query `TEXT_SPAN.is_cluster_boundary`), so it cannot split a cluster. That matters because of U11.
>
> **Documented, by choice:**
> - **No SpacingMark/Prepend rules**, in the `UNICODE_WIDTH` class note. Merging them would match only terminals that shape Indic text. Most terminals and wcwidth give the spacing mark its own column.
> - **Ambiguous width fixed at 1**, in the `UNICODE_WIDTH` class note. An option would be global, per-thread state (`once` routines are per-thread here), for a rare terminal setting.
> - **Tabs**, in the `BUFFER` class note. They are dropped, not expanded, because the buffer does not know the caller's tab stops. Replace them before drawing.
>
> **Generated code:** `unicode_width.e` is generated, so the changes are in `tools/generate_unicode_width.py` (template, Emoji table, sanity checks), which was then run again. Before the change, the generator reproduced the committed file exactly (apart from the date).
>
> **Verification:**
> - **New tests** (`tests/test_unicode_gaps.e`, registered in `test_app.e`, 5 in all):
>   - `test_vs16_widens_only_emoji`.
>   - `test_bidi_controls_are_own_clusters`: all nine controls. ZWJ still extends, and LRM is not a bidi control.
>   - `test_buffer_drops_bidi_controls`: no cell holds a bidi control, at the start or mid-text, and a combining mark before a control stays attached.
>   - `test_calendar_header_centred_by_width`: a two-character, 4-column month name, via `LOCALIZED_CALENDAR_STATE`.
>   - `test_sub_span_on_cluster_boundaries`.
> - **New Windows test** (`test_win32_astral_key_release`): real key-up records for U+1F600 (`VK_PACKET`, D83D then DE00) give one release of U+1F600. A lone low half and a lone high half are dropped.
> - **Against the old code** (each fix reverted, with the new queries kept so that the tests compile): all 6 new tests fail.
> - **Full suite, Windows:** 370/370 pass (workbench). The library (`eiffeltui`, all classes) and demo targets compile.
> - **Full suite, Linux** (`docker/build.sh --test`): 366/366 pass.

**Original analysis** (kept for the record):
- **No SpacingMark/Prepend rules:** GB9a/GB9b (Mc/Prepend) are not applied, so Devanagari `कि` becomes two cells. This matches `wcwidth`, but not terminals that shape Indic text.
- **VS16 widens any base:** `A` + VS16 becomes width 2; the rule should apply only to Emoji characters.
- **Ambiguous width fixed at 1:** no option for CJK-configured terminals.
- **Bidi controls pass through:** RLO/LRO/isolates (Cf, zero-width) attach to the previous cell and reach the terminal, which enables bidi display spoofing on terminals that do bidi. Consider stripping U+202A..202E and U+2066..2069 like controls.
- **Windows key-up of astral characters lost:** the Win32 driver sends the lone UTF-16 unit as the Kitty key code; the parser rightly rejects surrogates, so the release event is lost.
- **Tabs silently removed** (width 0, dropped by the buffer): no tab expansion.
- **Latent centring bug:** the calendar header is centred with `count` (`tui_calendar.e:455`); it breaks once month names are localized.
- **Unused cluster-splitting API:** `TEXT_SPAN.sub_span` slices by code point (currently unused).

### U11 — Low — A cluster split across differently styled spans — **FIXED**
`text_layout.e` (wrappers), `buffer.e` (`set_line_clipped`), `text_line.e` (`append_span`). Found while fixing U2.

> **Status: fixed on 2026-09-28** (committed in `fdca736`, with `9417d23`).
>
> **Changes:**
> - **`TEXT_LINE.append_span`:** a grapheme cluster no longer straddles two spans. If the new span starts with code points that continue the last cluster of the last span, they move into that span and take its style (a cell has one style); the rest is added as a new span, or nothing if nothing is left. Otherwise the span object is stored as it is. Postconditions state that the text is unchanged and when the object is kept.
> - **`TEXT_LINE.continuation_length`** (class feature) and **`continuation_of`** (new queries): how many leading code points continue the previous cluster. There is an early exit unless the first code point is Extend, a regional indicator, Extended_Pictographic or LF, so the common case costs one table lookup.
> - **`TEXT_LAYOUT.with_merged_spans`:** also rebuilds the line when it finds a split cluster, since `spans` is a public list and can be filled without `append_span`.
>
> **Verification:**
> - **New tests** (`tests/test_unicode_wrap.e`, 5; one earlier test that asserted the old behaviour was replaced): continuation moved for a combining mark, VS16, a ZWJ tail and a flag half; an independent span kept as the same object; a split ZWJ pair not broken by either wrap mode; a line filled through `spans.extend` normalized by the wrap (removed later, when `spans` became read-only); the buffer drawing `"❤"` + VS16 + `"x"` in three spans.
> - **Against the old code:** 4 of the 5 fail; the "kept as the same object" guard passes, as expected. The existing `test_combining_mark_across_spans` still passes (the mark now arrives in the first span).
> - **Full suite:** 270/270 pass (workbench, Windows).
>
> **Empty spans (follow-up):** `append_span` first examined only the last span, so a cluster split around an empty span (`"e"`, `""`, U+0301) was not joined. It now joins into the last *non-empty* span (`last_text_index`, new), and the empty spans stay where they are. `with_merged_spans` drops empty spans when it rebuilds; before, a same-style piece could be merged into an empty span with `set_content`, which skipped `append_span`. Three more tests (`test_append_span_skips_empty_spans`, `test_wrap_normalizes_split_around_empty_span`, `test_buffer_draws_vs16_split_around_empty_span`); all three fail before the change. Full suite: 273/273.
>
> **Closing the bypasses (follow-up, API change):** a split could still be created by editing a span after it was added (`spans.i_th (k).set_content (…)`, `span.content.append (…)`) or by filling `spans` directly. Now:
> - **`TEXT_SPAN` is immutable:** `content` is an `IMMUTABLE_STRING_32` and `set_content` is removed. `set_style` stays (a style cannot split a cluster). This also removes a stale-width hazard: `content.append` used to change the text without updating `width`.
> - **`TEXT_LINE.spans` is a read-only view** (`TEXT_SPAN_LIST`, new: `count`, `is_empty`, `i_th`, `first`, `last`, `valid_index`, `across`). The list itself is private. Readers compile unchanged; `spans.extend` / `remove` no longer compile.
> - **New commands** replace the direct edits in `TEXT_LAYOUT`: `TEXT_LINE.append_text` (join to an equal-style last span, else `append_span`) and `TEXT_LINE.right_adjust` (trim trailing white space).
> - **Invariant `no_split_cluster`** (`not has_split_cluster`, empty spans ignored) states the rule.
> - **`TEXT_LAYOUT.with_merged_spans` removed:** with the invariant, joining same-style output pieces cannot form a new cluster, so per-span measuring already matches the output.
>
> **Verification:** the two tests that filled `spans` directly no longer compile by design; one was removed (it duplicated `test_wrap_different_style_spans_split_zwj` once built through `append_span`), the other now builds its line with `append_span` (`test_wrap_split_around_empty_span`). New `test_append_text` and `test_right_adjust`. The copy-isolation test in `test_milestone_g_followups.e` replaced the copied line's text instead of calling `set_content`. The test, examples (all reachable from `EXAMPLE_RUNNER`) and demo targets compile. Full suite: 274/274.
>
> **Cost:** the invariant is checked on every qualified call to a `TEXT_LINE` while assertions are on (they are, in the ECF). For each span boundary it normally costs one or two table lookups (the early exit in `continuation_length`).

**Original analysis** (kept for the record; the drawing bullet is corrected by the buffer test):

Clusters are found within each span. When an app builds a line with a span boundary inside a cluster *and the two spans have different styles* (`"e"` red + U+0301 blue, `"👨‍"` + `"👩"` in two colours, `"❤"` + VS16), both the wrap and `BUFFER` treat it as two clusters. But:
- **Wrap can break inside the cluster:** a ZWJ pair split over two spans has a visible piece on each side, so the two halves can land on different lines. (A zero-width piece never causes a break, so accents stay on their line.)
- **The buffer draws over a widened cluster:** `BUFFER.attached_to_previous` joins VS16 to the heart and widens it to 2 columns. But `set_line_clipped` moves on by the VS16 span's width (0), so the next span starts at column 1 and overwrites the heart's continuation cell. `TEXT_LINE.width` also says 1 for what is drawn as 2. (The first version of this finding said the heart stayed in a 1-column cell; the test showed otherwise.)

The same-style case was fixed with U2 (`with_merged_spans`). Nothing in the library creates such lines (`TEXT_SPAN.sub_span`, the only code-point slicer, is unused), so exposure was app code that styles text by code-point position (search highlights, syntax colouring).

### U12 — Medium — Non-ASCII string literals are compiled as Latin-1 (found while fixing U5) — **FIXED**
`tests/*.e`, `examples/tier3_visualization/example_canvas.e:221-224`

> **Status: fixed on 2026-09-29** (committed in `005a2ed`).
>
> **Corrections to the first version of this finding:** it was written from a `grep` for quoted non-ASCII text, which also matched comments. A scanner that skips comments (below) gave different numbers:
> - **Scope:** 182 characters in literals, in 10 test files and `example_canvas` (not "72 lines in 14 files").
> - **`test_unicode_wrap.e` was never affected:** its 7 "hits" were comments that quote examples such as `"❤️❤️"`. The tests build their text with `%/0x…/` escapes and `append_code`, in every committed version.
> - **Withdrawn:** so the paragraph that explained why the U1 tests "still failed against the old code" (C1 controls in the mojibake) described a problem that did not exist, and is removed.
> - **Library:** clean, as first stated. Its 8 remaining non-ASCII characters are in class `note` text, which is documentation.
>
> **Changes:**
> - **Escapes:** every non-ASCII character in a string or character literal of `tests/` and `examples/` is now a `%/0x…/` escape, 182 in all.
> - **`tools/escape_non_ascii_literals.py`** (new) does the conversion. It skips comments, handles `%` escapes, character literals and verbatim strings, and only reports the non-ASCII characters of verbatim strings, since `%` is not interpreted there. Without `--fix`, it lists every non-ASCII character in a literal and exits with status 1 if there is one, so it can serve as a check. `tools/` is not under version control yet (the width-table generator is there too).
> - **`utf8` helper removed:** `BUFFER_TEST_HELPER` had a `utf8 (a_str)` helper that decoded a literal's Latin-1 bytes back to the intended characters, the workaround for this very problem. Once the literals are right, it corrupts them (it narrowed them with the obsolete `as_string_8`). Its 57 calls on literals became `{STRING_32} "…"`, and the helper is gone.
> - **Assertion helpers:** `assert_buffer_lines`, `assert_virtual_terminal_lines` and `assert_cell_symbol` UTF-8-decoded every `STRING_8` expected value in the same way. They now take the expected text as it is.
> - **`example_canvas`:** its marker labels (`•`, `█`, `▀`, `┃`) are drawn correctly now.
>
> **Why escapes and not a byte order mark:** a probe class saved with a UTF-8 BOM compiled `{STRING_32} "日"` to one character, so a BOM also works in EiffelStudio 25.12. Escapes were kept: they do not depend on an editor keeping an invisible byte, and they match the library's style.
>
> **Re-check of U1, U2 and U11:** their evidence is unaffected.
> - **Wrap tests:** `test_unicode_wrap.e` contains no literal non-ASCII character in `d81d319`, `fdca736`, `9417d23` or `HEAD` (the scanner reports 0 for each). So its tests always exercised the combining marks, VS16, ZWJ sequences and flags their names say.
> - **The other U11 tests:** `test_combining_mark_across_spans` builds its mark with `append_code`, and the copy-isolation test in `test_milestone_g_followups.e` has no literals.
> - **Result:** the "against the old code" results recorded under U1, U2 and U11 stand as measured, and the conversion did not touch those files.
>
> **Verification:**
> - **The tests that did change** now exercise the real characters: CJK in paragraphs and scrolling, accented text, box drawing, block and braille symbols, emoji. They all pass: 320/320 (workbench, Windows), the same count as before. No test had been passing only because of the mojibake, and no library defect was hidden by it.
> - **Compiler:** no obsolete-call warnings are left.
> - **Scanner:** `python tools/escape_non_ascii_literals.py tests examples demo library` reports no non-ASCII character in a code literal; the only ones left are the 8 in library `note` text.
> - **Builds:** the examples and demo targets compile.

**Original analysis** (kept for the record; see the corrections above):

The source files are UTF-8 without a byte order mark, and the compiler reads them as ISO-8859-1. A probe in a test class printed `count=3 code=230` for `{STRING_32} "日"`: the three UTF-8 bytes `E6 97 A5` became three Latin-1 characters. Code written with `%/0x65E5/` escapes is not affected. The example `example_canvas` drew its marker labels as mojibake, and tests that wrote emoji, CJK, box drawing or accented letters literally were testing Latin-1 text.

---

## 3. Memory management

Eiffel is garbage collected, so the questions here are unbounded growth, aliasing of shared mutable objects, GC/C interop, and allocation churn in the render loop.

### What is solid
- **C interop:** both `C blocking` externals (`c_win32_read_unit`, `c_posix_read_char`) take only scalars, so no Eiffel reference is exposed while the GC can move objects. `$` is used only on expanded locals and consumed synchronously. `sprintf` into `l_seq_buf[64]` writes at most ~14 bytes.
- **`LAYOUT_CACHE`:** bounded at 500 entries. Eviction unlinks from the LRU list and removes from the hash table in the same step. The reused lookup key is never stored, and stored keys reference only immutable `RECT` / `LAYOUT` / `CONSTRAINT` objects.
- **Parser buffers bounded:** CSI/SGR parameter buffers are capped at 64 and `ANSI_TEXT_SCANNER` at 32; OSC is consumed without buffering.
- **Render path:** cells are updated in place, styles are shared through `owned_style`, the symbol pool is capped at 4096, and front/back buffers are swapped instead of copied. Diff spans are consumed before the swap and before the next `diff`, so the pooled-span "valid until next diff" rule holds.

### M1 — High (together with C1) — The paste buffer is unbounded and never shrinks — **FIXED**
`ansi_input_parser.e:125-126, 431-437` (locations as of `75f184b`)

> **Status: fixed on 2026-09-28** (committed in `3a719cd`).
>
> **Changes:**
> - **Size cap, paste delivered in parts:** `ANSI_INPUT_PARSER.max_paste_size` (default `Default_max_paste_size` = 1,048,576 characters, 4 MB of `STRING_32`; set with `set_max_paste_size`, or `EVENT_THREAD.set_max_paste_size` before `launch`). When the collected text reaches that size, it is delivered as a `PASTE_EVENT` with the new `is_continued` flag set, and collecting goes on. The last part of a paste has `is_continued = False`; it can be empty when the paste size is an exact multiple of the cap. Joining the texts of the parts gives the paste, code point for code point. So nothing is lost, and memory stays bounded however long a paste (or an unterminated one) runs. A part boundary can fall inside a grapheme cluster, or between CR and LF.
> - **All paste text goes through one routine:** `append_to_paste` / `append_string_to_paste` (new, `{NONE}`) replace the direct `paste_buffer.append…` calls, including the sequences kept as text inside a paste. So the cap is exact.
> - **New invariants:** `paste_bounded: paste_buffer.count < max_paste_size`, `no_paste_text_outside_paste`, `positive_max_paste_size`.
> - **Buffer handed over, not copied:** `deliver_paste` (new) gives the buffer itself to the event (`PASTE_EVENT.make_owned`, creation exported to `ANSI_INPUT_PARSER` only) and starts a new 64-character buffer. Before, the text existed three times at the peak: the buffer, the `twin` passed to `PASTE_EVENT.make`, and the copy that `make` itself takes. And the grown buffer stayed with the parser after `wipe_out`. Now there is one copy, and it is released with the event. `PASTE_EVENT.make` still copies, for application code.
> - **Less work per byte:** `EVENT_THREAD.read_step` queries the console size at most once per `poll_interval_ms` (`last_resize_poll_ms`, new) instead of before every byte. Resize latency is unchanged (at most one poll interval).
> - **Block reads on POSIX:** `c_posix_read_char` reads up to 4 KB per `read` into a file-scope buffer and returns the next bytes from it without a system call. The buffer is dropped together with the kernel input when the tty is restored (`TCSAFLUSH` in `disable_raw_mode` / `restore_modes`). It is used only by the input reader, which C3 requires to be single (enforced since the C3 fix by `CONSOLE_DRIVER.input_claim`).
>
> **Not done:** the Windows driver still reads one console record per call. It already decodes each record into `pending_bytes`, so the remaining cost is a `GetNumberOfConsoleInputEvents` + `ReadConsoleInputW` pair per character. Draining all pending records at once means reworking the Kitty key-up synthesis in `c_win32_read_unit`, which has a separate static sequence buffer (see C3). Left for later; with the cap in place, it is a speed matter, not a memory one.
>
> **Verification:**
> - **New tests** (`tests/test_paste_robustness.e`, 6, registered in `test_app.e`):
>   - a paste split into full parts, then a short final part;
>   - a paste of exactly the cap, followed by an empty final part;
>   - sequences kept as text (CSI, SS3, SGR mouse, ESC ESC, a cut `ESC[20`) split across parts of 3, joined back verbatim, with a key after the paste;
>   - the watchdog ending a split paste with the rest as the final part;
>   - an earlier paste event keeping its text while the next paste is collected (the buffer is not shared);
>   - `EVENT_THREAD` reading a 5,000-byte paste in parts of 1,000 with far fewer size queries than bytes (`FAKE_CONSOLE_DRIVER.resize_poll_count`, new).
> - **Against the old code:** the tests use the new API (`set_max_paste_size`, `is_continued`), so they do not compile against it.
> - **Full suite:** 280/280 pass (workbench, Windows).
> - **POSIX driver:** not compiled on this machine (Windows only). The C body of `c_posix_read_char` was syntax-checked with `gcc -Wall -fsyntax-only` against stub headers. It needs a build and a paste test on Linux or macOS.

**Original analysis** (kept for the record):

- **Unbounded growth:** there is no maximum on `paste_buffer`, so an unterminated paste (C1, a dropped byte, a crashed terminal) grows it by 4 bytes per keystroke forever.
- **Peak held forever:** a 50 MB paste allocates about 200 MB, plus another 200 MB for the `twin` handed to `PASTE_EVENT`. `STRING_32.wipe_out` keeps its capacity (checked in EiffelBase 25.12), so the peak stays allocated for the life of the event thread.
- **Per-byte cost:** every byte also costs one `poll_resize` system call and one read.

**Fix:**
- Cap the buffer (for example at 1-8 MB); on overflow emit a truncated `PASTE_EVENT` or chunked events.
- Replace the buffer (`create paste_buffer.make (64)`) after a paste instead of `wipe_out`.
- Read input in blocks (the POSIX `read` can take 4 KB; the Windows driver can drain all pending records) instead of one byte per poll.

### M2 — Medium — Each frame is decoded again to track the cursor — **FIXED**
`ansi_terminal_backend.e:137-141, 370-381`; `ansi_serializer.e` (`create l_frame.make (1024)`) (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (committed in `3fbe449`).
>
> **Changes:** the review's fix, both parts.
> - **One frame buffer:** `ANSI_SERIALIZER.frame` (new, public, self-initialized attribute) holds the frame being built, and every `render_spans_with_offset` starts it again with `wipe_out`. `TERMINAL` keeps one serializer for its whole life, so the buffer grows to the largest frame (a full redraw) once and is then reused, with no new string and no doubling per frame. The trade-off: that peak capacity stays allocated, which is bounded by the screen size.
> - **Cursor reported, not rescanned:** `TERMINAL_BACKEND.put_frame (a_frame, a_cursor)` (new) writes a frame whose producer knows where the cursor ends (`Void`: it does not move). The default implementation is `put_string`, so `VIRTUAL_TERMINAL` still interprets the bytes for its grid. `ANSI_TERMINAL_BACKEND` redefines it to write the frame and set the tracked cursor from `a_cursor`, clamped as before, with no UTF-8 decode into a new `STRING_32` and no second scan. The postconditions say which position results.
> - **The serializer's side:** it records where the last printed cell ends, in integers, with no allocation per cell, and makes one tuple for the whole frame. It passes that position to `put_frame`, or `Void` when nothing was drawn.
> - **The caller's side:** `put_frame` says the caller may reuse the string afterwards, so a backend must not keep it. Both backends copy or print it.
>
> **Effect beyond memory:** the tracked position is in the buffer's columns, which the U5 re-anchoring makes the terminal follow. After a frame that ends with a ZWJ family, the cursor is now tracked 2 columns after it. Scanning counted 2 + 0 + 2 = 4.
>
> **Not changed:** `ANSI_TERMINAL_BACKEND.put_string` still scans its output. It is used for the short escape sequences written outside frames (mode switches, cursor moves), where the cost is negligible.
>
> **Verification:**
> - **New tests** (`tests/test_frame_output.e`, 7, registered in `test_app.e`):
>   - two frames built in the same string, with its capacity kept and only the second frame in it;
>   - the cursor after a frame, with the viewport offset;
>   - the cursor after a frame ending with a ZWJ family (column 4, not 6);
>   - the cursor at the right edge, which stays on the last column;
>   - an empty frame leaving the cursor where it was;
>   - `put_frame` writing the bytes as they are and taking the given position, so text and moves in the frame do not change it, and `Void` keeping it;
>   - plain `put_string` still tracking.
> - **Against the old code** (serializer reverted to `HEAD`, with only an unused `frame` attribute added so that the tests compile): the buffer-reuse and ZWJ tests fail. The other 5 pass: the old scan gave the same position in those cases, and `put_frame` itself is new.
> - **Full suite:** 350/350 pass (workbench, Windows). The examples and demo targets compile.

**Original analysis** (kept for the record):

`put_string (l_frame)` writes the frame, then `advance_cursor_tracking` decodes the **entire** UTF-8 frame into a new `STRING_32` and scans it again, only to learn where the cursor ends up. The serializer already knows that.

On full redraws (first frame, resize, truecolor dashboards; roughly 100-500 KB) this is several times the frame size in garbage per frame, plus a second full scan. A new frame string is also created each frame and grows by doubling.

**Fix:** keep one frame buffer in the serializer, reused with `wipe_out`. Have the serializer report the final cursor position to the backend (`set_tracked_cursor`) and skip re-scanning its own output.

### M3 — Low — The diff span pool keeps its high-water mark — **FIXED**
`diff_engine.e:75, 79, 125` (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (working tree, not yet committed).
>
> **Changes** (`DIFF_ENGINE`, `TERMINAL`):
> - **Small spans:** a new span starts with room for `Initial_span_capacity` (8) cells and grows as needed, instead of `width - column`. The pool's total capacity now follows the cells that frames actually change.
> - **Unused spans hold nothing:** at the end of each `diff`, the pooled spans that the previous diff used and this one did not are emptied (`release_unused_spans`, which costs only the difference). So they no longer keep cells of old buffers alive. `wipe_out` is enough: the collector follows a list's items only up to its count (`RT_SPECIAL_COUNT` in `garcol.c`).
> - **`discard_pool`** (new) drops the whole pool. `TERMINAL` calls it when it replaces its buffers (`autoresize` on a size change, and `resize`). The spans returned by the last `diff` stay valid.
> - **New queries:** `pool_size`, `pool_in_use`, `pool_cell_capacity`, `pool_cell_count`.
> - **New postcondition** on `diff`, `spans_from_pool`: the result holds exactly the spans taken from the pool.
>
> **Verification:**
> - **New tests** (`tests/test_diff_pool.e`, registered in `test_app.e`, 5 in all):
>   - `test_sparse_frame_pool_is_small`: 400×120 with one change per row gives 120 spans of capacity 8, which is 960 slots (it was 48,000).
>   - `test_unused_spans_emptied`: after a busy frame, one quiet frame leaves 1 cell in the pool, and a frame with no change leaves none.
>   - `test_span_grows_to_a_row`: a whole 400-cell row is one span.
>   - `test_discard_pool`.
>   - `test_terminal_resize_discards_pool`, through the test class `INSPECTABLE_TERMINAL`.
> - **Against the old behaviour** (spans sized to the rest of the row, no emptying, no discard): the 3 tests aimed at those defects fail. The row-growth and `discard_pool` tests pass, as expected.
> - **Full suite, Windows:** 375/375 pass (workbench). The library (`eiffeltui`, all classes) and demo targets compile.
> - **Full suite, Linux** (`docker/build.sh --test`): 371/371 pass.

**Original analysis** (kept for the record):

`acquire_span (r, c, a_curr.width - c)` gives each span a list sized to the rest of the row, even when the span holds one cell. A sparse frame on a 400×120 terminal allocates about 240k reference slots, and the pool keeps them forever. Spans past `pool_index` also keep references to cells of discarded buffers after a resize.

**Fix:** start with a small capacity (8) and let the list grow; clear pooled spans on resize.

### M4 — Low — Shared mutable objects behind "immutable" promises — **FIXED**

> **Status: fixed on 2026-09-29** (working tree, not yet committed).
>
> **Changes:**
> - **Immutable symbols:** `TERMINAL_CELL.symbol` is now an `IMMUTABLE_STRING_32`, and so is everything that can end up in it:
>   - the pooled symbols (`pooled_char`, `pooled_symbol`, the ASCII table, the blank and empty symbols);
>   - the clusters `BUFFER` builds (in `set_string_clipped`, and when a zero-width cluster is attached to the previous cell);
>   - the parameter of `set_content` and `put_grapheme`.
>
>   `attached {STRING_32} cell.symbol` can no longer succeed, so no client can change a symbol that other cells share. `pooled_char` stays public, because the string it returns cannot be changed.
> - **Private style copy:** `TERMINAL_CELL.set_style` stores `a_style.twin`, as the class note says, with a new postcondition `private: style /= a_style`. The BUFFER paths keep sharing through `owned_style` and `set_content_style`.
> - **`STYLE.copy`:** exported to `{STYLE}` only. It was the one public way to change a style in place, so `cell.style.copy (other)` could restyle every cell sharing that style. `twin` still works; no caller used `copy`. The notes of STYLE and TERMINAL_CELL say so.
>
> **Verification:**
> - **New tests** (`tests/test_shared_objects.e`, 2 in all):
>   - **Symbols:** no symbol is a `STRING_32`. This covers pooled ASCII and non-ASCII symbols, a wide character, a combining cluster, a ZWJ family, blanks, a continuation, and a cluster grown by a mark written on its own.
>   - **Styles:** `set_style` keeps an equal but separate style.
>
>   The export of `copy` is checked by the compiler.
> - **Against the old code** (`TERMINAL_CELL` and `BUFFER` at `HEAD`): both tests fail.

**Original analysis** (kept for the record):
- **Mutable shared symbols:** `TERMINAL_CELL.pooled_char` is public and returns the shared mutable `STRING_32` used by every cell showing that character. `attached {STRING_32} cell.symbol as s then s.append (…)` corrupts all of them. **Fix:** return `IMMUTABLE_STRING_32`, or export `pooled_char` to `{BUFFER, TERMINAL_CELL}` only.
- **Code contradicts the class note:** the class note says `set_style` "stores a private copy", but the code is `style := a_style` (`terminal_cell.e:118-121`). `STYLE`'s setters are private, but the redefined `copy` is public, so `my_style.copy (other)` restyles every cell holding `my_style`. BUFFER paths are safe (they use `owned_style`). **Fix:** twin in `set_style`, or correct the note and restrict `copy`.

### M5 — Low — The event queue has no bound, and a flood delays redraws — **FIXED**
`synchronized_event_queue.e:218`, `tui_application.e:168-174` (locations as of `75f184b`)

> **Status: fixed on 2026-09-29** (working tree, not yet committed).
>
> **Changes:**
> - **Redraw budget:** `TUI_APPLICATION.run` stops processing waiting events after `event_budget_ms` (default 50 ms), then draws. The next iteration's poll takes the rest at once. A flood of input, or slow handlers, now delays the screen by at most one budget plus one event. It is set with `set_event_budget`.
> - **Coalescing:** when `SYNCHRONIZED_EVENT_QUEUE` hands out a drag, move or resize event, it skips to the newest of the run of events of the same sort that follows. For the mouse, that means the same kind, button and modifiers. It does this under the lock, in `poll` and `poll_with_timeout`.
>   - **Never merged:** presses, releases, scrolls, keys and a move following a drag.
>   - **No change for a consumer that keeps up:** a run only forms while events are waiting.
>   - **Continuous strokes:** the mouse-drawing example draws a line from the previous drag point, so its strokes stay continuous.
>   - **Controls:** it is on by default (`is_coalescing`, `set_coalescing`, and `TUI_APPLICATION.set_event_coalescing`). The new `coalesced_count` counts the skipped events.
> - **Bound:** the queue reports `is_full` from `max_count` waiting events on (default 4096; `set_max_count`, and `TUI_APPLICATION.set_max_queued_events`). While it is full, `EVENT_THREAD` waits one poll interval instead of reading, so the input stays in the operating system's buffer.
>   - **Nothing is dropped.** The queue holds at most `max_count` plus the few events that one input byte completes.
>   - **Stopping still works:** `stop` stays responsive while the thread waits.
>   - **Pastes are not ended early:** a wait does not count as idle input for the paste watchdog.
>   - **Measurement:** the new `backlog_wait_count` counts the waits.
>
> **Verification:**
> - **New tests** (`tests/test_event_flood.e`, 5 in all, plus `test_event_budget_redraws_during_flood` in `tests/test_milestone_c.e`):
>   - **Merged runs:** runs of drags and resizes give their newest event, a key or another button breaks a run, and `coalesced_count` is exact.
>   - **Not merged:** presses, scrolls, and a move after a drag.
>   - **Coalescing off:** every drag is delivered.
>   - **`is_full`.**
>   - **The input thread with room for 2 events:** it never holds more than 2, all 8 keys arrive in order, and it waited.
>   - **The budget:** 20 keys of 30 ms each with a 50 ms budget give at least 6 draws during the flood.
> - **Against the old behaviour** (coalescing, the full-queue wait and the budget turned off): the 4 tests aimed at those defects fail. The coalescing-off and `is_full` tests cover the new settings, and pass.
>
> **Full suite for M4 and M5, Windows:** 383/383 pass (workbench). The library, demo and examples (`eiffeltui_examples`) targets compile. **Linux** (`docker/build.sh --test`): 379/379 pass.

**Original analysis** (kept for the record):

The queue is an unbounded `ARRAYED_QUEUE`. The main loop drains *all* pending events before drawing, so if handlers are slower than input (drag motion, key repeat, a slow `process`), the queue grows and the screen does not update until input stops.

**Fix:** process at most N events (or at most a time budget) per iteration before drawing; coalesce consecutive drag and resize events.

### Minor
- **Size overflow:** `BUFFER.make` computes `width * height` in `INTEGER_32`, which overflows only for fixed viewports near 65535×65535 (a precondition failure, not memory corruption).
- **Test backend growth:** `VIRTUAL_TERMINAL` logs a copy of every write and never trims scrollback. This matters only if it is used as a long-running headless backend.
- **Handles never closed:** `CONIN$` / `CONOUT$` are opened once and never closed. That is acceptable for the process lifetime.

---

## 4. Implicit contracts found (the review theme)

The code relies on these rules, but no precondition or invariant states them. Each has a finding above:

| Implicit rule | Where it should be stated | Finding |
|---|---|---|
| "No one reads the console while `EVENT_THREAD` runs" | `query_cursor_position`, `setup_inline_viewport` precondition | C3 (**fixed**: `input_not_in_use` preconditions, enforced by `CONSOLE_INPUT_CLAIM`) |
| "`run` is called at most once per application" | `TUI_APPLICATION.run` precondition, or remove the limitation | C2 (**fixed**: limitation removed; `input_thread_available` precondition) |
| "`flush_escape` is never called during a paste" | `ANSI_INPUT_PARSER` (handle it, don't assume it) | C1 (**fixed**: handled in the parser) |
| "Strings in the buffer are valid Unicode scalar values" | `BUFFER` write preconditions, or sanitize there | U3 (**fixed**: replaced with U+FFFD on entry; `TERMINAL_CELL` invariant `scalar_symbol`) |
| "Input bytes are well-formed UTF-8" | Parser: validate, don't assume | U4 (**fixed**: strict decoder, U+FFFD per maximal subpart) |
| "The terminal agrees with our width tables" | Serializer: re-anchor the cursor | U5 (**fixed**: absolute move after each disputed cell) |
| "String literals hold the characters written in the source" | Tests and examples (`%/0x…/` escapes), or the source encoding | U12 (**fixed**: escapes; `tools/escape_non_ascii_literals.py` checks) |
| "Widget symbols are one column wide" | Setter preconditions in scrollbar and line gauge | U6, U7 (**fixed**: `one_column` preconditions and invariants on both widgets, per-cell clip; one shared rule, `{TERMINAL_CELL}.is_one_column_symbol`) |
| "Pooled symbols and stored styles are never mutated" | Type (`IMMUTABLE_STRING_32`) / export restrictions | M4 |
| "No grapheme cluster straddles two spans" | `TEXT_LINE` invariant, immutable `TEXT_SPAN`, read-only `spans` | U11 (**fixed**: stated and enforced) |
| "Once objects are only compared across threads with `~`" | Architecture note on per-thread `once` | §1 |
| "`join_with_timeout` always succeeds" | `clean_up` postcondition | C4 (**fixed**: `input_thread_stopped_or_reported`; `input_thread_timed_out`, `wait_for_input_thread`) |

---

## 5. Recommended order of work

1. **C1 + M1: paste robustness.** (**done**: paste-aware `flush_escape`, watchdog and split-timing tests in C1; paste size cap, buffer hand-over, fewer size queries and POSIX block reads in M1. Windows record draining is left, see M1.)
2. **U1 + U2: grapheme-based wrapping** in `TEXT_LAYOUT`, with tests for combining marks, VS16, ZWJ and flags at several widths. (**done**: character wrap in U1; word wrap and the oversized-word split in U2).
3. **U4 + U3: Unicode validation at both ends.** Strict UTF-8 decoding with U+FFFD, and non-scalar values mapped to U+FFFD at the buffer boundary. (**done**: U3, `UNICODE_SCALAR`, replacement in `BUFFER` and `TERMINAL_CELL`, invariant `scalar_symbol`; U4, strict decoding in `ANSI_INPUT_PARSER.parse_code`.)
4. **C2 + C3: make the threading contracts explicit** (fresh input thread per `run`; precondition or queue-based DSR). (**done**: C2, `EVENT_THREAD.renewed` for each run after the first and the `input_thread_available` precondition; C3, the console input claim and the `input_not_in_use` preconditions. The queue-based DSR query was not needed.)
5. **U5: cursor re-anchoring** after wide or multi-code-point clusters. (**done**: `is_width_disputed` and a `CSI row;col H` before the next cell.)
5a. **U12: non-ASCII literals.** Convert the literals in `tests/` and `example_canvas` to escapes, then re-check the Unicode tests. (**done**: 182 escapes, the `utf8` workaround removed; the U1/U2/U11 evidence was never affected.)
6. **M2: remove the per-frame decode.** This is the largest render-path allocation. (**done**: one reused frame buffer, `put_frame` with the end position.)
7. **The rest** (U6-U10, C4-C6, M3-M5) as clean-up. (U6, U7, U8, U11 and C4 are done.)

**Tests that would have caught the High findings:**
- the parser fed with `flush_escape` inserted at every position;
- an invalid-UTF-8 matrix (overlong, surrogate, > U+10FFFF, truncated, stray continuation bytes);
- wrap/measure property tests: `Σ grapheme widths` = `TEXT_LINE.width`, and the concatenation of wrapped lines = the input, code point for code point.

---

## Appendix A — Probe results

The probe is a throwaway console program compiled against `eiffeltui.ecf` with all assertions on (workbench, EiffelStudio 25.12, Windows). It is kept outside the repository.

Before the fixes:

```
1. paste split: is_in_paste=True events=0
2. overlong ESC: is_in_paste=False events=3 [PASTE_EVENT] [KEY_EVENT] [KEY_EVENT]
   ED A0 80 -> key char U+0000D800
3. surrogates: string_width=3 bytes: ED A0 BD ED B8 80 valid_utf8=True
4. relaunch: is_launchable=False should_stop=True
   second launch raised: is_launchable
```

| # | Input | Shows |
|---|-------|-------|
| 1 | `ESC[200~hello`, `ESC[20`, `flush_escape`, `1~`, `q` | C1: stuck in paste, `q` swallowed |
| 2 | `ESC[200~safe`, `E0 80 9B`, `[201~rm`; then `ED A0 80` | U4: overlong ESC ends the paste; surrogate decoded as a key |
| 3 | `STRING_32` with `D83D DE00 'x'` through `BUFFER` → `DIFF_ENGINE` → `ANSI_SERIALIZER` | U3: CESU-8 output; EiffelBase's validator accepts it |
| 4 | `EVENT_THREAD` launch/stop/join, then launch again | C2: second `run` cannot start the input thread |

After the C1 fix (clean rebuild):

```
1. paste split: is_in_paste=False events=2
2. overlong ESC: is_in_paste=False events=3 [PASTE_EVENT] [KEY_EVENT] [KEY_EVENT]
   ED A0 80 -> key char U+0000D800
```

- **Case 1 fixed:** the paste is delivered and `q` arrives as a key.
- **Case 2 unchanged, as expected:** it is U4, which was still open then. Fixed since: the same paste is now one `PASTE_EVENT` holding the whole text, and `ED A0 80` gives three U+FFFD keys (`test_overlong_esc_does_not_end_paste`, `test_surrogates_rejected`).
- **Case 3 (U3):** fixed. The same input now reaches the terminal as `EF BF BD EF BF BD 78` (`test_frame_is_valid_utf_8`). The probe line `valid_utf8=True` shows why a strict validator is needed: EiffelBase's check accepted the CESU-8 bytes.
- **Case 4 (C2):** still reports `is_launchable=False` for a terminated `EVENT_THREAD`, as it must (EiffelThread never relaunches a `THREAD` object). The fix is in `TUI_APPLICATION.run`, which now launches `event_thread.renewed` instead; `test_tui_application_runs_twice` covers it.
- **Rebuild note:** the probe references the library through `<library>`, which is treated as read-only. An incremental rebuild kept the old parser, so rebuild it with `-clean` after library changes.
