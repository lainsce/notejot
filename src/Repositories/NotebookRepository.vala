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
public class Notejot.NotebookRepository : Object {
    const string FILENAME = "saved_notebooks.json";

    Queue<Notebook> insert_queue = new Queue<Notebook> ();
    public Queue<Notebook> update_queue = new Queue<Notebook> ();
    Queue<string> delete_queue = new Queue<string> ();

    public async List<Notebook> get_notebooks () {
        try {
            var contents = yield FileUtils.read_text_file (FILENAME);

            if (contents == null)
                return new List<Notebook> ();

            var json = Json.from_string (contents);

            if (json.get_node_type () != ARRAY)
                return new List<Notebook> ();

            return Notebook.list_from_json (json);
        } catch (Error err) {
            critical ("Error: %s", err.message);
            return new List<Notebook> ();
        }
    }

    public void insert_notebook (Notebook notebook) {
        insert_queue.push_tail (notebook);
    }

    public async void update_notebook (Notebook? notebook, string nb) {
        if (notebook != null) {
            notebook.title = nb;
            update_queue.push_tail (notebook);
            save.begin ();
        }
    }

    public void delete_notebook (string id) {
        delete_queue.push_tail (id);
    }

    public async bool save () {
        var notebooks = yield get_notebooks ();

        Notebook? notebook = null;
        while ((notebook = update_queue.pop_head ()) != null) {
            var current_notebook = search_notebook_by_id (notebooks, notebook.id);

            if (current_notebook == null) {
                insert_queue.push_tail (notebook);
                continue;
            }
            current_notebook.title = notebook.title;
        }

        string? notebook_id = null;
        while ((notebook_id = delete_queue.pop_head ()) != null) {
            notebook = search_notebook_by_id (notebooks, notebook_id);

            if (notebook == null)
                continue;

            notebooks.remove (notebook);
        }

        notebook = null;
        while ((notebook = insert_queue.pop_head ()) != null)
            notebooks.append (notebook);

        var json_array = new Json.Array ();
        foreach (var item in notebooks)
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

    public inline Notebook? search_notebook_by_id (List<Notebook> notebooks, string id) {
        unowned var link = notebooks.search<string> (id, (notebook, id) => strcmp (notebook.id, id));
        return link?.data;
    }

    public inline Notebook? search_notebook_by_title (List<Notebook> notebooks, string title) {
        unowned var link = notebooks.search<string> (title, (notebook, title) => strcmp (notebook.title, title));
        return link?.data;
    }
}
