# GTK+ 3 themes for EiffelVision2

Optional themes for EiffelVision2 applications built with the GTK+ 3
implementation (Linux, BSD, macOS with X11 or Quartz).

## Adwaita-compact

The default GTK+ 3 theme (Adwaita) with smaller widgets, for a denser GUI
(for instance in EiffelStudio): only minimum sizes and paddings change.

| Widget | Adwaita | Adwaita-compact |
| --- | --- | --- |
| Text field, combo box with entry | 34 px | 28 px |
| Button | 34 px | 26-28 px |

Notebook tabs, menu items, image buttons and scrollbar sliders are smaller too.

Use it for one application, by selecting it with `GTK_THEME`:

```bash
mkdir -p ~/.themes/Adwaita-compact/gtk-3.0
cp Adwaita-compact/gtk-3.0/gtk.css ~/.themes/Adwaita-compact/gtk-3.0/
GTK_THEME=Adwaita-compact estudio
```

Instead of copying it, add the parent folder of this `themes` folder to the
GTK+ data folders (GTK+ looks for `<data folder>/themes/<theme name>`):

```bash
XDG_DATA_DIRS="$ISE_LIBRARY/library/vision2/implementation/gtk3:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" GTK_THEME=Adwaita-compact estudio
```

Or use it for all the GTK+ 3 applications of the user, by copying
`Adwaita-compact/gtk-3.0/gtk.css` to `~/.config/gtk-3.0/gtk.css`.
