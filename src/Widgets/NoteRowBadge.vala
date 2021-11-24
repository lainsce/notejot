[GtkTemplate (ui = "/io/github/lainsce/Notejot/noterowbadge.ui")]
public class Notejot.NoteRowBadge : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image badge;

    private Gtk.CssProvider provider = new Gtk.CssProvider();

    Note? _note;
    public Note? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            _note = value;

            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf(_note.color));
        }
    }

    construct {
        badge.get_style_context().add_provider(provider, 1);
    }
}
