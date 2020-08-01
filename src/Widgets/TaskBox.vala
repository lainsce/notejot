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
    public class Widgets.TaskBox : Gtk.Grid {
        private MainWindow win;
        private int uid;
        private static int uid_counter;
        public Gtk.Grid main_grid;
        public Gtk.ActionBar bar;
        public Gtk.Label task_label;
        public Gtk.Label task_contents;
        public Services.Task task;

        public Widgets.SidebarItem sidebaritem;

        public TaskBox (MainWindow win, string title, string contents, string color) {
            this.win = win;
            this.get_style_context ().add_class ("notejot-column-box");

            this.uid = uid_counter++;
            update_theme (color);

            win.tm.save_notes ();

            sidebaritem = new Widgets.SidebarItem (win, title);
            win.notes_category.add (sidebaritem);

            task = new Services.Task (win, title, contents, color);

            bar = new Gtk.ActionBar ();
            bar.get_style_context ().add_class ("notejot-bar");

            task_label = new Gtk.Label (title);
            task_label.halign = Gtk.Align.START;
            task_label.wrap = true;
            task_label.hexpand = true;
            task_label.max_width_chars = 24;
            task_label.margin_start = task_label.margin_end = 6;
            task_label.ellipsize = Pango.EllipsizeMode.END;

            task_contents = new Gtk.Label (contents);
            task_contents.halign = Gtk.Align.START;
            task_contents.wrap = true;
            task_contents.wrap_mode = Pango.WrapMode.WORD_CHAR;
            task_contents.hexpand = true;
            task_contents.use_markup = true;
            task_contents.max_width_chars = 24;
            task_contents.margin_start = task_contents.margin_end = 6;

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

            var color_button_indigo = new Gtk.RadioButton.from_widget (color_button_red) {
                tooltip_text = _("Indigo")
            };
            color_button_indigo.get_style_context ().add_class ("color-button");
            color_button_indigo.get_style_context ().add_class ("color-indigo");

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
            color_button_box.add (color_button_indigo);
            color_button_box.add (color_button_neutral);

            var color_button_label = new Granite.HeaderLabel (_("Note Badge Color"));

            var delete_note_button = new Gtk.ModelButton ();
			delete_note_button.text = (_("Delete Note"));

			delete_note_button.clicked.connect (() => {
                this.get_parent ().destroy ();
                win.tm.save_notes ();
                if (win.flowgrid.get_children () == null) {
                    if (win.stack.get_visible_child () == win.grid_view) {
                        win.stack.set_visible_child (win.normal_view);
                    }
                }
                sidebaritem.destroy_item ();
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
                update_theme("#F3ACAA");
                win.tm.save_notes ();
            });

            color_button_orange.clicked.connect (() => {
                update_theme("#FFC78B");
                win.tm.save_notes ();
            });

            color_button_yellow.clicked.connect (() => {
                update_theme("#FCF092");
                win.tm.save_notes ();
            });

            color_button_green.clicked.connect (() => {
                update_theme("#B1FBA2");
                win.tm.save_notes ();
            });

            color_button_blue.clicked.connect (() => {
                update_theme("#B8EFFA");
                win.tm.save_notes ();
            });

            color_button_indigo.clicked.connect (() => {
                update_theme("#C0C0F5");
                win.tm.save_notes ();
            });

            color_button_neutral.clicked.connect (() => {
                update_theme("#DADADA");
                win.tm.save_notes ();
            });

            var popout_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("window-pop-out-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Popout Note to Desktop"))
            };
            bar.pack_start (popout_button);

            popout_button.clicked.connect (() => {
                Widgets.NoteWindow notewindow = new Widgets.NoteWindow (win, title, contents, uid);
                notewindow.run (null);
            });
            
            bar.pack_start (task_label);
            bar.pack_end (app_button);

            this.set_size_request (200,200);
            this.get_style_context ().add_class ("notejot-note-grid");
            this.get_style_context ().add_class ("notejot-note-grid-%d".printf(uid));
            this.orientation = Gtk.Orientation.VERTICAL;
            this.halign = Gtk.Align.CENTER;
            this.valign = Gtk.Align.CENTER;
            this.row_spacing = 12;
            app_button.halign = Gtk.Align.END;
            this.add (bar);
            this.add (task_contents);
            
            this.expand = false;
            
            this.show_all ();
        }

        private void update_theme(string color) {
            var css_provider = new Gtk.CssProvider();

            string style = null;
            style = (N_("""
            .notejot-note-grid-%d {
                background-image: linear-gradient(to bottom, %s 30px, shade(@base_color, 1.1) 1px);
            }
            .notejot-nbar-%d {
                border-radius: 8px 8px 0 0;
                background-color: %s;
                background-image: none;
                padding: 0;
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
        }
    }
}
