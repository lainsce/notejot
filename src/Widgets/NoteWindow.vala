namespace Notejot {
    public class Widgets.NoteWindow : Gtk.Application {
        private MainWindow win = null;
        private static NoteWindow? instance = null;
        private Gtk.ApplicationWindow window;
        private int uid;

        public static NoteWindow get_instance () {
            return instance;
        }

        public NoteWindow (MainWindow win, Services.Task task, int uid) {
            this.win = win;
            this.uid = uid;

            window = new Gtk.ApplicationWindow (this);

            var notebar = new Gtk.HeaderBar ();
            notebar.show_close_button = true;
            notebar.has_subtitle = false;
            notebar.set_size_request (-1, 30);
            notebar.get_style_context ().add_class ("notejot-nbar-%d".printf(this.uid));
            notebar.set_title (task.title);

            window.set_titlebar (notebar);
            
            window.title = task.title;
            window.resizable = false;
            window.set_size_request (350, 350);
            window.show_all ();
            window.get_style_context ().add_class ("rounded");
            instance = this;

            var sync_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Sync Note")),
                visible = true
            };
            sync_button.get_style_context ().add_class ("notejot-button");
            notebar.pack_end (sync_button);

            var textfield = Widgets.TextField.get_instance ();
            textfield.visible = true;
            window.add (textfield);
            sync_button.clicked.connect (() => {
                textfield.send_text ();
                win.tm.save_notes ();
            });

            if (uid == task.uid) {
                textfield.text = task.contents;
                textfield.connect_signals ();
            }
            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                textfield.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                textfield.update_html_view ();
            }

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    textfield.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    textfield.update_html_view ();
                }
            });

            window.delete_event.connect (() => {
                window.remove (Widgets.TextField.get_instance ());
                win.tm.save_notes ();
                instance = null;
                return false;
            });
        }
    }
}