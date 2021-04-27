namespace Notejot {
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/formatbar.ui")]
    public class Widgets.FormatBar : Adw.Bin {
        public Widgets.TextField controller;

        [GtkChild]
        public unowned Gtk.Label notebooklabel;
        [GtkChild]
        public unowned Gtk.Box nb_box;
    }
}
