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
public class Notejot.TaskViewModel : Object {
    uint timeout_id = 0;

    public ObservableList<Task> tasks { get; default = new ObservableList<Task> (); }
    public TaskRepository? repository { private get; construct; }

    public TaskViewModel (TaskRepository repository) {
        Object (repository: repository);
    }

    construct {
        populate_tasks.begin ();
    }

    public void create_new_task (Task? task) {
        var dt = new GLib.DateTime.now_local ();

        var n = new Task () {
            title = _("New Task"),
            subtitle = "%s".printf (dt.format ("%A, %d/%m %H∶%M")),
            text = _("Task text here"),
            color = "#797775",
        };

        if (task == null) {
            tasks.add (n);
            repository.insert_task (n);
        } else {
            tasks.add (task);
            repository.insert_task (task);
        }
        save_tasks ();
    }

    public void restore_trash (Trash trash) {
        var task = new Task () {
            title = trash.title,
            subtitle = trash.subtitle,
            text = trash.text,
            color = trash.color,
        };

        tasks.add (task);

        repository.insert_task (task);
        save_tasks ();
    }

    public void update_task (Task task) {
        repository.update_task (task);

        save_tasks ();
    }

    public void update_task_color (Task task, string color) {
        task.color = color;

        var style_manager = new StyleManager ();
        style_manager.set_css (color);
        repository.update_task (task);

        save_tasks ();
    }

    public void delete_task (Task task) {
        tasks.remove (task);

        repository.delete_task (task.id);
        save_tasks ();
    }

    async void populate_tasks () {
        var tasks = yield repository.get_tasks ();
        this.tasks.add_all (tasks);
    }

    void save_tasks () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = Timeout.add (500, () => {
            timeout_id = 0;

            repository.save.begin ();

            return Source.REMOVE;
        });
    }
}
