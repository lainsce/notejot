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
    public class Widgets.TaskLine : Gtk.ListBoxRow {
        private MainWindow win;
        public Widgets.TaskBox? taskbox;
        public Gtk.Box bar;
        public Gtk.Grid main_grid;
        public Gtk.Label task_label;
        public Gtk.Box dummy_badge;
        public int uid;

        public TaskLine (MainWindow win, Widgets.TaskBox taskbox, int uid) {
            this.win = win;
            this.uid = uid;
            this.taskbox = taskbox;
            this.get_style_context ().add_class ("notejot-column-box");

            win.tm.save_notes.begin ();

            // Used to make up the colored badge
            dummy_badge = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            dummy_badge.margin = 6;
            dummy_badge.valign = Gtk.Align.CENTER;
            dummy_badge.margin_top = dummy_badge.margin_bottom = 0;
            dummy_badge.get_style_context ().add_class ("notejot-dbg-%d".printf(uid));

            bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            bar.margin = 6;
            bar.margin_top = bar.margin_bottom = 0;
            var bar_c = bar.get_style_context ();
            bar_c.add_class ("notejot-bar");

            task_label = new Gtk.Label (taskbox.title);
            task_label.halign = Gtk.Align.START;
            task_label.wrap = true;
            task_label.hexpand = true;
            task_label.max_width_chars = 20;
            task_label.ellipsize = Pango.EllipsizeMode.END;
            task_label.get_style_context ().add_class ("notejot-tc");

            var setting_menu = new Widgets.SettingMenu (win, taskbox);

            var popout_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("window-pop-out-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Popout Note to Desktop"))
            };

            popout_button.clicked.connect (() => {
                var notewindow = new Widgets.NoteWindow (win, taskbox.task_contents, taskbox.title, taskbox.contents, taskbox.uid);
                notewindow.run (null);
            });

            bar.pack_end (setting_menu);
            bar.pack_end (popout_button);

            main_grid = new Gtk.Grid ();
            main_grid.orientation = Gtk.Orientation.HORIZONTAL;
            main_grid.expand = true;
            main_grid.add (dummy_badge);
            main_grid.add (task_label);
            main_grid.add (bar);
            main_grid.show_all ();
            
            this.add (main_grid);
            this.show_all ();
        }
    }
}
