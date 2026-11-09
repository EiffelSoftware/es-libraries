# EiffelVision2 on macOS with the native Quartz backend

The gtk3 implementation of EiffelVision2 can use a GTK+ 3 built with the
native macOS backend (Quartz), without X11 and without XQuartz.

## Prerequisites

- A Quartz GTK+ 3. Homebrew's `gtk+3` is built with
  `-Dquartz_backend=true -Dx11_backend=false`:

  ```bash
  brew install gtk+3
  ```

  It can be installed next to MacPorts (whose `gtk3` defaults to `+x11`).
  Alternatively, `sudo port install gtk3 -x11 +quartz` replaces the MacPorts
  X11 GTK+ 3 for every MacPorts consumer.
- EiffelStudio (`ISE_EIFFEL`, `ISE_PLATFORM`), and Xcode or the Command Line Tools.

## Environment

From the root of the repository:

```bash
export ES_GTK_BACKEND=quartz      # or ES_GTK_BACKEND=quartz in .env
. Src/scripts/setup_env.sh
```

With `ES_GTK_BACKEND=quartz`, `setup_env.sh` sets `PKG_CONFIG_LIBDIR` to the
Homebrew `.pc` folders only, so `pkg-config` (even MacPorts' one) finds the
Quartz GTK+ 3, and checks that it reports the `quartz` target:

```bash
pkg-config --variable=targets gtk+-3.0      # quartz
```

## Build the C libraries of the source tree

`ISE_LIBRARY` is the `Src` folder of the repository, so the C libraries are
linked from there and must be built against the Quartz GTK+ 3 (an X11 build
from the EiffelStudio installation does not fit):

```bash
(cd Src/library/vision2/implementation/gtk3/Clib && finish_freezing -library)
```

The flags come from `Clib/vision2-gtk-config`, which adds Xlib only when
GTK+ 3 provides the X11 backend. Check: `nm` on
`Src/library/vision2/spec/$ISE_PLATFORM/lib/gtk3_eiffel.o` shows no `gdk_x11` symbol.

The EiffelStudio IDE (`Src/Eiffel/Ace/ec.ecf`, target `bench`) also links
other C libraries of the source tree, not related to GTK+:

- `library/net/Clib`, `library/cURL/Clib`, `framework/dotnet/il_emitter/Clib`:
  `finish_freezing -library` in each folder (see `Src/Delivery/scripts/unix/compile_libraries`);
- run-time `C/ipc/ewb`, `C/bench` and `C/platform`: `make` in each folder,
  once `Src/C` is configured (`Src/C/quick_configure`).

## Compile and run

No ECF change is needed: `vision2.ecf` uses the gtk3 implementation, with the
flags given by `vision2-gtk-config`.

```bash
ec -batch -config Src/examples/vision2/widget_test/vision2_demo.ecf -target vision2_demo -project_path <dir>/vision2_demo -c_compile
GDK_BACKEND=quartz Src/scripts/run_as_macos_app.sh <dir>/vision2_demo/EIFGENs/vision2_demo/W_code/vision2_demo
```

- Start the application as an `.app` bundle, with `Src/scripts/run_as_macos_app.sh`:
  macOS only makes a process a regular application (Dock icon, keyboard input)
  when LaunchServices launches it from a bundle. Started directly from a
  terminal, a GTK+ 3 Quartz application gets the mouse events, but its keyboard
  input goes to the terminal (this is not specific to EiffelVision2).
  The script keeps the environment of the shell, waits for the application,
  and writes its output to the terminal (or to `$ES_APP_LOG`).
- The IDE is built the same way (`Src/Eiffel/Ace/ec.ecf`, target `bench`) and started with
  `Src/scripts/run_as_macos_app.sh <dir>/EIFGENs/bench/W_code/ec -gui`.
- `otool -L` on the executable lists the Homebrew GTK+ 3 and no X11 library.
- `GDK_BACKEND=quartz` makes GDK fail instead of falling back to X11.
- `vision2` is a read-only library: after a change in its Eiffel code, recompile
  the application with `-clean`.
- At startup GTK+ prints `GtkSettings Cursor Theme: Unsupported GDK backend`: expected on Quartz.
- The C compilation reports `-Wreturn-type` warnings for the X11 externals
  guarded by `#ifdef GDK_WINDOWING_X11` ({GDK_X11}); they are not called on Quartz.

## Known limitations on Quartz

- `EV_SCREEN` drawing and screen capture are disabled (`has_x11_support` is
  False on macOS); the same fallbacks as on Wayland are used.
- The transparent overlay window used by `EV_SCREEN` for drag feedback is off
  by default: on Quartz, updating it at each pointer motion makes the drag
  slow until the application stops responding. So, for instance, the resize
  bar of an auto-hidden docking tool shows no feedback while dragging; the
  tool is resized on release. `EV_SCREEN_OVERLAY=yes` enables the overlay anyway.
- Fake pointer and key events (`fake_pointer_*`, `fake_key_*`) rely on XTest
  and do nothing.
- No global menu bar, Dock or Cmd shortcut integration (would need `gtk-mac-integration`).

## Quartz specifics handled in the gtk3 implementation

- GDK Quartz only fetches the native events while the GLib main context is
  polled, and dispatches them to the GDK event handler: `gdk_event_get` never
  returns any. `{EV_APPLICATION_IMP}` installs a handler that queues them
  (`ev_gdk_event_get` in `Clib/ev_c_util.c`), so that EiffelVision2 processes
  them as with X11 (pointer actions, capture, pick and drop, keys, ...).
- A popup menu shown without anchor widget is positioned relative to the
  window under the pointer, and is never made transient for itself (AppKit
  aborts on `addChildWindow:` of a window to itself).
- Input shapes are not implemented by GDK Quartz: a window meant to let the
  pointer events through also ignores them at the `NSWindow` level.
- GDK Quartz does not always honor `gtk_window_move` on a window that is not
  mapped yet (the first time, it may appear elsewhere): `{EV_GTK_WINDOW_IMP}.set_position`
  keeps that position and `show` applies it again once the window is mapped.
- A newly shown window does not reliably become the key window (for instance
  when shown from a mouse event in another window): `{EV_POPUP_WINDOW_IMP}.show`
  makes it key (`gtk_window_present`), unless it is disconnected from the window manager.
- The keyboard focus moves asynchronously to a newly shown window: code that
  hides a popup when none of its widgets has the focus should check again a bit
  later (see `{EB_ADDRESS_MANAGER}.one_lost_focus`).
