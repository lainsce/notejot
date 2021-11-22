[GtkTemplate (ui = "/io/github/lainsce/Notejot/logrowcontent.ui")]
public class Notejot.LogRowContent : Adw.Bin {
    [GtkChild]
    public unowned Gtk.Image badge;

    Log? _note;
    public Log note {
        get { return _note; }
        set {
            _note = value;

            badge.add_css_class ("notejot-badge-%s".printf(_note.id));
        }
    }

    construct {
    }
}
