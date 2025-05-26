/*
 * Copyright (C) 2017-2021 Lains
 *
 * This program is free software; you can redistribute it &&/or
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
    public class MigrationManager {
        public MainWindow? win;
        public Json.Builder builder;
        private string app_dir = Environment.get_user_data_dir ()
            + "/io.github.lainsce.Notejot";
        private string file_name_n;
        private string file_name_p;
        private string file_name_nb;
        private string file_name_t;

        public MigrationManager (MainWindow? win) {
            this.win = win;
            file_name_n = this.app_dir + "/saved_notes.json";
            file_name_p = this.app_dir + "/saved_pinned_notes.json";
            file_name_t = this.app_dir + "/saved_trash.json";
            file_name_nb = this.app_dir + "/saved_notebooks.json";
        }

        public async void migrate_from_file_notes () {
            debug ("Migrate Notes...");
            try {
                var file = File.new_for_path (file_name_n);
                var filep = File.new_for_path (file_name_p);

                if (file.query_exists ()) {
                    debug ("Migrating normal notes...");
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var node = Json.from_string (line);
                    var array = node.get_array ();
                    foreach (var tasks in array.get_elements ()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element (0);
                        var subtitle = task.get_string_element (1);
                        var text = task.get_string_element (2);
                        var color = task.get_string_element (3);
                        var notebook = task.get_string_element (4);

                        if (win != null) {
                            win.make_note (Uuid.string_random (), title, subtitle, text, color, notebook, "0");
                        }
                    }
                    debug ("Normal notes migration completed");
                }

                if (filep.query_exists ()) {
                    debug ("Migrating pinned notes...");
                    string linep;
                    GLib.FileUtils.get_contents (filep.get_path (), out linep);
                    var pnode = Json.from_string (linep);
                    var parray = pnode.get_array ();
                    foreach (var ptasks in parray.get_elements ()) {
                        var ptask = ptasks.get_array ();
                        var ptitle = ptask.get_string_element (0);
                        var psubtitle = ptask.get_string_element (1);
                        var ptext = ptask.get_string_element (2);
                        var pcolor = ptask.get_string_element (3);
                        var pnotebook = ptask.get_string_element (4);

                        if (win != null) {
                            win.make_note (Uuid.string_random (), ptitle, psubtitle, ptext, pcolor, pnotebook, "1");
                        }
                    }
                    debug ("Pinned notes migration completed");
                }
            } catch (Error e) {
                warning ("Failed to migrate notes: %s", e.message);
            }
        }

        public async void migrate_from_file_trash () {
            debug ("Migrate Trashed Notes...");
            try {
                var file = File.new_for_path (file_name_t);

                if (file.query_exists ()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var node = Json.from_string (line);
                    var array = node.get_array ();
                    foreach (var tasks in array.get_elements ()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element (0);
                        var subtitle = task.get_string_element (1);
                        var text = task.get_string_element (2);
                        var color = task.get_string_element (3);
                        var notebook = task.get_string_element (4);

                        if (win != null) {
                            win.make_trash_note (Uuid.string_random (), title, subtitle, text, color, notebook, "0");
                        }
                    }
                }
            } catch (Error e) {
                warning ("Failed to migrate trash: %s", e.message);
            }
        }

        public async void migrate_from_file_nb () {
            debug ("Migrate Notebooks...");
            try {
                var file = File.new_for_path (file_name_nb);

                if (file.query_exists ()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var node = Json.from_string (line);
                    var array = node.get_array ();
                    foreach (var tasks in array.get_elements ()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element (0);

                        if (win != null) {
                            win.make_notebook (Uuid.string_random (), title);
                        }
                    }
                }
            } catch (Error e) {
                warning ("Failed to migrate notebooks: %s", e.message);
            }
        }
    }
}
