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
    [GtkTemplate (ui = "/io/github/lainsce/Notejot/edit_notebooks.ui")]
    public class Widgets.EditNotebooksDialog : He.Window {
        public unowned MainWindow win = null;
        public NotebookViewModel nbview_model {get; set;}
        public NoteViewModel view_model {get; set;}

        [GtkChild]
        public unowned Gtk.Entry notebook_name_entry;
        [GtkChild]
        public unowned Gtk.Button notebook_add_button;

        public EditNotebooksDialog (MainWindow win, NotebookViewModel nbview_model, NoteViewModel view_model) {
            Object (
                nbview_model: nbview_model,
                view_model: view_model
            );
            this.win = win;
            this.set_modal (true);
            this.set_transient_for (win);

            notebook_name_entry.notify["text"].connect (() => {
                if (notebook_name_entry.get_text () != "") {
                    notebook_add_button.sensitive = true;
                } else {
                    notebook_add_button.sensitive = false;
                }
            });
        }

        [GtkCallback]
        void on_new_notebook_requested () {
            var notebook = new Notebook ();
            notebook.title = notebook_name_entry.text;
            nbview_model.create_new_notebook (notebook);
            notebook_name_entry.text = "";
        }
    }
}
