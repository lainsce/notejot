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
        private string file_name;
        private string app_dir = Environment.get_user_cache_dir () + "/com.github.lainsce.notejot";

        public NoteManager () {
            file_name = this.app_dir + "/saved_notes.json";
            debug ("%s".printf(file_name));
        }

        public void save_notes(List<Storage> notes) {
            string json_string = prepare_json_from_notes(notes);
            var file = File.new_for_path (file_name);
            var dir = File.new_for_path(app_dir);

            try {
                if (!dir.query_exists()) {
                    dir.make_directory();
                }

                if (file.query_exists ()) {
                    file.delete ();
                }

                var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION );
                var data_stream = new DataOutputStream (file_stream);
                data_stream.put_string(json_string);
            } catch (Error e) {
                warning ("Failed to save notes %s\n", e.message);
            }

        }

        private string prepare_json_from_notes (List<Storage> notes) {
            string[] json_notes = new string[notes.length()];
            int index = 0;

            foreach (Storage note in notes) {
                json_notes[index++] = "{\"x\":\"%d\", \"y\":\"%d\", \"color\":\"%d\", \"content\":\"%s\"}".printf(note.x, note.y, note.color, note.content);
            }

            return "[%s]".printf(string.joinv(",", json_notes));
        }

        public Gee.ArrayList<Storage> load_from_file() {
            Gee.ArrayList<Storage> stored_notes = new Gee.ArrayList<Storage>();

            try {
                var file = File.new_for_path(file_name);
                var json_string = "";
                if (file.query_exists()) {
                    var dis = new DataInputStream (file.read ());
                    string line;

                    while ((line = dis.read_line (null)) != null) {
                        json_string += line;
                    }

                    var parser = new Json.Parser();
                    parser.load_from_data(json_string);

                    var root = parser.get_root();
                    var array = root.get_array();
                    foreach (var item in array.get_elements()) {
                        var node = item.get_object();
                        int x = int.parse(node.get_string_member("x"));
                        int y = int.parse(node.get_string_member("y"));
                        int color = int.parse(node.get_string_member("color"));
                        string content = node.get_string_member("content");
                        Storage stored_note = new Storage.from_storage(x, y, color, content);
                        stored_notes.add(stored_note);
                    }

                }

            } catch (Error e) {
                warning ("Failed to load file %s\n", e.message);
            }

            return stored_notes;
        }
    }
}