/*
* Copyright (c) 2017 Lains
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
    public class Application : Granite.Application {
        public Gee.ArrayList<MainWindow> open_notes = new Gee.ArrayList<MainWindow>();
        private NoteManager note_manager = new NoteManager();
        private static bool create_new_window = false;

        public Application () {
            Object (flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                    application_id: "com.github.lainsce.notejot");
	    }

        construct {
            app_launcher = "com.github.lainsce.notejot";
            exec_name = "com.github.lainsce.notejot";

            var quit_action = new SimpleAction ("quit", null);
            set_accels_for_action ("app.quit", {"<Control>q"});
            add_action (quit_action);
            quit_action.activate.connect (() => {
    	        foreach (MainWindow windows in open_notes) {
                    debug ("Quitting all notes...\n");
    	            update_storage();
    	            windows.close();
    	        }
            });
            var new_action = new SimpleAction ("new", null);
            set_accels_for_action ("app.new", {"<Control>n"});
            add_action (new_action);
            new_action.activate.connect (() => {
                create_note(null);
            });
            var delete_action = new SimpleAction ("delete", null);
            set_accels_for_action ("app.delete", {"<Control>w"});
            add_action (delete_action);
            delete_action.activate.connect (() => {
                MainWindow note = (MainWindow)get_active_window ();
                remove_note(note);
                note.destroy();
            });
        }

        protected override void activate () {
            if (get_windows ().length () > 0) {
                foreach (var window in open_notes) {
                    if (window.visible) {
                        window.present ();
                    }
                }
            } else {
                var list = note_manager.load_from_file();

                if (list.size == 0) {
                    create_note(null);
                } else {
                    foreach (Storage storage in list) {
                        create_note(storage);
                    }
                }
            }
	    }

	    public void create_note(Storage? storage) {
            debug ("Creating a note...\n");
	        var note = new MainWindow(this, storage);
            open_notes.add(note);
            update_storage();
	    }

        public void remove_note(MainWindow note) {
            debug ("Removing a note...\n");
            open_notes.remove (note);
            update_storage();
	    }

	    public void update_storage() {
            debug ("Updating the storage...\n");
	        Gee.ArrayList<Storage> storage = new Gee.ArrayList<Storage>();

	        foreach (MainWindow w in open_notes) {
                storage.add(w.get_storage_note());
            }

            note_manager.save_notes(storage);
	    }

        protected override int command_line (ApplicationCommandLine command_line) {
            var context = new OptionContext ("File");
            context.add_main_entries (entries, Build.GETTEXT_PACKAGE);
            context.add_group (Gtk.get_option_group (true));

            string[] args = command_line.get_arguments ();
            int unclaimed_args;

            try {
                context.parse_strv (ref args);
                unclaimed_args = args.length - 1;
            } catch(Error e) {
                print (e.message + "\n");

                return 1;
            }

            // Create a next window if requested and it's not the app launch
            if (create_new_window) {
                create_new_window = false;
                create_note (null);
            }
            return 0;
        }

        const OptionEntry[] entries = {
            { "new-note", 'n', 0, OptionArg.NONE, out create_new_window, "New Note", null },
            { null }
        };

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.textdomain (Build.GETTEXT_PACKAGE);

            var app = new Application();
            return app.run(args);
        }
    }
}
