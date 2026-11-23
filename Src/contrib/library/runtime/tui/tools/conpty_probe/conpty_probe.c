/* ConPTY input probe (P2 T5 review fixes #2 and #3).
 *
 * Which INPUT_RECORDs does a console application with ENABLE_VIRTUAL_TERMINAL_INPUT on (as
 * EiffelTUI's raw mode sets it) receive for what Windows Terminal writes into ConPTY? The
 * probe runs itself as a child under a pseudo console, writes scenarios into the pseudo
 * console's input (plain text, as typed or pasted without win32-input-mode, and
 * win32-input-mode key records `ESC [ Vk ; Sc ; Uc ; Kd ; Cs ; Rc _`, as Windows Terminal
 * sends keys), and the child logs every record it reads.
 *
 * Build and run (MinGW gcc or MSVC, Windows 10 1809 or later):
 *     gcc -o conpty_probe.exe conpty_probe.c
 *     conpty_probe.exe probe.log
 *
 * Seen 2026-10-28 on Windows 11 (see review/p2_terminal_widgets_plan.md, T5 review fixes):
 * - Every key-down comes as records of its VT characters with no key code (vk=0), every
 *   key-up as it is (vk set): also for plain text, where ConPTY makes a key-down and a
 *   key-up per character, pasted "bookkeeper" included.
 * - A held key (key-down, key-down, key-down, key-up) gives its characters again with no
 *   key-up between: "a a a" then one key-up; a held Up arrow "ESC [ A" three times then one
 *   key-up (vk=38).
 */
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <stdio.h>
#include <string.h>

typedef VOID *probe_hpcon;
typedef HRESULT (WINAPI *probe_create_pc) (COORD, HANDLE, HANDLE, DWORD, probe_hpcon *);
typedef void (WINAPI *probe_close_pc) (probe_hpcon);
#ifndef PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE
#define PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE 0x00020016
#endif

static const char *scenarios [][2] = {
	{"plain text \"aab\"", "aab"},
	{"win32-input-mode: a held (down x3, up)",
		"\x1b[65;30;97;1;0;1_\x1b[65;30;97;1;0;1_\x1b[65;30;97;1;0;1_\x1b[65;30;97;0;0;1_"},
	{"win32-input-mode: Up held (down x3, up)",
		"\x1b[38;72;0;1;256;1_\x1b[38;72;0;1;256;1_\x1b[38;72;0;1;256;1_\x1b[38;72;0;0;256;1_"},
	{"win32-input-mode: \"ee\" typed",
		"\x1b[69;18;101;1;0;1_\x1b[69;18;101;0;0;1_\x1b[69;18;101;1;0;1_\x1b[69;18;101;0;0;1_"},
	{"plain text paste \"bookkeeper\"", "bookkeeper"},
	{"win32-input-mode: Esc alone", "\x1b[27;1;27;1;0;1_\x1b[27;1;27;0;0;1_"},
};
#define Scenario_count (sizeof (scenarios) / sizeof (scenarios [0]))
#define Scenario_gap_ms 700

static int run_child (const char *a_log_path)
{
	HANDLE l_in = CreateFileA ("CONIN$", GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
		NULL, OPEN_EXISTING, 0, NULL);
	FILE *f = fopen (a_log_path, "w");
	ULONGLONG l_start, l_end;
	if (f == NULL) return 1;
	if (!SetConsoleMode (l_in, ENABLE_VIRTUAL_TERMINAL_INPUT | ENABLE_WINDOW_INPUT)) {
		fprintf (f, "SetConsoleMode failed: %lu\n", GetLastError ());
	}
	l_start = GetTickCount64 ();
	l_end = l_start + 1500 + Scenario_count * Scenario_gap_ms + 1000;
	while (GetTickCount64 () < l_end) {
		INPUT_RECORD r;
		DWORD n = 0;
		if (WaitForSingleObject (l_in, 100) != WAIT_OBJECT_0) continue;
		if (!ReadConsoleInputW (l_in, &r, 1, &n) || n == 0) continue;
		fprintf (f, "%6llu ms  ", GetTickCount64 () - l_start);
		if (r.EventType == KEY_EVENT) {
			KEY_EVENT_RECORD *k = &r.Event.KeyEvent;
			unsigned c = k->uChar.UnicodeChar;
			fprintf (f, "KEY %s vk=%u sc=%u ch=%u(%c) rep=%u ctl=0x%lx\n", k->bKeyDown ? "down" : "up  ",
				k->wVirtualKeyCode, k->wVirtualScanCode, c, (c >= 32 && c < 127) ? c : '.',
				k->wRepeatCount, k->dwControlKeyState);
		} else if (r.EventType == FOCUS_EVENT) {
			fprintf (f, "FOCUS %d\n", r.Event.FocusEvent.bSetFocus);
		} else {
			fprintf (f, "EVENT type=%u\n", r.EventType);
		}
		fflush (f);
	}
	fclose (f);
	return 0;
}

static HANDLE probe_out_read;

static DWORD WINAPI drain_output (LPVOID a_unused)
{
	char l_buf [4096];
	DWORD n;
	(void) a_unused;
	while (ReadFile (probe_out_read, l_buf, sizeof l_buf, &n, NULL) && n > 0) {}
	return 0;
}

int main (int argc, char **argv)
{
	const char *l_log;
	HMODULE l_k32 = GetModuleHandleA ("kernel32.dll");
	probe_create_pc l_create = (probe_create_pc) GetProcAddress (l_k32, "CreatePseudoConsole");
	probe_close_pc l_close = (probe_close_pc) GetProcAddress (l_k32, "ClosePseudoConsole");
	HANDLE l_in_read, l_in_write, l_out_write;
	probe_hpcon l_pc;
	COORD l_size = {80, 25};
	SIZE_T l_attr_size = 0;
	STARTUPINFOEXA l_si;
	PROCESS_INFORMATION l_pi;
	char l_cmd [MAX_PATH * 2 + 32], l_self [MAX_PATH];
	size_t i;

	if (argc > 2 && strcmp (argv [1], "child") == 0) return run_child (argv [2]);
	l_log = argc > 1 ? argv [1] : "probe.log";
	if (l_create == NULL || l_close == NULL) {
		printf ("No ConPTY on this system\n");
		return 1;
	}
	CreatePipe (&l_in_read, &l_in_write, NULL, 0);
	CreatePipe (&probe_out_read, &l_out_write, NULL, 0);
	if (l_create (l_size, l_in_read, l_out_write, 0, &l_pc) != S_OK) {
		printf ("CreatePseudoConsole failed\n");
		return 1;
	}
	CreateThread (NULL, 0, drain_output, NULL, 0, NULL);

	InitializeProcThreadAttributeList (NULL, 1, 0, &l_attr_size);
	ZeroMemory (&l_si, sizeof l_si);
	l_si.StartupInfo.cb = sizeof l_si;
	l_si.StartupInfo.dwFlags = STARTF_USESTDHANDLES; /* no inherited standard handles */
	l_si.lpAttributeList = (LPPROC_THREAD_ATTRIBUTE_LIST) HeapAlloc (GetProcessHeap (), 0, l_attr_size);
	InitializeProcThreadAttributeList (l_si.lpAttributeList, 1, 0, &l_attr_size);
	UpdateProcThreadAttribute (l_si.lpAttributeList, 0, PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE, l_pc, sizeof l_pc, NULL, NULL);
	GetModuleFileNameA (NULL, l_self, MAX_PATH);
	snprintf (l_cmd, sizeof l_cmd, "\"%s\" child \"%s\"", l_self, l_log);
	if (!CreateProcessA (NULL, l_cmd, NULL, NULL, FALSE, EXTENDED_STARTUPINFO_PRESENT, NULL, NULL, &l_si.StartupInfo, &l_pi)) {
		printf ("CreateProcess failed: %lu\n", GetLastError ());
		return 1;
	}
	Sleep (1500);
	for (i = 0; i < Scenario_count; i++) {
		DWORD n;
		printf ("%6llu ms  scenario: %s\n", (unsigned long long) (1500 + i * Scenario_gap_ms), scenarios [i][0]);
		WriteFile (l_in_write, scenarios [i][1], (DWORD) strlen (scenarios [i][1]), &n, NULL);
		Sleep (Scenario_gap_ms);
	}
	WaitForSingleObject (l_pi.hProcess, 10000);
	l_close (l_pc);
	printf ("Records read by the child: %s\n", l_log);
	return 0;
}
