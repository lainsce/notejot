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
    public class Widgets.TrashedItem : Adw.ActionRow {
        public Widgets.TextField textfield;
        private static int uid_counter;
        public int uid;
        private Gtk.CssProvider css_provider;
        public unowned Log tlog { get; construct; }
        public unowned MainWindow win { get; construct; }

        public TrashedItem (MainWindow win, Log? tlog) {
            Object (tlog: tlog,
                    win: win);
            this.uid = uid_counter++;
            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("");
            icon.halign = Gtk.Align.START;
            icon.valign = Gtk.Align.CENTER;
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-%d".printf(uid));
            add_prefix (icon);
            set_title (tlog.title);
            set_subtitle (tlog.subtitle);
            this.get_style_context ().add_class ("notejot-sidebar-box");
            update_theme (tlog.color);
        }

        public void destroy_item () {
            this.dispose ();
            css_provider.dispose ();
        }

        public void update_theme(string? color) {
            css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-sidebar-dbg-%d {
                background: %s;
                border-radius: 9999px;
            }
            """)).printf(uid, color);
            css_provider.load_from_data(style.data);
            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
            tlog.color = color;
        }
    }
}
