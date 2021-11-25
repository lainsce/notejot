[GtkTemplate (ui = "/io/github/lainsce/Notejot/noterowbadge.ui")]
public class Notejot.NoteRowBadge : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image badge;

    private Gtk.CssProvider provider = new Gtk.CssProvider();

    string? _color;
    public string? color {
        get { return _color; }
        set {
            if (value == _color)
                return;

            _color = value;

            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf(_color));
        }
    }

    construct {
        badge.get_style_context().add_provider(provider, 1);
    }
}
