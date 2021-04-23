namespace Notejot {
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/formatbar.ui")]
    public class Widgets.FormatBar : Adw.Bin {
        public Widgets.TextField controller;
        public MainWindow win;
        public signal void clicked ();

        [GtkChild]
        public unowned Gtk.Label notebooklabel;
        [GtkChild]
        public unowned Gtk.Box nb_box;

        public FormatBar (MainWindow win) {
            this.win = win;
        }
    }
}
