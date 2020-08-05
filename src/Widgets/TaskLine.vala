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

            win.tm.save_notes ();

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

            var color_button_red = new Gtk.RadioButton (null) {
                tooltip_text = _("Red")
            };
            color_button_red.get_style_context ().add_class ("color-button");
            color_button_red.get_style_context ().add_class ("color-red");

            var color_button_orange = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Orange")
            };
            color_button_orange.get_style_context ().add_class ("color-button");
            color_button_orange.get_style_context ().add_class ("color-orange");

            var color_button_yellow = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Yellow")
            };
            color_button_yellow.get_style_context ().add_class ("color-button");
            color_button_yellow.get_style_context ().add_class ("color-yellow");

            var color_button_green = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Green")
            };
            color_button_green.get_style_context ().add_class ("color-button");
            color_button_green.get_style_context ().add_class ("color-green");

            var color_button_blue = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Blue")
            };
            color_button_blue.get_style_context ().add_class ("color-button");
            color_button_blue.get_style_context ().add_class ("color-blue");

            var color_button_violet = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Indigo")
            };
            color_button_violet.get_style_context ().add_class ("color-button");
            color_button_violet.get_style_context ().add_class ("color-violet");

            var color_button_neutral = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Gray")
            };
            color_button_neutral.get_style_context ().add_class ("color-button");
            color_button_neutral.get_style_context ().add_class ("color-neutral");

            var color_button_box = new Gtk.Grid () {
                margin_start = 12,
                column_spacing = 6
            };
            color_button_box.add (color_button_red);
            color_button_box.add (color_button_orange);
            color_button_box.add (color_button_yellow);
            color_button_box.add (color_button_green);
            color_button_box.add (color_button_blue);
            color_button_box.add (color_button_violet);
            color_button_box.add (color_button_neutral);

            var color_button_label = new Granite.HeaderLabel (_("Note Badge Color"));

            var delete_note_button = new Gtk.ModelButton ();
			delete_note_button.text = (_("Delete Note"));

			delete_note_button.clicked.connect (() => {
                this.destroy ();
                win.tm.save_notes ();
                if (win.flowgrid.get_children () == null) {
                    if (win.stack.get_visible_child () == win.list_view) {
                        win.stack.set_visible_child (win.welcome_view);
                    }
                }
                taskbox.sidebaritem.destroy_item ();
                taskbox.get_parent ().destroy ();
			});

            var setting_grid = new Gtk.Grid ();
            setting_grid.margin = 6;
            setting_grid.column_spacing = 6;
            setting_grid.row_spacing = 6;
            setting_grid.orientation = Gtk.Orientation.VERTICAL;
            setting_grid.attach (color_button_label, 0, 0, 1, 1);
            setting_grid.attach (color_button_box, 0, 1, 1, 1);
            setting_grid.attach (delete_note_button, 0, 2, 1, 1);
            setting_grid.show_all ();

            var popover = new Gtk.Popover (null);
            popover.add (setting_grid);

            var app_button = new Gtk.MenuButton();
            app_button.has_tooltip = true;
            app_button.tooltip_text = (_("Settings"));
            app_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            app_button.popover = popover;

            color_button_red.clicked.connect (() => {
                taskbox.update_theme("#F3ACAA");
            });

            color_button_orange.clicked.connect (() => {
                taskbox.update_theme("#FFC78B");
            });

            color_button_yellow.clicked.connect (() => {
                taskbox.update_theme("#FCF092");
            });

            color_button_green.clicked.connect (() => {
                taskbox.update_theme("#B1FBA2");
            });

            color_button_blue.clicked.connect (() => {
                taskbox.update_theme("#B8EFFA");
            });

            color_button_violet.clicked.connect (() => {
                taskbox.update_theme("#C0C0F5");
            });

            color_button_neutral.clicked.connect (() => {
                taskbox.update_theme("#DADADA");
            });

            var popout_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("window-pop-out-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Popout Note to Desktop"))
            };

            popout_button.clicked.connect (() => {
                var notewindow = new Widgets.NoteWindow (win, taskbox.title, taskbox.contents);
                notewindow.run (null);
            });

            bar.pack_end (app_button);
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
