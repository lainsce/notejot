namespace Notejot {
    public class Widgets.TextField : WebKit.WebView {
        public MainWindow win;
        public string text = "";
        public Widgets.Note controller;

        public TextField (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.editable = true;
            this.set_can_focus (true);
            this.opacity = 0.66;

            var settings = new WebKit.Settings ();
		    settings.set_enable_html5_database(false);
		    settings.set_enable_html5_local_storage(false);
		    settings.set_enable_java(false);
		    settings.set_enable_media_stream(false);
		    settings.set_enable_page_cache(false);
		    settings.set_enable_smooth_scrolling(true);
		    settings.set_javascript_can_access_clipboard(false);
		    settings.set_javascript_can_open_windows_automatically(false);
		    settings.set_media_playback_requires_user_gesture(true);

            update_html_view.begin ();
            connect_signals.begin ();
            send_text.begin ();

            Notejot.Application.gsettings.changed.connect (() => {
                update_html_view.begin ();
                win.tm.save_notes.begin (win.notestore);
            });

            Timeout.add_seconds (3, () => {
                send_text.begin ();
                return true;
            });

            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        run_javascript.begin ("document.execCommand('undo', false, false);");
                        send_text.begin ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if ((e.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                        if (match_keycode (Gdk.Key.z, keycode)) {
                            run_javascript.begin ("document.execCommand('redo', false, false);");
                            send_text.begin ();
                        }
                    }
                }
                return false;
            });
        }

#if VALA_0_42
        protected bool match_keycode (uint keyval, uint code) {
#else
        protected bool match_keycode (int keyval, uint code) {
#endif
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
            if (keymap.get_entries_for_keyval (keyval, out keys)) {
                foreach (var key in keys) {
                    if (code == key.keycode)
                        return true;
                    }
                }
            return false;
        }

        public async void connect_signals () {
            load_changed.connect ((event) => {
                if (event == WebKit.LoadEvent.COMMITTED) {
                    send_text.begin ();
                }
                if (event == WebKit.LoadEvent.FINISHED) {
                    send_text.begin ();
                }
            });
        }

        public async void send_text () {
            run_javascript.begin("""document.body.innerHTML;""", null, (obj, res) => {
                try {
                    var data = run_javascript.end(res);
                    if (data != null && win != null) {
                        var val = data.get_js_value ().to_string ();
                        this.text = val == "" ? " " : val;
                        controller.log.text = val == "" ? " " : val;

                        win.tm.save_notes.begin (win.notestore);
                    }
                } catch (Error e) {
                    warning ("%s".printf(e.message));
                }
            });
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

        public async void update_html_view () {
            string style = set_stylesheet ();
            string fstyle = set_font_stylesheet ();
            var html = """<!DOCTYPE html><html lang="en-us"><head><meta charset="utf-8"><style>%s %s</style></head><body>%s</body></html>""".printf(style, fstyle, text);
            this.load_html (html, "file:///");
        }
    }
}
