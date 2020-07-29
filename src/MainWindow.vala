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
        public Views.ListView listview;
        public Views.GridView gridview;
        public Views.WelcomeView welcomeview;
        public Views.NoteView noteview;
        public Gtk.Box views_box;
        public Gtk.Button new_button;
        public Gtk.Grid grid;
        public Gtk.Grid sgrid;
        public Gtk.Separator separator;
        public Gtk.Stack stack;
        public Gtk.Switch mode_switch;
        public Gtk.Switch applet_switch;
        public Gtk.ToggleButton format_button;
        public Hdy.Leaflet leaflet;
        public Hdy.HeaderBar titlebar;
        public Hdy.HeaderBar fauxtitlebar;
        public Services.TaskManager tm;
        public Gtk.Application app { get; construct; }

        public Gee.ArrayList<Widgets.Note> main_list;

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
                mode_switch.sensitive = false;
            } else if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                Notejot.Application.gsettings.set_boolean("dark-mode", false);
                mode_switch.sensitive = true;
            }

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                    Notejot.Application.gsettings.set_boolean("dark-mode", true);
                    mode_switch.sensitive = false;
                } else if (Notejot.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                    Notejot.Application.gsettings.set_boolean("dark-mode", false);
                    mode_switch.sensitive = true;
                }
            });

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                titlebar.get_style_context ().add_class ("notejot-tbar-dark");
                noteview.editablelabel.get_style_context ().add_class ("notejot-tview-dark");
                noteview.textfield.get_style_context ().add_class ("notejot-tview-dark");
                listview.get_style_context ().add_class ("notejot-lview-dark");
                noteview.toolbar.get_style_context ().add_class ("notejot-abar-dark");
                stack.get_style_context ().add_class ("notejot-stack-dark");
                noteview.textfield.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                titlebar.get_style_context ().remove_class ("notejot-tbar-dark");
                noteview.editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                noteview.toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                noteview.textfield.get_style_context ().remove_class ("notejot-tview-dark");
                listview.get_style_context ().remove_class ("notejot-lview-dark");
                stack.get_style_context ().remove_class ("notejot-stack-dark");
                noteview.textfield.update_html_view ();
            }

            if (Notejot.Application.gsettings.get_boolean("pinned")) {
                applet_switch.set_active (true);
                set_keep_below (Notejot.Application.gsettings.get_boolean("pinned"));
                stick ();
            } else {
                applet_switch.set_active (false);
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    titlebar.get_style_context ().add_class ("notejot-tbar-dark");
                    noteview.editablelabel.get_style_context ().add_class ("notejot-tview-dark");
                    noteview.textfield.get_style_context ().add_class ("notejot-tview-dark");
                    listview.get_style_context ().add_class ("notejot-lview-dark");
                    noteview.toolbar.get_style_context ().add_class ("notejot-abar-dark");
                    stack.get_style_context ().add_class ("notejot-stack-dark");
                    noteview.textfield.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    titlebar.get_style_context ().remove_class ("notejot-tbar-dark");
                    noteview.editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                    noteview.toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                    noteview.textfield.get_style_context ().remove_class ("notejot-tview-dark");
                    listview.get_style_context ().remove_class ("notejot-lview-dark");
                    stack.get_style_context ().remove_class ("notejot-stack-dark");
                    noteview.textfield.update_html_view ();
                }

                if (Notejot.Application.gsettings.get_boolean("pinned")) {
                    applet_switch.set_active (true);
                    set_keep_below (true);
                    stick ();
                } else {
                    applet_switch.set_active (false);
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

            tm = new Services.TaskManager (this);

            int x = Notejot.Application.gsettings.get_int("window-x");
            int y = Notejot.Application.gsettings.get_int("window-y");
            int w = Notejot.Application.gsettings.get_int("window-w");
            int h = Notejot.Application.gsettings.get_int("window-h");
            if (x != -1 && y != -1) {
                this.move (x, y);
            }
            this.resize (w, h);

            titlebar = new Hdy.HeaderBar () {
                show_close_button = true,
                has_subtitle = false,
                hexpand = true,
                title = "Notejot"
            };
            titlebar.set_size_request (-1, 45);
            titlebar.get_style_context ().add_class ("notejot-tbar");
            titlebar.get_style_context ().remove_class ("titlebar");

            fauxtitlebar = new Hdy.HeaderBar () {
                show_close_button = true,
                has_subtitle = false
            };
            fauxtitlebar.set_size_request (200, 45);
            fauxtitlebar.get_style_context ().add_class ("notejot-side-tbar");
            fauxtitlebar.get_style_context ().remove_class ("titlebar");

            new_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("New Note"))
            };
            new_button.get_style_context ().add_class ("notejot-button");
            titlebar.pack_start (new_button);

            format_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("font-x-generic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Formatting Options"))
            };
            format_button.get_style_context ().add_class ("notejot-button");

            // Column
            var sidebar_header = new Gtk.Label (null) {
                tooltip_text = _("Your notes will appear here."),
                use_markup = true,
                halign = Gtk.Align.START,
                margin_start = 15,
                margin_top = 6,
                label = _("VIEWS")
            };
            sidebar_header.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            //

            tm.load_from_file ();

            listview = new Views.ListView (this);
            gridview = new Views.GridView (this);
            noteview = new Views.NoteView (this);
            welcomeview = new Views.WelcomeView (this);

            stack = new Gtk.Stack ();
            stack.get_style_context ().add_class ("notejot-stack");
            stack.add (welcomeview);
            stack.add (listview);
            stack.add (gridview);
            stack.add (noteview);

            var alabel = new Gtk.Label (_("Pin To Desktop:"));
            applet_switch = new Gtk.Switch () {
                valign = Gtk.Align.CENTER,
                has_focus = false
            };
            Notejot.Application.gsettings.bind ("pinned", applet_switch, "active", SettingsBindFlags.DEFAULT);

            var applet_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                margin_start = 12
            };
            applet_box.add (alabel);
            applet_box.add (applet_switch);

            var interface_header = new Granite.HeaderLabel (_("Interface"));
            var dlabel = new Gtk.Label (_("Dark Mode:"));
            mode_switch = new Gtk.Switch () {
                valign = Gtk.Align.CENTER,
                has_focus = false
            };
            Notejot.Application.gsettings.bind ("dark-mode", mode_switch, "active", SettingsBindFlags.DEFAULT);

            var dark_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                margin_start = 12
            };
            dark_box.add (dlabel);
            dark_box.add (mode_switch);

            var menu_grid = new Gtk.Grid () {
                margin = 12,
                row_spacing = 6,
                column_spacing = 6,
                orientation = Gtk.Orientation.VERTICAL
            };
            menu_grid.attach (interface_header, 0, 0, 1, 1);
            menu_grid.attach (dark_box, 0, 1, 1, 1);
            menu_grid.attach (applet_box, 0, 2, 1, 1);
            menu_grid.show_all ();

            var popover = new Gtk.Popover (null);
            popover.add (menu_grid);

            var menu_button = new Gtk.MenuButton () {
                image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Settings")),
                popover = popover
            };
            titlebar.pack_end (menu_button);

            var grid_view_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("view-grid-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Formatting Options"))
            };
            grid_view_button.get_style_context ().add_class ("notejot-button");

            var list_view_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Formatting Options"))
            };
            list_view_button.get_style_context ().add_class ("notejot-button");

            views_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            views_box.pack_start (grid_view_button);
            views_box.pack_start (list_view_button);

            list_view_button.clicked.connect (() => {
                stack.set_visible_child (listview);
            });
            grid_view_button.clicked.connect (() => {
                stack.set_visible_child (gridview);
            });
            titlebar.pack_end (views_box);

            sgrid = new Gtk.Grid () {
                orientation = Gtk.Orientation.VERTICAL
            };
            sgrid.get_style_context ().add_class ("notejot-column");
            sgrid.attach (fauxtitlebar, 0, 0, 1, 1);
            sgrid.attach (sidebar_header, 0, 1, 1, 1);

            grid = new Gtk.Grid () {
                orientation = Gtk.Orientation.VERTICAL
            };
            grid.attach (titlebar, 0, 0, 1, 1);
            grid.attach (stack, 0, 1, 1, 1);

            separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

            update ();

            leaflet = new Hdy.Leaflet () {
                transition_type = Hdy.LeafletTransitionType.UNDER,
                can_swipe_back = true
            };
            leaflet.add (sgrid);
            leaflet.add (separator);
            leaflet.add (grid);
            leaflet.set_visible_child (grid);
            leaflet.child_set_property (separator, "allow-visible", false);

            leaflet.notify["folded"].connect (() => {
                update ();
            });

            new_button.clicked.connect (() => {
                add_task (_("New Note"), _("Write a New Note…"), "#FFE16B");
                welcomeview.visible = false;
            });

            this.add (leaflet);
            this.set_size_request (300, 500);
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

        public void add_task (string title, string contents, string color) {
            var task = new Widgets.Note (this, title, contents, color);

            if (stack.visible_child == listview) {
                widget_unparent (task);
                var taskbox = new Gtk.ListBoxRow ();
                taskbox.add (task);
                listview.column.insert (taskbox, 1);
                            
                if (main_list != null) {
                    main_list.insert (1, task);
                }
            }
            if (stack.visible_child == gridview)  {
                widget_unparent (task);
                gridview.grid.add (task);
                            
                if (main_list != null) {
                    main_list.insert (1, task);
                }
            }
            
            tm.save_notes ();
            format_button.visible = false;
            new_button.visible = true;
        }

        private static void widget_unparent (Gtk.Widget widget) {
            unowned Gtk.Container? parent = widget.get_parent ();
            if (parent == null) {
                return;
            }

            parent.remove (widget);
        }

        private void update () {
            if (leaflet != null && leaflet.get_folded ()) {
                // On Mobile size, so.... have to have no buttons anywhere.
                fauxtitlebar.set_decoration_layout (":");
                titlebar.set_decoration_layout (":");
            } else {
                // Else you're on Desktop size, so business as usual.
                fauxtitlebar.set_decoration_layout ("close:");
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