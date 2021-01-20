/*
* Copyright (c) 2017-2021 Lains
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
    public class MainWindow : Hdy.ApplicationWindow {
        delegate void HookFunc ();
        // Widgets
        public Gtk.Button new_button;
        public Gtk.Button welcome_new_button;
        public Gtk.ToggleButton pin_button;
        public Gtk.Grid grid;
        public Gtk.Grid welcome_view;
        public Gtk.Grid sgrid;
        public Gtk.Grid grid_box;
        public Gtk.Grid list_box;
        public Gtk.Overlay overlay;
        public Gtk.Separator separator;
        public Gtk.Stack stack;
        public Gtk.Stack main_stack;
        public Gtk.Stack titlebar_stack;
        public Gtk.ToggleButton format_button;
        public Gtk.ListBox sidebar_categories;
        public Hdy.HeaderBar fauxtitlebar;
        public Hdy.HeaderBar titlebar;
        public Hdy.HeaderBar welcome_titlebar;
        public Hdy.Leaflet leaflet;
        public Widgets.Dialog dialog = null;

        // Views
        public Views.GridView gridview;
        public Views.ListView listview;
        public Views.TrashView trashview;

        // Services
        public TaskManager tm;

        // Etc
        public bool pinned = false;

        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_ABOUT = "action_about";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
            { ACTION_ABOUT, action_about }
        };

        public Gtk.Application app { get; construct; }
        public MainWindow (Gtk.Application application) {
            GLib.Object (
                application: application,
                app: application,
                icon_name: "io.github.lainsce.Notejot",
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
            Hdy.init ();
            // Setting CSS
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/github/lainsce/Notejot/app.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            this.get_style_context ().add_class ("notejot-view");
            int x = Notejot.Application.gsettings.get_int("window-x");
            int y = Notejot.Application.gsettings.get_int("window-y");
            int w = Notejot.Application.gsettings.get_int("window-w");
            int h = Notejot.Application.gsettings.get_int("window-h");
            if (x != -1 && y != -1) {
                this.move (x, y);
            }
            this.resize (w, h);
            tm = new TaskManager (this);

            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            foreach (var action in action_accelerators.get_keys ()) {
                var accels_array = action_accelerators[action].to_array ();
                accels_array += null;

                app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
            }

            // Main View
            titlebar = new Hdy.HeaderBar ();
            titlebar.set_size_request (-1, 38);
            var titlebar_c = titlebar.get_style_context ();
            titlebar_c.add_class ("notejot-tbar");
            titlebar.show_close_button = true;
            titlebar.has_subtitle = false;
            titlebar.hexpand = true;
            titlebar.valign = Gtk.Align.START;

            new_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Create a new note"))
            };

            new_button.clicked.connect (() => {
                on_create_new ();
            });

            titlebar.pack_start (new_button);

            var about_button = new Gtk.ModelButton ();
            about_button.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_ABOUT;
            about_button.text = _("About Notejot");

            about_button.clicked.connect (() => {
                action_about ();
            });

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.attach (about_button, 0, 0);
            menu_grid.show_all ();

            var menu = new Gtk.Popover (null);
            menu.add (menu_grid);

            var menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON));
            menu_button.tooltip_text = (_("Settings"));
            menu_button.popover = menu;

            titlebar.pack_end (menu_button);

            // Sidebar
            sidebar_categories = new Gtk.ListBox ();
            sidebar_categories.get_style_context ().add_class ("notejot-sidecat");

            var sidebar_categories_holder = new Gtk.ScrolledWindow (null, null);
            sidebar_categories_holder.set_size_request (200, -1);
            sidebar_categories_holder.add (sidebar_categories);
            sidebar_categories_holder.vexpand = true;

            var sidebar = new Gtk.Grid ();
            sidebar.set_size_request (200, -1);
            sidebar.orientation = Gtk.Orientation.VERTICAL;
            sidebar.get_style_context ().add_class ("notejot-column");
            sidebar.attach (sidebar_categories_holder, 0, 0, 1, 1);
            sidebar.show_all ();

            // Welcome View

            // Used so the welcome titlebar, which is flat, and with no buttons
            // doesn't jump in size when transtitioning to the preview titlebar.
            var dummy_welcome_title_button = new Gtk.Button ();
            dummy_welcome_title_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            dummy_welcome_title_button.sensitive = false;

            welcome_titlebar = new Hdy.HeaderBar ();
            welcome_titlebar.show_close_button = true;
            welcome_titlebar.has_subtitle = false;
            welcome_titlebar.title = "Notejot";
            welcome_titlebar.valign = Gtk.Align.START;

            welcome_titlebar.pack_start (dummy_welcome_title_button);

            titlebar_stack = new Gtk.Stack ();
            titlebar_stack.valign = Gtk.Align.START;
            titlebar_stack.set_transition_type (Gtk.StackTransitionType.CROSSFADE);
            titlebar_stack.add_named (welcome_titlebar, "welcome-title");
            titlebar_stack.add_named (titlebar, "title");

            var welcome_title = new Gtk.Label (_("Jot some Notes"));
            welcome_title.get_style_context ().add_class ("title-1");
            welcome_title.margin_bottom = 24;

            var welcome_image = new Gtk.Image.from_resource ("/io/github/lainsce/Notejot/welcome.png");
            welcome_image.margin_bottom = 24;

            welcome_new_button = new Gtk.Button ();
            welcome_new_button.set_label (_("New Note"));
            welcome_new_button.get_style_context ().add_class ("suggested-action");
            welcome_new_button.get_style_context ().add_class ("circular-button");
            welcome_new_button.clicked.connect (() => {
                on_create_new ();
            });

            welcome_view = new Gtk.Grid () {
              expand = true,
              orientation = Gtk.Orientation.VERTICAL,
              halign = Gtk.Align.CENTER,
              valign = Gtk.Align.CENTER,
              row_spacing = 12
            };
            welcome_view.attach (welcome_title, 0, 0);
            welcome_view.attach (welcome_image, 0, 1);
            welcome_view.attach (welcome_new_button, 0, 2);

            // Grid View
            gridview = new Views.GridView (this);

            var grid_scroller = new Gtk.ScrolledWindow (null, null);
            grid_scroller.add (gridview);

            grid_box = new Gtk.Grid ();
            grid_box.add (grid_scroller);

            // List View
            listview = new Views.ListView (this);

            var list_scroller = new Gtk.ScrolledWindow (null, null);
            list_scroller.add (listview);

            list_box = new Gtk.Grid ();
            list_box.add (list_scroller);

            // Trash View
            trashview = new Views.TrashView (this);

            var trash_scroller = new Gtk.ScrolledWindow (null, null);
            trash_scroller.add (trashview);

            var trash_bar = new Gtk.ActionBar ();
            trash_bar.get_style_context ().add_class ("notejot-abar");
            var trash_button = new Gtk.Button () {
                label = _("Empty Trash…"),
                image = new Gtk.Image.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON),
                always_show_image = true
            };
            trash_button.clicked.connect (() => {
                dialog = new Widgets.Dialog (this,
                                             _("Empty the Trashed Notes?"),
                                             _("Emptying the trash means all the notes in it will be permanently lost with no recovery."),
                                             "dialog-warning-symbolic",
                                             _("Cancel"),
                                             _("Empty Trash"));
                if (dialog != null) {
                    dialog.present ();
                    return;
                } else {
                    dialog.run ();
                }
            });
            trash_button.get_style_context ().add_class ("notejot-abutton");
            trash_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            trash_bar.pack_end (trash_button);

            var trash_box = new Gtk.Grid ();
            trash_box.orientation = Gtk.Orientation.VERTICAL;
            trash_box.add (trash_scroller);
            trash_box.add (trash_bar);

            // Main View
            stack = new Gtk.Stack ();
            stack.get_style_context ().add_class ("notejot-stack");
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add_titled (grid_box, "grid", _("Grid"));
            stack.child_set_property (grid_box, "icon-name", "view-grid-symbolic");
            stack.add_titled (list_box, "list", _("List"));
            stack.child_set_property (list_box, "icon-name", "view-list-symbolic");
            stack.add_titled (trash_box, "trash", _("Trash"));
            stack.child_set_property (trash_box, "icon-name", "user-trash-symbolic");

            var viewswitcher = new Hdy.ViewSwitcher ();
            viewswitcher.stack = stack;

            titlebar.set_custom_title (viewswitcher);

            main_stack = new Gtk.Stack ();
            main_stack.get_style_context ().add_class ("notejot-stack");
            main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_stack.add_named (welcome_view, "welcome");
            main_stack.add_named (stack, "stack");

            sgrid = new Gtk.Grid ();
            sgrid.orientation = Gtk.Orientation.VERTICAL;
            sgrid.attach (sidebar, 0, 0, 1, 1);
            sgrid.no_show_all = true;
            sgrid.visible = false;

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (main_stack, 0, 0, 1, 1);
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

            if (gridview.is_modified == false) {
                main_stack.set_visible_child (welcome_view);
                stack.set_visible_child (grid_box);
                welcome_titlebar.visible = true;
                titlebar.visible = false;
                sgrid.no_show_all = true;
                sgrid.visible = false;
            } else {
                if (Notejot.Application.gsettings.get_string("last-view") == "grid") {
                    main_stack.set_visible_child (stack);
                    stack.set_visible_child (grid_box);
                    welcome_titlebar.visible = false;
                    titlebar.visible = true;
                    sgrid.no_show_all = false;
                    sgrid.visible = true;
                } else if (Notejot.Application.gsettings.get_string("last-view") == "list") {
                    main_stack.set_visible_child (stack);
                    stack.set_visible_child (list_box);
                    welcome_titlebar.visible = false;
                    titlebar.visible = true;
                    sgrid.no_show_all = false;
                    sgrid.visible = true;
                }
            }

            var fgv = grid_scroller.get_vadjustment ();
            var flv = list_scroller.get_vadjustment ();
            scrolling_titlebar_change (fgv);
            scrolling_titlebar_change (flv);

            var main_grid = new Gtk.Grid ();
            main_grid.attach (titlebar_stack, 0, 0);
            main_grid.attach (leaflet, 0, 1);

            this.add (main_grid);
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

        private void scrolling_titlebar_change (Gtk.Adjustment adjustment) {
            adjustment.value_changed.connect (() => {
                if (adjustment.get_value () >= 22.12) {
                    titlebar.get_style_context ().add_class ("notejot-filled-toolbar");
                } else if (adjustment.get_value () < 22.12) {
                    titlebar.get_style_context ().remove_class ("notejot-filled-toolbar");
                }
            });
        }

        private void update () {
            if (leaflet != null && leaflet.get_folded ()) {
                // On Mobile size, so.... have to have no buttons anywhere.
                titlebar.set_decoration_layout (":");
            } else {
                // Else you're on Desktop size, so business as usual.
                titlebar.set_decoration_layout (":close");
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

        // IO?
        public void on_create_new () {
            gridview.new_taskbox (this, "New Note", "Write a new note…", "#FCF092");
            if (Notejot.Application.gsettings.get_string("last-view") == "grid") {
                stack.set_visible_child (grid_box);
                main_stack.set_visible_child (stack);
            } else if (Notejot.Application.gsettings.get_string("last-view") == "list") {
                stack.set_visible_child (list_box);
                main_stack.set_visible_child (stack);
            }
            titlebar_stack.set_visible_child (titlebar);
            sgrid.no_show_all = false;
            sgrid.visible = true;
        }

        public void action_about () {
            const string COPYRIGHT = "Copyright \xc2\xa9 2017-2021 Paulo \"Lains\" Galardi\n";

            const string? AUTHORS[] = {
                "Paulo \"Lains\" Galardi"
            };

            var program_name = Config.NAME_PREFIX + _("Notejot");
            Gtk.show_about_dialog (this,
                                   "program-name", program_name,
                                   "logo-icon-name", "io.github.lainsce.Notejot",
                                   "version", Config.VERSION,
                                   "comments", _("Jot your ideas."),
                                   "copyright", COPYRIGHT,
                                   "authors", AUTHORS,
                                   "license-type", Gtk.License.GPL_3_0,
                                   "wrap-license", false,
                                   "translator-credits", _("translator-credits"),
                                   null);
        }
    }
}
