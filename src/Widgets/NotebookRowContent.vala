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
[GtkTemplate (ui = "/io/github/lainsce/Notejot/notebookrowcontent.ui")]
public class Notejot.NotebookRowContent : He.Bin {
    public signal void clicked ();
    public NotebookViewModel? notebooks {get; set;}

    [GtkChild]
    public unowned Gtk.Entry notebook_entry;

    Binding? text_binding;

    Notebook? _notebook;
    public Notebook? notebook {
        get { return _notebook; }
        set {
            if (value == _notebook)
                return;

            text_binding?.unbind ();

            _notebook = value;

            text_binding = _notebook?.bind_property ("title", notebook_entry, "text", SYNC_CREATE|BIDIRECTIONAL);
        }
    }

    construct {
    }

    [GtkCallback]
    async void on_edit_notebook_requested () {
        var vm = ((NotebookListView)MiscUtils.find_ancestor_of_type<NotebookListView>(this)).view_model;
        var notes = vm.notes;
        var nvm = ((NotebookListView)MiscUtils.find_ancestor_of_type<NotebookListView>(this)).nbview_model;
        var nbrepo = nvm.repository;
        List<Notebook> nbrepognbs = yield nbrepo.get_notebooks ();
        Notebook? target_notebook = nbrepo.search_notebook_by_id (nbrepognbs, notebook.id);

        uint i,n = notes.get_n_items ();
        for (i = 0; i < n; i++) {
            var item = notes.get_item (i);

            if (target_notebook.title == ((Note) item).notebook) {
                if (((Note) item).notebook != notebook_entry.get_text()) {
                    vm.update_notebook (((Note) item), notebook_entry.get_text());
                }
            }
        }

        ((NotebookListView)MiscUtils.find_ancestor_of_type<NotebookListView>(this)).nbview_model.update_notebook (notebook, notebook_entry.get_text());
    }

    [GtkCallback]
    void on_delete_button_clicked () {
        var vm = ((NotebookListView)MiscUtils.find_ancestor_of_type<NotebookListView>(this)).view_model;
        var notes = vm.notes;

        uint i,n = notes.get_n_items ();
        for (i = 0; i < n; i++) {
            var item = notes.get_item (i);

            if (((Note) item).notebook == notebook_entry.get_text()) {
                vm.update_notebook (((Note) item), "<i>No Notebook</i>");
            }
        }

        ((NotebookListView)MiscUtils.find_ancestor_of_type<NotebookListView>(this)).notebook_removal_requested (notebook);
    }
}
