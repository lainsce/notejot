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
        public Widgets.FlowGrid flowgrid;
        public Widgets.TextView textview;
        public Widgets.EditableLabel editablelabel;
        public Widgets.Menu menu;
        public Gtk.Box note_view;
        public Gtk.Box views_box;
        public Gtk.Button new_button;
        public Gtk.Button return_button;
        public Gtk.Grid grid;
        public Gtk.Grid grid_view;
        public Gtk.Grid list_view;
        public Gtk.Grid normal_view;
        public Gtk.Grid sgrid;
        public Gtk.Revealer toolbar;
        public Gtk.Separator separator;
        public Gtk.Stack stack;
        public Gtk.ToggleButton format_button;
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
                textview.get_style_context ().add_class ("notejot-tview-dark");
                column.get_style_context ().add_class ("notejot-lview-dark");
                flowgrid.get_style_context ().add_class ("notejot-lview-dark");
                toolbar.get_style_context ().add_class ("notejot-abar-dark");
                stack.get_style_context ().add_class ("notejot-stack-dark");
                textview.update_html_view ();
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                titlebar.get_style_context ().remove_class ("notejot-tbar-dark");
                editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                textview.get_style_context ().remove_class ("notejot-tview-dark");
                flowgrid.get_style_context ().remove_class ("notejot-lview-dark");
                column.get_style_context ().remove_class ("notejot-lview-dark");
                stack.get_style_context ().remove_class ("notejot-stack-dark");
                textview.update_html_view ();
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
                    textview.get_style_context ().add_class ("notejot-tview-dark");
                    column.get_style_context ().add_class ("notejot-lview-dark");
                    flowgrid.get_style_context ().add_class ("notejot-lview-dark");
                    toolbar.get_style_context ().add_class ("notejot-abar-dark");
                    stack.get_style_context ().add_class ("notejot-stack-dark");
                    textview.update_html_view ();
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    titlebar.get_style_context ().remove_class ("notejot-tbar-dark");
                    editablelabel.get_style_context ().remove_class ("notejot-tview-dark");
                    toolbar.get_style_context ().remove_class ("notejot-abar-dark");
                    textview.get_style_context ().remove_class ("notejot-tview-dark");
                    flowgrid.get_style_context ().remove_class ("notejot-lview-dark");
                    column.get_style_context ().remove_class ("notejot-lview-dark");
                    stack.get_style_context ().remove_class ("notejot-stack-dark");
                    textview.update_html_view ();
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

            tm = new Services.TaskManager (this);

            int x = Notejot.Application.gsettings.get_int("window-x");
            int y = Notejot.Application.gsettings.get_int("window-y");
            int w = Notejot.Application.gsettings.get_int("window-w");
            int h = Notejot.Application.gsettings.get_int("window-h");
            if (x != -1 && y != -1) {
                this.move (x, y);
            }
            this.resize (w, h);

            titlebar = new Hdy.HeaderBar ();
            titlebar.set_size_request (-1, 45);
            var titlebar_c = titlebar.get_style_context ();
            titlebar_c.add_class ("notejot-tbar");
            titlebar_c.remove_class ("titlebar");
            titlebar.show_close_button = true;
            titlebar.has_subtitle = false;
            titlebar.hexpand = true;
            titlebar.title = "Notejot";

            fauxtitlebar = new Hdy.HeaderBar ();
            fauxtitlebar.set_size_request (199, 45);
            var fauxtitlebar_c = fauxtitlebar.get_style_context ();
            fauxtitlebar_c.add_class ("notejot-side-tbar");
            fauxtitlebar_c.remove_class ("titlebar");
            fauxtitlebar.show_close_button = true;
            fauxtitlebar.has_subtitle = false;

            new_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("New Note"))
            };
            new_button.get_style_context ().add_class ("notejot-button");
            titlebar.pack_start (new_button);

            format_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("font-x-generic-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Formatting Options")),
                sensitive = false
            };
            format_button.get_style_context ().add_class ("notejot-button");
            titlebar.pack_start (format_button);

            var grid_view_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("view-grid-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("View as Grid"))
            };
            grid_view_button.get_style_context ().add_class ("notejot-button");

            var list_view_button = new Gtk.ToggleButton () {
                image = new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("View as List"))
            };
            list_view_button.get_style_context ().add_class ("notejot-button");

            views_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            views_box.sensitive = false;
            views_box.pack_start (grid_view_button);
            views_box.pack_start (list_view_button);

            list_view_button.clicked.connect (() => {
                stack.set_visible_child (list_view);
                format_button.sensitive = false;
            });
            grid_view_button.clicked.connect (() => {
                stack.set_visible_child (grid_view);
                format_button.sensitive = false;
            });

            // Back button
            return_button = new Gtk.Button ();
            return_button.get_style_context ().add_class ("notejot-back-button");
            fauxtitlebar.pack_start (return_button);
            return_button.no_show_all = true;

            // List
            column = new Widgets.Column (this);

            var column_scroller = new Gtk.ScrolledWindow (null, null);
            column_scroller.margin_top = 6;
            column_scroller.add (column);

            // Grid
            flowgrid = new Widgets.FlowGrid (this);

            var flowgrid_scroller = new Gtk.ScrolledWindow (null, null);
            flowgrid_scroller.margin_top = 6;
            flowgrid_scroller.add (flowgrid);

            // Sidebar
            var sidebar_header = new Gtk.Label (null);
            sidebar_header.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            sidebar_header.tooltip_text = _("Your notes will appear here.");
            sidebar_header.use_markup = true;
            sidebar_header.halign = Gtk.Align.START;
            sidebar_header.margin_start = 15;
            sidebar_header.margin_top = 6;
            sidebar_header.label = _("NOTES");

            tm.load_from_file ();

            // Note
            textview = new Widgets.TextView (this);
            editablelabel = new Widgets.EditableLabel (this, "");

            // Toolbar with Note formatting options
            toolbar = new Widgets.Toolbar (this);

            note_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            note_view.add (toolbar);
            note_view.add (editablelabel);
            note_view.add (textview);

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

            list_view = new Gtk.Grid ();
            list_view.margin = 6;
            list_view.add (column_scroller);

            grid_view = new Gtk.Grid ();
            grid_view.margin = 6;
            grid_view.add (flowgrid_scroller);

            stack = new Gtk.Stack ();
            stack.get_style_context ().add_class ("notejot-stack");
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add (normal_view);
            stack.add (list_view);
            stack.add (grid_view);
            stack.add (note_view);

            menu = new Widgets.Menu (this);

            titlebar.pack_end (menu);
            titlebar.pack_end (views_box);

            sgrid = new Gtk.Grid ();
            sgrid.orientation = Gtk.Orientation.VERTICAL;
            sgrid.get_style_context ().add_class ("notejot-column");
            sgrid.attach (fauxtitlebar, 0, 0, 1, 1);
            sgrid.attach (sidebar_header, 0, 1, 1, 1);
            sgrid.show_all ();

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (titlebar, 0, 0, 1, 1);
            grid.attach (stack, 0, 1, 1, 1);
            grid.show_all ();

            separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

            update ();

            if (column.is_modified == false) {
                stack.set_visible_child (normal_view);
            } else {
                stack.set_visible_child (list_view);
                views_box.sensitive = true;
            }

            leaflet = new Hdy.Leaflet ();
            leaflet.add (sgrid);
            leaflet.add (separator);
            leaflet.add (grid);
            leaflet.transition_type = Hdy.LeafletTransitionType.UNDER;
            leaflet.show_all ();
            leaflet.can_swipe_back = true;
            leaflet.set_visible_child (grid);

            leaflet.child_set_property (separator, "allow-visible", false);

            leaflet.notify["folded"].connect (() => {
                update ();
            });

            new_button.clicked.connect (() => {
                add_task (_("New Note"), _("Write a New Note…"), "#FFE16B");
                if (stack.get_visible_child () == normal_view) {
                    stack.set_visible_child (list_view);
                }
                views_box.sensitive = true;
            });

            return_button.clicked.connect (() => {
                if (stack.get_visible_child () == note_view) {
                    stack.set_visible_child (list_view);
                }
                views_box.sensitive = true;
                return_button.visible = false;
            });

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

            editablelabel.changed.connect (() => {
                (((Widgets.TaskBox)column.get_selected_row ())).task_label.set_label(editablelabel.title.get_label ());
                (((Widgets.TaskBox)column.get_selected_row ())).title = editablelabel.title.get_label ();
                tm.save_notes ();
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
            if (stack.get_visible_child () == list_view) {
                var task = new Widgets.TaskBox (this, title, contents, color, false);
                column.insert (task, 1);
                task.get_parent ().get_style_context ().add_class ("notejot-note-list");
                column.is_modified = true;
                tm.save_notes ();
            }
            if (stack.get_visible_child () == grid_view) {
                var taskbox = new Widgets.TaskBox (this, title, contents, color, true);
                flowgrid.add (taskbox);
                tm.save_notes ();
            }
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