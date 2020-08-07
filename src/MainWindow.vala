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
        public Widgets.FlowGrid flowgrid;
        public Widgets.FlowList flowlist;
        public Widgets.Menu menu;
        public Gtk.Button new_button;
        public Gtk.Grid grid;
        public Gtk.Grid grid_view;
        public Gtk.Grid list_view;
        public Gtk.Grid welcome_view;
        public Gtk.Grid sgrid;
        public Gtk.Separator separator;
        public Gtk.Stack stack;
        public Gtk.ToggleButton format_button;
        public Granite.Widgets.SourceList sidebar_categories;
        public Granite.Widgets.SourceList.ExpandableItem notes_category;
        public Hdy.HeaderBar fauxtitlebar;
        public Hdy.HeaderBar titlebar;
        public Hdy.Leaflet leaflet;
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

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                stack.get_style_context ().add_class ("notejot-stack-dark");
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                stack.get_style_context ().remove_class ("notejot-stack-dark");
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    stack.get_style_context ().add_class ("notejot-stack-dark");
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    stack.get_style_context ().remove_class ("notejot-stack-dark");
                }
            });

            Notejot.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    stack.get_style_context ().add_class ("notejot-stack-dark");
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    stack.get_style_context ().remove_class ("notejot-stack-dark");
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
            titlebar.valign = Gtk.Align.START;
            titlebar.title = "Notejot";

            new_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("New Note"))
            };
            new_button.get_style_context ().add_class ("notejot-button");
            titlebar.pack_start (new_button);

            // Grid View
            flowgrid = new Widgets.FlowGrid (this);

            new_button.clicked.connect (() => {
                flowgrid.new_taskbox (this, "New Note", "Write a new note…", "#FCF092");
                if (Notejot.Application.gsettings.get_string("last-view") == "grid") {
                    stack.set_visible_child (grid_view);
                } else if (Notejot.Application.gsettings.get_string("last-view") == "list") {
                    stack.set_visible_child (list_view);
                }
            });

            var flowgrid_scroller = new Gtk.ScrolledWindow (null, null);
            flowgrid_scroller.add (flowgrid);

            grid_view = new Gtk.Grid ();
            grid_view.add (flowgrid_scroller);

            // Sidebar
            fauxtitlebar = new Hdy.HeaderBar ();
            fauxtitlebar.set_size_request (199, 45);
            var fauxtitlebar_c = fauxtitlebar.get_style_context ();
            fauxtitlebar_c.add_class ("notejot-side-tbar");
            fauxtitlebar_c.remove_class ("titlebar");
            fauxtitlebar.show_close_button = true;
            fauxtitlebar.has_subtitle = false;

            var sidebar_header = new Gtk.Label (null);
            sidebar_header.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            sidebar_header.use_markup = true;
            sidebar_header.halign = Gtk.Align.START;
            sidebar_header.margin_start = 15;
            sidebar_header.margin_top = 6;
            sidebar_header.label = _("VIEWS");

            sidebar_categories = new Granite.Widgets.SourceList ();
            sidebar_categories.hexpand = false;
            sidebar_categories.margin_top = 4;
			sidebar_categories.margin_start = sidebar_categories.margin_end = 8;
            notes_category = new Granite.Widgets.SourceList.ExpandableItem ("");
            notes_category.collapsible = false;
            notes_category.markup = _("NOTES");
            notes_category.tooltip = _("Your notes will appear here.");
            notes_category.set_data("item-name", "projects");
			sidebar_categories.root.add(notes_category);
            sidebar_categories.root.expand_all();
            sidebar_categories.opacity = 0.8;

            var sidebar_button_grid = new Gtk.Button.with_label (_("Grid"));
            sidebar_button_grid.image = new Gtk.Image.from_icon_name ("view-grid-symbolic", Gtk.IconSize.BUTTON);
            sidebar_button_grid.always_show_image = true;
            sidebar_button_grid.tooltip_text = (_("Go Back to Notes Grid"));
            sidebar_button_grid.get_style_context ().add_class ("notejot-side-button");

            sidebar_button_grid.clicked.connect (() => {
                stack.set_visible_child (grid_view);
                Notejot.Application.gsettings.set_string("last-view", "grid");
            });

            var sidebar_button_list = new Gtk.Button.with_label (_("List "));
            sidebar_button_list.image = new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.BUTTON);
            sidebar_button_list.always_show_image = true;
            sidebar_button_list.tooltip_text = (_("Go Back to Notes List"));
            sidebar_button_list.get_style_context ().add_class ("notejot-side-button");

            sidebar_button_list.clicked.connect (() => {
                stack.set_visible_child (list_view);
                Notejot.Application.gsettings.set_string("last-view", "list");
            });

            var sidebar_button_holder = new Gtk.Grid ();
            sidebar_button_holder.orientation = Gtk.Orientation.VERTICAL;
            sidebar_button_holder.margin_start = sidebar_button_holder.margin_end = 12;
            sidebar_button_holder.add (sidebar_button_grid);
            sidebar_button_holder.add (sidebar_button_list);

            // Welcome View
            var normal_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DND);
            var normal_label = new Gtk.Label (_("Start by adding some notes…"));
            var normal_label_context = normal_label.get_style_context ();
            normal_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            normal_label_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            welcome_view = new Gtk.Grid ();
            welcome_view.column_spacing = 12;
            welcome_view.margin = 24;
            welcome_view.expand = true;
            welcome_view.halign = welcome_view.valign = Gtk.Align.CENTER;
            welcome_view.add (normal_icon);
            welcome_view.add (normal_label);

            // List View
            flowlist = new Widgets.FlowList (this);

            var flowlist_scroller = new Gtk.ScrolledWindow (null, null);
            flowlist_scroller.add (flowlist);

            list_view = new Gtk.Grid ();
            list_view.add (flowlist_scroller);

            stack = new Gtk.Stack ();
            stack.get_style_context ().add_class ("notejot-stack");
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add (welcome_view);
            stack.add (grid_view);
            stack.add (list_view);

            menu = new Widgets.Menu (this);
            titlebar.pack_end (menu);

            sgrid = new Gtk.Grid ();
            sgrid.orientation = Gtk.Orientation.VERTICAL;
            sgrid.get_style_context ().add_class ("notejot-column");
            sgrid.attach (fauxtitlebar, 0, 0, 1, 1);
            sgrid.attach (sidebar_header, 0, 1, 1, 1);
            sgrid.attach (sidebar_button_holder, 0, 2, 1, 1);
            sgrid.attach (sidebar_categories, 0, 4, 1, 1);
            sgrid.show_all ();

            var overlay = new Gtk.Overlay ();
            overlay.add_overlay (titlebar);
            overlay.add (stack);

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (overlay, 0, 0, 1, 1);
            grid.show_all ();

            leaflet = new Hdy.Leaflet ();
            leaflet.add (sgrid);
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

            if (flowgrid.is_modified == false) {
                stack.set_visible_child (welcome_view);
            } else {
                if (Notejot.Application.gsettings.get_string("last-view") == "grid") {
                    stack.set_visible_child (grid_view);
                    sidebar_button_grid.is_focus = true;
                    sidebar_button_list.is_focus = false;
                } else if (Notejot.Application.gsettings.get_string("last-view") == "list") {
                    stack.set_visible_child (list_view);
                    sidebar_button_list.is_focus = true;
                    sidebar_button_grid.is_focus = false;
                }
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