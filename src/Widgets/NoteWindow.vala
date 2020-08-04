namespace Notejot {
    public class Widgets.NoteWindow : Gtk.Application {
        private MainWindow win = null;
        private static NoteWindow? instance = null;
        private Hdy.ApplicationWindow window;
        public Gtk.ToggleButton format_button;
        private int uid;

        public static NoteWindow get_instance () {
            return instance;
        }

        public NoteWindow (MainWindow win, Services.Task task, int uid) {
            this.win = win;
            this.uid = uid;

            window = new Hdy.ApplicationWindow ();

            var notebar = new Hdy.HeaderBar ();
            notebar.show_close_button = true;
            notebar.has_subtitle = false;
            notebar.set_size_request (-1, 30);
            notebar.get_style_context ().add_class ("notejot-nbar-%d".printf(this.uid));
            notebar.set_title (task.title);
            
            window.title = task.title;
            window.resizable = false;
            window.set_size_request (450, 450);
            window.show_all ();
            window.get_style_context ().add_class ("rounded");
            instance = this;

            format_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("font-x-generic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Formatting Options"))
            };
            format_button.get_style_context ().add_class ("notejot-button");
            notebar.pack_start (format_button);

            format_button.toggled.connect (() => {
                if (Notejot.Application.gsettings.get_boolean ("show-formattingbar")) {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", false);
                } else {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", true);
                }
                win.tm.save_notes ();
            });

            var sync_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Sync Note")),
                visible = true
            };
            sync_button.get_style_context ().add_class ("notejot-button");
            notebar.pack_end (sync_button);

            var noteview = new Views.NoteView (win, task);

            sync_button.clicked.connect (() => {
                noteview.textfield.send_text ();
                win.tm.save_notes ();
            });

            var notegrid = new Gtk.Grid ();
            notegrid.orientation = Gtk.Orientation.VERTICAL;
            notegrid.add (notebar);
            notegrid.add (noteview);

            window.add (notegrid);
            window.show_all ();

            if (uid == task.uid) {
                noteview.textfield.text = task.contents;
                noteview.textfield.connect_signals ();
            }
            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                noteview.textfield.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                noteview.textfield.update_html_view ();
            }

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    noteview.textfield.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    noteview.textfield.update_html_view ();
                }
            });

            window.delete_event.connect (() => {
                win.tm.save_notes ();
                instance = null;
                return false;
            });
        }
    }
}