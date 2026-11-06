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
GDK_BACKEND=quartz <dir>/vision2_demo/EIFGENs/vision2_demo/W_code/vision2_demo
```

- `otool -L` on the executable lists the Homebrew GTK+ 3 and no X11 library.
- The IDE is built the same way and started with `GDK_BACKEND=quartz ./ec -gui`
  from its `W_code` folder.
- `GDK_BACKEND=quartz` makes GDK fail instead of falling back to X11.
- At startup GTK+ prints `GtkSettings Cursor Theme: Unsupported GDK backend`: expected on Quartz.
- The C compilation reports `-Wreturn-type` warnings for the X11 externals
  guarded by `#ifdef GDK_WINDOWING_X11` ({GDK_X11}); they are not called on Quartz.

## Known limitations on Quartz

- `EV_SCREEN` drawing and screen capture are disabled (`has_x11_support` is
  False on macOS); the same fallbacks as on Wayland are used.
- Fake pointer and key events (`fake_pointer_*`, `fake_key_*`) rely on XTest
  and do nothing.
- Drag and drop (docking, pick and drop) is a known weak spot of GTK+ 3 Quartz: to be checked.
- No global menu bar, Dock or Cmd shortcut integration (would need `gtk-mac-integration`).
