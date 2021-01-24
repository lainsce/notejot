namespace Notejot {
    public class Widgets.TextField : WebKit.WebView {
        public MainWindow win;
        public string text = "";
        public Widgets.Note controller;

        public TextField (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.editable = true;

            var settings = new WebKit.Settings ();
		    settings.set_enable_accelerated_2d_canvas(true);
		    settings.set_enable_html5_database(false);
		    settings.set_enable_html5_local_storage(false);
		    settings.set_enable_java(false);
		    settings.set_enable_media_stream(false);
		    settings.set_enable_page_cache(false);
		    settings.set_enable_plugins(false);
		    settings.set_enable_smooth_scrolling(true);
		    settings.set_javascript_can_access_clipboard(false);
		    settings.set_javascript_can_open_windows_automatically(false);
		    settings.set_media_playback_requires_user_gesture(true);

            update_html_view.begin ();
            connect_signals.begin ();
            send_text.begin ();
            win.tm.save_notes.begin ();

            Notejot.Application.gsettings.changed.connect (() => {
                update_html_view.begin ();
                win.tm.save_notes.begin ();
            });
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
                        controller.text = val == "" ? " " : val;
                    }
                } catch (Error e) {
                    assert_not_reached ();
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

        public async void update_html_view () {
            string style = set_stylesheet ();
            var html = """
            <!doctype html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <style>%s</style>
                </head>
                <body>%s</body>
            </html>""".printf(style, text);
            this.load_html (html, "file:///");
        }
    }
}
