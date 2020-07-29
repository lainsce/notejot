/*
* Copyright (C) 2017-2020 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
namespace Notejot {
    public class Widgets.TextField : WebKit.WebView {
        public MainWindow win;
        public string html = "";
        public string text = "";

        public TextField (MainWindow win) {
            this.win = win;
            this.expand = true;
            this.editable = true;
            this.get_style_context ().add_class ("notejot-tview");

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

            update_html_view ();
            connect_signals ();

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                update_html_view ();
            });
        }

        private void connect_signals () {
            load_changed.connect ((event) => {
                if (event == WebKit.LoadEvent.COMMITTED) {
                    send_text ();
                    win.tm.save_notes ();
                }
                if (event == WebKit.LoadEvent.FINISHED) {
                    send_text ();
                    win.tm.save_notes ();
                }
            });
        }

        public void send_text () {
            run_javascript.begin("""document.getElementById("textarea").innerHTML;""", null, (obj, res) => {
                try {
                    var data = run_javascript.end(res);
                    if (data != null) { 
                        if (win.listview.column.get_children () != null) {
                            var row = (Widgets.Note)win.listview.column.get_selected_row ();
                            if (data != null) {
                                var val = data.get_js_value ().to_string ();
                                row.contents = val == "" ? " " : val;
                                text = val == "" ? " " : val;
                            }
                        }
                    }
                } catch (Error e) {
                    assert_not_reached ();
                }
            });
        }

        private string set_stylesheet () {
            if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                string dark = Styles.dark.css;
                return dark;
            } else if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                if (Notejot.Application.gsettings.get_boolean("dark-mode") == true) {
                    string dark = Styles.dark.css;
                    return dark;
                } else {
                    string normal = Styles.light.css;
                    return normal;
                }
            } else {
                string normal = Styles.light.css;
                return normal;
            }
        }

        public void update_html_view () {
            string style = set_stylesheet ();
            html = """
            <!doctype html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <style>%s</style>
                </head>
                <body>
                    <div id="textarea">%s</div>
                </body>
            </html>""".printf(style, text);
            this.load_html (html, "file:///");
        }
    }
}