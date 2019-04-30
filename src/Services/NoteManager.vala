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
    public class NoteManager {
        private string app_dir = Environment.get_user_data_dir () + "/com.github.lainsce.notejot";
        private string file_name;

        public NoteManager () {
            file_name = this.app_dir + "/saved_notes.json";
            debug ("%s".printf(file_name));
        }

        public void save_notes(Gee.ArrayList<Storage> notes) {
            string json_string = prepare_json_from_notes(notes);
            var dir = File.new_for_path(app_dir);
            var file = File.new_for_path (file_name);

            try {
                if (!dir.query_exists()) {
                    dir.make_directory();
                }

                if (file.query_exists ()) {
                    file.delete ();
                }

                var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
                var data_stream = new DataOutputStream (file_stream);
                data_stream.put_string(json_string);
            } catch (Error e) {
                warning ("Failed to save notes %s\n", e.message);
            }

        }

        private string prepare_json_from_notes (Gee.ArrayList<Storage> notes) {
            Json.Builder builder = new Json.Builder ();

            builder.begin_array ();
            foreach (Storage note in notes) {
                builder.begin_object ();
                builder.set_member_name ("x");
                builder.add_int_value (note.x);
                builder.set_member_name ("y");
                builder.add_int_value (note.y);
                builder.set_member_name ("w");
                builder.add_int_value (note.w);
                builder.set_member_name ("h");
                builder.add_int_value (note.h);
                builder.set_member_name ("color");
                builder.add_string_value (note.color);
                builder.set_member_name ("selected_color_text");
                builder.add_string_value (note.selected_color_text);
                builder.set_member_name ("pinned");
                builder.add_boolean_value (note.pinned);
                builder.set_member_name ("content");
                builder.add_string_value (note.content);
                builder.set_member_name ("title");
                builder.add_string_value (note.title);
                builder.end_object ();
            };
            builder.end_array ();

            Json.Generator generator = new Json.Generator ();
            Json.Node root = builder.get_root ();
            generator.set_root (root);

            string str = generator.to_data (null);
            return str;
        }

        public Gee.ArrayList<Storage> load_from_file() {
            Gee.ArrayList<Storage> stored_notes = new Gee.ArrayList<Storage>();

            try {
                var file = File.new_for_path(file_name);
                var json_string = "";
                if (file.query_exists()) {
                    string line;
                    var dis = new DataInputStream (file.read ());

                    while ((line = dis.read_line (null)) != null) {
                        json_string += line;
                    }

                    var parser = new Json.Parser();
                    parser.load_from_data(json_string);

                    var root = parser.get_root();
                    var array = root.get_array();
                    foreach (var item in array.get_elements()) {
                        var node = item.get_object();
                        string color = node.get_string_member("color");
                        string selected_color_text = node.get_string_member("selected_color_text");
                        bool pinned = node.get_boolean_member("pinned");
                        int64 x = node.get_int_member("x");
                        int64 y = node.get_int_member("y");
                        int64 w = node.get_int_member("w");
                        int64 h = node.get_int_member("h");
                        string content = node.get_string_member("content");
                        string title = node.get_string_member("title");
                        Storage stored_note = new Storage.from_storage(x, y, w, h, color, selected_color_text, pinned, content, title);
                        stored_notes.add(stored_note);
                    }

                }

            } catch (Error e) {
                warning ("Failed to load file: %s\n", e.message);
            }

            return stored_notes;
        }
    }
}
