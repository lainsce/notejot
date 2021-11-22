/*
* Copyright (C) 2017-2021 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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
    public class Widgets.Note : Object {
        public unowned Log log { get; construct; }
        public unowned MainWindow win { get; construct; }
        public int uid = 0;
        public int uid_counter = 0;
        private Gtk.CssProvider css_provider;

        public Note (MainWindow win, Log? log) {
            Object (log: log,
                    win: win);
            this.uid = uid_counter++;
            update_theme (log.color);
        }

        public void update_theme(string? color) {
            css_provider = new Gtk.CssProvider();

            string style = null;
            style = """
            .notejot-sidebar-dbg-%d {
                background: linear-gradient(mix(%s, @view_bg_color, 0.5),shade(mix(%s, @view_bg_color, 0.4), 0.9));
                border-radius: 9999px;
            }
            .nw-titlebox-%d {
                background: mix(@view_bg_color, %s, 0.1);
            }
            .nw-formatbar-%d {
                background: mix(@view_bg_color, %s, 0.1);
            }
            .notejot-tview-%d text {
                background: mix(@popover_bg_color, %s, 0.02);
            }
            """.printf( uid,
                        color,
                        color,
                        uid,
                        color,
                        uid,
                        color,
                        uid,
                        color
            );

            css_provider.load_from_data(style.data);

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            log.color = color;
        }
    }
}
