namespace Notejot {
    public class Widgets.NoteWindow : Gtk.Application {
        private MainWindow win;
        private static NoteWindow? instance = null;
        private Gtk.ApplicationWindow window;
        private string title = "";
        private string contents = "";
        private int uid;

        public static NoteWindow get_instance () {
            return instance;
        }

        public NoteWindow (MainWindow win, string title, string contents, int uid) {
            this.win = win;
            this.title = title;
            this.uid = uid;
            this.contents = contents;
        }

        protected override void activate () {
            window = new Gtk.ApplicationWindow (this);

            var notebar = new Gtk.HeaderBar ();
            notebar.show_close_button = true;
            notebar.has_subtitle = false;
            notebar.set_decoration_layout ("close:");
            notebar.set_size_request (-1, 30);
            notebar.get_style_context ().add_class ("notejot-nbar-%d".printf(this.uid));
            notebar.set_title (this.title);

            window.set_titlebar (notebar);
            window.add (Widgets.TextField.get_instance ());
            window.title = this.title;
            window.set_size_request (350, 350);
            window.show_all ();
            window.get_style_context ().add_class ("rounded");
            instance = this;

            Widgets.TextField.get_instance ().update_html_view ();
            Widgets.TextField.get_instance ().connect_signals ();

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                Widgets.TextField.get_instance ().update_html_view ();
            });
        }

        public bool on_delete_event () {
            window.remove (Widgets.TextField.get_instance ());
            instance = null;

            return false;
        }
    }
}