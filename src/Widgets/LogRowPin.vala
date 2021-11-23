[GtkTemplate (ui = "/io/github/lainsce/Notejot/logrowpin.ui")]
public class Notejot.LogRowPin : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image pin;

    Binding? pinned_binding;

    Log? _note;
    public Log? note {
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

    construct {
    }
}
