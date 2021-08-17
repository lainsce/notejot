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
            this.left_margin = this.right_margin = this.top_margin = 20;
            this.wrap_mode = Gtk.WrapMode.WORD_CHAR;


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

            set_stylesheet ();
            set_font_stylesheet ();
            fmt_syntax_start ();

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
            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
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

            string buf = buffer.get_text (start, end, true);

            try {
                var reg_bold = new Regex("""(?m)(?<bold>\|.*\|)""");
                var reg_italic = new Regex("""(?m)(?<italic>\*.*\*)""");
                var reg_ul = new Regex("""(?m)(?<ul>\_.*\_)""");
                var reg_s = new Regex("""(?m)(?<strike>\~.*\~)""");
                GLib.MatchInfo bmatch;
                GLib.MatchInfo imatch;
                GLib.MatchInfo ulmatch;
                GLib.MatchInfo smatch;

                if (reg_bold.match (buf, 0, out bmatch)) {
                    do {
                        if (start.forward_search (bmatch.fetch_named ("bold"), Gtk.TextSearchFlags.CASE_INSENSITIVE, out match_start, out match_end, null)) {
                            buffer.apply_tag(bold_font, match_start, match_end);
                            buffer.remove_tag(italic_font, match_start, match_end);
                            buffer.remove_tag(ul_font, match_start, match_end);
                            buffer.remove_tag(s_font, match_start, match_end);
                        }
                    } while (bmatch.next ());
                }

                if (reg_italic.match (buf, 0, out imatch)) {
                    do {
                        if (start.forward_search (imatch.fetch_named ("italic"), Gtk.TextSearchFlags.CASE_INSENSITIVE, out match_start, out match_end, null)) {
                            buffer.apply_tag(italic_font, match_start, match_end);
                            buffer.remove_tag(bold_font, match_start, match_end);
                            buffer.remove_tag(ul_font, match_start, match_end);
                            buffer.remove_tag(s_font, match_start, match_end);
                        }
                    } while (imatch.next ());
                }

                if (reg_ul.match (buf, 0, out ulmatch)) {
                    do {
                        if (start.forward_search (ulmatch.fetch_named ("ul"), Gtk.TextSearchFlags.CASE_INSENSITIVE, out match_start, out match_end, null)) {
                            buffer.apply_tag(ul_font, match_start, match_end);
                            buffer.remove_tag(bold_font, match_start, match_end);
                            buffer.remove_tag(italic_font, match_start, match_end);
                            buffer.remove_tag(s_font, match_start, match_end);
                        }
                    } while (ulmatch.next ());
                }

                if (reg_s.match (buf, 0, out smatch)) {
                    do {
                        if (start.forward_search (smatch.fetch_named ("strike"), Gtk.TextSearchFlags.CASE_INSENSITIVE, out match_start, out match_end, null)) {
                            buffer.apply_tag(s_font, match_start, match_end);
                            buffer.remove_tag(bold_font, match_start, match_end);
                            buffer.remove_tag(italic_font, match_start, match_end);
                            buffer.remove_tag(ul_font, match_start, match_end);
                        }
                    } while (smatch.next ());
                }
            } catch (GLib.RegexError re) {
                warning ("%s".printf(re.message));
            }

            update_idle_source = 0;
            return GLib.Source.REMOVE;
        }
    }
}
