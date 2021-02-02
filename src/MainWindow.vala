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
        public Gtk.Button back_button;
        public Gtk.Button welcome_new_button;
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
        public Gtk.Stack sidebar_stack;
        public Gtk.Grid sidebar;
        public Gtk.Label titlebar_label;
        public Gtk.ScrolledWindow trash_scroller;
        public Gtk.ScrolledWindow list_scroller;
        public Hdy.HeaderBar stitlebar;
        public Hdy.HeaderBar titlebar;
        public Hdy.HeaderBar welcome_titlebar;
        public Hdy.Leaflet leaflet;
        public Widgets.Dialog dialog = null;
        public Widgets.SettingMenu settingmenu;
        public Widgets.HeaderBarButton sidebar_title_button;
        public Gtk.Label empty_state_title;
        public Hdy.HeaderGroup titlegroup;

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
        public const string ACTION_ALL_NOTES = "action_all_notes";
        public const string ACTION_TRASH = "action_trash";
        public const string ACTION_KEYS = "action_keys";
        public const string ACTION_TRASH_NOTES = "action_trash_notes";
        public const string ACTION_DARK_MODE = "action_dark_mode";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
              {ACTION_ABOUT, action_about },
              {ACTION_ALL_NOTES, action_all_notes},
              {ACTION_TRASH, action_trash},
              {ACTION_KEYS, action_keys},
              {ACTION_TRASH_NOTES, action_trash_notes},
              {ACTION_DARK_MODE, action_dark_mode, null, "false", null},
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
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.n, keycode)) {
                         on_create_new.begin ();
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

            Gtk.StyleContext style = get_style_context ();
            if (Config.PROFILE == "Devel") {
                style.add_class ("devel");
            }

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
            titlebar.title = "";

            settingmenu = new Widgets.SettingMenu(this);
            settingmenu.visible = false;

            back_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("go-previous-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Go back to notes list"))
            };
            back_button.show_all ();

            back_button.clicked.connect (() => {
                leaflet.set_visible_child (sgrid);
            });
            back_button.no_show_all = true;

            titlebar.pack_start (back_button);

            // Sidebar Titlebar
            stitlebar = new Hdy.HeaderBar ();
            stitlebar.show_close_button = true;
            stitlebar.has_subtitle = false;
            stitlebar.set_size_request (250, -1);
            stitlebar.show_all ();

            new_button = new Gtk.Button () {
                image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON),
                tooltip_text = (_("Create a new note"))
            };
            new_button.show_all ();

            new_button.clicked.connect (() => {
                on_create_new.begin ();
            });

            var builder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/menu.ui");

            var menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON));
            menu_button.tooltip_text = (_("Settings"));
            menu_button.menu_model = (MenuModel)builder.get_object ("menu");

            stitlebar.pack_start (new_button);
            stitlebar.pack_end (menu_button);

            // List View
            listview = new Views.ListView (this);

            list_scroller = new Gtk.ScrolledWindow (null, null);
            list_scroller.vexpand = true;
            list_scroller.add (listview);
            list_scroller.set_size_request (250, -1);

            // Trash View
            trashview = new Views.TrashView (this);

            trash_scroller = new Gtk.ScrolledWindow (null, null);
            trash_scroller.vexpand = true;
            trash_scroller.add (trashview);

            sidebar_stack = new Gtk.Stack ();
            sidebar_stack.add_named (list_scroller, "list");
            sidebar_stack.add_named (trash_scroller, "trash");

            sidebar = new Gtk.Grid ();
            sidebar.orientation = Gtk.Orientation.VERTICAL;
            sidebar.get_style_context ().add_class ("view");
            sidebar.attach (sidebar_stack, 0, 0, 1, 1);
            sidebar.show_all ();

            var sidebar_revealer = new Gtk.Revealer ();
            sidebar_revealer.add (sidebar);
            sidebar_revealer.reveal_child = true;

            var tbuilder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/title_menu.ui");

            sidebar_title_button = new Widgets.HeaderBarButton ();
            sidebar_title_button.has_tooltip = true;
            sidebar_title_button.title = (_("All Notes"));
            sidebar_title_button.menu.menu_model = (MenuModel)tbuilder.get_object ("menu");
            sidebar_title_button.show_all ();
            sidebar_title_button.get_style_context ().add_class ("rename-button");
            sidebar_title_button.get_style_context ().add_class ("flat");

            stitlebar.set_custom_title (sidebar_title_button);

            // Welcome View

            // Used so the welcome titlebar, which is flat, and with no buttons
            // doesn't jump in size when transtitioning to the preview titlebar.
            var dummy_welcome_title_button = new Gtk.Button ();
            dummy_welcome_title_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            dummy_welcome_title_button.sensitive = false;

            welcome_titlebar = new Hdy.HeaderBar ();
            welcome_titlebar.show_close_button = true;
            welcome_titlebar.has_subtitle = false;
            welcome_titlebar.valign = Gtk.Align.START;
            welcome_titlebar.get_style_context ().add_class ("notejot-flat-title");

            welcome_titlebar.pack_start (dummy_welcome_title_button);

            titlebar_stack = new Gtk.Stack ();
            titlebar_stack.valign = Gtk.Align.START;
            titlebar_stack.set_transition_type (Gtk.StackTransitionType.CROSSFADE);
            titlebar_stack.add_named (welcome_titlebar, "welcome-title");
            titlebar_stack.add_named (titlebar, "title");

            var welcome_title = new Gtk.Label (_("Jot Some Notes"));
            welcome_title.get_style_context ().add_class ("large-title");
            welcome_title.margin_bottom = 24;

            var welcome_image = new Gtk.Image.from_icon_name ("io.github.lainsce.Notejot", Gtk.IconSize.BUTTON);
            welcome_image.pixel_size = 128;
            welcome_image.margin_bottom = 12;
            welcome_image.opacity = 0.5501;

            welcome_new_button = new Gtk.Button ();
            welcome_new_button.margin_bottom = 12;
            welcome_new_button.set_label (_("New Note"));
            welcome_new_button.get_style_context ().add_class ("circular-button");
            welcome_new_button.get_style_context ().add_class ("suggested-action");
            welcome_new_button.clicked.connect (() => {
                on_create_new.begin ();
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

            var welcome_view_handle = new Hdy.WindowHandle ();
            welcome_view_handle.add (welcome_view);

            empty_state_title = new Gtk.Label (_("No Open Notes"));
            empty_state_title.get_style_context ().add_class ("large-title");

            var empty_state_subtitle = new Gtk.Label (_("Use the + button to add a note."));

            var empty_state_image = new Gtk.Image.from_icon_name ("io.github.lainsce.Notejot-symbolic", Gtk.IconSize.BUTTON);
            empty_state_image.pixel_size = 96;
            empty_state_image.margin_bottom = 12;
            empty_state_image.opacity = 0.5501;

            empty_state = new Gtk.Grid () {
              orientation = Gtk.Orientation.VERTICAL,
              halign = Gtk.Align.CENTER,
              valign = Gtk.Align.CENTER,
              row_spacing = 6
            };
            empty_state.attach (empty_state_image, 0, 0);
            empty_state.attach (empty_state_title, 0, 1);
            empty_state.attach (empty_state_subtitle, 0, 2);

            // Main View

            main_stack = new Gtk.Stack ();
            main_stack.get_style_context ().add_class ("notejot-stack");
            main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
            main_stack.add_named (welcome_view_handle, "welcome");
            main_stack.add_named (empty_state, "empty");

            sgrid = new Gtk.Grid ();
            sgrid.orientation = Gtk.Orientation.VERTICAL;
            sgrid.attach (stitlebar, 0, 0, 1, 1);
            sgrid.attach (sidebar_revealer, 0, 1, 1, 1);
            sgrid.no_show_all = true;
            sgrid.visible = false;
            sgrid.hexpand = false;

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (titlebar_stack, 0, 0, 1, 1);
            grid.attach (main_stack, 0, 1, 1, 1);
            grid.show_all ();

            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            sep.get_style_context ().add_class ("sidebar");

            leaflet = new Hdy.Leaflet ();
            leaflet.add (sgrid);
            leaflet.add (sep);
            leaflet.add (grid);
            leaflet.show_all ();
            leaflet.can_swipe_back = true;
            leaflet.set_visible_child (sgrid);
            leaflet.child_set_property (sep, "navigatable", false);

            update ();

            leaflet.notify["folded"].connect (() => {
                update ();
            });

            titlegroup = new Hdy.HeaderGroup ();
            titlegroup.add_header_bar (stitlebar);
            titlegroup.add_header_bar (titlebar);

            tm.load_from_file.begin ();

            if (listview.is_modified == false) {
                main_stack.set_visible_child (welcome_view);
                titlebar_stack.set_visible_child (welcome_titlebar);
                sgrid.no_show_all = true;
                sgrid.visible = false;
                menu_button.visible = true;
                settingmenu.visible = false;
            } else {
                main_stack.set_visible_child (empty_state);
                titlebar_stack.set_visible_child (titlebar);
                sgrid.no_show_all = false;
                sgrid.visible = true;
                menu_button.visible = true;
                settingmenu.visible = false;
            }

            var cgrid = new Gtk.Grid ();
            cgrid.add (leaflet);

            this.add (cgrid);
            this.set_size_request (375, 280);
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
            if (leaflet != null && titlegroup != null && leaflet.get_folded ()) {
                back_button.visible = true;
                back_button.no_show_all = false;
                titlegroup.set_decorate_all (true);
            } else {
                back_button.visible = false;
                back_button.no_show_all = true;
                titlegroup.set_decorate_all (false);
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
        public async void on_create_new () {
            var sidebaritem = new Widgets.Note (this, "New Note", "Note Subtitle", "This is a text example.", "#f6f5f4");
            listview.add (sidebaritem);
            listview.is_modified = true;
            listview.select_row (sidebaritem);

            if (listview.get_selected_row () == null) {
                main_stack.set_visible_child (empty_state);
            }
            titlebar_stack.set_visible_child (titlebar);
            sgrid.no_show_all = false;
            sgrid.visible = true;
            sgrid.show_all ();
            settingmenu.visible = true;
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
                                   "artists", null,
                                   "license-type", Gtk.License.GPL_3_0,
                                   "wrap-license", false,
                                   "translator-credits", _("translator-credits"),
                                   null);
        }

        public void action_all_notes () {
            sidebar_stack.set_visible_child (list_scroller);
            Notejot.Application.gsettings.set_string("last-view", "list");
            sidebar_title_button.title = (_("All Notes"));
            main_stack.set_visible_child (empty_state);
            if (listview.get_selected_row () != null) {
                listview.unselect_row(listview.get_selected_row ());
            }
            settingmenu.visible = false;
            titlebar.title = "";
        }

        public void action_trash () {
            sidebar_stack.set_visible_child (trash_scroller);
            Notejot.Application.gsettings.set_string("last-view", "trash");
            sidebar_title_button.title = (_("Trash"));
            main_stack.set_visible_child (empty_state);
            if (trashview.get_selected_row () != null) {
                trashview.unselect_row(trashview.get_selected_row ());
            }
            settingmenu.visible = false;
            titlebar.title = "";
        }

        public void action_trash_notes () {
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
        }

        public void action_keys () {
            try {
                var build = new Gtk.Builder ();
                build.add_from_resource ("/io/github/lainsce/Notejot/shortcuts.ui");
                var window =  (Gtk.ApplicationWindow) build.get_object ("shortcuts-notejot");
                window.set_transient_for (this);
                window.show_all ();
            } catch (Error e) {
                warning ("Failed to open shortcuts window: %s\n", e.message);
            }
        }

        public void action_dark_mode (GLib.SimpleAction action, GLib.Variant? parameter) {
            var state = ((!) action.get_state ()).get_boolean ();
            action.set_state (new Variant.boolean (!state));
            Notejot.Application.gsettings.set_boolean("dark-mode", !state);
        }
    }
}
