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
        public Widgets.NoteWindow notewindow;
        private static int uid_counter;

        public Gtk.ActionBar bar;
        public Gtk.Grid main_grid;
        
        public Gtk.Label task_label;

        public int uid;
        public string color = "#FFE16B";
        public string title = "New Note…";
        public string contents = "Write a new note…";

        public Widgets.SidebarItem sidebaritem;
        public Widgets.TaskLine taskline;
        public Widgets.TaskContentView task_contents;

        public TaskBox (MainWindow win, string? title, string? contents, string? color) {
            this.win = win;

            this.uid = uid_counter++;

            this.title = title;
            this.contents = contents;
            this.color = color;

            update_theme (this.color);
            win.tm.save_notes ();

            sidebaritem = new Widgets.SidebarItem (win, this.title);
            win.notes_category.add (sidebaritem);

            taskline = new Widgets.TaskLine (win, this, this.uid);
            win.flowlist.add (taskline);
            win.flowlist.is_modified = true;

            bar = new Gtk.ActionBar ();
            bar.get_style_context ().add_class ("notejot-bar");

            task_label = new Gtk.Label (this.title);
            task_label.halign = Gtk.Align.CENTER;
            task_label.wrap = true;
            task_label.hexpand = true;
            task_label.max_width_chars = 24;
            task_label.margin_start = task_label.margin_end = 6;
            task_label.ellipsize = Pango.EllipsizeMode.END;

            task_contents = new Widgets.TaskContentView (win, this.contents);
            task_contents.margin_bottom = 8;
            task_contents.update_html_view ();

            var task_contents_holder = new Gtk.ScrolledWindow (null, null);
            task_contents_holder.vexpand = true;
            task_contents_holder.add (task_contents);

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
                tooltip_text = _("Violet")
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
                this.get_parent ().destroy ();
                win.tm.save_notes ();
                if (win.flowgrid.get_children () == null) {
                    if (win.stack.get_visible_child () == win.grid_view) {
                        win.stack.set_visible_child (win.welcome_view);
                    }
                }
                sidebaritem.destroy_item ();
                taskline.destroy ();
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
            app_button.halign = Gtk.Align.END;

            color_button_red.clicked.connect (() => {
                update_theme("#F3ACAA");
            });

            color_button_orange.clicked.connect (() => {
                update_theme("#FFC78B");
            });

            color_button_yellow.clicked.connect (() => {
                update_theme("#FCF092");
            });

            color_button_green.clicked.connect (() => {
                update_theme("#B1FBA2");
            });

            color_button_blue.clicked.connect (() => {
                update_theme("#B8EFFA");
            });

            color_button_violet.clicked.connect (() => {
                update_theme("#C0C0F5");
            });

            color_button_neutral.clicked.connect (() => {
                update_theme("#DADADA");
            });

            var popout_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("window-pop-out-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Popout Note to Desktop"))
            };
            bar.pack_start (popout_button);

            popout_button.clicked.connect (() => {
                notewindow = new Widgets.NoteWindow (win, this.task_contents, this.title, this.contents, this.uid);
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
            this.add (bar);
            this.add (task_contents_holder);
            this.expand = false;
            this.show_all ();

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                this.get_style_context ().add_class ("notejot-note-grid-dark");
                this.get_style_context ().add_class ("notejot-note-grid-dark-%d".printf(uid));
                taskline.get_style_context ().add_class ("notejot-column-box-dark");
                taskline.dummy_badge.get_style_context ().add_class ("notejot-dbg-dark-%d".printf(uid));
                task_contents.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                this.get_style_context ().remove_class ("notejot-note-grid-dark");
                this.get_style_context ().remove_class ("notejot-note-grid-dark-%d".printf(uid));
                taskline.get_style_context ().remove_class ("notejot-column-box-dark");
                taskline.dummy_badge.get_style_context ().remove_class ("notejot-dbg-dark-%d".printf(uid));
                task_contents.update_html_view ();
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    this.get_style_context ().add_class ("notejot-note-grid-dark");
                    this.get_style_context ().add_class ("notejot-note-grid-dark-%d".printf(uid));
                    taskline.get_style_context ().add_class ("notejot-column-box-dark");
                    taskline.dummy_badge.get_style_context ().add_class ("notejot-dbg-dark-%d".printf(uid));
                    task_contents.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    this.get_style_context ().remove_class ("notejot-note-grid-dark");
                    this.get_style_context ().remove_class ("notejot-note-grid-dark-%d".printf(uid));
                    taskline.get_style_context ().remove_class ("notejot-column-box-dark");
                    taskline.dummy_badge.get_style_context ().remove_class ("notejot-dbg-dark-%d".printf(uid));
                    task_contents.update_html_view ();
                }
            });
        }

        public void update_theme(string? color) {
            var css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-note-grid-%d {
                background-image: linear-gradient(to bottom, %s 30px, #F7F7F7 1px);
            }
            .notejot-note-grid-dark-%d {
                background-image: linear-gradient(to bottom, shade(%s, 0.8) 30px, #151515 1px);
            }
            .notejot-nbar-%d {
                border-radius: 8px 8px 0 0;
                background-color: %s;
                box-shadow: none;
                background-image: none;
                padding: 0 5px;
                color: #000;
            }
            .notejot-nbar-dark-%d {
                background-color: shade(%s, 0.8);
            }
            .notejot-nbar-%d label {
                text-shadow: 1px 1px transparent;
            }
            .notejot-nbar-%d image {
                -gtk-icon-shadow: 1px 1px transparent;
                color: #000;
            }
            .notejot-dbg-%d {
                border: 1px solid alpha(black, 0.25);
                background: %s;
                border-radius: 8px;
                padding: 5px;
                box-shadow:
                    0 1px 0 0 alpha(@highlight_color, 0.3),
                    inset 0 1px 1px alpha(black, 0.05),
                    inset 0 0 1px 1px alpha(black, 0.05),
                    0 1px 0 0 alpha(@highlight_color, 0.2);
            }
            .notejot-dbg-dark-%d {
                border: 1px solid alpha(black, 0.25);
                background: shade(%s, 0.8);
                border-radius: 8px;
                padding: 5px;
                box-shadow:
                    0 1px 0 0 alpha(@highlight_color, 0.3),
                    inset 0 1px 1px alpha(black, 0.05),
                    inset 0 0 1px 1px alpha(black, 0.05),
                    0 1px 0 0 alpha(@highlight_color, 0.2);
            }
            """)).printf(uid, color, uid, color, uid, color, uid, color, uid, uid, uid, color, uid, color);

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
            win.tm.save_notes ();
        }
    }
}
