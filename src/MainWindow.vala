/*
* Copyright (c) 2017-2020 Lains
*
* This program is free software; you can redistribute it and/or
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
    public class MainWindow : Hdy.Window {
        // Widgets
        public Gtk.Button new_button;
        public Gtk.Grid grid;
        public Gtk.Separator separator;
        public Gtk.Stack stack;
        public Gtk.ToggleButton format_button;
        public Hdy.HeaderBar titlebar;
        public Hdy.Leaflet leaflet;

        public Services.TaskManager tm;
        public Views.GridView grid_view;
        public Views.WelcomeView welcome_view;
        public Widgets.Menu menu;
        public Widgets.Sidebar sidebar;

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

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                titlebar.get_style_context ().add_class ("notejot-tbar-dark");
                grid_view.flowgrid.get_style_context ().add_class ("notejot-fgview-dark");
                stack.get_style_context ().add_class ("notejot-stack-dark");
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                titlebar.get_style_context ().remove_class ("notejot-tbar-dark");
                grid_view.flowgrid.get_style_context ().remove_class ("notejot-fgview-dark");
                stack.get_style_context ().remove_class ("notejot-stack-dark");
            }

            if (Notejot.Application.gsettings.get_boolean("pinned")) {
                menu.applet_switch.set_active (true);
                set_keep_below (Notejot.Application.gsettings.get_boolean("pinned"));
                stick ();
            } else {
                menu.applet_switch.set_active (false);
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    titlebar.get_style_context ().add_class ("notejot-tbar-dark");
                    grid_view.flowgrid.get_style_context ().add_class ("notejot-fgview-dark");
                    stack.get_style_context ().add_class ("notejot-stack-dark");
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    titlebar.get_style_context ().remove_class ("notejot-tbar-dark");
                    grid_view.flowgrid.get_style_context ().remove_class ("notejot-fgview-dark");
                    stack.get_style_context ().remove_class ("notejot-stack-dark");
                }

                if (Notejot.Application.gsettings.get_boolean("pinned")) {
                    menu.applet_switch.set_active (true);
                    set_keep_below (true);
                    stick ();
                } else {
                    menu.applet_switch.set_active (false);
                    set_keep_below (false);
                    unstick ();
                }
            });
        }

        construct {
            Hdy.init ();
            // Setting CSS
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/lainsce/notejot/app.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            // Ensure use of elementary theme and icons, accent color doesn't matter
            Gtk.Settings.get_default().set_property("gtk-theme-name", "io.elementary.stylesheet.blueberry");
            Gtk.Settings.get_default().set_property("gtk-icon-theme-name", "elementary");
            this.get_style_context ().add_class ("notejot-view");
            int x = Notejot.Application.gsettings.get_int("window-x");
            int y = Notejot.Application.gsettings.get_int("window-y");
            int w = Notejot.Application.gsettings.get_int("window-w");
            int h = Notejot.Application.gsettings.get_int("window-h");
            if (x != -1 && y != -1) {
                this.move (x, y);
            }
            this.resize (w, h);

            tm = new Services.TaskManager (this);

            // Main View
            titlebar = new Hdy.HeaderBar ();
            titlebar.set_size_request (-1, 45);
            var titlebar_c = titlebar.get_style_context ();
            titlebar_c.add_class ("notejot-tbar");
            titlebar_c.remove_class ("titlebar");
            titlebar.show_close_button = true;
            titlebar.has_subtitle = false;
            titlebar.hexpand = true;
            titlebar.title = "Notejot";

            new_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("New Note"))
            };
            new_button.get_style_context ().add_class ("notejot-button");
            titlebar.pack_start (new_button);

            new_button.clicked.connect (() => {
                add_task (_("New Note"), _("Write a New Note…"), "#FCF092", 0);
                if (stack.get_visible_child () == welcome_view) {
                    stack.set_visible_child (grid_view);
                }
            });

            format_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("font-x-generic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Formatting Options")),
                sensitive = false
            };
            format_button.get_style_context ().add_class ("notejot-button");
            titlebar.pack_start (format_button);

            // Grid View
            grid_view = new Views.GridView (this);

            // Sidebar
            sidebar = new Widgets.Sidebar (this);

            // Welcome View
            welcome_view = new Views.WelcomeView (this);

            stack = new Gtk.Stack ();
            stack.get_style_context ().add_class ("notejot-stack");
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add (welcome_view);
            stack.add (grid_view);

            menu = new Widgets.Menu (this);
            titlebar.pack_end (menu);

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (titlebar, 0, 0, 1, 1);
            grid.attach (stack, 0, 1, 1, 1);
            grid.show_all ();

            leaflet = new Hdy.Leaflet ();
            leaflet.add (sidebar);
            leaflet.add (grid);
            leaflet.transition_type = Hdy.LeafletTransitionType.UNDER;
            leaflet.show_all ();
            leaflet.can_swipe_back = true;
            leaflet.set_visible_child (grid);

            update ();

            leaflet.notify["folded"].connect (() => {
                update ();
            });

            tm.load_from_file ();

            if (grid_view.flowgrid.is_modified == false) {
                stack.set_visible_child (welcome_view);
            } else {
                stack.set_visible_child (grid_view);
            }

            this.add (leaflet);
            this.set_size_request (375, 600);
            this.show_all ();
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

        public void add_task (string title, string contents, string color, int uid) {
            var task = new Services.Task (this, title, contents, color, uid);
            var taskbox = new Widgets.TaskBox (this, task);
            grid_view.flowgrid.add (taskbox);
            grid_view.flowgrid.is_modified = true;
            tm.save_notes ();
        }

        private void update () {
            if (leaflet != null && leaflet.get_folded ()) {
                // On Mobile size, so.... have to have no buttons anywhere.
                sidebar.fauxtitlebar.set_decoration_layout (":");
                titlebar.set_decoration_layout (":");
            } else {
                // Else you're on Desktop size, so business as usual.
                sidebar.fauxtitlebar.set_decoration_layout ("close:");
                titlebar.set_decoration_layout (":maximize");
            }
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