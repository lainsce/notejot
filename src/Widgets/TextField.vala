namespace Notejot {
    public class Widgets.TextField : Gtk.TextView {
        public MainWindow win;
        public Widgets.Note controller;

        public TextField (MainWindow win) {
            this.win = win;
            this.editable = true;
            this.set_can_focus (true);
            this.opacity = 0.8;
            this.right_margin = this.bottom_margin = this.top_margin = this.left_margin = 20;

            send_text ();
            set_stylesheet ();
            set_font_stylesheet ();

            Notejot.Application.gsettings.changed.connect (() => {
                set_stylesheet ();
                set_font_stylesheet ();
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

        private void set_stylesheet () {
            if (Notejot.Application.gsettings.get_boolean("dark-mode") == true) {
                this.get_style_context ().add_class ("dark");
                this.get_style_context ().remove_class ("light");
            } else {
                this.get_style_context ().add_class ("light");
                this.get_style_context ().remove_class ("dark");
            }
        }

        private void set_font_stylesheet () {
            if (Notejot.Application.gsettings.get_string("font-size") == "'small'") {
                this.get_style_context ().add_class ("sml-font");
                this.get_style_context ().remove_class ("med-font");
                this.get_style_context ().remove_class ("big-font");
            } else if (Notejot.Application.gsettings.get_string("font-size") == "'medium'") {
                this.get_style_context ().remove_class ("sml-font");
                this.get_style_context ().add_class ("med-font");
                this.get_style_context ().remove_class ("big-font");
            } else if (Notejot.Application.gsettings.get_string("font-size") == "'large'") {
                this.get_style_context ().remove_class ("sml-font");
                this.get_style_context ().remove_class ("med-font");
                this.get_style_context ().add_class ("big-font");
            } else {
                this.get_style_context ().remove_class ("sml-font");
                this.get_style_context ().add_class ("med-font");
                this.get_style_context ().remove_class ("big-font");
            }
        }
    }
}
