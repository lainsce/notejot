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
        public Widgets.TextView textfield;
        public Widgets.EditableLabel editablelabel;
        public Widgets.Menu menu;
        public Widgets.Toolbar toolbar;
        public Gtk.Box note_view;
        public Gtk.Button new_button;
        public Gtk.Grid grid;
        public Gtk.Grid grid_view;
        public Gtk.Grid normal_view;
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
                editablelabel.get_style_context ().add_class ("notejot-tview-dark");
                textfield.get_style_context ().add_class ("notejot-tview-dark");
                flowgrid.get_style_context ().add_class ("notejot-fgview-dark");
                toolbar.toolbar.get_style_context ().add_class ("notejot-abar-dark");
                stack.get_style_context ().add_class ("notejot-stack-dark");
                textfield.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                titlebar.get_style_context ().remove_class ("notejot-tbar-dark");
                editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                toolbar.toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                textfield.get_style_context ().remove_class ("notejot-tview-dark");
                flowgrid.get_style_context ().remove_class ("notejot-fgview-dark");
                stack.get_style_context ().remove_class ("notejot-stack-dark");
                textfield.update_html_view ();
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
                    editablelabel.get_style_context ().add_class ("notejot-tview-dark");
                    textfield.get_style_context ().add_class ("notejot-tview-dark");
                    flowgrid.get_style_context ().add_class ("notejot-fgview-dark");
                    toolbar.toolbar.get_style_context ().add_class ("notejot-abar-dark");
                    stack.get_style_context ().add_class ("notejot-stack-dark");
                    textfield.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    titlebar.get_style_context ().remove_class ("notejot-tbar-dark");
                    editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                    toolbar.toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                    textfield.get_style_context ().remove_class ("notejot-tview-dark");
                    flowgrid.get_style_context ().remove_class ("notejot-fgview-dark");
                    stack.get_style_context ().remove_class ("notejot-stack-dark");
                    textfield.update_html_view ();
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
            tm.load_from_file ();

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
                add_task (_("New Note"), _("Write a New Note…"), "#FCF092");
                if (stack.get_visible_child () == normal_view) {
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

            format_button.toggled.connect (() => {
                if (Notejot.Application.gsettings.get_boolean ("show-formattingbar")) {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", false);
                    toolbar.reveal_child = false;
                } else {
                    Notejot.Application.gsettings.set_boolean ("show-formattingbar", true);
                    toolbar.reveal_child = true;
                }
                tm.save_notes ();
            });

            // Grid View
            flowgrid = new Widgets.FlowGrid (this);

            var flowgrid_scroller = new Gtk.ScrolledWindow (null, null);
            flowgrid_scroller.margin_top = 6;
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
            sidebar_header.label = _("VIEW");

            sidebar_categories = new Granite.Widgets.SourceList ();
            sidebar_categories.hexpand = false;
            sidebar_categories.margin_top = 4;
			sidebar_categories.margin_start = sidebar_categories.margin_end = 8;
            notes_category = new Granite.Widgets.SourceList.ExpandableItem ("");
            notes_category.markup = _("NOTES");
            notes_category.tooltip = _("Your notes will appear here.");
			notes_category.set_data("item-name", "projects");
			sidebar_categories.root.add(notes_category);
			sidebar_categories.root.expand_all();

            var sidebar_button = new Gtk.Button.with_label (_("Dashboard"));
            sidebar_button.image = new Gtk.Image.from_icon_name ("view-grid-symbolic", Gtk.IconSize.BUTTON);
            sidebar_button.always_show_image = true;
            sidebar_button.margin_start = sidebar_button.margin_end = 9;
            sidebar_button.tooltip_text = (_("Go Back to Notes Overview"));
            sidebar_button.get_style_context ().add_class ("notejot-side-button");

            sidebar_button.clicked.connect (() => {
                if (stack.get_visible_child () == note_view) {
                    stack.set_visible_child (grid_view);
                }
            });

            // Note View
            textfield = new Widgets.TextView (this);
            editablelabel = new Widgets.EditableLabel (this, "");

            editablelabel.changed.connect (() => {
                flowgrid.selected_foreach ((item, child) => {
                    ((Widgets.TaskBox)child.get_child ()).task_label.set_label(editablelabel.title.get_label ());
                    ((Widgets.TaskBox)child.get_child ()).sidebaritem.title = editablelabel.title.get_label ();
                    ((Widgets.TaskBox)child.get_child ()).title = editablelabel.title.get_label ();
                });
                tm.save_notes ();
            });

            toolbar = new Widgets.Toolbar (this);

            note_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            note_view.add (toolbar);
            note_view.add (editablelabel);
            note_view.add (textfield);

            // Welcome View
            var normal_icon = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.DND);
            var normal_label = new Gtk.Label (_("Start by adding some notes…"));
            var normal_label_context = normal_label.get_style_context ();
            normal_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            normal_label_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            normal_view = new Gtk.Grid ();
            normal_view.column_spacing = 12;
            normal_view.margin = 24;
            normal_view.expand = true;
            normal_view.halign = normal_view.valign = Gtk.Align.CENTER;
            normal_view.add (normal_icon);
            normal_view.add (normal_label);

            stack = new Gtk.Stack ();
            stack.get_style_context ().add_class ("notejot-stack");
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add (normal_view);
            stack.add (grid_view);
            stack.add (note_view);

            if (flowgrid.is_modified == false) {
                stack.set_visible_child (normal_view);
            } else {
                stack.set_visible_child (grid_view);
            }

            menu = new Widgets.Menu (this);
            titlebar.pack_end (menu);

            sgrid = new Gtk.Grid ();
            sgrid.orientation = Gtk.Orientation.VERTICAL;
            sgrid.get_style_context ().add_class ("notejot-column");
            sgrid.attach (fauxtitlebar, 0, 0, 1, 1);
            sgrid.attach (sidebar_header, 0, 1, 1, 1);
            sgrid.attach (sidebar_button, 0, 2, 1, 1);
            sgrid.attach (sidebar_categories, 0, 3, 1, 1);
            sgrid.show_all ();

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (titlebar, 0, 0, 1, 1);
            grid.attach (stack, 0, 1, 1, 1);
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

        public void add_task (string title, string contents, string color) {
            var taskbox = new Widgets.TaskBox (this, title, contents, color);
            flowgrid.add (taskbox);
            flowgrid.is_modified = true;
            tm.save_notes ();
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