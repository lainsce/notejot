namespace Notejot {
    public class Widgets.TextField : Gtk.TextView {
        public MainWindow win;
        public Widgets.Note controller;

        public TextField (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.editable = true;
            this.set_can_focus (true);
            this.opacity = 0.66;
            this.right_margin = this.bottom_margin = this.top_margin = this.left_margin = 20;

            send_text ();

            Notejot.Application.gsettings.changed.connect (() => {
                win.tm.save_notes.begin (win.notestore);
            });

            Timeout.add_seconds (3, () => {
                send_text ();
                return true;
            });

            get_buffer ().changed.connect (() => {
                send_text ();
            });
        }

        public string get_selected_text () {
            Gtk.TextIter A;
            Gtk.TextIter B;
            if (get_buffer ().get_selection_bounds (out A, out B)) {
               return get_buffer ().get_text(A, B, true);
            }

            return "";
        }

        public void send_text () {
            Gtk.TextIter A;
            Gtk.TextIter B;
            get_buffer ().get_bounds (out A, out B);
            var val = get_buffer ().get_text (A, B, true);
            controller.log.text = val;

            win.tm.save_notes.begin (win.notestore);
        }

        private string set_stylesheet () {
            if (Notejot.Application.gsettings.get_boolean("dark-mode") == true) {
                return Styles.dark.css;
            } else {
                return Styles.light.css;
            }
        }

        private string set_font_stylesheet () {
            if (Notejot.Application.gsettings.get_string("font-size") == "'small'") {
                return Styles.small.css;
            } else if (Notejot.Application.gsettings.get_string("font-size") == "'medium'") {
                return Styles.medium.css;
            } else if (Notejot.Application.gsettings.get_string("font-size") == "'large'") {
                return Styles.large.css;
            } else {
                return Styles.medium.css;
            }
        }
    }
}
