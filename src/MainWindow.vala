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
        public signal void clicked ();

        [GtkChild]
        public unowned Gtk.Button new_button;
        [GtkChild]
        public unowned Gtk.Button back_button;
        [GtkChild]
        public unowned Gtk.MenuButton menu_button;

        [GtkChild]
        public unowned Gtk.Box grid;
        [GtkChild]
        public unowned Gtk.Box sgrid;
        [GtkChild]
        public unowned Adw.Leaflet leaflet;
        [GtkChild]
        public unowned Gtk.Overlay list_scroller;
        [GtkChild]
        public unowned Notejot.LogListView listview;

        [GtkChild]
        public unowned Gtk.Box main_box;
        [GtkChild]
        public unowned Gtk.Stack sidebar_stack;
        [GtkChild]
        public new unowned Adw.HeaderBar titlebar;
        [GtkChild]
        public unowned Adw.HeaderBar stitlebar;

        // Custom
        public LogListView view_list;

        // Etc
        public Gtk.Settings gtk_settings;
        public LogViewModel view_model { get; construct; }
        public NotebookViewModel nbview_model { get; construct; }

        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_ABOUT = "action_about";
        public const string ACTION_KEYS = "action_keys";
        public const string ACTION_MOVE_TO = "action_move_to";
        public const string ACTION_EDIT_NOTEBOOKS = "action_edit_notebooks";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
              {ACTION_ABOUT, action_about },
              {ACTION_KEYS, action_keys},
              {ACTION_MOVE_TO, action_move_to},
              {ACTION_EDIT_NOTEBOOKS, action_edit_notebooks},
        };

        public Adw.Application app { get; construct; }
        public MainWindow (Adw.Application application, LogViewModel view_model, NotebookViewModel nbview_model) {
            GLib.Object (
                application: application,
                app: application,
                view_model: view_model,
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
            back_button.clicked.connect (() => {
                leaflet.set_visible_child (sgrid);
            });

            var builder = new Gtk.Builder.from_resource ("/io/github/lainsce/Notejot/menu.ui");
            menu_button.menu_model = (MenuModel)builder.get_object ("menu");

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

            if (Config.PROFILE == ".Devel")
			    add_css_class ("devel");

            this.show ();
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
            view_model.create_new_note (this);
        }

        [GtkCallback]
        public void on_note_update_requested (Log note) {
            view_model.update_note (note);
            leaflet.set_visible_child (grid);
        }

        [GtkCallback]
        public void on_note_removal_requested (Log note) {
            view_model.delete_note (note, this);
        }

        public void action_about () {
            const string COPYRIGHT = "Copyright \xc2\xa9 2017-2021 Paulo \"Lains\" Galardi\n";

            const string? AUTHORS[] = {
                "Paulo \"Lains\" Galardi",
                null
            };

            var program_name = Config.NAME_PREFIX + "Notejot";
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

        public void action_move_to () {
            var move_to_dialog = new Widgets.MoveToDialog (this, nbview_model, view_model);
            move_to_dialog.show ();
        }

        public void action_edit_notebooks () {
            var edit_nb_dialog = new Widgets.EditNotebooksDialog (this, nbview_model);
            edit_nb_dialog.show ();
        }
    }
}
