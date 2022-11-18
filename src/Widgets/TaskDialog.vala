/*
* Copyright (C) 2017-2021 Lains
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
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/task_dialog.ui")]
    public class Widgets.TaskDialog : He.Window {
        public unowned MainWindow win = null;
        public TaskViewModel tsview_model {get; set;}

        [GtkChild]
        public unowned Gtk.Entry task_name_entry;
        [GtkChild]
        public unowned Gtk.Entry task_detail_entry;
        [GtkChild]
        public unowned Gtk.Button task_add_button;

        public TaskDialog (MainWindow win, TaskViewModel tsview_model) {
            Object (
                tsview_model: tsview_model
            );
            this.win = win;
            this.set_modal (true);
            this.set_transient_for (win);

            task_name_entry.notify["text"].connect (() => {
                if (task_name_entry.get_text () != "") {
                    task_add_button.sensitive = true;
                } else {
                    task_add_button.sensitive = false;
                }
            });
        }

        [GtkCallback]
        void on_new_task_requested () {
            var task = new Task ();
            task.title = task_name_entry.text;
            task.subtitle = task_detail_entry.text;
            task.text = task_detail_entry.text;
            task.color = "#797775";
            tsview_model.create_new_task (task);
            task_name_entry.text = "";
            this.close ();
        }
    }
}
