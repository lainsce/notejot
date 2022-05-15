/*
* Copyright (c) 2017-2022 Lains
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
        public signal void clicked ();

        [GtkChild]
        public unowned Gtk.MenuButton menu_button;
        [GtkChild]
        public unowned Gtk.Stack grid;
        [GtkChild]
        public unowned Gtk.Stack sgrid;
        [GtkChild]
        public unowned Gtk.WindowHandle nbgrid;
        [GtkChild]
        public unowned Adw.Leaflet leaf;
        [GtkChild]
        public unowned Gtk.Box main_box;
        [GtkChild]
        public unowned Gtk.Separator sep1;
        [GtkChild]
        public unowned Gtk.Separator sep2;
        [GtkChild]
        public unowned Gtk.ToggleButton an_button;
        [GtkChild]
        public unowned Gtk.ToggleButton g_button;
        [GtkChild]
        public unowned Gtk.ToggleButton t_button;
        [GtkChild]
        public unowned Gtk.SingleSelection selection_model;
        [GtkChild]
        public unowned NoteContentView notecontent;
        [GtkChild]
        public unowned Gtk.Overlay list_scroller;
        [GtkChild]
        public unowned Gtk.Overlay glist_scroller;
        [GtkChild]
        public unowned Gtk.Sorter sorter;

        // Custom
        public MainWindow? mw {get; set;}
        public Adw.Leaflet? leaflet {get; set;}
        public Gtk.SelectionModel? ss {get; set;}
        public NotebookMainListView? mlv {get; set;}

        [GtkChild]
        public unowned NoteListView listview;
        [GtkChild]
        public unowned NoteGridView gridview;
        [GtkChild]
        public unowned TrashListView tlistview;
        [GtkChild]
        public unowned NotebookMainListView nblistview;

        // Etc
        public Gtk.Settings gtk_settings;
        public NoteViewModel view_model { get; construct; }
        public NotebookViewModel nbview_model { get; construct; }
        public TrashViewModel tview_model { get; construct; }

        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_ABOUT = "action_about";
        public const string ACTION_KEYS = "action_keys";
        public const string ACTION_EDIT_NOTEBOOKS = "action_edit_notebooks";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
              {ACTION_ABOUT, action_about },
              {ACTION_KEYS, action_keys},
              {ACTION_EDIT_NOTEBOOKS, action_edit_notebooks},
        };

        public Adw.Application app { get; construct; }
        public MainWindow (Adw.Application application, NoteViewModel view_model, TrashViewModel tview_model, NotebookViewModel nbview_model) {
            GLib.Object (
                application: application,
                app: application,
                view_model: view_model,
                tview_model: tview_model,
                nbview_model: nbview_model,
                icon_name: Config.APP_ID,
                title: "Notejot"
            );
        }

        construct {
            // Actions
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            foreach (var action in action_accelerators.get_keys ()) {
                var accels_array = action_accelerators[action].to_array ();
                accels_array += null;

                app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
            }
            app.set_accels_for_action("app.quit", {"<Ctrl>q"});
            app.set_accels_for_action ("win.action_keys", {"<Ctrl>question"});

            // Main View
            var builder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/menu.ui");
            menu_button.menu_model = (MenuModel)builder.get_object ("menu");

            var theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
            theme.add_resource_path ("/io/github/lainsce/Notejot/");

            // Preparing window to be shown
            var settings = new Settings ();
            set_default_size(
                settings.window_w,
                settings.window_h
            );
            if (settings.is_maximized)
                maximize ();

            var action_fontsize = settings.create_action ("font-size");
            app.add_action(action_fontsize);

            // Migrate things from old version
            if (settings.schema_version == 0) {
                var mm = new MigrationManager (this);
                mm.migrate_from_file_trash.begin ();
                mm.migrate_from_file_notes.begin ();
                mm.migrate_from_file_nb.begin ();
                settings.schema_version = 1;
            }

            // Needed to ensure colors in places
            var style_manager = new StyleManager ();
            style_manager.set_css ("");

this.set_size_request (360, 360);
            this.show ();
            this.mw = (MainWindow) app.get_active_window ();
            this.leaflet = leaf;
            an_button.set_active(true);
        }

        protected override bool close_request () {
            debug ("Exiting window... Disposing of stuff...");
            var settings = new Settings ();
            settings.is_maximized = is_maximized ();

            if (!is_maximized()) {
                settings.window_w = get_width ();
                settings.window_h = get_height ();
            }

            this.dispose ();
            return true;
        }

        // IO?
        [GtkCallback]
        void on_new_note_requested () {
            view_model.create_new_note (null);
        }

        [GtkCallback]
        public void on_note_update_requested (Note note) {
            view_model.update_note (note);
            sorter.changed (Gtk.SorterChange.DIFFERENT);
        }

        [GtkCallback]
        public void on_note_removal_requested (Note note) {
            tview_model.create_new_trash (note);
            view_model.delete_note (note);
        }

        [GtkCallback]
        void on_clear_trash_requested () {
            tview_model.delete_trash.begin (this);
        }

        [GtkCallback]
        public void on_trash_update_requested (Trash trash) {
            tview_model.update_trash (trash);
        }

        [GtkCallback]
        public void on_trash_restore_requested (Trash trash) {
            tview_model.delete_one_trash (trash);
            view_model.restore_trash (trash);
        }

        [GtkCallback]
        public void on_action_all_notes () {
            var settings = new Settings ();
            settings.last_view = "list";
            leaf.set_visible_child (sgrid);
            sgrid.set_hexpand (false);
            sgrid.set_visible_child_name ("notelist");
            grid.set_visible (true);
            sep2.set_visible (true);
            grid.set_visible_child_name ("note");
            nblistview.sntext = "";
            nblistview.selection_model.set_selected (-1);
            if (leaf.folded) {
                listview.back_button.set_visible (true);
            } else {
                listview.back_button.set_visible (false);
            }
            notecontent.back2_button.set_visible (false);
        }

        [GtkCallback]
        public void on_action_grid () {
            var settings = new Settings ();
            settings.last_view = "grid";
            leaf.set_visible_child (sgrid);
            sgrid.set_hexpand (true);
            sgrid.set_visible_child_name ("notegrid");
            grid.set_visible (false);
            sep2.set_visible (false);
            grid.set_visible_child_name ("note");
            nblistview.sntext = "";
            nblistview.selection_model.set_selected (-1);
            if (leaf.folded) {
                gridview.back_button.set_visible (true);
            } else {
                gridview.back_button.set_visible (false);
            }
        }

        [GtkCallback]
        public void on_action_trash () {
            var settings = new Settings ();
            settings.last_view = "trash";
            leaf.set_visible_child (sgrid);
            sgrid.set_hexpand (false);
            sgrid.set_visible_child_name ("trashlist");
            grid.set_visible (true);
            sep2.set_visible (true);
            grid.set_visible_child_name ("trash");
            nblistview.sntext = "";
            nblistview.selection_model.set_selected (-1);
            if (leaf.folded) {
                tlistview.back_button.set_visible (true);
            } else {
                tlistview.back_button.set_visible (false);
            }
            notecontent.back2_button.set_visible (false);
        }

        public void make_note (string id, string title, string subtitle, string text, string color, string notebook, string pinned) {
            var log = new Note ();
            log.id = id;
            log.title = title;
            log.subtitle = subtitle;
            log.text = text;
            log.color = color;
            log.notebook = notebook;

            if (pinned == "0") {
                log.pinned = false;
            } else if (pinned == "1") {
                log.pinned = true;
            }

            view_model.create_new_note (log);
        }

        public void make_trash_note (string id, string title, string subtitle, string text, string color, string notebook, string pinned) {
            var tlog = new Note ();
            tlog.id = id;
            tlog.title = title;
            tlog.subtitle = subtitle;
            tlog.text = text;
            tlog.color = color;
            tlog.notebook = notebook;
            tlog.pinned = false;

            tview_model.create_new_trash (tlog);
        }

        public void make_notebook (string id, string title) {
            var nb = new Notebook ();
            nb.id = id;
            nb.title = title;

            nbview_model.create_new_notebook (nb);
        }

        public void action_about () {
            const string COPYRIGHT = "Copyright \xc2\xa9 2017-2021 Paulo \"Lains\" Galardi\n";

            const string? AUTHORS[] = {
                "Paulo \"Lains\" Galardi",
                null
            };

            Gtk.show_about_dialog (this,
                                   "program-name", "Notejot" + Config.NAME_SUFFIX,
                                   "logo-icon-name", Config.APP_ID,
                                   "version", Config.VERSION,
                                   "comments", _("Jot your ideas."),
                                   "copyright", COPYRIGHT,
                                   "authors", AUTHORS,
                                   "artists", null,
                                   "license-type", Gtk.License.GPL_3_0,
                                   "wrap-license", false,
                                   // TRANSLATORS: 'Name <email@domain.com>' or 'Name https://website.example'
                                   "translator-credits", _("translator-credits"),
                                   null);
        }

        public void action_keys () {
            try {
                var build = new Gtk.Builder ();
                build.add_from_resource ("/io/github/lainsce/Notejot/shortcuts.ui");
                var window =  (Gtk.ShortcutsWindow) build.get_object ("shortcuts-notejot");
                window.set_transient_for (this);
                window.show ();
            } catch (Error e) {
                warning ("Failed to open shortcuts window: %s\n", e.message);
            }
        }

        public void action_edit_notebooks () {
            var edit_nb_dialog = new Widgets.EditNotebooksDialog (this, nbview_model, view_model);
            edit_nb_dialog.show ();
        }
    }
}
