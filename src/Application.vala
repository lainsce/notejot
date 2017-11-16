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
        private Gee.LinkedList<MainWindow> open_notes = new Gee.LinkedList<MainWindow>();
        private NoteManager note_manager = new NoteManager();


        public Application () {
            Object (flags: ApplicationFlags.FLAGS_NONE,
                    application_id: "com.github.lainsce.notejot");
	    }

        construct {
            app_launcher = "com.github.lainsce.notejot";
            exec_name = "com.github.lainsce.notejot";

            var quit_action = new SimpleAction ("quit", null);
            add_accelerator ("<Control>q", "app.quit", null);
            add_action (quit_action);
            quit_action.activate.connect (() => {
    	        foreach (MainWindow windows in open_notes) {
                    debug ("Quitting all notes...\n");
    	            update_storage();
    	            windows.close();
    	        }
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
	    }

        public void remove_note(MainWindow note) {
            debug ("Removing a note...\n");
            if (open_notes.size > 1) {
                open_notes.remove(note);
            } else {
                open_notes.clear ();
            }
	    }

	    public void update_storage() {
            debug ("Updating the storage...\n");
	        Gee.ArrayList<Storage> storage = new Gee.ArrayList<Storage>();

	        foreach (MainWindow w in open_notes) {
                storage.add(w.get_storage_note());
            }

            note_manager.save_notes(storage);
	    }

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.textdomain (Build.GETTEXT_PACKAGE);

            var app = new Application();
            return app.run(args);
        }
    }
}
