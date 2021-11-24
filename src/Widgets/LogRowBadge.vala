[GtkTemplate (ui = "/io/github/lainsce/Notejot/logrowbadge.ui")]
public class Notejot.LogRowBadge : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image badge;

    private Gtk.CssProvider provider = new Gtk.CssProvider();

    Log? _note;
    public Log? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            _note = value;

            provider.load_from_data ((uint8[]) "@define-color badge_color %s;".printf(_note.color));
        }
    }

    construct {
        badge.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    }
}
