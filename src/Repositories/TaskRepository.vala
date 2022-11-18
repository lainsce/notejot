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
public class Notejot.TaskRepository : Object {
    const string FILENAME = "saved_tasks.json";

    Queue<Task> insert_queue = new Queue<Task> ();
    public Queue<Task> update_queue = new Queue<Task> ();
    Queue<string> delete_queue = new Queue<string> ();

    public async List<Task> get_tasks () {
        try {
            var settings = new Settings ();
            if (settings.schema_version == 1) {
                var contents = yield FileUtils.read_text_file (FILENAME);

                if (contents == null)
                    return new List<Task> ();

                var json = Json.from_string (contents);

                if (json.get_node_type () != ARRAY)
                    return new List<Task> ();

                return Task.list_from_json (json);
            }
            return new List<Task> ();
        } catch (Error err) {
            critical ("Error: %s", err.message);
            return new List<Task> ();
        }
    }

    public void insert_task (Task task) {
        insert_queue.push_tail (task);
    }

    public void update_task (Task task) {
        update_queue.push_tail (task);
    }

    public void delete_task (string id) {
        delete_queue.push_tail (id);
    }

    public async bool save () {
        var tasks = yield get_tasks ();

        Task? task = null;
        while ((task = update_queue.pop_head ()) != null) {
            var current_task = search_task_by_id (tasks, task.id);

            if (current_task == null) {
                insert_queue.push_tail (task);
                continue;
            }
            current_task.title = task.title;
            current_task.subtitle = task.subtitle;
            current_task.text = task.text;
            current_task.color = task.color;
        }

        string? task_id = null;
        while ((task_id = delete_queue.pop_head ()) != null) {
            task = search_task_by_id (tasks, task_id);

            if (task == null)
                continue;

            tasks.remove (task);
        }

        task = null;
        while ((task = insert_queue.pop_head ()) != null)
            tasks.append (task);

        var json_array = new Json.Array ();
        foreach (var item in tasks)
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

    public inline Task? search_task_by_id (List<Task> tasks, string id) {
        unowned var link = tasks.search<string> (id, (task, id) => strcmp (task.id, id));
        return link?.data;
    }
}
