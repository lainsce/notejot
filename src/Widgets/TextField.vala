namespace Notejot {
    public class Widgets.TextField : Gtk.TextView {
        public MainWindow win;
        public new unowned Gtk.TextBuffer buffer;
        public Widgets.Note controller;
        private uint update_idle_source = 0;

        private Gtk.TextTag bold_font;
        private Gtk.TextTag italic_font;
        private Gtk.TextTag ul_font;
        private Gtk.TextTag s_font;

        public string text {
            owned get {
                return buffer.text;
            }

            set {
                buffer.text = value;
            }
        }

        public TextField (MainWindow win) {
            this.win = win;
            this.editable = true;
            this.set_can_focus (true);
            this.opacity = 0.7;
            this.right_margin = this.bottom_margin = this.top_margin = this.left_margin = 20;

            var buffer = new Gtk.TextBuffer (null);
            this.buffer = buffer;
            set_buffer (buffer);

            bold_font = new Gtk.TextTag();
            italic_font = new Gtk.TextTag();
            ul_font = new Gtk.TextTag();
            s_font = new Gtk.TextTag();

            bold_font = buffer.create_tag("bold", "weight", Pango.Weight.BOLD);
            italic_font = buffer.create_tag("italic", "style", Pango.Style.ITALIC);
            ul_font = buffer.create_tag("underline", "underline", Pango.Underline.SINGLE);
            s_font = buffer.create_tag("strike", "strikethrough", true);

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
                fmt_syntax_start ();
                return true;
            });

            buffer.changed.connect (() => {
                send_text ();
                fmt_syntax_start ();
            });
        }

        public string get_selected_text () {
            Gtk.TextIter A;
            Gtk.TextIter B;
            if (buffer.get_selection_bounds (out A, out B)) {
               return buffer.get_text(A, B, true);
            }

            return "";
        }

        public void send_text () {
            Gtk.TextIter A;
            Gtk.TextIter B;
            buffer.get_bounds (out A, out B);
            var val = buffer.get_text (A, B, true);
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

        public void fmt_syntax_start () {
            if (update_idle_source > 0) {
                GLib.Source.remove (update_idle_source);
            }

            update_idle_source = GLib.Idle.add (() => {
                fmt_syntax ();
                return false;
            });
        }

        private bool fmt_syntax () {
            Gtk.TextIter start, end, match_start, match_end;
            buffer.get_bounds (out start, out end);

            string no_punct_buffer = buffer.get_text (start, end, false).strip();
            string[] words = no_punct_buffer.split(" ");
            int p = 0;

            foreach (string word in words) {
                if (word.length == 0) {
                    p += word.length + 1;
                    continue;
                }
                if (word.has_suffix ("^") && word.has_prefix ("^")) {
                    buffer.get_iter_at_offset (out match_start, p);
                    buffer.get_iter_at_offset (out match_end, p + word.length);
                    buffer.apply_tag(bold_font, match_start, match_end);
                }
                if (word.has_suffix ("*") && word.has_prefix ("*")) {
                    buffer.get_iter_at_offset (out match_start, p);
                    buffer.get_iter_at_offset (out match_end, p + word.length);
                    buffer.apply_tag(italic_font, match_start, match_end);
                }
                if (word.has_suffix ("_") && word.has_prefix ("_")) {
                    buffer.get_iter_at_offset (out match_start, p);
                    buffer.get_iter_at_offset (out match_end, p + word.length);
                    buffer.apply_tag(ul_font, match_start, match_end);
                }
                if (word.has_suffix ("~") && word.has_prefix ("~")) {
                    buffer.get_iter_at_offset (out match_start, p);
                    buffer.get_iter_at_offset (out match_end, p + word.length);
                    buffer.apply_tag(s_font, match_start, match_end);
                }

                p += word.length + 1;
            }

            update_idle_source = 0;
            return GLib.Source.REMOVE;
        }
    }
}
