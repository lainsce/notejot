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
public class Notejot.NoteRepository : Object {
    const string FILENAME = "saved_notes.json";

    Queue<Note> insert_queue = new Queue<Note> ();
    public Queue<Note> update_queue = new Queue<Note> ();
    Queue<string> delete_queue = new Queue<string> ();

    public async List<Note> get_notes () {
        try {
            var settings = new Settings ();
            if (settings.schema_version == 1) {
                var contents = yield FileUtils.read_text_file (FILENAME);

                if (contents == null)
                    return new List<Note> ();

                var json = Json.from_string (contents);

                if (json.get_node_type () != ARRAY)
                    return new List<Note> ();

                return Note.list_from_json (json);
            }
            return new List<Note> ();
        } catch (Error err) {
            critical ("Error: %s", err.message);
            return new List<Note> ();
        }
    }

    public void insert_note (Note note) {
        if (note != null) {
            insert_queue.push_tail (note);
        }
    }

    public void update_note (Note note) {
        update_queue.push_tail (note);
    }

    public async void update_notebook (Note? note, string nb) {
        if (note != null) {
            note.notebook = nb;
            update_queue.push_tail (note);
            save.begin ();
        }
    }

    public void delete_note (string id) {
        delete_queue.push_tail (id);
    }

    public async bool save () {
        var notes = yield get_notes ();

        Note? note = null;
        while ((note = update_queue.pop_head ()) != null) {
            var current_note = search_note_by_id (notes, note.id);

            if (current_note == null) {
                insert_queue.push_tail (note);
                continue;
            }
            current_note.title = note.title;
            current_note.subtitle = note.subtitle;
            current_note.text = note.text;
            current_note.notebook = note.notebook;
            current_note.color = note.color;
            current_note.picture = note.picture;
            current_note.pinned = note.pinned;
        }

        string? note_id = null;
        while ((note_id = delete_queue.pop_head ()) != null) {
            note = search_note_by_id (notes, note_id);

            if (note == null)
                continue;

            notes.remove (note);
        }

        note = null;
        while ((note = insert_queue.pop_head ()) != null)
            notes.append (note);

        var json_array = new Json.Array ();
        foreach (var item in notes)
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

    public inline Note? search_note_by_id (List<Note> notes, string id) {
        unowned var link = notes.search<string> (id, (note, id) => strcmp (note.id, id));
        return link?.data;
    }
}