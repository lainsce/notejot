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
    public class MainWindow : He.ApplicationWindow {
        delegate void HookFunc ();
        public signal void clicked ();

        [GtkChild]
        public unowned Gtk.MenuButton menu_button;
        [GtkChild]
        public unowned Gtk.ToggleButton search_button;
        [GtkChild]
        public unowned Gtk.Stack grid;
        [GtkChild]
        public unowned Gtk.Box sbox;
        [GtkChild]
        public unowned Gtk.Stack sgrid;
        [GtkChild]
        public unowned Gtk.WindowHandle nbgrid;
        [GtkChild]
        public unowned Bis.Album albumt;
        [GtkChild]
        public unowned Gtk.Box main_box;
        [GtkChild]
        public unowned Gtk.Separator sep1;
        [GtkChild]
        public unowned Gtk.Separator sep2;
        [GtkChild]
        public unowned Gtk.ToggleButton an_button;
        [GtkChild]
        public unowned Gtk.ToggleButton t_button;
        [GtkChild]
        public unowned Gtk.ToggleButton anf_button;
        [GtkChild]
        public unowned Gtk.ToggleButton tf_button;
        [GtkChild]
        public unowned Gtk.SingleSelection selection_model;
        [GtkChild]
        public unowned NoteContentView notecontent;
        [GtkChild]
        public unowned He.OverlayButton list_scroller;
        [GtkChild]
        public unowned He.ViewTitle view_title;
        [GtkChild]
        public unowned Gtk.Sorter sorter;

        // Custom
        public MainWindow? mw {get; set;}
        public Bis.Album? album {get; set;}
        public Gtk.SelectionModel? ss {get; set;}
        public NotebookMainListView? mlv {get; set;}

        [GtkChild]
        public unowned NoteListView listview;
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
        public const string ACTION_EDIT_NOTEBOOKS = "action_edit_notebooks";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
              {ACTION_ABOUT, action_about },
              {ACTION_EDIT_NOTEBOOKS, action_edit_notebooks},
        };

        public He.Application app { get; construct; }
        public MainWindow (He.Application application, NoteViewModel view_model, TrashViewModel tview_model, NotebookViewModel nbview_model) {
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

            // Main View
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
            this.album = albumt;
            an_button.set_active(true);
            anf_button.set_active(true);
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
            albumt.set_visible_child (sbox);
            sgrid.set_hexpand (false);
            sgrid.set_visible_child_name ("notelist");
            sgrid.set_visible (true);
            grid.set_visible (true);
            sep2.set_visible (true);
            grid.set_visible_child_name ("note");
            nblistview.sntext = "";
            nblistview.selection_model.set_selected (-1);
            view_title.label = _("Notes");
            search_button.set_visible (true);
        }

        [GtkCallback]
        public void on_action_trash () {
            var settings = new Settings ();
            settings.last_view = "trash";
            albumt.set_visible_child (sbox);
            sgrid.set_hexpand (false);
            sgrid.set_visible_child_name ("trashlist");
            grid.set_visible (true);
            sep2.set_visible (true);
            grid.set_visible_child_name ("trash");
            nblistview.sntext = "";
            nblistview.selection_model.set_selected (-1);
            view_title.label = _("Trash");
            search_button.set_visible (false);
        }

        [GtkCallback]
        public void on_action_fall_notes () {
            on_action_all_notes ();
        }

        [GtkCallback]
        public void on_action_ftrash () {
            on_action_trash ();
        }


        public void make_note (string id, string title, string subtitle, string text, string color, string notebook, string pinned) {
            var log = new Note ();
            log.id = id;
            log.title = title;
            log.subtitle = subtitle;
            log.text = text;
            log.color = color;
            log.picture = "";
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
            tlog.picture = "";
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
            // TRANSLATORS: 'Name <email@domain.com>' or 'Name https://website.example'
            string translators = (_(""));

            var about = new He.AboutWindow (
                this,
                "Notejot",
                Config.APP_ID,
                Config.VERSION,
                Config.APP_ID,
                "https://github.com/lainsce/notejot/tree/main/po",
                "https://github.com/lainsce/notejot/issues/new",
                "https://github.com/lainsce/notejot",
                {translators},
                {"Paulo \"Lains\" Galardi"},
                2017, // Year of first publication.
                He.AboutWindow.Licenses.GPLv3,
                He.Colors.YELLOW
            );
            about.present ();
        }

        public void action_edit_notebooks () {
            var edit_nb_dialog = new Widgets.EditNotebooksDialog (this, nbview_model, view_model);
            edit_nb_dialog.show ();
        }
    }
}

