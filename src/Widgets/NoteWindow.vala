namespace Notejot {
    public class Widgets.NoteWindow : Hdy.Window {
        private MainWindow win;

        public NoteWindow (MainWindow win, Services.Task task, int uid) {
            this.win = win;
            var notebar = new Hdy.HeaderBar ();
            notebar.show_close_button = true;
            notebar.has_subtitle = false;
            notebar.set_decoration_layout ("close:");
            notebar.set_size_request (-1, 45);
            notebar.get_style_context ().add_class ("notejot-nbar-%d".printf(uid));
            notebar.set_title (task.title);

            var textfield = new Widgets.TextField (win);
            textfield.text = task.contents;
            textfield.update_html_view ();

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                textfield.update_html_view ();
            });

            var notegrid = new Gtk.Grid ();
            notegrid.orientation = Gtk.Orientation.VERTICAL;
            notegrid.add (notebar);
            notegrid.add (textfield);

            this.add (notegrid);
            this.title = task.title;
            this.set_size_request (350, 350);
            this.show_all ();
        }
    }
}