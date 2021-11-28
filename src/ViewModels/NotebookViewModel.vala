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
public class Notejot.NotebookViewModel : Object {
    uint timeout_id = 0;

    public ObservableList<Notebook> notebooks { get; default = new ObservableList<Notebook> (); }
    public NotebookRepository? repository { get; construct; }

    public NotebookViewModel (NotebookRepository repository) {
        Object (repository: repository);
    }

    construct {
        populate_notebooks.begin ();
    }

    public void create_new_notebook (Notebook notebook) {
        notebooks.add (notebook);

        repository.insert_notebook (notebook);
        save_notebooks ();
    }

    public void update_notebook (Notebook notebook, string nb) {
        repository.update_notebook.begin (notebook, nb);

        save_notebooks ();
    }

    public void delete_notebook (Notebook notebook) {
        notebooks.remove (notebook);

        repository.delete_notebook (notebook.id);
        save_notebooks ();
    }

    async void populate_notebooks () {
        var notebooks = yield repository.get_notebooks ();
        this.notebooks.add_all (notebooks);
    }

    void save_notebooks () {
        if (timeout_id != 0)
            Source.remove (timeout_id);

        timeout_id = Timeout.add (500, () => {
            timeout_id = 0;

            repository.save.begin ();

            return Source.REMOVE;
        });
    }
}
