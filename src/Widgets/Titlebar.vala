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
    public class Widgets.Titlebar : Hdy.HeaderBar {
        private MainWindow win;
        public Gtk.ToggleButton format_button;
        public Gtk.Button new_button;

        public Widgets.Menu menu;

        public Titlebar (MainWindow win) {
            this.win = win;
            this.set_size_request (-1, 45);
            this.get_style_context ().add_class ("notejot-tbar");
            this.get_style_context ().remove_class ("titlebar");
            this.show_close_button = true;
            this.has_subtitle = false;
            this.hexpand = true;
            this.title = "Notejot";

            new_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("New Note"))
            };
            new_button.get_style_context ().add_class ("notejot-button");
            this.pack_start (new_button);

            new_button.clicked.connect (() => {
                var task = new Services.Task (win, "New Note", "Write a new note…", "#FCF092", 0);
                if (win.main_view.stack.get_visible_child () == win.main_view.welcome_view) {
                    win.main_view.stack.set_visible_child (win.main_view.grid_view);
                }
            });

            format_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("font-x-generic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Formatting Options")),
                sensitive = false
            };
            format_button.get_style_context ().add_class ("notejot-button");
            this.pack_start (format_button);

            format_button.toggled.connect (() => {
                if (Notejot.Application.gsettings.get_boolean ("show-formattingbar")) {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", false);
                } else {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", true);
                }
                win.tm.save_notes ();
            });

            menu = new Widgets.Menu (win);
            this.pack_end (menu);

            if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                Notejot.Application.gsettings.set_boolean("dark-mode", true);
                menu.mode_switch.sensitive = false;
            } else if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                Notejot.Application.gsettings.set_boolean("dark-mode", false);
                menu.mode_switch.sensitive = true;
            }

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                    Notejot.Application.gsettings.set_boolean("dark-mode", true);
                    menu.mode_switch.sensitive = false;
                } else if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                    Notejot.Application.gsettings.set_boolean("dark-mode", false);
                    menu.mode_switch.sensitive = true;
                }
            });

            if (Notejot.Application.gsettings.get_boolean("pinned")) {
                menu.applet_switch.set_active (true);
                win.set_keep_below (Notejot.Application.gsettings.get_boolean("pinned"));
                win.stick ();
            } else {
                menu.applet_switch.set_active (false);
            }

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                this.get_style_context ().add_class ("notejot-tbar-dark");
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                this.get_style_context ().remove_class ("notejot-tbar-dark");
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    this.get_style_context ().add_class ("notejot-tbar-dark");
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    this.get_style_context ().remove_class ("notejot-tbar-dark");
                }

                if (Notejot.Application.gsettings.get_boolean("pinned")) {
                    menu.applet_switch.set_active (true);
                    win.set_keep_below (Notejot.Application.gsettings.get_boolean("pinned"));
                    win.stick ();
                } else {
                    menu.applet_switch.set_active (false);
                }
            });

            this.show_all ();
        }
    }
}