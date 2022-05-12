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
public class Notejot.TrashRepository : Object {
    const string FILENAME = "saved_trash.json";

    Queue<Trash> insert_queue = new Queue<Trash> ();
    public Queue<Trash> update_queue = new Queue<Trash> ();
    Queue<string> delete_queue = new Queue<string> ();

    public async List<Trash> get_trashs () {
        try {
            var settings = new Settings ();
            if (settings.schema_version == 1) {
                var contents = yield FileUtils.read_text_file (FILENAME);

                if (contents == null)
                    return new List<Trash> ();

                var json = Json.from_string (contents);

                if (json.get_node_type () != ARRAY)
                    return new List<Trash> ();

                return Trash.list_from_json (json);
            }
            return new List<Trash> ();
        } catch (Error err) {
            critical ("Error: %s", err.message);
            return new List<Trash> ();
        }
    }

    public void insert_trash (Trash trash) {
        insert_queue.push_tail (trash);
    }

    public void update_trash (Trash trash) {
        update_queue.push_tail (trash);
    }

    public void delete_trash (string id) {
        delete_queue.push_tail (id);
    }

    public async bool save () {
        var trashs = yield get_trashs ();

        Trash? trash = null;
        while ((trash = update_queue.pop_head ()) != null) {
            var current_trash = search_trash_by_id (trashs, trash.id);

            if (current_trash == null) {
                insert_queue.push_tail (trash);
                continue;
            }
            current_trash.title = trash.title;
            current_trash.subtitle = trash.subtitle;
            current_trash.text = trash.text;
            current_trash.notebook = trash.notebook;
            current_trash.color = trash.color;
            current_trash.pinned = trash.pinned;
            current_trash.picture = trash.picture;
        }

        string? trash_id = null;
        while ((trash_id = delete_queue.pop_head ()) != null) {
            trash = search_trash_by_id (trashs, trash_id);

            if (trash == null)
                continue;

            trashs.remove (trash);
        }

        trash = null;
        while ((trash = insert_queue.pop_head ()) != null)
            trashs.append (trash);

        var json_array = new Json.Array ();
        foreach (var item in trashs)
            json_array.add_element (item.to_json ());

        var node = new Json.Node (ARRAY);
        node.set_array (json_array);

        var str = Json.to_string (node, false);

        try {
            return yield FileUtils.create_text_file (FILENAME, str);
        } catch (Error err) {
              critical ("Error: %s", err.message);
              return false;
        }
    }

    public inline Trash? search_trash_by_id (List<Trash> trashs, string id) {
        unowned var link = trashs.search<string> (id, (trash, id) => strcmp (trash.id, id));
        return link?.data;
    }
}
