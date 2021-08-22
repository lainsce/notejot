namespace Notejot {
    public enum Format {
        BOLD,
        ITALIC,
        STRIKETHROUGH,
        UNDERLINE
    }

    public struct FormatBlock {
        public int start;
        public int end;
        public Format format;
    }

    public string format_to_string(Format fmt) {
        switch (fmt) {
            case Format.BOLD:
                return "|";
            case Format.ITALIC:
                return "*";
            case Format.STRIKETHROUGH:
                return "~";
            case Format.UNDERLINE:
                return "_";
            default:
                assert_not_reached();
        }
    }

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

        public FormatBlock[] fmt_syntax_blocks() {
            Gtk.TextIter start, end;
            int match_start_offset, match_end_offset;
            FormatBlock[] format_blocks = {};

            GLib.MatchInfo match;

            buffer.get_bounds(out start, out end);
            string measure_text, buf = buffer.get_text (start, end, true);

            try {
                var regex = new Regex("""(?s)(?<wrap>[*_|~]).*?\g{wrap}""");

                if (regex.match (buf, 0, out match)) {
                    do {
                        if (match.fetch_pos (0, out match_start_offset, out match_end_offset)) {
                            // measure the offset of the actual unicode glyphs,
                            // not the byte offset
                            measure_text = buf[0:match_start_offset];
                            match_start_offset = measure_text.char_count();
                            measure_text = buf[0:match_end_offset];
                            match_end_offset = measure_text.char_count();

                            Format format = Format.BOLD;
                            switch (match.fetch_named("wrap")) {
                                case "|":
                                    format = Format.BOLD;
                                    break;
                                case "*":
                                    format = Format.ITALIC;
                                    break;
                                case "_":
                                    format = Format.UNDERLINE;
                                    break;
                                case "~":
                                    format = Format.STRIKETHROUGH;
                                    break;
                            }

                            format_blocks += FormatBlock() {
                                start = match_start_offset,
                                end = match_end_offset,
                                format = format
                            };
                        }
                    } while (match.next());
                }
            } catch (GLib.RegexError re) {
                warning ("%s".printf(re.message));
            }

            return format_blocks;
        }

        private bool fmt_syntax () {
            Gtk.TextIter start, end, fmt_start, fmt_end;

            buffer.get_bounds (out start, out end);
            buffer.remove_all_tags (start, end);

            foreach (FormatBlock fmt in fmt_syntax_blocks ()) {
                buffer.get_iter_at_offset (out fmt_start, fmt.start);
                buffer.get_iter_at_offset (out fmt_end, fmt.end);

                Gtk.TextTag tag = bold_font;
                switch (fmt.format) {
                    case Format.BOLD:
                        tag = bold_font;
                        break;
                    case Format.ITALIC:
                        tag = italic_font;
                        break;
                    case Format.STRIKETHROUGH:
                        tag = s_font;
                        break;
                    case Format.UNDERLINE:
                        tag = ul_font;
                        break;
                }

                buffer.apply_tag (tag, fmt_start, fmt_end);
            }

            update_idle_source = 0;
            return GLib.Source.REMOVE;
        }
    }
}
