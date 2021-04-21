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
    public class MainWindow : Adw.ApplicationWindow {
        delegate void HookFunc ();

        [GtkChild]
        public unowned Gtk.Button new_button;
        [GtkChild]
        public unowned Gtk.Button back_button;
        [GtkChild]
        public unowned Gtk.ToggleButton search_button;
        [GtkChild]
        public unowned Gtk.MenuButton menu_button;
        [GtkChild]
        public unowned Gtk.MenuButton settingmenu;
        [GtkChild]
        public unowned Gtk.Revealer search_revealer;
        [GtkChild]
        public unowned Gtk.SearchEntry note_search;

        [GtkChild]
        public unowned Gtk.Box grid;
        [GtkChild]
        public unowned Gtk.Box sgrid;
        [GtkChild]
        public unowned Gtk.Box empty_state;
        [GtkChild]
        public unowned Adw.Leaflet leaflet;
        [GtkChild]
        public unowned Gtk.ScrolledWindow list_scroller;
        [GtkChild]
        public unowned Gtk.ScrolledWindow trash_scroller;
        [GtkChild]
        public unowned Gtk.ListBox listview;
        [GtkChild]
        public unowned Gtk.ListBox trashview;

        [GtkChild]
        public unowned Gtk.Stack main_stack;
        [GtkChild]
        public unowned Gtk.Stack sidebar_stack;
        [GtkChild]
        public unowned Adw.HeaderBar titlebar;
        [GtkChild]
        public unowned Adw.HeaderBar stitlebar;

        // Custom
        public Widgets.SettingMenu sm;
        public Widgets.HeaderBarButton hbb;
        public Views.ListView lv;
        public Views.TrashView tv;
        public TaskManager tm;

        // Etc
        public bool pinned = false;
        int uid = 0;

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
        public const string ACTION_MOVE_TO = "action_move_to";
        public const string ACTION_DELETE_NOTE = "action_delete_note";
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
              {ACTION_DELETE_NOTE, action_delete_note},
              {ACTION_EDIT_NOTEBOOKS, action_edit_notebooks},
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
        }

        construct {
            // Initial settings
            Adw.init ();
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/github/lainsce/Notejot/app.css");
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
            default_theme.add_resource_path ("/io/github/lainsce/Notejot");

            // Gtk.StyleContext style = get_style_context ();
            // if (Config.PROFILE == "Devel") {
            //     style.add_class ("devel");
            // }
            //

            // Actions
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            foreach (var action in action_accelerators.get_keys ()) {
                var accels_array = action_accelerators[action].to_array ();
                accels_array += null;

                app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
            }

            var action_darkmode = Notejot.Application.gsettings.create_action ("dark-mode");
            app.add_action(action_darkmode);

            var action_fontsize = Notejot.Application.gsettings.create_action ("font-size");
            app.add_action(action_fontsize);
            //

            // Main View
            tm = new TaskManager (this);

            sm = new Widgets.SettingMenu(this);
            settingmenu.popover = sm.popover;

            back_button.visible = false;
            back_button.clicked.connect (() => {
                leaflet.set_visible_child (sgrid);
            });

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
            lv = new Views.ListView (this);
            listview.bind_model (notestore, item => make_item (this, item));

            notestore.items_changed.connect (() => {
                tm.save_notes.begin (notestore);
            });

            // Trash View
            tv = new Views.TrashView (this);
            trashview.bind_model (trashstore, item => make_item (this, item));

            trashstore.items_changed.connect (() => {
                tm.save_notes.begin (trashstore);
            });

            var tbuilder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/title_menu.ui");
            var tmenu = (Menu)tbuilder.get_object ("tmenu");

            hbb = new Widgets.HeaderBarButton ();
            hbb.has_tooltip = true;
            hbb.title = (_("All Notes"));
            hbb.menu.menu_model = tmenu;
            hbb.get_style_context ().add_class ("rename-button");
            hbb.get_style_context ().add_class ("flat");

            stitlebar.set_title_widget (hbb);

            search_button.toggled.connect (() => {
                if (search_button.get_active ()) {
                    search_revealer.set_reveal_child (true);
                } else {
                    search_revealer.set_reveal_child (false);
                }
            });

            note_search.notify["text"].connect (() => {
               lv.set_search_text (note_search.get_text ());
            });

            // Main View
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

            listen_to_changes ();

            this.set_size_request (375, 280);
            this.show ();
        }

        private void update () {
            if (leaflet != null && leaflet.get_folded ()) {
                back_button.visible = true;
            } else {
                back_button.visible = false;
            }
        }

        protected override bool close_request () {
            debug ("Exiting window... Disposing of stuff...");
            listview.bind_model (null, null);
            trashview.bind_model (null, null);
            this.dispose ();
            return true;
        }

        public void listen_to_changes () {
            Notejot.Application.gsettings.bind ("window-w", this, "default-width", GLib.SettingsBindFlags.DEFAULT);
            Notejot.Application.gsettings.bind ("window-h", this, "default-height", GLib.SettingsBindFlags.DEFAULT);
        }

        // IO?
        public Widgets.Note make_item (MainWindow win, GLib.Object item) {
            lv.is_modified = true;
            return new Widgets.Note (this, (Log) item);
        }

        public void make_note (string title, string subtitle, string text, string color, string notebook) {
            var log = new Log ();
            log.title = title;
            log.subtitle = subtitle;
            log.text = text;
            log.color = color;
            log.notebook = notebook;
            lv.is_modified = true;

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

            uid++;

            log.title = "";
            log.subtitle = "%s".printf (dt.format ("%A, %d/%m %H∶%M"));
            log.text = _("A Note ")+(@"$uid\n\n")+_("This is a text example.");
            log.color = "#fff";
            log.notebook = "";

            lv.is_modified = true;

            notestore.append (log);

            if (listview.get_selected_row () == null) {
                main_stack.set_visible_child (empty_state);
            }
            settingmenu.visible = true;
        }

        public void select_notebook (GLib.SimpleAction action, GLib.Variant? parameter) {
            hbb.title = parameter.get_string ();
            lv.set_search_text (parameter.get_string ());

            main_stack.set_visible_child (empty_state);
            if (listview.get_selected_row () != null) {
                listview.unselect_row(listview.get_selected_row ());
            }
            settingmenu.visible = false;
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
            hbb.title = (_("All Notes"));
            main_stack.set_visible_child (empty_state);
            if (listview.get_selected_row () != null) {
                listview.unselect_row(listview.get_selected_row ());
            }
            settingmenu.visible = false;
            lv.set_search_text ("");
        }

        public void action_trash () {
            sidebar_stack.set_visible_child (trash_scroller);
            Notejot.Application.gsettings.set_string("last-view", "trash");
            hbb.title = (_("Trash"));
            main_stack.set_visible_child (empty_state);
            if (trashview.get_selected_row () != null) {
                trashview.unselect_row(trashview.get_selected_row ());
            }
            settingmenu.visible = false;
        }

        public void action_trash_notes () {
            var dialog = new Gtk.MessageDialog (this, 0, 0, 0, null);
            dialog.modal = true;

            dialog.set_title (_("Empty the Trashed Notes?"));
            dialog.text = (_("Emptying the trash means all the notes in it will be permanently lost with no recovery."));

            dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            dialog.add_button (_("Empty Trash"), Gtk.ResponseType.OK);

            dialog.response.connect ((response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.OK:
                        trashstore.remove_all ();
                        dialog.close ();
                        break;
                    case Gtk.ResponseType.NO:
                        dialog.close ();
                        break;
                    case Gtk.ResponseType.CANCEL:
                    case Gtk.ResponseType.CLOSE:
                    case Gtk.ResponseType.DELETE_EVENT:
                        dialog.close ();
                        return;
                    default:
                        assert_not_reached ();
                }
            });

            if (dialog != null) {
                dialog.present ();
                return;
            } else {
                dialog.show ();
            }
        }

        public void action_keys () {
            try {
                var build = new Gtk.Builder ();
                build.add_from_resource ("/io/github/lainsce/Notejot/shortcuts.ui");
                var window =  (Gtk.ShortcutsWindow) build.get_object ("shortcuts-notejot");
                window.set_transient_for (this);
            } catch (Error e) {
                warning ("Failed to open shortcuts window: %s\n", e.message);
            }
        }

        public void action_move_to () {
            var move_to_dialog = new Widgets.MoveToDialog (this);
            move_to_dialog.show ();
        }

        public void action_delete_note () {
            var row = listview.get_selected_row ();

            var tlog = new Log ();
            tlog.title = ((Widgets.Note)row).log.title;
            tlog.subtitle = ((Widgets.Note)row).log.subtitle;
            tlog.text = ((Widgets.Note)row).log.text;
            tlog.color = ((Widgets.Note)row).log.color;
            tlog.notebook = ((Widgets.Note)row).log.notebook;
	        trashstore.append (tlog);

            main_stack.set_visible_child (empty_state);
            var rowd = main_stack.get_child_by_name ("textfield-%d".printf(((Widgets.Note)row).uid));
            main_stack.remove (rowd);

            uint pos;
            notestore.find (((Widgets.Note)row), out pos);
            notestore.remove (pos);
            settingmenu.visible = false;
        }

        public void action_edit_notebooks () {
            var edit_nb_dialog = new Widgets.EditNotebooksDialog (this);
            edit_nb_dialog.show ();
        }
    }
}

