[GtkTemplate (ui = "/io/github/lainsce/Notejot/noterowcontent.ui")]
public class Notejot.NoteRowContent : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image pin;

    Binding? pinned_binding;

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
        }
    }

    public NoteRowContent (Note note) {
        Object(
            note: note
        );
    }

    [GtkCallback]
    string get_subtitle_line () {
        return note.notebook + " – " + note.text;
    }
}
