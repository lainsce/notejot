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
    public class TaskManager {
        public MainWindow win;
        public Json.Builder builder;
        private string app_dir = Environment.get_user_data_dir () +
                                 "/io.github.lainsce.Notejot";
        private string file_name_n;
        private string file_name_nb;
        private string file_name_t;

        public TaskManager (MainWindow win) {
            this.win = win;
            file_name_n = this.app_dir + "/saved_notes.json";
            file_name_t = this.app_dir + "/saved_trash.json";
            file_name_nb = this.app_dir + "/saved_notebooks.json";
        }

        public async void load_from_file_notes () {
            debug ("Load Normal Notes...");
            try {
                var file = File.new_for_path(file_name_n);
                if (file.query_exists()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var parser = new Json.Parser();
                    parser.load_from_data(line);
                    var root = parser.get_root();
                    var array = root.get_array();
                    foreach (var tasks in array.get_elements()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element(0);
                        var subtitle = task.get_string_element(1);
                        var text = task.get_string_element(2);
                        var color = task.get_string_element(3);
                        var notebook = task.get_string_element(4);
                        var pinned = task.get_string_element(5);

                        win.make_note (title, subtitle, text, color, notebook, pinned);
                    }
                }
            } catch (Error e) {
                warning ("Failed to load file: %s\n", e.message);
            }
        }

        public async void save_notes (ListStore liststore) {
            string json_string = "";
            var b = new Json.Builder ();
            builder = b;

            builder.begin_array ();
	        uint i, n = liststore.get_n_items ();

	        if (n == 0)
	            return;

            for (i = 0; i < n; i++) {
                builder.begin_array ();
                var item = liststore.get_item (i);
                builder.add_string_value (((Log)item).title);
                builder.add_string_value (((Log)item).subtitle);
                builder.add_string_value (((Log)item).text);
                builder.add_string_value (((Log)item).color);
                builder.add_string_value (((Log)item).notebook);
                builder.add_string_value (((Log)item).pinned);
                builder.end_array ();
            }
            builder.end_array ();

            Json.Generator generator = new Json.Generator ();
            Json.Node root = builder.get_root ();
            generator.set_root (root);
            json_string = generator.to_data (null);
            FileError error = null;

            var dir = File.new_for_path(app_dir);
            var file = File.new_for_path (file_name_n);
            try {
                if (!dir.query_exists()) {
                    dir.make_directory();
                }

                new Thread<void>.try ("", () => {
                    try {
                        GLib.FileUtils.set_contents (file.get_path (), json_string);
                    } catch (GLib.FileError e) {
                        warning ("Failed to save file: %s\n", e.message);
                    }
                    save_notes.callback ();
                });

                yield;

                if (error != null)
		            throw error;

                debug ("Save Normal Notes...");
            } catch (Error e) {
                warning ("Failed to save file: %s\n", e.message);
            }
        }

        public async void load_from_file_trash () {
            debug ("Load Trashed Notes...");
            try {
                var file = File.new_for_path(file_name_t);

                if (file.query_exists()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var parser = new Json.Parser();
                    parser.load_from_data(line);
                    var root = parser.get_root();
                    var array = root.get_array();
                    foreach (var tasks in array.get_elements()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element(0);
                        var subtitle = task.get_string_element(1);
                        var text = task.get_string_element(2);
                        var color = task.get_string_element(3);
                        var notebook = task.get_string_element(4);

                        win.make_trash_note (title, subtitle, text, color, notebook);
                    }
                }
            } catch (Error e) {
                warning ("Failed to load file: %s\n", e.message);
            }
        }

        public async void save_trash_notes (ListStore liststore) {
            string json_string_t = "";
            var builder = new Json.Builder ();

            builder.begin_array ();
	        uint i, n = liststore.get_n_items ();

            for (i = 0; i < n; i++) {
                builder.begin_array ();
                var item = liststore.get_item (i);
                builder.add_string_value (((TrashLog)item).title);
                builder.add_string_value (((TrashLog)item).subtitle);
                builder.add_string_value (((TrashLog)item).text);
                builder.add_string_value (((TrashLog)item).color);
                builder.add_string_value (((TrashLog)item).notebook);
                builder.end_array ();
            }
            builder.end_array ();

            Json.Generator generator = new Json.Generator ();
            Json.Node root = builder.get_root ();
            generator.set_root (root);
            json_string_t = generator.to_data (null);

            var dir = File.new_for_path(app_dir);
            var file = File.new_for_path (file_name_t);
            try {
                if (!dir.query_exists()) {
                    dir.make_directory();
                }

                new Thread<void>.try ("", () => {
                    try {
                        GLib.FileUtils.set_contents (file.get_path (), json_string_t);
                    } catch (GLib.FileError e) {
                        warning ("Failed to save file: %s\n", e.message);
                    }
                    save_trash_notes.callback ();
                });

                yield;
            } catch (Error e) {
                warning ("Failed to save file: %s\n", e.message);
            }
        }

        public async void save_notebooks (ListStore liststore) {
            string json_string_n = "";
            var builder = new Json.Builder ();

            builder.begin_array ();
	        uint i, n = liststore.get_n_items ();
            for (i = 0; i < n; i++) {
                builder.begin_array ();
                var item = liststore.get_item (i);
                builder.add_string_value (((Notebook)item).title);
                builder.end_array ();
            }
            builder.end_array ();

            Json.Generator generator = new Json.Generator ();
            Json.Node root = builder.get_root ();
            generator.set_root (root);
            json_string_n = generator.to_data (null);

            var dir = File.new_for_path(app_dir);
            var file = File.new_for_path (file_name_nb);
            try {
                if (!dir.query_exists()) {
                    dir.make_directory();
                }

                new Thread<void>.try ("", () => {
                    try {
                        GLib.FileUtils.set_contents (file.get_path (), json_string_n);
                    } catch (GLib.FileError e) {
                        warning ("Failed to save file: %s\n", e.message);
                    }
                    save_notebooks.callback ();
                });

                yield;
            } catch (Error e) {
                warning ("Failed to save file: %s\n", e.message);
            }
        }

        public async void load_from_file_nb () {
            debug ("Load Notebooks...");
            try {
                var file = File.new_for_path(file_name_nb);

                if (file.query_exists()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var parser = new Json.Parser();
                    parser.load_from_data(line);
                    var root = parser.get_root();
                    var array = root.get_array();
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
