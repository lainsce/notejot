[GtkTemplate (ui = "/io/github/lainsce/Notejot/logrowbadge.ui")]
public class Notejot.LogRowBadge : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image badge;

    Log? _note;
    public Log? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            _note = value;

            badge.add_css_class ("notejot-badge-%s".printf(_note.id));
        }
    }

    construct {
        badge.add_css_class ("notejot-badge-%s".printf(note.id));
    }
}
