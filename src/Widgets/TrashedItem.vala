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
    public class Widgets.TrashedItem : Hdy.ActionRow {
        private MainWindow win;
        public Widgets.TextField textfield;
        public Widgets.EditableLabel editablelabel;
        private static int uid_counter;
        public int uid;
        public new string title;
        public new string subtitle;
        public string text;
        public string color;

        public TrashedItem (MainWindow win, string title, string subtitle, string text, string color) {
            this.win = win;
            this.uid = uid_counter++;
            this.title = title;
            this.subtitle = subtitle;
            this.text = text;

            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("", Gtk.IconSize.BUTTON);
            icon.halign = Gtk.Align.START;
            icon.valign = Gtk.Align.CENTER;
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-%d".printf(uid));

            add_prefix (icon);

            set_title (this.title);
            set_subtitle (this.subtitle);

            this.show_all ();
            this.get_style_context ().add_class ("notejot-sidebar-box");

            update_theme (color);
        }

        public void destroy_item () {
            this.destroy ();
        }

        public void update_theme(string? color) {
            var css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-sidebar-dbg-%d {
                border: 1px solid alpha(black, 0.25);
                background: %s;
                border-radius: 50px;
                margin-left: 12px;
            }
            .notejot-sidebar-dbg-dark-%d {
                border: 1px solid alpha(black, 0.25);
                background: shade(%s, 0.8);
                border-radius: 50px;
                margin-left: 12px;
            }
            """)).printf(uid, color, uid, color);

            try {
                css_provider.load_from_data(style, -1);
            } catch (GLib.Error e) {
                warning ("Failed to parse css style : %s", e.message);
            }

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            this.color = color;
            win.tm.save_notes.begin ();
        }
    }
}
