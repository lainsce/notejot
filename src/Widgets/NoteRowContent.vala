[GtkTemplate (ui = "/io/github/lainsce/Notejot/noterowcontent.ui")]
public class Notejot.NoteRowContent : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image badge;
    [GtkChild]
    unowned Gtk.Image pin;

    Binding? pinned_binding;

    private Gtk.CssProvider provider = new Gtk.CssProvider();

    Note? _note;
    public Note? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            pinned_binding?.unbind ();

            _note = value;

            pinned_binding = _note?.bind_property (
                "pinned", pin, "visible", SYNC_CREATE|BIDIRECTIONAL);

            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf(_note.color));
            var style_manager = new StyleManager ();
            style_manager.set_css (_note.color);
        }
    }

    public NoteRowContent (Note note) {
        Object(
            note: note
        );
    }

    construct {
        badge.get_style_context().add_provider(provider, 1);
    }

    [GtkCallback]
    string get_subtitle_line () {
        return note.notebook + " – " + note.text;
    }
}
