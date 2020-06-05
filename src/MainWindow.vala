/*
* Copyright (c) 2017-2020 Lains
*
* This program is free software; you can redistribute it and/or
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
    public class MainWindow : Hdy.Window {
        // Widgets
        public Widgets.Column column;
        public Gtk.Grid grid;
        public bool pinned = false;

        public Services.TaskManager tm;

        public Gtk.Application app { get; construct; }

        public MainWindow (Gtk.Application application) {
            GLib.Object (
                application: application,
                app: application,
                icon_name: "com.github.lainsce.notejot",
                title: (_("Notejot"))
            );

            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;

                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.q, keycode)) {
                        this.destroy ();
                    }
                }
                return false;
            });
        }

        construct {
            // Ensure use of elementary theme and icons, accent color doesn't matter
            Gtk.Settings.get_default().set_property("gtk-theme-name", "io.elementary.stylesheet.blueberry");
            Gtk.Settings.get_default().set_property("gtk-icon-theme-name", "elementary");

            tm = new Services.TaskManager (this);

            int x = Notejot.Application.gsettings.get_int("window-x");
            int y = Notejot.Application.gsettings.get_int("window-y");
            int w = Notejot.Application.gsettings.get_int("window-w");
            int h = Notejot.Application.gsettings.get_int("window-h");
            if (x != -1 && y != -1) {
                this.move (x, y);
            }
            this.resize (w, h);

            var titlebar = new Gtk.HeaderBar ();
            var titlebar_c = titlebar.get_style_context ();
            titlebar_c.add_class ("notejot-tbar");
            titlebar.show_close_button = true;
            set_title (title);
            titlebar.title = "Notejot";

            var handle = new Hdy.WindowHandle ();
            handle.add(titlebar);

            var bar = new Gtk.ActionBar ();
            var bar_c = bar.get_style_context ();
            bar_c.add_class ("notejot-mbar");


            var applet_button = new Gtk.ToggleButton ();
            applet_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            var applet_button_image = new Gtk.Image.from_icon_name ("view-pin", Gtk.IconSize.LARGE_TOOLBAR);
            applet_button.set_image (applet_button_image);

            if (pinned) {
                applet_button.set_active (true);
                applet_button.get_style_context().add_class("rotated");
                set_keep_below (pinned);
                stick ();
            } else {
                applet_button.set_active (false);
                applet_button.get_style_context().remove_class("rotated");
            }

            applet_button.toggled.connect (() => {
                if (applet_button.active) {
                    pinned = true;
                    applet_button.get_style_context().add_class("rotated");
                    set_keep_below (pinned);
                    stick ();
    			} else {
    			    pinned = false;
                    set_keep_below (pinned);
                    applet_button.get_style_context().remove_class("rotated");
    			    unstick ();
                }
            });

            bar.pack_end (applet_button);

            var new_button = new Gtk.Button ();
            new_button.set_image (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            new_button.has_tooltip = true;
            new_button.tooltip_text = (_("New Note"));
            bar.set_center_widget (new_button);

            // Column
            column = new Widgets.Column (this);

            tm.load_from_file ();

            grid = new Gtk.Grid ();
            grid.vexpand = true;
            grid.attach (column, 0, 0, 1, 1);
            grid.show_all ();

            new_button.clicked.connect (() => {
                add_task (_("Write a New Note…"), "#fff394");
            });

            var scrwindow = new Gtk.ScrolledWindow (null, null);
            scrwindow.vexpand = true;
            scrwindow.add (grid);

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.add (handle);
            box.add (scrwindow);
            box.add (bar);

            this.add (box);
            this.set_size_request (360, 360);
            this.show_all ();

            // Setting CSS
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/lainsce/notejot/app.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

#if VALA_0_42
        protected bool match_keycode (uint keyval, uint code) {
#else
        protected bool match_keycode (int keyval, uint code) {
#endif
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
            if (keymap.get_entries_for_keyval (keyval, out keys)) {
                foreach (var key in keys) {
                    if (code == key.keycode)
                        return true;
                    }
                }

            return false;
        }

        public void add_task (string contents, string color) {
            var taskbox = new Widgets.TaskBox (this, contents, color);
            column.add (taskbox);
            tm.save_notes ();
            column.is_modified = true;
        }

        public override bool delete_event (Gdk.EventAny event) {
            int x, y;
            get_position (out x, out y);
            int w, h;
            get_size (out w, out h);
            Notejot.Application.gsettings.set_int("window-w", w);
            Notejot.Application.gsettings.set_int("window-h", h);
            Notejot.Application.gsettings.set_int("window-x", x);
            Notejot.Application.gsettings.set_int("window-y", y);

            return false;
        }
    }
}

