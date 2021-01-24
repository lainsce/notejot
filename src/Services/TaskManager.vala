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
        private string file_name;

        public TaskManager (MainWindow win) {
            this.win = win;
            file_name = this.app_dir + "/saved_notes.json";
        }

        public async void save_notes() {
            try {
                string json_string = prepare_json_from_notes().replace ("\"", "\\\"").replace ("/", "\\/");
                var dir = File.new_for_path(app_dir);
                var file = File.new_for_path (file_name);
                if (!dir.query_exists()) {
                    dir.make_directory();
                }
                GLib.FileUtils.set_contents (file.get_path (), json_string);
            } catch (Error e) {
                warning ("Failed to save: %s\n", e.message);
            }

        }

        private string prepare_json_from_notes () {
            builder = new Json.Builder ();

            builder.begin_array ();
            if (win.listview != null) {
                save_column.begin (builder, win.listview);
            }
            builder.end_array ();

            Json.Generator generator = new Json.Generator ();
            Json.Node root = builder.get_root ();
            generator.set_root (root);
            string str = generator.to_data (null);
            return str;
        }

        private async void save_column (Json.Builder builder,
                                         Views.ListView listview) {
            builder.begin_array ();
            if (listview.get_children () != null) {
                foreach (Widgets.Note item in listview.get_rows ()) {
                    builder.begin_array ();
                    builder.add_string_value (item.title);
                    builder.add_string_value (item.subtitle);
                    builder.add_string_value (item.text);
                    builder.add_string_value (item.color);
                    builder.end_array ();
                }
            }
	        builder.end_array ();
        }

        public async void load_from_file () {
            try {
                var file = File.new_for_path(file_name);

                if (file.query_exists()) {
                    string line;
                    GLib.FileUtils.get_contents (file.get_path (), out line);
                    var parser = new Json.Parser();
                    parser.load_from_data(line.replace ("\\/", "/").replace ("\\\"", "\""));
                    var root = parser.get_root();
                    var array = root.get_array();
                    var columns = array.get_array_element (0);
                    foreach (var tasks in columns.get_elements()) {
                        var task = tasks.get_array ();
                        var title = task.get_string_element(0);
                        var subtitle = task.get_string_element(1);
                        var text = task.get_string_element(2);
                        var color = task.get_string_element(3);

                        win.listview.new_taskbox.begin (win, title, subtitle, text, color);
                    }
                }
            } catch (Error e) {
                warning ("Failed to load file: %s\n", e.message);
            }
        }
    }
}
