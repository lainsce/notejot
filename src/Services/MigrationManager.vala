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
        public MainWindow win;
        public Json.Builder builder;
        private string app_dir = Environment.get_user_data_dir () +
                                 "/io.github.lainsce.Notejot";
        private string file_name_n;
        private string file_name_nb;
        private string file_name_t;

        public MigrationManager (MainWindow win) {
            this.win = win;
            file_name_n = this.app_dir + "/saved_notes.json";
            file_name_t = this.app_dir + "/saved_trash.json";
            file_name_nb = this.app_dir + "/saved_notebooks.json";
        }

        public async void migrate_from_file_notes () {
            debug ("Migrate Normal Notes...");
            try {
                var file = File.new_for_path(file_name_n);
                if (file.query_exists()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var node = Json.from_string (line);
                    var array = node.get_array ();
                    foreach (var tasks in array.get_elements()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element(0);
                        var subtitle = task.get_string_element(1);
                        var text = task.get_string_element(2);
                        var color = task.get_string_element(3);
                        var notebook = task.get_string_element(4);
                        var pinned = task.get_string_element(5);

                        if (pinned != null) {
                            win.make_note (title, subtitle, text, color, notebook, pinned);
                        } else {
                            win.make_note (title, subtitle, text, color, notebook, "0");
                        }
                    }
                }
            } catch (Error e) {
                warning ("Failed to load file: %s\n", e.message);
            }
        }

        public async void migrate_from_file_trash () {
            debug ("Migrate Trashed Notes...");
            try {
                var file = File.new_for_path(file_name_t);

                if (file.query_exists()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var node = Json.from_string (line);
                    var array = node.get_array ();
                    foreach (var tasks in array.get_elements()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element(0);
                        var subtitle = task.get_string_element(1);
                        var text = task.get_string_element(2);
                        var color = task.get_string_element(3);
                        var notebook = task.get_string_element(4);
                        var pinned = task.get_string_element(5);

                        if (pinned != null) {
                            win.make_trash_note (title, subtitle, text, color, notebook, pinned);
                        } else {
                            win.make_trash_note (title, subtitle, text, color, notebook, "0");
                        }
                    }
                }
            } catch (Error e) {
                warning ("Failed to load file: %s\n", e.message);
            }
        }

        public async void migrate_from_file_nb () {
            debug ("Migrate Notebooks...");
            try {
                var file = File.new_for_path(file_name_nb);

                if (file.query_exists()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var node = Json.from_string (line);
                    var array = node.get_array ();
                    foreach (var tasks in array.get_elements()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element(0);

                        win.make_notebook (title);
                    }
                }
            } catch (Error e) {
                warning ("Failed to load file: %s\n", e.message);
            }
        }
    }
}
