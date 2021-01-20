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
        public Gtk.Grid empty_state;
        public Gtk.Grid sgrid;
        public Gtk.Grid grid_box;
        public Gtk.Grid list_box;
        public Gtk.Overlay overlay;
        public Gtk.Separator separator;
        public Gtk.Stack stack;
        public Gtk.Stack main_stack;
        public Gtk.Stack titlebar_stack;
        public Gtk.Stack titlebar_title_stack;
        public Gtk.ToggleButton format_button;
        public Gtk.ListBox sidebar_categories;
        public Hdy.HeaderBar stitlebar;
        public Hdy.HeaderBar titlebar;
        public Hdy.HeaderBar welcome_titlebar;
        public Hdy.Leaflet leaflet;
        public Widgets.Dialog dialog = null;
        public Widgets.SettingMenu settingmenu;
        public Gtk.Label empty_state_title;

        // Views
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
            var titlebar_c = titlebar.get_style_context ();
            titlebar_c.add_class ("notejot-tbar");
            titlebar.show_close_button = true;
            titlebar.has_subtitle = false;
            titlebar.hexpand = true;
            titlebar.set_size_request (-1, 41);

            settingmenu = new Widgets.SettingMenu(this);
            titlebar.pack_end (settingmenu);

            var label = new Gtk.Label ("");
            var labelt = new Gtk.Label ("Trash");

            titlebar_title_stack = new Gtk.Stack ();
            titlebar_title_stack.valign = Gtk.Align.START;
            titlebar_title_stack.set_transition_type (Gtk.StackTransitionType.CROSSFADE);
            titlebar_title_stack.add_named (label, "normal-title");
            titlebar_title_stack.add_named (labelt, "trash-title");

            titlebar.set_custom_title (titlebar_title_stack);

            // Sidebar Titlebar
            stitlebar = new Hdy.HeaderBar ();
            stitlebar.show_close_button = true;
            stitlebar.has_subtitle = false;
            stitlebar.set_decoration_layout (":");
            stitlebar.show_all ();

            new_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Create a new note"))
            };
            new_button.show_all ();

            new_button.clicked.connect (() => {
                on_create_new ();
            });

            var about_button = new Gtk.ModelButton ();
            about_button.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_ABOUT;
            about_button.text = _("About Notejot");

            about_button.clicked.connect (() => {
                action_about ();
            });

            var trash_button = new Gtk.ModelButton () {
                text = _("Empty Trash")
            };
            trash_button.clicked.connect (() => {
                dialog = new Widgets.Dialog (this,
                                             _("Empty the Trashed Notes?"),
                                             _("Emptying the trash means all the notes in it will be permanently lost with no recovery."),
                                             _("Cancel"),
                                             _("Empty Trash"));
                if (dialog != null) {
                    dialog.present ();
                    return;
                } else {
                    dialog.run ();
                }
            });

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.attach (trash_button, 0, 0);
            menu_grid.attach (about_button, 0, 1);
            menu_grid.show_all ();

            var menu = new Gtk.Popover (null);
            menu.add (menu_grid);

            var menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON));
            menu_button.tooltip_text = (_("Settings"));
            menu_button.popover = menu;
            menu_button.show_all ();

            stitlebar.pack_start (new_button);
            stitlebar.pack_end (menu_button);

            // List View
            listview = new Views.ListView (this);

            var list_scroller = new Gtk.ScrolledWindow (null, null);
            list_scroller.margin_top = 12;
            list_scroller.vexpand = true;
            list_scroller.add (listview);
            list_scroller.set_size_request (250, -1);

            // Trash View
            trashview = new Views.TrashView (this);

            var trash_scroller = new Gtk.ScrolledWindow (null, null);
            trash_scroller.margin_top = 12;
            trash_scroller.vexpand = true;
            trash_scroller.add (trashview);

            var sidebar_stack = new Gtk.Stack ();
            sidebar_stack.add_named (list_scroller, "list");
            sidebar_stack.add_named (trash_scroller, "trash");

            var sidebar = new Gtk.Grid ();
            sidebar.orientation = Gtk.Orientation.VERTICAL;
            sidebar.get_style_context ().add_class ("notejot-column");
            sidebar.attach (sidebar_stack, 0, 0, 1, 1);
            sidebar.show_all ();

            var note_button = new Gtk.ModelButton ();
            note_button.label = (_("Notes"));

            var delete_note_button = new Gtk.ModelButton ();
            delete_note_button.label = (_("Trash"));

            var sidebar_title_grid = new Gtk.Grid ();
            sidebar_title_grid.margin = 6;
            sidebar_title_grid.row_spacing = 6;
            sidebar_title_grid.attach (note_button, 0, 0);
            sidebar_title_grid.attach (delete_note_button, 0, 1);
            sidebar_title_grid.show_all ();

            var sidebar_title_menu = new Gtk.Popover (null);
            sidebar_title_menu.add (sidebar_title_grid);

            var sidebar_title_button = new Gtk.MenuButton ();
            sidebar_title_button.has_tooltip = true;
            sidebar_title_button.label = (_("Notes"));
            sidebar_title_button.tooltip_text = (_("Settings"));
            sidebar_title_button.popover = sidebar_title_menu;
            sidebar_title_button.show_all ();
            sidebar_title_button.get_style_context ().add_class ("rename-button");
            sidebar_title_button.get_style_context ().add_class ("flat");

            stitlebar.set_custom_title (sidebar_title_button);

            note_button.clicked.connect (() => {
                sidebar_stack.set_visible_child (list_scroller);
                Notejot.Application.gsettings.set_string("last-view", "notes");
                sidebar_title_button.label = (_("Notes"));
                settingmenu.visible = true;
            });

            delete_note_button.clicked.connect (() => {
                sidebar_stack.set_visible_child (trash_scroller);
                Notejot.Application.gsettings.set_string("last-view", "trash");
                sidebar_title_button.label = (_("Trash"));
                settingmenu.visible = false;
            });


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
            welcome_view.attach (welcome_image, 0, 0);
            welcome_view.attach (welcome_title, 0, 1);
            welcome_view.attach (welcome_new_button, 0, 2);

            empty_state_title = new Gtk.Label (_("No Open Notes"));
            empty_state_title.get_style_context ().add_class ("title-1");
            empty_state_title.get_style_context ().add_class ("dim-label");
            empty_state_title.margin_bottom = 24;

            var empty_state_image = new Gtk.Image.from_icon_name ("io.github.lainsce.Notejot-symbolic", Gtk.IconSize.BUTTON);
            empty_state_image.pixel_size = 96;
            empty_state_image.margin_bottom = 24;
            empty_state_image.opacity = 0.6;

            empty_state = new Gtk.Grid () {
              expand = true,
              orientation = Gtk.Orientation.VERTICAL,
              halign = Gtk.Align.CENTER,
              valign = Gtk.Align.CENTER,
              row_spacing = 12
            };
            empty_state.attach (empty_state_image, 0, 0);
            empty_state.attach (empty_state_title, 0, 1);

            Timeout.add_seconds (3, () => {
                tm.save_notes ();
                return true;
            });

            // Main View
            main_stack = new Gtk.Stack ();
            main_stack.get_style_context ().add_class ("notejot-stack");
            main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_stack.add_named (welcome_view, "welcome");
            main_stack.add_named (empty_state, "empty");

            sgrid = new Gtk.Grid ();
            sgrid.orientation = Gtk.Orientation.VERTICAL;
            sgrid.attach (stitlebar, 0, 0, 1, 1);
            sgrid.attach (sidebar, 0, 1, 1, 1);
            sgrid.no_show_all = true;
            sgrid.visible = false;

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (titlebar_stack, 0, 0, 1, 1);
            grid.attach (main_stack, 0, 0, 1, 1);
            grid.show_all ();

            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            sep.get_style_context ().add_class ("sidebar");

            leaflet = new Hdy.Leaflet ();
            leaflet.add (sgrid);
            leaflet.add (sep);
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

            if (listview.is_modified == false) {
                main_stack.set_visible_child (welcome_view);
                titlebar_stack.set_visible_child (welcome_titlebar);
                titlebar_title_stack.set_visible_child (label);
                sgrid.no_show_all = true;
                sgrid.visible = false;
            } else {
                main_stack.set_visible_child (empty_state);
                titlebar_stack.set_visible_child (titlebar);
                sgrid.no_show_all = false;
                sgrid.visible = true;
            }

            var flv = list_scroller.get_vadjustment ();
            scrolling_titlebar_change (flv);

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
            var sidebaritem = new Widgets.SidebarItem (this, "New Note", "Write a new note…", "This is an example of text.", "#f9f06b");
            listview.add (sidebaritem);
            listview.is_modified = true;

            main_stack.set_visible_child (empty_state);
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
