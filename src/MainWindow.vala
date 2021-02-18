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
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/main_window.ui")]
    public class MainWindow : Hdy.ApplicationWindow {
        delegate void HookFunc ();

        [GtkChild]
        public Gtk.Button new_button;
        [GtkChild]
        public Gtk.Button back_button;
        [GtkChild]
        public Gtk.MenuButton menu_button;
        [GtkChild]
        public Gtk.SearchEntry note_search;

        [GtkChild]
        public Gtk.Box grid;
        [GtkChild]
        public Gtk.Box sgrid;
        [GtkChild]
        public Gtk.Box empty_state;
        [GtkChild]
        public Hdy.Leaflet leaflet;
        [GtkChild]
        public Gtk.ScrolledWindow list_scroller;
        [GtkChild]
        public Gtk.ScrolledWindow trash_scroller;

        [GtkChild]
        public Gtk.Stack main_stack;
        [GtkChild]
        public Gtk.Stack sidebar_stack;
        [GtkChild]
        public Hdy.HeaderBar titlebar;
        [GtkChild]
        public Hdy.HeaderBar stitlebar;
        [GtkChild]
        public Hdy.HeaderGroup titlegroup;

        // Custom
        public Widgets.Dialog dialog = null;
        public Widgets.SettingMenu settingmenu;
        public Widgets.HeaderBarButton sidebar_title_button;
        public Views.ListView listview;
        public Views.TrashView trashview;
        public TaskManager tm;

        // Etc
        public bool pinned = false;

        public GLib.ListStore notestore;
        public GLib.ListStore trashstore;
        public GLib.ListStore notebookstore;

        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_ABOUT = "action_about";
        public const string ACTION_ALL_NOTES = "action_all_notes";
        public const string ACTION_TRASH = "action_trash";
        public const string ACTION_KEYS = "action_keys";
        public const string ACTION_TRASH_NOTES = "action_trash_notes";
        public const string ACTION_DARK_MODE = "action_dark_mode";
        public const string ACTION_MOVE_TO = "action_move_to";
        public const string ACTION_EDIT_NOTEBOOKS = "action_edit_notebooks";
        public const string ACTION_NOTEBOOK = "select_notebook";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
              {ACTION_ABOUT, action_about },
              {ACTION_ALL_NOTES, action_all_notes},
              {ACTION_TRASH, action_trash},
              {ACTION_KEYS, action_keys},
              {ACTION_TRASH_NOTES, action_trash_notes},
              {ACTION_MOVE_TO, action_move_to},
              {ACTION_EDIT_NOTEBOOKS, action_edit_notebooks},
              {ACTION_DARK_MODE, action_dark_mode, null, "false", null},
              {ACTION_NOTEBOOK, select_notebook, "s"},
        };

        public Gtk.Application app { get; construct; }
        public MainWindow (Gtk.Application application) {
            GLib.Object (
                application: application,
                app: application,
                icon_name: Config.APP_ID,
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

            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/io/github/lainsce/Notejot");

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
            settingmenu = new Widgets.SettingMenu(this);
            settingmenu.visible = false;
            settingmenu.no_show_all = true;

            titlebar.pack_end (settingmenu);

            back_button.show_all ();
            back_button.clicked.connect (() => {
                leaflet.set_visible_child (sgrid);
            });
            back_button.no_show_all = true;

            // Sidebar Titlebar
            new_button.clicked.connect (() => {
                on_create_new.begin ();
            });

            var builder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/menu.ui");
            menu_button.menu_model = (MenuModel)builder.get_object ("menu");

            notestore = new GLib.ListStore (typeof (Log));
            notestore.sort ((a, b) => {
                return ((Log) a).subtitle.collate (((Log) b).subtitle);
            });

            trashstore = new GLib.ListStore (typeof (Log));

            // List View
            listview = new Views.ListView (this);
            listview.bind_model (notestore, item => make_item (this, item));

            notestore.items_changed.connect (() => {
                tm.save_notes.begin (notestore);
            });

            list_scroller.add (listview);

            // Trash View
            trashview = new Views.TrashView (this);
            trashview.bind_model (trashstore, item => make_item (this, item));

            trashstore.items_changed.connect (() => {
                tm.save_notes.begin (trashstore);
            });

            trash_scroller.add (trashview);

            var tbuilder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/title_menu.ui");
            var tmenu = (Menu)tbuilder.get_object ("tmenu");

            sidebar_title_button = new Widgets.HeaderBarButton ();
            sidebar_title_button.has_tooltip = true;
            sidebar_title_button.title = (_("All Notes"));
            sidebar_title_button.menu.menu_model = tmenu;
            sidebar_title_button.show_all ();
            sidebar_title_button.get_style_context ().add_class ("rename-button");
            sidebar_title_button.get_style_context ().add_class ("flat");

            stitlebar.set_custom_title (sidebar_title_button);

            sgrid.show_all ();

            note_search.notify["text"].connect (() => {
               listview.set_search_text (note_search.get_text ());
            });

            // Main View
            leaflet.show_all ();

            update ();

            leaflet.notify["folded"].connect (() => {
                update ();
            });

            notebookstore = new GLib.ListStore (typeof (Notebook));
            notebookstore.items_changed.connect (() => {
                tm.save_notebooks.begin (notebookstore);
                ((Menu)tbuilder.get_object ("edit")).remove_all ();

                uint i, n = notebookstore.get_n_items ();
                for (i = 0; i < n; i++) {
                    var item = notebookstore.get_item (i);
                    string notebook_name = (((Notebook)item).title);

                    var menuitem = new GLib.MenuItem (notebook_name, null);
                    menuitem.set_action_and_target_value ("win.select_notebook", notebook_name);

                    ((Menu)tbuilder.get_object ("edit")).insert_item (-1, menuitem);
                }
            });

            tm.load_from_file.begin ();
            tm.load_from_file_nb.begin ();

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
        public Widgets.Note make_item (MainWindow win, GLib.Object item) {
            listview.is_modified = true;
            return new Widgets.Note (this, (Log) item);
        }

        public void make_note (string title, string subtitle, string text, string color, string notebook) {
            var log = new Log ();
            log.title = title;
            log.subtitle = subtitle;
            log.text = text;
            log.color = color;
            log.notebook = notebook;
            listview.is_modified = true;

            notestore.append(log);
        }

        public void make_notebook (string title) {
            var nb = new Notebook ();
            nb.title = title;

            notebookstore.append(nb);
        }

        public async void on_create_new () {
            var dt = new GLib.DateTime.now_local ();
            var log = new Log ();
            log.title = "";
            log.subtitle = "%s".printf (dt.format ("%A, %d/%m %H∶%M"));
            log.text = "This is a text example.";
            log.color = "#fff";
            log.notebook = "";
            listview.is_modified = true;
            notestore.append (log);

            if (listview.get_selected_row () == null) {
                main_stack.set_visible_child (empty_state);
            }
            settingmenu.visible = true;
        }

        public void select_notebook (GLib.SimpleAction action, GLib.Variant? parameter) {
            sidebar_title_button.title = parameter.get_string ();
            listview.set_search_text (parameter.get_string ());

            main_stack.set_visible_child (empty_state);
            if (listview.get_selected_row () != null) {
                listview.unselect_row(listview.get_selected_row ());
            }
            settingmenu.visible = false;
            titlebar.title = "";
        }

        public void action_about () {
            const string COPYRIGHT = "Copyright \xc2\xa9 2017-2021 Paulo \"Lains\" Galardi\n";

            const string? AUTHORS[] = {
                "Paulo \"Lains\" Galardi",
                null
            };

            var program_name = Config.NAME_PREFIX + _("Notejot");
            Gtk.show_about_dialog (this,
                                   "program-name", program_name,
                                   "logo-icon-name", Config.APP_ID,
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
            listview.set_search_text ("");
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
            listview.set_search_text ("");
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
                var window =  (Gtk.ShortcutsWindow) build.get_object ("shortcuts-notejot");
                window.set_transient_for (this);
                window.show_all ();
            } catch (Error e) {
                warning ("Failed to open shortcuts window: %s\n", e.message);
            }
        }

        public void action_move_to () {
            var move_to_dialog = new Widgets.MoveToDialog (this);
            move_to_dialog.show_all ();
        }

        public void action_edit_notebooks () {
            var edit_nb_dialog = new Widgets.EditNotebooksDialog (this);
            edit_nb_dialog.show_all ();
        }

        public void action_dark_mode (GLib.SimpleAction action, GLib.Variant? parameter) {
            var state = ((!) action.get_state ()).get_boolean ();
            action.set_state (new Variant.boolean (!state));
            Notejot.Application.gsettings.set_boolean("dark-mode", !state);
        }
    }
}
