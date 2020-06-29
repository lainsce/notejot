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
        public Widgets.TextView textview;
        public Widgets.EditableLabel editablelabel;
        public Gtk.Grid grid;
        public Gtk.Grid sgrid;
        public Gtk.Box note_view;
        public Gtk.Grid normal_view;
        public Gtk.Separator separator;
        public Gtk.Stack stack;
        public Hdy.Leaflet leaflet;
        public Hdy.HeaderBar titlebar;
        public Hdy.HeaderBar fauxtitlebar;
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
            titlebar_c.add_class (Gtk.STYLE_CLASS_FLAT);
            titlebar.show_close_button = true;
            titlebar.has_subtitle = false;
            titlebar.hexpand = true;
            set_title (titlebar.title);
            titlebar.title = "Notejot";

            fauxtitlebar = new Hdy.HeaderBar ();
            fauxtitlebar.set_size_request (199, 45);
            var fauxtitlebar_c = fauxtitlebar.get_style_context ();
            fauxtitlebar_c.add_class ("notejot-side-tbar");
            fauxtitlebar_c.add_class (Gtk.STYLE_CLASS_FLAT);
            fauxtitlebar.show_close_button = true;
            fauxtitlebar.has_subtitle = false;

            var applet_button = new Gtk.ToggleButton ();
            applet_button.tooltip_text = (_("Pin to Desktop"));
            applet_button.get_style_context ().add_class ("notejot-button");
            var applet_button_image = new Gtk.Image.from_icon_name ("view-pin-symbolic", Gtk.IconSize.BUTTON);
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

            titlebar.pack_end (applet_button);

            var new_button = new Gtk.Button ();
            new_button.set_image (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON));
            new_button.has_tooltip = true;
            new_button.tooltip_text = (_("New Note"));
            titlebar.pack_start (new_button);
            new_button.get_style_context ().add_class ("notejot-button");

            var clear_all_button = new Gtk.Button ();
            clear_all_button.set_image (new Gtk.Image.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.BUTTON));
            clear_all_button.has_tooltip = true;
            clear_all_button.tooltip_text = (_("Clear Notes"));
            titlebar.pack_start (clear_all_button);
            clear_all_button.get_style_context ().add_class ("notejot-button");

            // Column
            column = new Widgets.Column (this);

            var column_scroller = new Gtk.ScrolledWindow (null, null);
            column_scroller.add (column);


            var column_label = new Gtk.Label (null);
            column_label.tooltip_text = _("Your notes will appear here.");
            column_label.use_markup = true;
            column_label.halign = Gtk.Align.START;
            column_label.margin_start = 15;
            column_label.margin_top = 6;
            string label = _("NOTES");
            column_label.label = "<span weight=\"bold\">%s</span>".printf(label);

            tm.load_from_file ();

            textview = new Widgets.TextView (this);

            editablelabel = new Widgets.EditableLabel (this, "");

            note_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
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

            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add (normal_view);
            stack.add (note_view);

            if (column.is_modified == false) {
                normal_view.visible = true;
                note_view.visible = false;
            } else {
                normal_view.visible = false;
                note_view.visible = true;
            }

            sgrid = new Gtk.Grid ();
            sgrid.orientation = Gtk.Orientation.VERTICAL;
            sgrid.get_style_context ().add_class ("notejot-column");
            sgrid.attach (fauxtitlebar, 0, 0, 1, 1);
            sgrid.attach (column_label, 0, 1, 1, 1);
            sgrid.attach (column_scroller, 0, 2, 1, 1);
            sgrid.show_all ();

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (titlebar, 0, 0, 1, 1);
            grid.attach (stack, 0, 1, 1, 1);
            grid.show_all ();

            separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            var separator_cx = separator.get_style_context ();
            separator_cx.add_class ("vsep");

            update ();

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

            new_button.clicked.connect (() => {
                column.add_task (_("New Note"), _("Write a New Note…"), "#FFE16B");
                note_view.visible = true;
                normal_view.visible = false;
            });

            clear_all_button.clicked.connect (() => {
                column.clear_column ();
                normal_view.visible = true;
                note_view.visible = false;
                tm.save_notes ();
            });

            editablelabel.changed.connect (() => {
                (((Widgets.TaskBox)column.get_selected_row ())).title = editablelabel.text;
                tm.save_notes ();
            });

            textview.buffer.changed.connect (() => {
                (((Widgets.TaskBox)column.get_selected_row ())).contents = textview.text;
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

