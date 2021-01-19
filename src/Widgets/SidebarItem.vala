/*
* Copyright (C) 2017-2020 Lains
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
    public class Widgets.SidebarItem : Gtk.ListBoxRow {
        private MainWindow win;
        public Widgets.TaskBox? taskbox;
        public int uid;
        private Gtk.Label label;

        public SidebarItem (MainWindow win, Widgets.TaskBox taskbox, int uid) {
            this.win = win;
            this.uid = uid;
            this.taskbox = taskbox;

            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("", Gtk.IconSize.SMALL_TOOLBAR);
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-%d".printf(uid));

            label = new Gtk.Label (taskbox.title);

            var grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.attach (icon, 0, 0);
            grid.attach (label, 1, 0);
            grid.show_all ();

            this.show_all ();
            this.add (grid);
            this.get_style_context ().add_class ("notejot-sidebar-dbg");
        }

        public void destroy_item () {
            this.destroy ();
        }
    }
}
